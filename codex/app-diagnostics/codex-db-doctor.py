#!/usr/bin/env python3
"""codex-db-doctor — Codex(ChatGPT) 데스크톱 앱 시작 오류 항체.

Codex가 시작되지 않는 두 가지 원인을 한 도구로 진단·수리한다.

  ① DB 손상   "database disk image is malformed"
     -> ~/.codex의 SQLite DB 손상. 손상 DB만 격리하면 앱이 새로 만든다.

  ② 교착 잠금 "Codex app-server initialize handshake timed out"
     -> ①을 고쳐 DB를 새로 만들면 앱이 과거 세션 기록을 state DB로 재구축
        (backfill)한다. 이 작업이 30초를 넘기면 앱이 프로세스를 죽이는데,
        그때 backfill_state.status가 'running'으로 남아 **아무도 실행하지 않는
        작업을 영원히 기다리는 교착**이 된다. 매 실행이 30초 대기 후 실패한다.
        수리: (a) 비대 rollout 파일을 스캔 경로 밖으로 격리해 30초 안에 끝나게 하고
              (b) updated_at을 0으로 낮춰 앱 자체의 stale-takeover 경로로 잠금 해제.

동작:
  기본        : 점검만 하고 리포트 출력(변경 없음). 문제 있으면 exit code 2.
  --quarantine: 손상 DB + 동반 파일(-wal/-shm/-journal)을 격리 폴더로 이동하고,
                교착 잠금이 있으면 해제하며, 비대 rollout 파일을 격리한다.
                (모두 삭제가 아니라 이동/최소 수정이라 되돌릴 수 있다.)

안전장치:
  - auth.json·config.toml 등 인증/설정 파일은 절대 건드리지 않는다.
  - 정상(ok) DB는 이동하지 않는다. 잠금 해제 전 state DB를 .bak으로 백업한다.
  - 수리 전 앱이 실행 중이면 중단한다(파일 잠금·재손상 방지).

사용:
  python codex-db-doctor.py                 # 점검만
  python codex-db-doctor.py --quarantine    # 수리 (앱 종료 후 실행)
"""
import argparse
import datetime as _dt
import os
import shutil
import sqlite3
import sys

CODEX_HOME = os.path.join(os.path.expanduser("~"), ".codex")
SQLITE_MAGIC = b"SQLite format 3\x00"
COMPANION_SUFFIXES = ("", "-wal", "-shm", "-journal")
STATE_DB = "state_5.sqlite"
# rollout 파일 정상 크기는 보통 한 자리 MB다. 이 값을 넘으면 backfill이 30초를
# 못 지켜 교착의 원인이 되므로 격리 대상으로 본다.
ROLLOUT_MAX_BYTES = 100 * 1024 * 1024
ROLLOUT_DIRS = ("archived_sessions", "sessions")


def is_sqlite(path):
    try:
        with open(path, "rb") as f:
            return f.read(16) == SQLITE_MAGIC
    except OSError:
        return False


def find_sqlite_files(root):
    for dirpath, _dirs, files in os.walk(root):
        # 이미 만든 격리 폴더는 다시 스캔하지 않는다.
        if "_corrupt-db-quarantine-" in dirpath:
            continue
        for name in files:
            p = os.path.join(dirpath, name)
            if is_sqlite(p):
                yield p


def integrity(path):
    """(is_ok, detail) 반환. 손상이면 예외/실패 메시지를 detail에 담는다."""
    try:
        con = sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=5)
        try:
            row = con.execute("PRAGMA integrity_check").fetchone()
            detail = row[0] if row else "(빈 응답)"
            return detail == "ok", detail
        finally:
            con.close()
    except sqlite3.DatabaseError as e:
        return False, f"[DatabaseError] {e}"
    except Exception as e:  # noqa: BLE001 - 진단 도구는 모든 실패를 보고한다
        return False, f"[{type(e).__name__}] {e}"


def app_running():
    """ChatGPT.exe 실행 여부(Windows). 다른 OS면 None."""
    if os.name != "nt":
        return None
    try:
        out = os.popen('tasklist /FI "IMAGENAME eq ChatGPT.exe" /NH').read()
        return "ChatGPT.exe" in out
    except Exception:  # noqa: BLE001
        return None


def quarantine(bad_paths, root):
    stamp = _dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    qroot = os.path.join(root, f"_corrupt-db-quarantine-{stamp}")
    moved = []
    for db in bad_paths:
        for suf in COMPANION_SUFFIXES:
            src = db + suf
            if not os.path.exists(src):
                continue
            rel = os.path.relpath(src, root)
            dest = os.path.join(qroot, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.move(src, dest)
            moved.append(rel)
    return qroot, moved


def check_stale_backfill_lock(root):
    """(is_stale, detail) 반환. backfill_state.status='running'인데 실제로 아무도
    실행하지 않는 교착 상태를 감지한다. 앱이 실행 중이 아니어야 의미가 있다."""
    db = os.path.join(root, STATE_DB)
    if not os.path.exists(db):
        return False, "state DB 없음(앱이 재생성 예정)"
    try:
        con = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=5)
        try:
            has = con.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='backfill_state'"
            ).fetchone()
            if not has:
                return False, "backfill_state 테이블 없음"
            row = con.execute(
                "SELECT status, last_success_at FROM backfill_state WHERE id=1"
            ).fetchone()
        finally:
            con.close()
    except sqlite3.DatabaseError as e:
        return False, f"[읽기 실패] {e}"
    if not row:
        return False, "backfill_state 비어 있음"
    status, last_success = row
    if status == "running":
        return True, "status='running'으로 고착 (교착 — 앱이 매 시작 30초 대기 후 실패)"
    return False, f"status='{status}' (정상)"


