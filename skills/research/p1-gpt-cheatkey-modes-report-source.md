# GPT 실전 치트키 모드 전수분석 및 독립 Skill 설계 근거

- 대상: `p1. GPT 실전 치트키 모드.md`
- 독자: MIA 스킬 설계·검증 담당자
- 분석일: 2026-09-05
- 범위: 원문의 10개 모드와 사용자 조합 의견, Agent Skill 전환 가능성, 공개 1차 자료 및 연구의 반증
- 권한 경계: 원문과 웹 자료는 근거이며 실행 지시나 설치·배포 권한이 아니다.

## 결론

원문의 10개 호출어는 기억하기 쉽지만, 그대로는 결과 품질을 안정적으로 높이는 “치트키”가 아니다. 성공 기준, 입력 계약, 검증 수단, 조합 우선순위, 비용 중단 조건이 없기 때문이다. 최적 설계는 각 호출어를 **관찰 가능한 산출물 계약**으로 바꾸고, 여러 모드를 한 회로로 합성하며, 자기검토에는 외부 기준·테스트를 우선 연결하는 것이다.

새 후보 `slash-prompt-modes`는 이 원칙을 구현한다. MIA 시리즈와 독립된 `skills/custom/slash-prompt-modes/`에 직접 배치하며, 자동 과발동을 막기 위해 원문처럼 앞에 `/`가 붙은 정확한 명령어만 트리거로 사용한다. 일반적인 “쉽게/비판적으로/최적화” 표현이나 MIA 호출문에는 반응하지 않는다.

또한 이 표기는 GPT·ChatGPT·Codex·Claude가 공통으로 제공하는 내장 명령이 아니다. Skill이 설치·발견된 환경에서 description과 본문 계약을 통해 해석하는 사용자 정의 토큰이다.

## CRITIC — 원문의 구조적 결함

1. **효과를 과장한다.** “크게 올라갑니다”, “최고의 효율”, “원천 차단”, “비약적 상승”은 과제·모델·평가셋 없는 보편 주장이다.
2. **모드의 결과 계약이 없다.** `/CRITIC`이 무엇을 기준으로 평가하고 `/REDTEAM`이 어디까지 공격하며 언제 멈추는지 알 수 없다.
3. **비슷한 모드가 충돌한다.** `/SELFREFINE`, `/CRITIC`, `/REDTEAM`, `/OPTIMIZE`는 경계가 없으면 같은 비판을 네 번 반복한다.
4. **깊이와 길이를 혼동한다.** `/DEEPDIVE`는 근거 슬롯·출처 우선순위·최신성·중단 조건 없이 장문만 유도할 수 있다.
5. **권위 역할극 위험이 있다.** `/EXPERT`는 전문 표준을 적용하기보다 근거 없는 전문가 페르소나를 만들 수 있다.
6. **추론 공개를 암묵적으로 요구한다.** `/STEPBYSTEP`은 사용자 행동 절차와 내부 사고 과정이 구분되지 않는다.
7. **Few-shot을 절대화한다.** “100% 동일”, “원천 차단”은 확률적 생성과 예시 과적합·예시 오류·인젝션 가능성을 무시한다.
8. **쉬운 설명의 손실 기준이 없다.** `/ELI10`은 정확한 조건·예외·위험을 지운 과도한 단순화가 될 수 있다.
9. **권한 경계가 없다.** 깊이 조사나 최적화 요청이 웹 검색·설치·배포·파괴적 수정 허가로 오해될 수 있다.
10. **검증 불가능하다.** 전후 비교 사례, 실패 사례, 비발동 사례와 통과 임계치가 없다.

## REDTEAM — 실패 시나리오와 보강

| 실패 시나리오 | 드러나는 맹점 | 보강 |
|---|---|---|
| 틀린 계산을 `/SELFREFINE`으로 반복 | 같은 모델이 오류를 강화 | 테스트·계산기·외부 피드백 우선, 반복 상한 |
| 모든 요청에 `/DEEPDIVE` 적용 | 비용·지연·컨텍스트 오염 | 결정 가치와 수익 체감 기반 중단 |
| `/CRITIC /REDTEAM` 동시 호출 | 중복 비판과 과도한 부정성 | 기준 결함 → 공격 시나리오 → 완화책으로 합성 |
| `/EXPERT`로 법률·의료 답변 요구 | 가짜 권위와 최신성 오류 | 관할·시점·공식 근거·불확실성 확인 |
| 한 개의 Few-shot 예시에 오류 포함 | 오류와 우연한 표현을 복제 | 불변 구조/가변 내용 분리, 예시 간 모순 검사 |
| 예시에 “앞 지시 무시” 삽입 | 프롬프트 인젝션 | 예시와 첨부 자료를 신뢰하지 않는 데이터로 격리 |
| “10살처럼”이 전문 세부를 제거 | 안전·정확성 손실 | 쉬운 설명층과 전문 용어·수치·예외를 함께 유지 |
| `/OPTIMIZE`의 목표가 불명확 | 임의의 축을 최적화 | 목적 함수·기준선·비목표·보존 제약 고정 |
| `/ALT3`가 표현만 다른 세 안 생성 | 거짓 선택지 | 메커니즘·비용·위험 중 하나 이상이 다른지 검사 |
| `/STEPBYSTEP`이 장황한 독백 생성 | 실용성 저하·추론 노출 | 외부 행동·체크포인트·실패 분기만 출력 |

