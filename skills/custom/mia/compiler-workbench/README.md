# MIA Skill Compiler 작업대

> 초기 아이디어나 기존 문서를 Claude Code, Codex, Antigravity용 Agent Skill 후보로
> 설계하고 검증하는 작업대입니다. GPT 챗봇을 만드는 폴더가 아닙니다.

## 무엇이 들어 있나요?

| 경로 | 역할 | 현재 상태 |
|---|---|---|
| `candidates/mia-skill-compiler/` | 조사·PRD·생성·검증·승격을 잇는 현재 후보 | 주 개발 대상 |
| `candidates/mia-skill-forge/` | 이전 정적 후보 생성 계약 | 호환·회귀 근거 |
| `candidates/hybrid-image-production-architect/` | 실제 입력을 변환한 첫 사례 | 예제 후보 |
| `evals/` | 정적 검사와 런타임 평가 결과 | 검증 증거 |
| `fixtures/` | 원본 규칙 추적과 실패 표본 | 감사 근거 |
| `reports/` | 사람이 읽는 설계·분석 보고서 | 설명 자료 |

## 상태를 쉽게 이해하기

- `STATIC_CANDIDATE`: 서류와 구조를 검사한 시제품입니다. 실제 사용 성공은 아닙니다.
- `DISCOVERY_CONFIRMED`: 새 작업의 Skill 목록에서 실제로 보인 상태입니다.
- `VERIFIED_RESULT`: 발견, 발동, 작업, 안전, 회귀 평가를 모두 통과한 결과입니다.

정적 검사 통과만으로 설치·전역 배포·외부 실행 성공을 주장하지 않습니다. 각 작업은
영향 범위가 다르므로 별도 승인과 증거가 필요합니다.

## 작업 흐름

1. 입력 아이디어와 출처를 `fixtures/` 또는 후보의 추적 파일에 기록합니다.
2. 후보를 `candidates/` 아래에서 만듭니다.
3. 감사 스크립트와 JSON·YAML 검사를 실행합니다.
4. 평가 계약을 `evals/`에 기록합니다.
5. 새 작업에서 발견 확인 후 명시 호출 사례를 실행합니다.
6. 품질 문턱을 통과한 후보만 실제 MIA 실행 Skill로 승격합니다.

승격 대상은 자동으로 [`../plan-review-execute/`](../plan-review-execute/)에 덮어쓰지
않습니다. 차이, 위험, 복구 방법을 검토한 뒤 별도 변경으로 반영합니다.

## 이전 경로와 역사적 증거

2026-07-20에 다음 작업 폴더를 이곳으로 통합했습니다.

- `skills/gpt를 이용해서 Skills-모드 만들기/`
- `skills/[userfile]/# 260720_gpt를 이용해서 Skills-모드 만들기/`

두 폴더에는 바이트 단위 완전 중복 파일이 없었지만 이름과 목적이 겹쳐 정본이
불명확했습니다. 통합 판단과 제거한 문서의 해시는
`evals/mia-skill-compiler/workspace-consolidation-2026-07-20.json`에 남아 있습니다.

평가 파일의 `historical_path`, 이전 절대 경로, 과거 폴더 이름은 당시 검증 위치를
보존하는 증거입니다. 현재 편집 경로가 아닙니다. `.agents/`도 임시 설치 영역이므로
정본이나 커밋 대상이 아닙니다.
