# MIA GPT 챗봇 Skills 구현 계획

> 문서 상태: `DIRECTION_DRAFT`<br>
> 결정: `GO` — `mia-skill-forge` 1종을 먼저 구현<br>
> 첫 검증 표본: `plan-review-execute`<br>
> 작성일: 2026-07-19 KST

## 1. 구현 목표

설계항해·제작항해가 만든 GPT 중심 산출물을 그대로 복제하지 않고, Claude Code·Codex·Antigravity가 공통으로 사용할 수 있는 **작고 검증 가능한 Agent Skill 정적 후보**로 정제하는 `mia-skill-forge`를 만든다.

이 Skill의 성공은 문서를 많이 생성하는 것이 아니다. 다음 흐름을 반복 가능하게 만드는 것이다.

```text
사용자 목표와 사용 예시
→ 설계항해 Skill Brief
→ 제작항해 정적 초안
→ mia-skill-forge 표준 변환
→ 구조·보안·발동·행동 검증
→ 검증된 경우에만 정본 승격
```

### 결정 주체와 제약

| 항목 | 내용 |
|---|---|
| 결정 주체 | 윤겸스 |
| 구현 주체 | 로컬 에이전트(Codex 또는 Claude Code) |
| 1차 대상 | 세 플랫폼 공통 Skill 정적 후보 생성 |
| 제외 | 전역 설치, 플러그인 배포, 자동 푸시, ChatGPT Builder 조작 |
| 안전 경계 | 외부 쓰기·삭제·배포·권한 변경은 별도 승인 |
| 성숙도 경계 | 실제 실행 전까지 `STATIC_CANDIDATE` |

## 2. 후보군 선별

### 평가 기준

- 기존 도구가 해결하지 못하는 고유 가치가 있는가
- 현재 MIA·`skill-creator`·동기화 스크립트를 재사용할 수 있는가
- 작은 범위로 실제 검증할 수 있는가
- 세 플랫폼 변화에 따른 유지비가 감당 가능한가
- 첫 실험에서 유의미한 학습을 얻을 수 있는가

### 후보 비교

| 후보 | 역할 | 판정 | 이유 |
|---|---|---|---|
| `mia-skill-forge` | GPT 산출물을 공통 Agent Skill 후보로 정제 | **1차 구현** | MIA 고유 품질 회로와 Agent Skills 규격 사이의 실제 공백을 해결 |
| `mia-skill-evaluator` | 발동·행동·회귀 벤치마크 전담 | **2차 보류** | 첫 실험은 기존 `skill-creator` 평가 기능과 수동 테스트로 충분 |
| `mia-skill-distributor` | 세 플랫폼 설치본 생성·동기화 | **별도 Skill 기각** | 공통 정본과 얇은 어댑터면 충분하며 기존 동기화 스크립트와 중복 |
| `mia-skill-factory` | 설계·제작·평가·배포를 한 번에 수행 | **No-Go** | 과도한 권한·컨텍스트·실패 범위로 상태 정직성과 되돌림이 약해짐 |
| 기존 `skill-creator`만 사용 | 일반 Skill 생성 | 기준선 | 잘 만든 일반 생성기지만 MIA GPT 자료 정제·성숙도 Gate·3도구 계약은 없음 |

### 결정 Gate

- 결정: `GO` — `mia-skill-forge`만 먼저 제작
- 병합: 플랫폼 배포 설명은 forge의 reference로 포함
- 보류: 독립 evaluator는 1차 평가에서 반복 병목이 확인될 때만 분리
- 기각: 전 과정 단일 자동화와 자동 전역 설치
- 재검토 조건: 2개 이상의 Skill에서 동일한 평가·배포 로직이 반복될 때

## 3. 가져올 데이터 선별

원본 JSON과 보고서를 통째로 복사하지 않는다. 규칙 단위로 추출하고 Agent Skill에 필요한 표현으로 다시 쓴다.

### A. 반드시 가져올 MIA 데이터