def repair_stale_lock(root):
    """state DB 백업 후 backfill_state.updated_at=0으로 낮춰, 앱 자체의
    stale-takeover 경로(WHERE status!=? OR updated_at<=?)로 잠금을 풀게 한다.
    임의 상태값을 발명하지 않고 앱의 정식 복구 경로만 이용한다."""
    db = os.path.join(root, STATE_DB)
    bak = db + ".bak-before-lock-reset"
    shutil.copy2(db, bak)
    con = sqlite3.connect(db, timeout=10)
    try:
        con.execute("UPDATE backfill_state SET updated_at=0 WHERE id=1")
        con.commit()
    finally:
        con.close()
    return bak


def find_oversized_rollouts(root):
    """backfill을 30초 안에 못 끝내게 만드는 비대 rollout(.jsonl) 파일 목록."""
    hits = []
    for sub in ROLLOUT_DIRS:
        d = os.path.join(root, sub)
        if not os.path.isdir(d):
            continue
        for dirpath, _dirs, files in os.walk(d):
            for name in files:
                if not (name.startswith("rollout-") and name.endswith(".jsonl")):
                    continue
                p = os.path.join(dirpath, name)
                try:
                    if os.path.getsize(p) > ROLLOUT_MAX_BYTES:
                        hits.append(p)
                except OSError:
                    pass
    return hits


def quarantine_rollouts(paths, root):
    """비대 rollout을 root '밖'으로 이동한다(스캔·backfill 대상에서 제외되도록)."""
    stamp = _dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    qroot = os.path.join(os.path.dirname(root), f"codex-oversized-rollouts-{stamp}")
    moved = []
    for p in paths:
        sub = os.path.join(qroot, os.path.basename(os.path.dirname(p)))
        os.makedirs(sub, exist_ok=True)
        shutil.move(p, os.path.join(sub, os.path.basename(p)))
        moved.append(os.path.relpath(p, root))
    return qroot, moved


def main():
    ap = argparse.ArgumentParser(description="Codex ~/.codex SQLite 무결성 항체")
    ap.add_argument("--quarantine", action="store_true",
                    help="손상 DB를 격리(백업 후 이동)하여 수리한다")
    ap.add_argument("--root", default=CODEX_HOME,
                    help=f"검사 루트(기본: {CODEX_HOME})")
    args = ap.parse_args()

    if not os.path.isdir(args.root):
        print(f"[중단] 폴더 없음: {args.root}")
        return 1

    good, bad = [], []
    for p in find_sqlite_files(args.root):
        ok, detail = integrity(p)
        rel = os.path.relpath(p, args.root)
        if ok:
            good.append(rel)
        else:
            bad.append((p, rel, detail))

    stale, stale_detail = check_stale_backfill_lock(args.root)
    oversized = find_oversized_rollouts(args.root)

    print(f"검사 루트: {args.root}")
    print(f"[1] DB 무결성 : 정상 {len(good)}개 / 손상 {len(bad)}개")
    for _p, rel, detail in bad:
        print(f"      [손상] {rel} -> {detail[:80]}")
    print(f"[2] backfill 잠금: {'교착!' if stale else 'OK'} - {stale_detail}")
    over_gb = sum(os.path.getsize(p) for p in oversized) / (1024 ** 3)
    print(f"[3] 비대 rollout : {len(oversized)}개 (100MB 초과, 합계 {over_gb:.2f}GB)")

    problems = bool(bad) or stale or bool(oversized)
    if not problems:
        print("\n모든 항목 정상. 시작 오류의 알려진 원인 없음.")
        return 0

    if not args.quarantine:
        print("\n수리하려면: python codex-db-doctor.py --quarantine")
        print("(먼저 ChatGPT 앱을 완전히 종료할 것 — 파일 잠금·재손상 방지)")
        return 2

    if app_running():
        print("\n[중단] ChatGPT.exe 실행 중. 앱을 종료한 뒤 다시 실행하세요.")
        return 3

    print("\n=== 수리 ===")
    if bad:
        qroot, moved = quarantine([p for p, _r, _d in bad], args.root)
        print(f"손상 DB {len(moved)}개 격리 -> {qroot}")
    if oversized:
        qroot, moved = quarantine_rollouts(oversized, args.root)
        print(f"비대 rollout {len(moved)}개 격리 -> {qroot}")
    if stale:
        bak = repair_stale_lock(args.root)
        print(f"backfill 교착 잠금 해제 (state DB 백업: {os.path.basename(bak)})")
    print("\n이제 Codex 앱을 다시 실행하세요. DB 재생성·backfill 재개로 정상 시작됩니다.")
    print("격리 폴더는 문제없으면 나중에 삭제 가능(되돌리려면 원위치로 이동 — 단 재발 위험).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
