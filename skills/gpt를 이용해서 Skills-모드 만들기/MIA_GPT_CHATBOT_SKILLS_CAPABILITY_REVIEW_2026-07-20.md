# MIA GPT 챗봇 Skills 제작 역량 검토 보고서

> 검토 질문: **설계항해·제작항해 챗봇으로 얼마나 훌륭한 Skill을 만들 수 있는가?**<br>
> 검토 상태: `STATIC_CANDIDATE_REVIEW`<br>
> 결정: `PIVOT → CONDITIONAL_GO`<br>
> 검토일: 2026-07-19 KST

## 1. 최종 결론

설계항해 v2.1과 제작항해 v4.7 R2는 **최상급 Skill의 기획·아키텍처·정적 초안**을 만드는 기반으로 충분히 강하다. 특히 요구사항 구조화, 근거 구분, 권한 경계, 안전, 상태 정직성, REDTEAM, 검증 계획, 핸드오프 설계는 일반적인 단발성 챗봇보다 훨씬 성숙하다.

그러나 두 챗봇을 그대로 사용해 만든 결과를 곧바로 Claude Code·Codex·Antigravity용 최종 Skill로 배포해서는 안 된다. 현재 정본은 **ChatGPT 커스텀 GPT Package A 제작기**이며, Agent Skills 전용 컴파일러가 아니다. 실제 조사에서도 최신 두 패키지 안에서 `SKILL.md`, `.agents/skills`, `.claude/skills`, `agents/openai.yaml`, `allow_implicit_invocation`, `disable-model-invocation`, `quick_validate.py` 같은 Skill 전용 계약은 발견되지 않았다.

따라서 권장 방식은 다음과 같다.

```text
설계항해: Skill PRD와 성공 기준 설계
→ 제작항해: 공통 Skill 정적 후보 생성
→ 로컬 에이전트: Agent Skills 표준 변환과 플랫폼 어댑터 적용
→ 실제 설치·발동·실행·회귀 평가
→ 통과할 때만 VERIFIED_RESULT 및 3도구 배포
```

이 어댑터와 검증 루프를 추가하면 **상급 이상의 Skill 제작 시스템**으로 발전할 가능성이 높다. 현재 상태만으로는 `STATIC_CANDIDATE`이며, `VERIFIED_RESULT`가 아니다.

## 2. 검토 범위와 증거

### 로컬 정본

- 설계항해 v2.1 PRD Pack Commander의 최종 후보: 20개 파일, Runtime Knowledge JSON 12개
- 제작항해 v4.7 R2 Personal Compact Package A: 19개 파일, Runtime Knowledge JSON 11개
- 설계항해 Core Instructions: 한국어 7,451자, 영어 7,709자
- 제작항해 Core Instructions: 한국어 6,214자, 영어 7,572자
- 두 패키지 모두 정적 무결성 자료와 Preview QA 틀을 포함
- 제작항해 기록상 Preview QA는 `not_run`, Runtime은 `not_verified`, Release는 `blocked`

### 공식 규격