| 원본 | 추출할 핵심 | 정제 방식 | 후보 내 위치 |
|---|---|---|---|
| `02_authority_intake_router_modes.json` | 권한 우선순위, 적응형 확인 질문, 모드가 권한이 아니라는 규칙 | 질문은 중요한 불확실성이 있을 때만, 추천안은 권한이 아님 | `SKILL.md` |
| `03_evidence_freshness_claim_ledger.json` | 사실·가정·미확인 분리, 최신성, 반대 증거 | 모든 작업에 ledger를 강제하지 않고 중요한 주장에만 적용 | `references/mia-quality-gates.md` |
| `04_decision_reliability_review_loop.json` | REDTEAM·CRITIC·SELFREFINE·OPTIMIZE 역할 | Skill 후보 검토 순서와 결함 분류로 축약 | `SKILL.md` |
| `05_architecture_sizing_contracts.json` | 논리 책임 후 물리 파일 수 결정 | 고정 20파일·GPT 모듈 수를 제거하고 필요한 resource만 생성 | `SKILL.md` |
| `06_harness_agent_package_delivery.json` | 실행 파일과 감사 자료의 경계 | Skill 폴더에는 실행 필수 자료만, 평가 기록은 외부에 보관 | `references/output-contract.md` |
| `07_invariants_evidence_dod_collision.json` | 불변조건, DoD, 충돌, 롤백 | frontmatter·발동·안전·검증의 합격 기준으로 변환 | `references/mia-quality-gates.md` |
| `08_safety_budget_permissions.json` | 비밀·외부 쓰기·배포·파괴 작업 승인 경계 | 현재 워크스페이스 안전 규칙과 중복 제거 후 핵심만 유지 | `SKILL.md` |
| `09_eval_status_preview_release.json` | 금지 상태 전이와 검증 증거 | `DIRECTION_DRAFT` → `STATIC_CANDIDATE` → `VERIFIED_RESULT` Gate로 변환 | `references/output-contract.md` |
| `10_vcn_entry_verification_feedback.json` | 한 실패→한 원인→최소 수정→재검증 | 오류·검증 상황에서만 발동하는 반복 회로로 축약 | `SKILL.md` |

### B. Agent Skills 규격에서 가져올 데이터

| 출처 | 가져올 내용 | 처리 원칙 |
|---|---|---|
| 설치된 `skill-creator` | 이름 규칙, 초기화, progressive disclosure, scripts/references/assets 분리, `quick_validate.py` | 복사하지 않고 제작 절차와 검증 도구를 재사용 |
| OpenAI Codex 공식 문서 | `SKILL.md`, `name`·`description`, `.agents/skills`, `agents/openai.yaml` | 확인일과 링크를 기록하고 플랫폼 계약으로 요약 |
| Claude Code 공식 문서 | `.claude/skills`, 명시·자동 호출, Claude 전용 frontmatter | 공통 정본을 오염시키지 않고 파생본 규칙으로 분리 |
| Antigravity 공식 문서 | `.agents/skills`, 전역 경로, `description` 기반 선택 | 공통 정본을 그대로 우선 사용 |
| 현재 `plan-review-execute` | 짧은 frontmatter, 단계 선택, 권한 경계, 성숙도 라벨 | 첫 변환·회귀 표본으로 사용 |

### C. 가져오지 않을 데이터

- 원본 Runtime Knowledge JSON 전체
- M00–M15와 L00–L10 같은 내부 Owner 번호
- ChatGPT Builder의 Package A 업로드 순서
- 8,000자 Core Instructions 프레임
- Knowledge 20파일 고정 상한
- Apps와 Actions 설정
- GPT 전용 Preview 창·Release 의미
- 체크섬·과거 생성 overlay·step 번호·포렌식 아카이브
- 웹앱·DB·서버용 VCN 세부 로직
- 원본 챗봇 지시문과 개인 자료

제외 원칙은 “기능 손실”이 아니라 **대상 시스템이 달라 발생하는 비관련 구조 제거**다.

## 4. 1차 후보 설계

### 이름과 역할

| 항목 | 결정 |
|---|---|
| 후보 이름 | `mia-skill-forge` |
| 한 가지 핵심 작업 | GPT·문서 기반 Skill 설계를 Agent Skills 표준 정적 후보로 변환 |
| 명시 호출 예 | `$mia-skill-forge 이 GPT 설계를 3도구 공통 Skill 후보로 만들어줘` |
| 자동 발동 | 초기에는 비활성 권장 |
| 출력 상태 | 항상 `STATIC_CANDIDATE`에서 시작 |
| 비목표 | 설치·배포·푸시·검증 결과 조작 |

### 후보 작업 폴더

검증 전에는 자동 발견되는 `.agents/skills`나 전역 Skills 경로에 넣지 않는다.

