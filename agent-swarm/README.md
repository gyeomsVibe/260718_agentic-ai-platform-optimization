# agent-swarm

3대 AI 도구(Antigravity, Claude Code, Codex)의 **상호 오케스트레이션 프로토콜 정본과 감사 로그**를 두는 섹션.

## 이 폴더의 정체성 (2026-08-20 재정의)

- ✅ **프로토콜 정본 + 오케스트레이션 감사 로그 보관소**
- ❌ **에이전트 간 메시지 버스가 아니다.** 어떤 에이전트도 이 폴더를 폴링하지 않는다.

2026-07-26 원안은 이 폴더를 "3대 AI가 서로 대화하는 공간"으로 설계했으나,
그 사이 각 도구가 에이전트 간 통신을 제품 기능(Claude Code 크로스세션 메시징·Agent Teams,
Antigravity CLI, MCP)으로 내장하면서 파일 기반 자작 버스는 열등한 구현이 되었다.
전환 근거와 대안 비교는 아래 보고서 §2.1·§3에 있다.

## 문서

| 파일 | 내용 |
|---|---|
| [AGENT_SWARM_INTEGRATED_REPORT_2026-08-20.md](AGENT_SWARM_INTEGRATED_REPORT_2026-08-20.md) | 통합 최종보고서. 자료 3건 전수 검증, 대안 비교, MIA Swarm Protocol v2, 실행 실험 3건, 위험·승인 항목 |

## 실험 로그 (`logs/`)

위임 1건 = 로그 1개 (프로토콜 S7.1). 이 폴더는 산출물 보관소이지 메시지 버스가 아니다.

| 로그 | 판정 | 핵심 발견 |
|---|---|---|
| [exp1 · Codex → Antigravity 위임](logs/2026-08-21_exp1_codex-to-antigravity.md) | ⚠️ 부분 성공 | Codex 샌드박스 안에서는 `agy` 인증 불가 (F4). 자료 C의 기법은 샌드박스 해제가 전제 (F5) |
| [exp2 · 지시 위반 적발](logs/2026-08-21_exp2_instruction-violation-detection.md) | ⚠️ 부분 수행 | 실행자는 제약 준수 (F12). 하우스키핑을 위반으로 오판하면 안 됨 (F13) |
| [exp3 · Claude Agent Teams](logs/2026-08-21_exp3_claude-agent-teams.md) | ❌ 실패 | `SendMessage`는 있고 `ListAgents`는 없음 (F8). 형제 에이전트는 서로 발견 불가 (F9) |
| [exp4·5 · MCP 브리지 위임과 위반 적발](logs/2026-08-21_exp4-5_mcp-bridge-delegation.md) | ✅ **PASS** | **MCP 경유는 샌드박스를 켠 채 인증에 성공한다 (F18) — exp1의 "샌드박스 해제 필수" 결론을 뒤집음.** 감독자 판별력도 실증 (F22) |

## 소스 감사 (`audits/`)

외부 브리지·플러그인은 설치 전 감사하고 결과를 남긴다 (프로토콜 S6.5).

| 감사 | 판정 | 핵심 |
|---|---|---|
| [mcp-server-google-antigravity](audits/2026-08-21_mcp-server-google-antigravity.md) | ❌ 현 상태 부적합 | 설치 시 코드 실행·네트워크·텔레메트리 전부 없음. 그러나 자동승인이 기본값이라 **R1을 회피하는 경로가 아니라 내장한 경로** (F17) |

## 관련 위치

- 글로벌 룰 정본: `shared/global-rules/core.md`
- Skill 정본: `skills/custom/mia/`
- 원본 자료: `[user data]/260820_한도구가 나머지 도구 직접 조정/`
