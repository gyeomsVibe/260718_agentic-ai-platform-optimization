# 역할별 규칙의 근거

전역 규칙의 역할 문구가 어디서 왔는지 남긴다. 근거 없는 규칙은 관례가 아니라 결함이다(검증 절).

## 1. 역할 구조: 지휘자–작업자–검증자

| 역할 | 도구 | 근거 |
|---|---|---|
| 지휘자(orchestrator) | Codex | Anthropic, *Building Effective Agents* (2024) — orchestrator-workers: 중앙 모델이 과제를 동적으로 나누고 위임하고 결과를 종합한다. 코딩처럼 바뀔 파일 수를 미리 알 수 없는 과제에 맞는다. |
| 작업자(worker) | Antigravity, 로컬 모델 | 같은 문서 — 작업자는 위임받은 하위 과제만 수행한다. |
| 부지휘자(deputy orchestrator) | Claude Code | 사용자 지정(2026-09-21): Codex와 동등. Codex 활동 중에는 그 지시를 받고 독립 검증(evaluator-optimizer의 평가자)을 맡으며, 부재 중에는 지휘자의 모든 권한을 대행한다. 대행 중 만든 변경은 Codex 복귀 시 재검토 — 만든 이가 유일한 검증자가 되지 않게(§3). |

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

## 5. 로컬 모델 캐스케이드 (`olla`)

| 근거 | 내용 | 규칙 |
|---|---|---|
| FrugalGPT (Chen et al., arXiv:2305.05176) | 싼 모델부터 쓰고 부족할 때만 비싼 모델로 넘기는 캐스케이드로 최대 98% 비용 절감, 최고 모델 성능 유지 | 기계적인 일은 로컬 먼저 |
| RouteLLM (ICLR 2025) | 강·약 모델 라우팅으로 비용 85% 이상 절감, 강 모델 성능의 95% 유지 | 판단이 필요하면 강 모델로 올림 |
| GitHub 위임 도구(claude-sidekick, mcp-local-llm, ollama-mcp-server 등) | "생각은 비싼 모델이, 기계적인 일은 로컬이" 분업이 공통 패턴 | ask/edit/find 세 용도로 한정 |
| 이 프로젝트 벤치 v2 | 로컬 실패 축은 지시의 모호함 하나 | 정확히 적을 수 있는 수정만 `olla edit` |
| LLMLingua (Jiang et al., EMNLP 2023, arXiv:2310.05736) | 작은 모델로 입력을 최대 20배 압축해도 성능 손실이 적다 | 큰 읽기는 `olla digest` 요약본을 먼저 |
| 에이전트 비용 공학 실무 보고(ReAct 류는 매 턴 문맥 재전송으로 비용이 5~7배 증가, 토큰의 40~60%가 줄일 수 있는 낭비) | 읽은 내용은 이후 턴마다 다시 과금된다 | 추정에 재전송 3턴을 포함 |
| 이 프로젝트 실측 | 753줄 파일 10,464 → 855토큰(−91.8%), 보조 경로 1곳 누락 | 요약본은 지도, 줄은 직접 확인 |

## 6. 출력 최소화: 결론 먼저, 사실은 한 번, 누락 없이 (v6.2.0)

사용자 보고 화면을 받아 조사했다(2026-09-29). 표의 "종류"는 근거의 무게다: 논문·공식 자료 > 측정된 공개 실험 > 저장소 주장 > 레딧·기사(경험담).