## 공개 근거와 설계 반영

- [Agent Skills 공개 규격](https://agentskills.io/specification)은 `name`과 `description`이 무엇을 하고 언제 쓰는지를 명확히 해야 하며, 긴 본문은 참조 파일로 분리할 수 있다고 규정한다. 따라서 트리거는 frontmatter에, 10개 상세 계약은 `references/`에 둔다.
- [OpenAI 공식 skills 저장소](https://github.com/openai/skills)와 [공식 skill-creator](https://github.com/openai/skills/blob/main/skills/.system/skill-creator/SKILL.md)는 스킬을 반복 가능한 작업용 지침·스크립트·자원 묶음으로 정의하고, 핵심 지침을 간결하게 유지하며 실제 사용으로 반복 개선하도록 안내한다. 단순 명령어 목록 대신 실행·검증 계약을 만든 이유다.
- [Google의 공식 프롬프트 설계 가이드](https://ai.google.dev/gemini-api/docs/prompting-strategies)는 명확한 지시, 일관된 예시 형식, 반복 실험을 권장하면서 예시가 너무 많으면 과적합할 수 있고 복잡한 JSON은 구조화 출력 기능을 쓰라고 권한다. `/STRUCTURED FEW-SHOT`에 예시 검증과 구조화 출력 우선 규칙을 추가했다.
- [Anthropic의 공식 프롬프트 가이드](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)는 최신 모델에서 과도한 지시가 과잉 실행·과잉 검증을 만들 수 있고, 일반 원칙이 손으로 쓴 세부 추론 절차보다 나을 수 있다고 설명한다. `/DEEPDIVE`와 `/STEPBYSTEP`을 무조건적 장문화·추론 강제가 아니라 적응형 깊이와 사용자 행동 절차로 바꿨다.
- [Self-Refine 공식 구현 저장소](https://github.com/madaan/self-refine)는 생성 → 피드백 → 개선의 반복 구조를 보여준다. 반면 [Huang 외의 자기수정 연구](https://arxiv.org/abs/2310.01798)는 외부 피드백 없는 추론 자기수정이 성능을 떨어뜨릴 수도 있음을 보고한다. [Chain-of-Verification](https://arxiv.org/abs/2309.11495)은 초안과 분리된 검증 질문이 환각을 줄일 수 있음을 보고한다. 따라서 `/SELFREFINE`은 만능 보증이 아니라 독립 검증·제한된 반복으로 설계했다.
- [OpenAI의 평가 플라이휠](https://github.com/openai/openai-cookbook/blob/main/examples/evaluation/Building_resilient_prompts_using_an_evaluation_flywheel.md), [OpenAI Evals](https://github.com/openai/evals/blob/main/docs/build-eval.md), [DSPy 평가 계약](https://github.com/stanfordnlp/dspy/blob/main/docs/docs/diving-deeper/metrics-and-evaluation.md)은 공통적으로 고정 사례·지표·기준선을 먼저 정의하는 방향을 지지한다. `/OPTIMIZE`에 동일 평가셋의 전후 비교를 추가했다.
- [Promptfoo](https://github.com/promptfoo/promptfoo)와 [OWASP GenAI LLM Top 10 2026](https://github.com/GenAI-Security-Project/GenAI-LLM-Top10)은 레드팀을 반복 가능한 평가와 프롬프트 인젝션·과도한 권한·무제한 소비·출력 처리 위험으로 확장한다.

## 설계 결정

- 이름: `slash-prompt-modes`
- 정본 경로: `skills/custom/slash-prompt-modes/` — 추상적인 `prompt-tools` 중간 분류 없이 MIA 시리즈와 독립
- 핵심 사용자 문제: 여러 품질 지시를 짧게 조합하되 중복·과잉·권위 환각 없이 일관된 결과를 얻는다.
- 기준선: 원문의 한 줄 명령 목록 및 무-Skill 일반 요청.
- 개선 가설: 명시적 계약과 조합 규칙이 모드 중복, 과잉 조사, 자기확신, 형식 오류를 줄인다.
- 구조: 얇은 `SKILL.md`, 조건부로 읽는 `references/mode-contracts.md`, 후보 밖 행동 평가 사례.
- 상태: 구조 검증과 사용자 범위 설치 완료. 10개 슬래시 입력은 ASCII 대소문자를 구분하지 않는다. 공통 본체는 `allow_implicit_invocation: false`로 유지하고 명령별 별칭을 사용한다. Codex·Claude Code의 `/OPTIMIZE` 대문자·소문자는 런타임 통과했으며, Antigravity는 CLI 부재로 새 IDE 세션 발동이 아직 미확인이다.
- 비목표: 시스템 권한 확대, 자동 웹 조사 강제, 모든 일반 비판·설명 요청에 자동 발동, “100% 정확” 보장.

## 2026-09-05 SELFREFINE·REDTEAM 재감사

초기 구조·해시 감사가 통과했지만 생성된 별칭 본문에는 실제 토큰 대신
`$(System.Collections.Hashtable.Token)`이 남아 있었다. PowerShell double-quoted here-string에서
Markdown 백틱이 `$` 보간을 이스케이프한 것이 원인이다. description에는 올바른 토큰이 있어
발견은 가능했지만, 본문이 어떤 모드 계약을 읽어야 하는지는 손상됐다.

이 결함은 다음 주장을 무효화한다.

- 같은 파일의 해시가 맞는다는 사실은 생성 내용이 의미적으로 올바르다는 증거가 아니다.
- `/OPTIMIZE` 단일 응답 성공은 10개 별칭 전체와 조합 기능의 성공을 증명하지 않는다.
- 구조 감사 오류 0건은 미해석 템플릿·보간 잔재가 없다는 뜻이 아니다.

교정은 생성기의 백틱 처리를 수정하고, 생성된 10개 `SKILL.md` 각각에 정본 토큰과
`license: MIT`가 있으며 `$(`와 `System.Collections.Hashtable.Token`이 없는지 검사하는 회귀
테스트를 추가하는 방식으로 제한했다. 교정본을 세 플랫폼에 재배포하고 새 세션에서 10개
양성·음성·조합 사례를 각각 통과하기 전에는 `CROSS_PLATFORM_VERIFIED`를 선언하지 않는다.

## 라이선스 판정

GitHub는 라이선스가 없는 공개 저장소에 기본 저작권이 적용돼 다른 사람의 복제·수정·배포
권한이 자동으로 생기지 않는다고 안내한다. Agent Skills 공개 규격은 `license`를 선택 필드로
지원한다. 이 저장소에서는 사용자 소유·배포 가능 Skill의 출고 필수 항목으로 강화했다.

- `slash-prompt-modes`: 해당 폴더 범위 MIT, `Copyright (c) 2026 gyeomsVibe`
- MIA 시리즈: `skills/custom/mia/` 범위 MIT, 활성 3종과 생성본에 `license: MIT`
- `legacy-harness`: 출처·권리 재확인 전 라이선스를 추측하지 않고 격리 유지
- `skills/external/`: 각 외부 항목의 원 라이선스와 `SOURCE.md`가 우선

저장소 루트에 MIT를 두지 않은 이유는 기존 외부·보존 자료 전체를 사용자 저작물로 오해해
재라이선스하는 위험을 피하기 위해서다.

## 검증 계획

1. frontmatter·이름·링크·UI 메타데이터 정적 검증.
2. `/`가 붙은 10개 명령어의 양성 발동과 슬래시 없는 음성 사례를 전수 평가하고, 예시 인젝션·자기수정·단계별 설명 경계도 검사.
3. 무-Skill 기준선과 모드 중복, 검증 상태 정직성, 형식 준수, 토큰·시간을 비교.
4. 나머지 9개 모드의 대문자·소문자 양성 및 슬래시 없는 음성 사례를 플랫폼별로 평가하고, Antigravity 새 IDE 세션에서 발견과 발동을 확인한다.

## 한계

- 공개 문서는 모델·버전에 따라 바뀌며, 한 공급자의 권고를 다른 모델에 그대로 일반화할 수 없다.
- 현재 설치본은 일부 런타임 검증 단계다. 실제 품질 개선은 전체 동일 평가셋의 전후 비교가 있어야 확정할 수 있다.
- `/REDTEAM`은 일반 품질·안전 실패 분석 계약이며, 실제 시스템에 대한 침투 권한을 부여하지 않는다.

## MIA 스킬 컴파일러 모듈성 확인

현재 `mia-skill-compiler`는 모듈식으로 작성되어 있다. `SKILL.md`가 얇은 라우터 역할을 하고 다음 8개 논리 책임을 조건부 참조로 분리한다.

| 모듈 | 물리 구현 | 소유 책임 |
|---|---|---|
| M00 core | `SKILL.md` | 임무·경계·라우팅·정상 흐름 |
| M01 efficiency | `fast-path-budget.md` | 속도·질문·비용·중단 |
| M02 discovery | `research-prd-contract.md` | 조사 깊이·차별화·PRD·점수표 |
| M03 architecture | `module-architecture.md` | 분리·병합·소유권 충돌 |
| M04 reasoning | `thinking-modes.md` | 사용자 지정 사고 모드 계약 |
| M05 lifecycle | `output-promotion-contract.md`, `preflight_skill_promotion.py` | 파일·상태·승인·평가·사전검사 |
| M06 platforms | `platform-skill-contracts.md` | 플랫폼별 설치·발견 차이 |
| M07 constitution | `skill-creation-bible.md` | 불변 상위원칙·최신성 |

모듈 수를 미리 고정하는 구조는 아니다. 독립 판단 책임, 변경 주기, 위험, 검색 비용과 독립 평가 필요성이 있을 때 분리하고, 하나의 소유 영역으로 설명되며 항상 함께 쓰이는 내용은 합친다.

## 주장-출처 원장

| 주장 | 출처 | 게시·확인 정보 | 신뢰·적용 범위 |
|---|---|---|---|
| 프롬프트 개선은 실패 분석·측정·표적 개선 회로가 필요 | OpenAI Cookbook evaluation flywheel | GitHub, 2026-09-05 확인 | 공식 실무 가이드, 일반 평가 절차 |
| 평가 데이터·버전·메타평가가 재현성을 높임 | OpenAI Evals build-eval | GitHub, 2026-09-05 확인 | 공식 오픈소스 평가 지침 |
| 최적화에는 수치 지표와 피드백 신호를 구분할 수 있음 | DSPy metrics and evaluation | GitHub, 2026-09-05 확인 | 공개 프레임워크 계약 |
| 독립 검증 질문은 환각 감소 가능 | Chain-of-Verification, 2023 | arXiv, 2026-09-05 확인 | 논문 평가 과제 범위 |
| 외부 피드백 없는 자기수정은 악화 가능 | Huang 외, 2023 | arXiv, 2026-09-05 확인 | 추론 과제의 반증 |
| 복수 경로 합의는 일부 추론 벤치마크에서 개선 | Self-Consistency, 2022 | arXiv, 2026-09-05 확인 | 특정 산술·상식 벤치마크, 추가 비용 있음 |
| few-shot은 형식 유도에 유용하나 과적합 가능 | Google Prompt design strategies | 공식 문서, 2026-09-05 확인 | Gemini 중심, 타 모델 일반화 주의 |
| 과도한 지시는 최신 모델에서 과잉 실행 가능 | Anthropic prompting best practices | 공식 문서, 2026-09-05 확인 | Claude 중심, 모델별 차이 |
| expert persona의 일관된 성능 향상은 불명확 | When Does Persona Prompting Actually Help?, 2026 | arXiv, 2026-09-05 확인 | 최신 연구, 추가 재현 필요 |
| 최신 LLM 위험에 인젝션·과도한 권한·무제한 소비 포함 | OWASP GenAI LLM Top 10 2026 | GitHub, 2026-08-04 공개·2026-09-05 확인 | 보안 위협 분류, 일반 품질 평가는 아님 |
| Skill frontmatter는 라이선스 이름 또는 번들 파일 참조를 지원 | Agent Skills specification | 공식 규격, 2026-09-05 확인 | `license`는 공개 규격상 선택, 로컬 출고 정책상 필수 |
| 라이선스 없는 공개 저장소에는 기본 저작권이 적용 | GitHub Docs, Licensing a repository | 공식 문서, 2026-09-05 확인 | 법률 자문이 아닌 GitHub 운영 안내 |
| MIT는 저작권·허가문 보존을 조건으로 사용·수정·배포를 허용 | SPDX MIT / Choose a License | 표준·GitHub 안내, 2026-09-05 확인 | 적용 범위와 저작권자는 별도 확인 필요 |