```text
skills/[userfile]/# 260720_gpt를 이용해서 Skills-모드 만들기/
├── candidates/
│   └── mia-skill-forge/
│       ├── SKILL.md
│       ├── agents/
│       │   └── openai.yaml
│       ├── references/
│       │   ├── mia-quality-gates.md
│       │   ├── platform-contracts.md
│       │   └── output-contract.md
│       └── scripts/
│           └── audit_skill_candidate.py
├── evals/
│   └── mia-skill-forge/
│       ├── cases.json
│       ├── results.json
│       └── benchmark.json
└── fixtures/
    └── plan-review-execute/
```

Skill 실행 폴더에는 README·변경 기록·제작 보고서를 넣지 않는다. 평가 자료와 표본은 sibling 폴더에 둔다.

### 입력 계약

- Skill의 핵심 작업 한 가지
- 실제 사용 예시 최소 3개
- 발동 예시와 비발동 예시
- 대상 플랫폼과 필요한 도구
- 입력·출력·중단 조건
- 성공 기준과 금지 행동
- GPT 초안 또는 참고 문서

입력이 부족하면 가장 영향이 큰 질문 하나를 먼저 제시하고, 안전한 임시 가정으로 계속할 수 있으면 표시 후 진행한다.

### 출력 계약

- 공통 `SKILL.md`
- 필요한 경우에만 scripts·references·assets
- Codex용 `agents/openai.yaml`
- Claude 전용 차이가 있을 때만 파생 frontmatter 제안
- should-trigger·should-not-trigger 평가 세트
- 핵심 작업·오류·보안 평가 세트
- 소스별 `preserve / adapt / omit` 결정 기록
- 미검증 항목과 다음 로컬 검증 단계

## 5. 구현 단계

### Phase 0 — 기준선 고정

- 현재 `plan-review-execute` 정본과 설치본 해시를 기록한다.
- 현재 발동 예시·비발동 예시·대표 출력 5개를 기준선으로 만든다.
- 챗봇 원문은 복사하지 않고 참조 경로와 추출 항목만 기록한다.

완료 기준: 재실행 가능한 표본과 기준선이 존재한다.

### Phase 1 — 후보 초기화

- `skill-creator/scripts/init_skill.py`로 후보 폴더를 생성한다.
- 이름은 `mia-skill-forge`, resources는 `scripts,references`만 선택한다.
- 임시 예제·불필요한 placeholder는 제거한다.
- `agents/openai.yaml`은 초기에는 명시 호출 전용으로 생성한다.

완료 기준: `quick_validate.py`가 기본 구조를 통과한다.

### Phase 2 — 데이터 정제

- 선별표의 원본 규칙을 한 항목씩 `preserve / adapt / omit`으로 분류한다.
- 중복되는 Authority·Safety·Status 규칙은 한 곳에만 둔다.
- `SKILL.md`에는 실행 절차만 남기고 배경 설명은 references로 이동한다.
- 플랫폼별 정보는 `platform-contracts.md` 한 파일에 모은다.

완료 기준: 원본 JSON을 읽지 않아도 후보가 동작하고, 모든 이식 규칙의 출처가 추적된다.

### Phase 3 — 정적 감사 스크립트

표준 라이브러리만 사용하는 `audit_skill_candidate.py`를 작성한다.

검사 항목:

- 폴더명과 frontmatter `name` 일치
- `name`·`description` 존재와 이름 규칙
- 본문 500줄 미만
- 깊게 중첩된 reference 또는 끊어진 상대 링크
- 불필요한 README·CHANGELOG·설치 가이드
- 민감 파일명과 위험 명령 패턴
- status 과장 표현
- 플랫폼 파생본의 공통 본문 이탈

이 스크립트는 행동 품질을 증명하지 않으며 구조 문제만 검사한다.

완료 기준: 정상 fixture는 통과하고, 의도적으로 망가뜨린 fixture는 정확한 오류로 실패한다.

### Phase 4 — 첫 표본 변환

`plan-review-execute`를 입력으로 다음을 수행한다.

- 기존 정본을 훼손하지 않고 별도 fixture로 복사한다.
- forge가 공통 정본·Codex metadata·Claude 차이를 제안하게 한다.
- 현재 정본과 결과의 의미 차이를 비교한다.
- 기능 추가보다 발동 정밀도와 중복 제거를 우선한다.

완료 기준: 기존 의미·안전 경계·성숙도 Gate가 유지되고 불필요한 구조가 늘지 않는다.

### Phase 5 — 발동·행동 평가