| 근거 | 종류 | 핵심 | 규칙에 반영 |
|---|---|---|---|
| Anthropic API 가격(2026-09, 제3자 정리) | 공식 가격 | 모든 모델에서 출력 토큰 단가가 입력의 5배(Opus 5.5 $4/$20) | 사용자 출력은 줄일 가치가 크다 |
| Xu et al., *Chain of Draft* (arXiv:2502.18600, 2025) | 논문 | 단계당 5단어 이내 초안으로 CoT와 비슷한 정확도, 토큰은 최저 7.6% | 줄 하나에 핵심어·숫자만 |
| *Brevity Constraints Reverse Performance Hierarchies* (arXiv:2604.00025, 2026) | 논문 | 31개 모델에서 큰 모델의 장황함이 오류를 만들고, 간결 제약이 정확도를 26%p 올림 | 짧게 쓰는 것이 품질도 지킨다 |
| Adams et al., *Chain of Density* (arXiv:2309.04269, NewSum 2023) | 논문 | 같은 길이에 빠진 핵심 개체를 채워 넣은 조밀한 요약을 사람이 더 선호. 정보량과 가독성은 맞바꿈 관계 | 줄이되 사실은 빼지 않는다(길이 고정, 밀도 증가) |
| BLUF, 미 육군 AR 25-50 | 작성 표준 | 첫 문장에 결론·요청, 이유는 뒤에. 신문의 역피라미드와 같다 | 쉬운 요약은 맨 위 `결과` 한 곳 |
| JetBrains, caveman 실측(2026-07, SkillsBench 82쌍) | 측정 실험 | 실제 에이전트 과제에서 출력 토큰 −8.5%, 비용 약 −10%, 품질 차이 없음(p=0.82). 출력 대부분이 코드·도구 호출이라 말투 압축 효과가 작다 | 절감은 측정 전까지 UNMEASURED |
| JuliusBrussee/caveman (GitHub) | 저장소 주장 | 군더더기·인사·도구 예고·결과 되풀이를 빼서 출력 토큰 65~75% 절감을 주장(자체 10문항) | 도구 예고·되풀이 금지는 이미 규칙, 과장 수치는 미채택 |
| r/ClaudeAI caveman 글(400여 댓글), Decrypt 기사 | 경험담·기사 | 실사용 절감은 30~50%라는 반론, "출력은 청구서에서 가장 싼 부분"이라는 지적(대화형 작업은 입력 문맥이 대부분) | 입력 절약(요약본·캐시)과 함께 본다 |

## 출처

- Anthropic, Building Effective AI Agents — https://www.anthropic.com/engineering/building-effective-agents
- Cemri, Pan, Yang et al., Why Do Multi-Agent LLM Systems Fail? — https://arxiv.org/abs/2503.13657
- Wataoka et al., Self-Preference Bias in LLM-as-a-Judge — https://arxiv.org/abs/2410.21819
- How Independent are Large Language Models? — https://arxiv.org/abs/2604.07650
- agentsmd/agents.md — https://github.com/agentsmd/agents.md
- AGENTS.md 실무 가이드(준수율 보고 포함) — https://www.betterclaw.io/blog/agents-md-best-practices
- FrugalGPT — https://arxiv.org/abs/2305.05176
- RouteLLM — https://github.com/lm-sys/RouteLLM
- claude-sidekick — https://github.com/andrewbrereton/claude-sidekick
- mcp-local-llm — https://github.com/aplaceforallmystuff/mcp-local-llm
- ollama-mcp-server — https://github.com/Shahriar-Hossein/ollama-mcp-server
- LLMLingua — https://arxiv.org/abs/2310.05736
- Token-Budget-Aware LLM Reasoning — https://arxiv.org/abs/2412.18547
- LLM cost optimization for agent workflows — https://dev.to/omnithium/llm-cost-optimization-for-agent-workflows-a-practical-guide-49c1
- Claude API pricing (2026-09) — https://benchlm.ai/anthropic/api-pricing
- Chain of Draft — https://arxiv.org/abs/2502.18600
- Brevity Constraints Reverse Performance Hierarchies in Language Models — https://arxiv.org/abs/2604.00025
- Chain of Density — https://aclanthology.org/2023.newsum-1.7/
- BLUF (communication) — https://en.wikipedia.org/wiki/BLUF_(communication)
- JetBrains, Speaking to AI Agents like Cavemen — https://blog.jetbrains.com/ai/2026/07/speak-to-ai-agents-like-cavemen-tosave-tokens/
- JuliusBrussee/caveman — https://github.com/juliusbrussee/caveman
- Decrypt, Devs Are Making Claude Talk Like a Caveman — https://decrypt.co/363440/devs-claude-talk-like-caveman-cut-costs-work-better
- andrew.ooo, Caveman Review (real-world 30–50%) — https://andrew.ooo/posts/caveman-claude-code-skill-token-savings-review/