- [OpenAI Codex — Build skills](https://learn.chatgpt.com/docs/build-skills): `SKILL.md`, 필수 `name`·`description`, 점진적 공개, 명시·암시 발동, 선택적 `agents/openai.yaml`
- [Claude Code — Extend Claude with skills](https://code.claude.com/docs/en/skills): `SKILL.md`, 프로젝트·사용자·플러그인 경로, 발동 제어, 도구 권한, 동적 컨텍스트, 평가 루프
- [Google Antigravity — Agent Skills](https://antigravity.google/docs/skills): `.agents/skills/` 또는 전역 Skills 경로, `description` 기반 자동 선택, 선택적 scripts·examples·resources
- [Agent Skills specification](https://agentskills.io/specification): 여러 도구가 공유하는 개방형 Skill 기본 규격

### 확인하지 않은 것

- 실제 ChatGPT Builder에 두 챗봇을 설치한 뒤 이번 Skill 요청을 대화로 수행하는 런타임 테스트
- 두 챗봇이 생성한 신규 `SKILL.md`를 세 도구에 설치해 비교한 결과
- Skill 사용 전후의 성공률·토큰·시간 벤치마크

이 미확인 항목 때문에 본 보고서는 능력의 **정적 검토**이지 런타임 성능 인증이 아니다.

## 3. 역량 판정

| 평가 면 | 현재 판정 | 근거 |
|---|---|---|
| 문제 정의·인터뷰 | A | 단계 기계, 적응형 확인 질문, 추천 기본값, 임시 가정이 존재 |
| 아키텍처·모듈화 | A | Owner/Caller/Adapter, 불변조건, DoD, 충돌·롤백 계약이 강함 |
| 근거·안전·상태 정직성 | A | Evidence Gate, Safety, `not_run`/`not_verified`와 PASS 분리 |
| 비판·최적화 | A- | REDTEAM·CRITIC·SELFREFINE·OPTIMIZE가 실제 산출물 효과로 정의됨 |
| 정적 패키징·핸드오프 | A- | 매니페스트, 검증 보고서, QA 계획, Agent 핸드오프가 존재 |
| Agent Skills 규격 적합성 | D | Skill 전용 파일 구조·필드·경로·검증기가 현재 정본에 없음 |
| 3플랫폼 적응 | C- | 도구 이름과 핸드오프는 다루지만 플랫폼별 Skill 계약은 없음 |
| 실제 발동·실행 검증 | 미검증 | Preview QA `not_run`, Runtime `not_verified`, Release `blocked` |

성숙도를 산출물 단계로 나누면 다음과 같다.

| 산출물 단계 | 기대 수준 |
|---|---|
| Skill PRD·아키텍처 | **A급 가능** |
| 공통 `SKILL.md` 정적 후보 | **B급 가능**, 전용 출력 계약 필요 |
| 세 플랫폼 설치 패키지 | **C급 이하**, 로컬 어댑터 없이는 신뢰 곤란 |
| 실행 검증된 최상급 Skill | **현재 미증명**, 로컬 평가 후 판정 |

## 4. 잘하는 부분

### 설계항해의 강점

- 모호한 요청을 사용자·목표·제약·성공 기준·비목표로 구조화한다.
- PRD와 시스템 설계, GPT 아키텍처, 핸드오프를 분리한다.
- 최신성·근거·반대 증거·불확실성을 기록하도록 요구한다.
- 검증되지 않은 정적 산출물을 완료로 과장하지 않는다.

Skill 제작에 적용하면 “무엇을 지시문에 쓸까”보다 먼저 “어떤 사용자 문장이 발동해야 하고, 어떤 결과가 성공인가”를 정하게 해준다. 이는 좋은 `description`과 평가 케이스를 만드는 데 직접 도움이 된다.

### 제작항해의 강점

- 승인된 의도를 보존하면서 파일 패키지로 변환하는 역할 경계가 명확하다.
- Core와 Runtime Knowledge를 분리해 큰 지식을 모듈화한다.
- Safety·Evidence·Eval·Status Honesty를 압축 때문에 제거하지 못하게 한다.
- REDTEAM·CRITIC·SELFREFINE·OPTIMIZE를 장식용 명령어가 아니라 결함 탐지와 개선 단계로 취급한다.
- 정적 무결성, Preview QA, Runtime verification, Release를 구분한다.

Skill 제작에 적용하면 `SKILL.md`와 references·scripts·assets를 분리하고, 검증 전 상태를 `STATIC_CANDIDATE`로 유지하는 데 유리하다.

## 5. /REDTEAM — 그대로 사용하면 실패하는 지점

### 5.1 대상 규격이 다르다

두 챗봇의 기본 산출물은 ChatGPT Builder의 Core Instructions와 Runtime Knowledge 중심 Package A다. Agent Skill은 작은 `SKILL.md`를 진입점으로 하고 필요한 references와 scripts를 점진적으로 읽는다. Package A를 이름만 바꿔 Skill 폴더로 옮기면 컨텍스트 낭비와 검색 충돌이 생긴다.

### 5.2 발동의 핵심이 빠져 있다

세 도구 모두 `description`을 Skill 선택의 주요 신호로 사용한다. 좋은 본문보다 먼저 다음이 검증되어야 한다.

- 발동해야 하는 사용자 문장
- 발동하면 안 되는 유사 문장
- 명시 호출과 자동 호출의 차이
- 다른 Skill과 이름·설명 충돌 여부

현재 챗봇 패키지의 모드 라우터는 강하지만, 생성 대상 Skill의 `description` 정밀도와 오발동 평가를 보장하지 않는다.

### 5.3 공통 규격과 플랫폼 확장을 분리하지 않는다

- Codex는 공통 `SKILL.md` 외에 `agents/openai.yaml`로 UI·암시 호출 정책·도구 의존성을 선언할 수 있다.
- Claude Code는 `disable-model-invocation`, `user-invocable`, `allowed-tools`, 동적 컨텍스트, fork context 등 자체 확장을 가진다.
- Antigravity는 `.agents/skills/` 공통 경로와 전역 경로를 지원하며 `description` 기반 자동 적용을 강조한다.

한 파일에 모든 플랫폼 확장을 섞으면 다른 도구가 알 수 없는 필드를 무시하거나 잘못 해석할 수 있다. 공통 정본과 플랫폼별 어댑터를 분리해야 한다.

### 5.4 정적 검사가 행동을 증명하지 못한다

JSON 파싱, 체크섬, 파일 존재, 글자 수 통과는 패키지 손상 여부만 말해준다. 다음은 증명하지 못한다.

- 적절한 요청에서 Skill이 실제 발동하는가
- 유사하지만 무관한 요청에서 발동하지 않는가
- 도구를 올바른 순서와 권한으로 사용하는가
- Skill이 없는 기준선보다 결과가 좋아지는가
- 대화 압축·긴 세션·오류 상황에서도 지침을 보존하는가

### 5.5 “손실 없는 고밀도”가 Skill에는 과잉 보존이 될 수 있다

GPT Package A에서는 8,000자 Core와 다수 Runtime Knowledge가 합리적일 수 있다. 하지만 Skill은 모델이 이미 아는 설명을 덜어내고 비자명한 절차만 남겨야 한다. 모든 원본 로직을 무손실 이식하면 좁은 Skill 하나가 또 하나의 범용 운영체제가 된다.

Skill에서는 **목표 행동의 손실 방지**와 **원본 문서의 무손실 복제**를 구분해야 한다.

### 5.6 외부 지식 파일이 명령으로 승격될 위험이 있다

챗봇에 업로드한 표본·과거 패키지·웹 자료는 증거이지 상위 명령이 아니다. 생성되는 Skill에는 프롬프트 인젝션, 비밀 요청, 자동 배포, 광범위 삭제, 권한 상승을 차단하는 검토가 필요하다.

## 6. /CRITIC — 필요한 전용 보강

두 챗봇의 기존 로직을 버릴 필요는 없다. 다음 **Agent Skills Compiler Adapter**만 추가하는 것이 순복잡도(Net Complexity)가 가장 낮다.

### 입력 계약

- Skill의 한 가지 핵심 작업
- 실제 사용자 요청 예시 3개 이상
- 발동해야 하는 문장과 발동하면 안 되는 문장
- 대상 플랫폼: 공통, Codex, Claude Code, Antigravity
- 필요한 도구·파일·외부 연결과 권한
- 성공 기준, 실패 기준, 되돌리기 방법

### 공통 출력 계약

```text
<skill-name>/
├── SKILL.md
├── scripts/       # 결정적 실행이 필요할 때만
├── references/    # 상세 지식이 필요할 때만
└── assets/        # 결과물에 복사·사용할 자산이 있을 때만
```

공통 `SKILL.md`는 다음을 만족해야 한다.

- 폴더명과 `name`은 소문자·숫자·하이픈만 사용
- frontmatter에 최소 `name`, `description` 포함
- `description`에 하는 일과 발동 조건·경계를 함께 기록
- 본문은 명령형 단계, 입력, 출력, 중단 조건, 검증을 명시
- 핵심 Skill은 한 가지 작업에 집중
- 상세 자료는 한 단계 아래 references로 이동
- scripts는 반복 코드나 결정적 신뢰성이 필요한 경우에만 생성
- 원문 제작 과정용 README·변경 기록·감사 자료는 Skill 실행 폴더에 넣지 않음

### 플랫폼 어댑터

| 대상 | 어댑터 산출물 |
|---|---|
| 공통·Antigravity | 표준 `SKILL.md`와 필요한 resources |
| Codex | 공통 Skill + 필요 시 `agents/openai.yaml` |
| Claude Code | 공통 Skill + 필요한 경우에만 Claude 전용 frontmatter 변형 |

공통 정본을 먼저 만들고, 플랫폼 전용 필드는 파생본에만 추가한다. 기능 차이가 없으면 세 벌을 만들지 않고 같은 공통 Skill을 복사·동기화한다.

## 7. /OPTIMIZE — 권장 제작 파이프라인

### 1단계: 설계항해 — Skill Brief

- 한 가지 사용자 작업과 비목표를 확정한다.
- 구체적 사용 예시와 반례를 수집한다.
- Skill 없이 수행했을 때의 실패·낭비를 정의한다.
- 필요한 scripts·references·assets 후보를 정한다.
- 성공 기준과 평가 방법을 먼저 고정한다.

산출물 상태: `DIRECTION_DRAFT`

### 2단계: 제작항해 — 정적 후보

- 공통 `SKILL.md`를 생성한다.
- 필요한 리소스만 분리한다.
- 플랫폼 어댑터와 설치 지도를 만든다.
- 평가 프롬프트·예상 행동·금지 행동을 만든다.
- 정적 검증을 통과시킨다.

산출물 상태: `STATIC_CANDIDATE`

### 3단계: 로컬 에이전트 — 구조 검증

- YAML frontmatter, 이름, 링크, 경로, 스크립트 구문을 검사한다.
- scripts가 있으면 실제로 실행해 대표 사례를 검증한다.
- 민감정보·파괴 명령·광범위 권한·외부 쓰기를 감사한다.
- 세 플랫폼이 Skill을 발견하는지 확인한다.

산출물 상태: 여전히 `STATIC_CANDIDATE`

### 4단계: 로컬 에이전트 — 행동 평가

- should-trigger와 should-not-trigger를 각각 최소 10개 실행한다.
- 핵심 작업 사례를 최소 5개 실행한다.
- Skill 사용 전후의 성공률·시간·토큰을 비교한다.
- 오류 입력, 빈 상태, 권한 거부, 도구 부재, 긴 대화를 시험한다.
- 실패 원인 하나마다 가장 작은 수정 후 재실행한다.

### 5단계: 배포 판정

다음을 모두 만족할 때만 `VERIFIED_RESULT`로 승격한다.

- 세 대상 도구에서 발견·명시 호출 성공
- 자동 발동 정밀도와 재현율이 각각 90% 이상
- 핵심 작업 평가 통과율 80% 이상이며 기준선보다 유의미하게 향상
- Critical 안전 실패 0건
- scripts 실행 및 오류 경로 검증 완료
- 문서 링크·상대 경로·플랫폼 파생본 동기화 확인
- 관찰 증거와 실행 로그가 남아 있음

기준 미달이면 `iterate`, 전용 어댑터가 불필요하면 `merge`, 효과가 없으면 `stop`으로 판정한다.

## 8. 챗봇에 전달할 표준 요청문

다음 틀을 설계항해와 제작항해에 순서대로 사용한다.

```text
/STEPBYSTEP /DEEPDIVE /CRITIC /REDTEAM /OPTIMIZE

목표: Claude Code, Codex, Antigravity에서 사용할 Agent Skill을 설계한다.
대상 작업: [한 가지 핵심 작업]
사용 예시: [실제 요청 3개 이상]
비발동 예시: [유사하지만 무관한 요청 3개 이상]
필요 도구·자료: [도구, 파일 형식, API 또는 없음]
제약: [보안, 권한, 예산, 플랫폼]

Agent Skills 개방 표준의 SKILL.md를 공통 정본으로 사용하라.
ChatGPT Builder용 Package A를 그대로 복제하지 마라.
공통 계약과 Codex·Claude Code·Antigravity 전용 확장을 분리하라.
SKILL.md에는 name, description, 명령형 절차, 입력, 출력, 중단 조건,
검증을 포함하고 상세 지식은 references로 분리하라.
반복적이고 결정적 실행이 필요한 경우에만 scripts를 제안하라.

출력:
1. Skill Brief와 비목표
2. 파일 트리와 각 파일의 필요성
3. 공통 SKILL.md 정적 후보
4. 플랫폼별 어댑터 차이
5. should-trigger / should-not-trigger 평가 세트
6. 핵심 작업·오류·보안 평가 세트
7. 로컬 에이전트 핸드오프
8. 확인된 사실·가정·미검증 항목

현재 상태는 STATIC_CANDIDATE로 표시하라.
실제 설치·발동·실행 증거 없이 PASS, VERIFIED_RESULT, Release를 선언하지 마라.
```

## 9. 결정 메모

### 대안 비교

| 대안 | 가치 | 실현성 | 위험 | 결정 |
|---|---|---|---|---|
| 챗봇 결과를 그대로 Skill로 배포 | 빠름 | 높아 보임 | 규격 누락·오발동·미검증 위험 큼 | No-Go |
| 새 Skill 전용 챗봇을 처음부터 제작 | 맞춤성 높음 | 비용·유지관리 증가 | 기존 강점 중복 | 보류 |
| 기존 두 챗봇 + 얇은 Compiler Adapter + 로컬 검증 | 기존 강점 재사용 | 높음 | 검증 작업 필요 | **Go** |

### 최종 Gate

- 결정: `PIVOT → CONDITIONAL_GO`
- 유지: 설계항해의 PRD·근거·결정 회로, 제작항해의 패키징·REDTEAM·상태 정직성
- 추가: Agent Skills 공통 출력 계약, 플랫폼 어댑터, 발동 평가, 실제 실행 비교
- 제거: Package A 구조의 무비판적 복제, 과잉 Runtime Knowledge, 검증 없는 PASS
- 재검토 조건: 실제 Skill 1종을 이 파이프라인으로 제작하고 세 도구에서 평가 결과를 확보했을 때

첫 실험은 기존 `plan-review-execute`를 새로 만들기보다, 현재 정본을 이 평가 계약으로 다시 측정하는 것이 가장 싸고 신뢰도 높은 방법이다.

## 10. 후속 구현 후보 선별

역량 검토 이후 후보를 실제 제작 단위로 다시 비교했다.

| 후보 | 판정 | 처리 |
|---|---|---|
| `mia-skill-forge` | Go | GPT 산출물을 공통 Agent Skill 정적 후보로 정제하는 1차 구현 대상 |
| `mia-skill-evaluator` | 보류 | 첫 후보 평가에서 반복 병목이 확인될 때 분리 |
| `mia-skill-distributor` | 병합 | 별도 Skill 대신 forge의 플랫폼 계약과 기존 동기화 도구로 처리 |
| 전 과정 단일 `mia-skill-factory` | No-Go | 권한·실패 범위·컨텍스트가 과도함 |

가져올 데이터는 적응형 확인 질문, 근거 Gate, REDTEAM·SELFREFINE, 논리 책임 기반 파일 분리, 안전 경계, 금지 상태 전이, 오류 피드백 회로로 제한한다. Package A 업로드 구조, 8,000자 Core 프레임, 20파일 상한, Apps·Actions, 원본 JSON과 생성 overlay는 이식하지 않는다.

구체적인 파일 구조·데이터 추출표·평가 기준·승격 절차는 [MIA GPT 챗봇 Skills 구현 계획](MIA_GPT_CHATBOT_SKILLS_IMPLEMENTATION_PLAN_2026-07-20.md)에 기록했다.