- should-trigger 10개
- should-not-trigger 10개
- 핵심 작업 5개
- 불완전 입력 3개
- 권한·안전 거부 3개
- Skill 없는 기준선과 비교

측정 항목:

- 명시 호출 성공
- 자동 발동 정밀도·재현율
- 핵심 작업 통과율
- 사용자 추가 질문 수
- 토큰·시간 증가량
- Critical 안전 실패

완료 기준은 다음과 같다.

- 발동 정밀도와 재현율 각각 90% 이상
- 핵심 작업 통과율 80% 이상
- 기준선보다 성공률이 개선되거나 사용자 작업이 의미 있게 감소
- Critical 안전 실패 0건
- 검증 없는 PASS 0건

### Phase 6 — 3플랫폼 smoke test

이 단계는 사용자 승인 후 전역 또는 임시 설치 경로에 쓴다.

- Codex: 발견, `$이름` 명시 호출, metadata 표시
- Claude Code: 발견, `/이름` 호출, 전용 frontmatter 동작
- Antigravity: 발견, 이름 호출, 공통 `description` 선택
- 각 도구에서 같은 핵심 작업 1개와 비발동 사례 1개 수행

완료 기준: 세 도구의 핵심 의미가 같고 플랫폼 전용 차이만 존재한다.

### Phase 7 — 승격 또는 중단

통과 시:

- 후보 상태를 `VERIFIED_RESULT`로 변경한다.
- 정본을 `shared/plugins/mia-modular-intelligence-architect/skills/mia-skill-forge/`로 승격한다.
- 필요하면 `shared/skills/` 미러와 동기화 스크립트를 확장한다.
- 버전과 검증 증거를 함께 기록한다.

실패 시:

- 한 실패→한 원인→최소 수정→해당 평가 재실행
- 세 번 같은 원인으로 실패하면 구현을 멈추고 설계 또는 후보 분리를 재검토
- 기준선보다 낫지 않으면 `stop` 또는 기존 `skill-creator` 보조 문서로 축소

## 6. 파일별 구현 책임

| 파일 | 책임 | 예상 규모 |
|---|---|---|
| `SKILL.md` | 입력 라우팅, 변환 절차, 안전·상태 Gate | 200줄 이하 목표 |
| `references/mia-quality-gates.md` | 선별한 MIA 품질 회로 | 150줄 이하 목표 |
| `references/platform-contracts.md` | 공통 규격과 세 플랫폼 차이 | 150줄 이하 목표 |
| `references/output-contract.md` | 파일 트리, 상태, 평가·승격 계약 | 120줄 이하 목표 |
| `scripts/audit_skill_candidate.py` | 결정적 정적 검사 | 외부 패키지 없음 |
| `agents/openai.yaml` | Codex UI와 명시 호출 정책 | 최소 필드만 |
| 외부 evals | 발동·행동·기준선 결과 | Skill 폴더 밖 |

규모는 합격 조건이 아니라 과잉 설계를 조기에 탐지하는 경보 값이다.

## 7. 위험과 완화

| 위험 | 영향 | 완화 |
|---|---|---|
| 기존 `skill-creator` 복제 | 유지비 증가 | 초기화·기본 검증은 그대로 재사용 |
| MIA 원본 과잉 이식 | 컨텍스트 비대 | 대상 행동에 필요한 규칙만 `preserve / adapt / omit` |
| 플랫폼별 복제본 드리프트 | 동작 불일치 | 공통 정본 우선, 파생 차이는 자동 비교 |
| 정적 검사 과신 | 거짓 완료 | 구조 통과와 행동 검증을 별도 상태로 유지 |
| 자동 설치의 권한 확대 | 사용자 환경 오염 | 후보 폴더에서 개발하고 설치는 별도 승인 |
| 챗봇 원문 유출 | 개인 자산 노출 | 원문 복사 금지, 경로·추출 규칙만 기록 |

## 8. 롤백 계획

- 후보는 자동 발견 경로 밖에서 개발한다.
- 기존 `plan-review-execute` 정본과 동기화 스크립트는 Phase 6 전까지 수정하지 않는다.
- 모든 비교는 별도 fixture에서 수행한다.
- 승격 후 문제가 생기면 새 Skill만 비활성화하거나 이전 버전으로 되돌린다.
- 기존 MIA Skill의 기능·이름·발동 문구는 첫 실험에서 변경하지 않는다.

## 9. Definition of Done

다음을 모두 만족해야 1차 구현이 완료된다.

