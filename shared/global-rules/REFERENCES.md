# 역할별 규칙의 근거

전역 규칙의 역할 문구가 어디서 왔는지 남긴다. 근거 없는 규칙은 관례가 아니라 결함이다(검증 절).

## 1. 역할 구조: 지휘자–작업자–검증자

| 역할 | 도구 | 근거 |
|---|---|---|
| 지휘자(orchestrator) | Codex | Anthropic, *Building Effective Agents* (2024) — orchestrator-workers: 중앙 모델이 과제를 동적으로 나누고 위임하고 결과를 종합한다. 코딩처럼 바뀔 파일 수를 미리 알 수 없는 과제에 맞는다. |
| 작업자(worker) | Antigravity, 로컬 모델 | 같은 문서 — 작업자는 위임받은 하위 과제만 수행한다. |
| 검증자(evaluator) | Claude Code | 같은 문서 — evaluator-optimizer: 한 모델이 만들고 다른 모델이 **명확한 평가 기준**으로 평가할 때 효과가 있다. |

## 2. 실패 유형과 그에 대응하는 규칙

Cemri et al., *Why Do Multi-Agent LLM Systems Fail?* (NeurIPS 2025, arXiv:2503.13657) — 7개 프레임워크 1,600여 실행 기록에서 14개 실패 유형(MAST)을 도출했다. 분포는 명세 문제 41.77%, 에이전트 간 불일치 36.94%, 검증 실패 21.30%다.

| MAST 실패 유형 | 대응 규칙 | 적용 도구 |
|---|---|---|
| FM-1.1 과제 명세 불이행, FM-2.2 확인 요청 실패 | 위임마다 목표·허용 파일·기계 검사 가능한 합격 명령·종료 조건. 구체화 못 하면 위임하지 않는다 | Codex |
| FM-1.3 단계 반복 (최다, 17.14%) | 배정 전 원장·스트림에서 같은 작업이 끝났거나 진행 중인지 확인 | Codex |
| FM-1.5 종료 조건 인지 실패 | 단계마다 통과할 관문을 먼저 선언 | 공통(core) |
| FM-1.2 역할 명세 불이행, FM-2.3 과제 이탈 | 허용 파일·완료 조건 밖으로 넓히지 않는다 | Antigravity |
| FM-2.2 확인 요청 실패 | 파일·값·합격 기준이 빠지면 추측 대신 무엇이 빠졌는지 돌려준다 | Antigravity |
| FM-2.4 정보 은닉, FM-2.6 추론–행동 불일치 | 실패·부분 완료·건너뜀을 성공만큼 분명히 보고, 요약의 변경 파일 목록이 diff와 일치 | Antigravity |
| FM-3.1 조기 종료 | 무변경 종료는 실패 | Antigravity, 파일럿 게이트 |
| FM-3.2 검증 누락·불완전 | 실행하지 않은 검사는 통과로 말하지 않는다, 합격 명령 종료 코드로만 판정 | 공통, 파일럿 게이트 |
| FM-3.3 잘못된 검증 | 반영 전 테스트 맞추기 분기 점검, 고정 인수 테스트 바이트 동일 확인 | Codex, Claude |

## 3. 검증자는 만든 이와 달라야 한다

- Wataoka et al., *Self-Preference Bias in LLM-as-a-Judge* (arXiv:2410.21819) — 모델은 자기에게 익숙한(낮은 perplexity) 출력을 더 높게 평가한다.
- *How Independent are Large Language Models?* (arXiv:2604.07650) — 판정 모델과 대상 모델이 일치해도 그것을 독립 검증으로 해석할 수 없다.

→ 규칙: **변경을 만든 도구가 그 변경의 유일한 검증자가 되지 않는다.** Claude가 대행으로 만든 변경은 Codex 재검토 대상으로 남긴다.

## 4. 규칙 파일 자체의 원칙

- 짧고 구체적으로: "모범 사례를 따르라" 대신 정확한 명령·경계·파일을 적는다. 긴 규칙 파일은 중요한 규칙이 묻힌다. ([agentsmd/agents.md](https://github.com/agentsmd/agents.md), [OpenAI Codex AGENTS.md 가이드](https://developers.openai.com/codex/guides/agents-md))
- 문서만으로는 준수율이 낮고(실무 보고 25~40%) 런타임 강제(훅·게이트)는 훨씬 높다(약 95%). 그래서 이 프로젝트는 핵심 규칙을 문장이 아니라 **파일럿 게이트**로 강제한다. 이 수치는 실무자 보고이며 통제 실험이 아니다.

## 출처

- Anthropic, Building Effective AI Agents — https://www.anthropic.com/engineering/building-effective-agents
- Cemri, Pan, Yang et al., Why Do Multi-Agent LLM Systems Fail? — https://arxiv.org/abs/2503.13657
- Wataoka et al., Self-Preference Bias in LLM-as-a-Judge — https://arxiv.org/abs/2410.21819
- How Independent are Large Language Models? — https://arxiv.org/abs/2604.07650
- agentsmd/agents.md — https://github.com/agentsmd/agents.md
- AGENTS.md 실무 가이드(준수율 보고 포함) — https://www.betterclaw.io/blog/agents-md-best-practices
