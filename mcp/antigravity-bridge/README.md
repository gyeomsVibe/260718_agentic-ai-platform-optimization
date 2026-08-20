# antigravity-bridge

Antigravity(`agy` CLI)를 MCP 도구로 노출해, Codex나 Claude Code가 작업을 위임할 수 있게 하는 브리지.
`mcp-server-google-antigravity@1.0.2`의 **권한 강화 포크**다.

- 원본·라이선스·변경 이력: [SOURCE.md](SOURCE.md)
- 포크 사유가 된 감사: [agent-swarm/audits/](../../agent-swarm/audits/2026-08-21_mcp-server-google-antigravity.md)

## 상류와 무엇이 다른가

| | 상류 | 이 포크 |
|---|---|---|
| 자동승인 기본값 | `true` → `--dangerously-skip-permissions` | **`false`** (환경변수로 켜지지 않음) |
| 샌드박스 기본값 | `false` | **`true`** (`--sandbox`) |
| 파일 읽기·쓰기 도구 | 6종 노출, 경로 제한 없음 | **전부 제거** |
| 자식 환경변수 | `process.env` 전체 상속 | **허용 목록만 전달** |
| 도구 수 | 14 | 9 |

## 상태

⚠️ **아직 어디에도 등록하지 않았다.** 의존성도 설치하지 않았다.
현재 검증된 것은 구문 검사(`node --check`)뿐이며, **런타임 동작은 미검증**이다.

## 쓰려면 (아직 실행하지 않은 단계)

1. 의존성 설치 — 이 디렉터리에서 `npm install`. 전이 포함 94개 패키지가 설치된다.
2. MCP 클라이언트에 등록 — Codex 기준:

```bash
codex mcp add antigravity-bridge -- node "D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/mcp/antigravity-bridge/index.js"
```

3. `antigravity_health`로 `agy` 탐지·버전을 먼저 확인한 뒤 위임을 시도한다.

> 등록은 **앞으로의 모든 세션에 도구를 추가하는 상시 설정 변경**이다. 별도 판단 후 진행한다.

## 도구 9종

| 도구 | 용도 |
|---|---|
| `use_antigravity` | 위임 작업 시작 (비동기, `jobId` 즉시 반환) |
| `antigravity_continue` | 기존 대화 이어서 위임 |
| `antigravity_result` | 결과 폴링·회수 |
| `antigravity_jobs` | 작업 목록 |
| `antigravity_cancel` | 실행 중 작업 취소 |
| `antigravity_cleanup` | 오래된 작업 레코드 정리 |
| `antigravity_models` | 사용 가능 모델 조회 (`agy models`) |
| `antigravity_agents` | 에이전트 프로필 조회 (`agy agents`) |
| `antigravity_health` | `agy` 탐지·버전·기본값 진단 |

## 알려진 한계

헤드리스 `agy`는 권한 프롬프트에서 멈추므로, `auto_approve: false`면 쓰기를 동반한 작업이
타임아웃될 수 있다. 상류가 기본값을 `true`로 둔 이유가 이것이다.

이 포크는 **무제한 실행을 기본값에서 예외로 강등**했을 뿐, 없애지 못했다.
읽기 전용 위임에 한해서는 기본값으로도 동작할 여지가 있으나
([실험 1 F2](../../agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md)) 아직 측정하지 않았다.
