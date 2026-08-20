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

## 상태 (2026-08-21)

✅ **설치·등록·런타임 검증 완료.** Codex에 `antigravity-bridge`로 등록됨 (`enabled`).

| 검증 | 결과 |
|---|---|
| stdio 핸드셰이크 | 서버 기동, `serverInfo: antigravity-bridge-fork@1.0.2-fork.1` |
| 노출 도구 | **9종** — 제거한 파일 도구 0건, `write_to_file` 파라미터 없음 |
| `antigravity_health` (Codex 경유) | `agy` 1.1.16 탐지, `autoApprove: false`, `sandbox: true` |
| 실제 위임 | 작업 완료(`done`), **샌드박스 켠 채 자동승인 없이 인증 성공** |
| `npm audit` | 취약점 0건 |

상세: [실험 4·5 로그](../../agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md)

## 재설치 방법

의존성은 **설치 시 스크립트 실행 없이** 넣는다. 유일한 네이티브 모듈 `node-pty`는 선택
의존성이고, 없으면 코드가 일반 `spawn`으로 폴백하며 기동 시 그 사실을 stderr에 알린다.

```bash
npm install --omit=optional --ignore-scripts
```

등록 (Codex):

```bash
codex mcp add antigravity-bridge -- node "D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/mcp/antigravity-bridge/index.js"
```

## 무인 위임 호출 방법

`codex exec`의 기본 승인 정책은 `never`라 MCP 도구 호출이 그대로 막힌다
(`MCP tool call requires approval, but approval policy is never`).
`--approve-for-me`를 쓰고, **`-s`는 함께 쓸 수 없다** (자체 샌드박스를 적용하기 때문).

```bash
codex exec --approve-for-me "antigravity-bridge로 antigravity_health를 호출하고 결과를 보고해"
```

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
