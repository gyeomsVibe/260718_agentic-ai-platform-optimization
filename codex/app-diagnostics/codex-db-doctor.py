#!/usr/bin/env python3
"""codex-db-doctor — Codex(ChatGPT) 데스크톱 앱의 SQLite DB 무결성 항체.

용도:
  "database disk image is malformed"로 앱이 시작되지 않는 근본 원인(=~/.codex 내
  SQLite DB 손상)을 조기에 탐지하고, 손상 DB만 안전하게 격리(백업 후 이동)한다.
  격리하면 앱이 다음 실행 때 해당 DB를 새로 만들므로 시작 오류가 해소된다.

동작:
  기본       : 스캔 후 무결성 리포트만 출력(변경 없음). 손상 있으면 exit code 2.
  --quarantine: 손상 DB + 동반 파일(-wal/-shm/-journal)을 타임스탬프 격리 폴더로 이동.
                (삭제가 아니라 이동이라 되돌릴 수 있다.)

안전장치:
  - auth.json·config.toml 등 인증/설정 파일은 절대 건드리지 않는다(SQLite만 대상).
  - 정상(ok) DB는 이동하지 않는다.
  - 격리 전 앱이 실행 중이면 경고한다(파일 잠금 방지 위해 먼저 종료 권장).

사용:
  python codex-db-doctor.py                 # 점검만
  python codex-db-doctor.py --quarantine    # 손상 DB 격리(수리)
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

    print(f"검사 루트: {args.root}")
    print(f"정상 {len(good)}개 / 손상 {len(bad)}개\n")
    for _p, rel, detail in bad:
        print(f"  [손상] {rel}\n         -> {detail[:100]}")

    if not bad:
        print("모든 Codex SQLite DB 정상. 시작 오류의 DB 손상 원인 없음.")
        return 0

    if not args.quarantine:
        print("\n수리하려면: python codex-db-doctor.py --quarantine")
        print("(먼저 ChatGPT 앱을 완전히 종료할 것 — 파일 잠금 방지)")
        return 2

    running = app_running()
    if running:
        print("\n[중단] ChatGPT.exe 실행 중. 앱을 종료한 뒤 다시 실행하세요.")
        return 3

    qroot, moved = quarantine([p for p, _r, _d in bad], args.root)
    print(f"\n격리 완료 -> {qroot}")
    for m in moved:
        print(f"  이동: {m}")
    print("\n이제 Codex 앱을 다시 실행하면 DB가 새로 생성되어 시작됩니다.")
    print("문제 없으면 위 격리 폴더는 나중에 삭제해도 됩니다(되돌리려면 원위치로 이동).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
