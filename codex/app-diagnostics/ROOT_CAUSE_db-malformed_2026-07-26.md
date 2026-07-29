# Codex 시작 오류 "database disk image is malformed" 근본 수정 (2026-07-26)

> Codex(ChatGPT) 데스크톱 앱이 **"ChatGPT failed to start — database disk image is
> malformed"** 로 시작되지 않던 문제의 근본 원인 진단·수정·재발 방지(항체) 기록.

## 증상

- 앱 실행 시 다이얼로그: `ChatGPT failed to start. database disk image is malformed`
- 실패 로그(`…\LocalCache\Local\Codex\Logs\…`):
  ```
  warning  Failed to repair missing thread cwd metadata  errorName=SqliteError
  error    Desktop bootstrap failed to start the main app  phase=bootstrap-import-main
  ```

## 근본 원인 (실측)

앱의 Chromium 내부 DB가 아니라 **Codex 자체 SQLite DB(`~/.codex/`)가 손상**된 것이었다.
부팅 시 앱이 `state_5.sqlite`(대화 스레드의 작업폴더 = "thread cwd" 메타데이터)를 읽는데
이 파일이 malformed라 `bootstrap-import-main`에서 중단됐다.

손상 확정 DB 5개 (`PRAGMA integrity_check` = *database disk image is malformed*):

| 파일 | 크기 |
|---|---|
| `~/.codex/logs_2.sqlite` | 394 MB (비정상 비대) |
| `~/.codex/state_5.sqlite` | 1.7 MB |
| `~/.codex/sqlite/logs_2.sqlite` | 17 MB |
| `~/.codex/sqlite/state_5.sqlite` | 179 KB |
| `~/.codex/sqlite/codex-dev.db` | 98 KB |

**단일 사건**: 5개 모두 수정시각이 **2026-07-25 21:01~21:11**의 10분 창에 집중.
디스크 여유는 101GB(디스크 풀 아님). → **WAL 기록 도중 비정상 종료(크래시/강제전원)로
여러 DB가 동시에 깨진 것**으로 결론. 루트 `logs_2.sqlite`의 394MB 비대는 로그 DB 미정리로,
손상을 키운 부수 요인.

## 수정 (가역적)

1. 크래시 루프 중인 `ChatGPT.exe` 전부 종료(파일 잠금 해제).
2. 손상 DB 5개 + 동반 파일(`-wal`/`-shm`)을 `~/.codex/_corrupt-db-quarantine-20260726/`
   로 **이동(삭제 아님)**. `auth.json`·`config.toml`·`history.jsonl`은 건드리지 않음 → 로그인 유지.
3. 앱 재실행 → 앱이 DB를 새로 생성.

### 검증 결과 (실측)
- 재시작 로그에 `bootstrap failed`·`malformed` 없음, 앱 정상 실행.
- DB 재생성·무결성 정상: `state_5.sqlite`(4KB), `codex-dev.db`, `logs_2.sqlite` **394MB→48KB**.
- 항체 스크립트 전체 스캔: **정상 37 / 손상 0**.

> 격리 폴더는 문제없음이 확인되면 삭제해도 된다. 되돌리려면 폴더 안의 파일을 원위치로 이동.

## 2차 결함: "handshake timed out" (DB 손상 뒤에 가려져 있던 문제)

DB 손상을 고치자 다른 오류가 드러났다: **`Codex app-server initialize handshake timed out`**.

- 실패 로그: `state db backfill is running at ...; waiting up to 30s` →
  `failed to initialize sqlite state runtime ...: timed out waiting for state db backfill after 30s (status: running)`
- **원인 사슬**:
  1. 폭주 세션이 **2.5GB짜리 단일 rollout 파일**(정상 중앙값 5.9MB) 등 비대 기록을 남김 → 이게 DB 손상의 시작점이기도 함.
  2. 새 DB 생성 후 앱이 과거 세션 기록 **9.15GB를 state DB로 재구축(backfill)** 시도 → 30초 안에 못 끝냄 → 프로세스 강제 종료.
  3. 그 결과 `state_5.sqlite`의 `backfill_state.status`가 **`running`으로 영구 고착** → 실행 주체가 없는데 "작업 중"으로 오해하는 **교착(stale lock)**. 이후 매 실행이 30초 대기 후 실패.
- **수정 (가역적)**:
  1. 100MB 초과 비대 rollout **24개(8.64GB)를 `~/codex-oversized-rollouts-...`로 격리**(이동). 남은 작업량 9.15GB→0.5GB.
  2. state DB 백업 후, 앱 자체의 stale-takeover 경로(`WHERE status!=? OR updated_at<=?`)가 동작하도록 `backfill_state.updated_at=0`으로 낮춰 잠금 해제.
  3. app-server를 GUI 밖에서 실행해 **backfill 완주**(`status='complete'`, threads 45→134행).
- **검증**: 핸드셰이크 `success, 670ms`(이전 30초 타임아웃), 앱 창 정상 생성·안정 실행.

## 항체 (재발 조기 탐지·수리)

[codex-db-doctor.py](codex-db-doctor.py) — 위 **두 가지 실패 모드를 한 도구로** 진단·수리한다:
① DB 손상, ② backfill 교착 잠금 + 비대 rollout. 재발 시 이 스크립트 하나로 끝낸다.

```bash
# 점검만 (변경 없음, 문제 있으면 exit 2). 세 항목을 각각 리포트:
#   [1] DB 무결성  [2] backfill 잠금  [3] 비대 rollout
python codex-db-doctor.py

# 수리 = 손상 DB 격리 + 비대 rollout 격리 + 교착 잠금 해제. 먼저 ChatGPT 앱 종료할 것
python codex-db-doctor.py --quarantine
```

- 정상 DB는 건드리지 않고, 인증/설정 파일(`auth.json` 등)은 대상에서 제외한다.
- 교착 잠금 해제 전 state DB를 `.bak-before-lock-reset`으로 백업한다.
- 삭제가 아니라 격리(이동)·최소 수정이라 되돌릴 수 있다.

## 재발 방지 팁

- 앱 사용 중 강제 종료(전원 차단·강제 리셋)를 피한다. WAL 기록 중 종료가 손상의 주원인.
- `logs_2.sqlite`나 rollout 파일이 수백 MB로 커지면 이상 신호 — 위 doctor로 주기 점검.