- `mia-skill-forge` 후보 구조가 정적 검증을 통과
- 선별 데이터의 `preserve / adapt / omit` 추적표 완성
- `plan-review-execute` 표본 변환 완료
- 발동·비발동·핵심 작업·안전 평가 기준 충족
- Skill 없는 기준선과 비교 결과 존재
- 세 플랫폼 smoke test 완료
- Critical 안전 실패와 거짓 PASS 없음
- 정본 승격 여부를 `scale / iterate / stop`으로 결정

## 10. 다음 실행 카드

다음 승인 범위는 **Phase 0~3의 로컬 후보 제작**이다.

- 생성: 후보 Skill, 3개 reference, 정적 감사 스크립트, eval 틀
- 수정하지 않음: 기존 MIA 정본, 전역 Skills, 플러그인 설치본
- 외부 작업 없음: 설치·배포·푸시 없음
- 중간 Gate: 정적 검사와 원본 추적표를 검토한 뒤 Phase 4로 진행

이 범위가 승인되면 `skill-creator`의 초기화 스크립트를 사용해 실제 후보 생성을 시작한다.

## 11. Phase 0~3 실행 기록 — 2026-07-19

승인된 로컬 범위의 구현을 완료했다. 후보의 현재 성숙도는 런타임 미검증 상태인
`STATIC_CANDIDATE`로 유지한다.

| Phase | 결과 | 증거 |
|---|---|---|
| Phase 0 기준선 | 완료 | 정본·플러그인 미러·Codex metadata SHA-256과 대표 사례 5개를 `fixtures/plan-review-execute/baseline.json`에 기록 |
| Phase 1 초기화 | 구현 완료·공식 검증 보류 | 공식 `init_skill.py`로 `mia-skill-forge` 및 `scripts,references` 골격 생성 |
| Phase 2 정제 | 완료 | `SKILL.md`, 3개 reference, `preserve / adapt / omit` 추적표 작성 |
| Phase 3 감사기 | 완료 | 표준 라이브러리 기반 감사기, 정상·오류 픽스처, 외부 eval 틀 작성 |

검증 결과:

- Python 구문 검사: 통과
- 자체 감사 — 후보: 오류 0, 경고 0
- 자체 감사 — 정상 픽스처: 오류 0, 경고 0
- 자체 감사 — 오류 픽스처: 예상대로 실패, 오류 3개 검출
- JSON 파싱 — baseline·cases·results·benchmark: 통과
- 공식 `quick_validate.py`: 실행 실패(환경 의존성). 두 로컬 Python 런타임 모두
  필수 모듈 `PyYAML`이 없어 `ModuleNotFoundError`가 발생했으며, 별도 승인 없는
  패키지 설치는 수행하지 않았다.

보류 항목:

- `plan-review-execute` 실제 변환은 Phase 4
- 발동·비발동·행동 평가는 Phase 5
- 전역 또는 임시 설치와 3플랫폼 smoke test는 Phase 6
- 정본 승격·동기화 변경·커밋·푸시는 별도 승인 범위

## 12. 최적화 수행 절차와 첫 표본 판정 — 2026-07-20

사용자 승인에 따라 `mia-skill-forge`에 최적화 수행 절차를 추가했다. 별도의
`mia-skill-optimizer`를 만들지 않고 기존 후보의 reference로 병합해 발동 충돌과
유지비를 줄였다.

절차는 목표 잠금, 기준선 고정, 단일 병목 진단, 최소 대안 비교, 별도 후보 수정,
층별 검증, 순개선 측정, `iterate / scale / stop / no-change` 판정으로 구성한다.

첫 표본 `plan-review-execute`의 판정은 `no-change`다.

- 정본과 플러그인 미러의 `SKILL.md` SHA-256이 동일함
- 새 후보 규격과 기존 Codex metadata 사이에 차이가 있지만 실제 발동 실패나
  오발동 증거는 아직 없음
- 정적 규격 차이만으로 기존 정본을 바꾸면 회귀 위험이 이득보다 큼
- 다음 최소 실험은 고정된 발동·비발동 사례와 `$plan-review-execute`·기존 문구
  호출을 실제 런타임에서 비교하는 것

판정 근거는 사용자 작업 폴더의
`fixtures/plan-review-execute/optimization-assessment.json`에 기록했다. 사용자용 설명은
`MIA_SKILL_FORGE_USER_GUIDE_2026-07-20.md`에서 별도로 제공한다.
