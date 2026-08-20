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

## 관련 위치

- 글로벌 룰 정본: `shared/global-rules/core.md`
- Skill 정본: `skills/custom/mia/`
- 원본 자료: `[user data]/260820_한도구가 나머지 도구 직접 조정/`
