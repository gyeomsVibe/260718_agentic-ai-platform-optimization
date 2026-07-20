# MIA Skill Compiler Workbench

이 폴더는 Claude Code, Codex, Antigravity용 Agent Skill을 설계하고 검증하는
단일 정본 작업대입니다. GPT 챗봇 제작 폴더가 아닙니다.

## 무엇이 들어 있나요?

| 경로 | 역할 | 현재 위치 |
|---|---|---|
| `candidates/mia-skill-compiler/` | 조사·PRD·생성·검증·승격을 잇는 현재 후보 | 주 개발 대상 |
| `candidates/mia-skill-forge/` | 정적 후보 생성 계약을 보존한 이전 세대 | 호환·회귀 근거 |
| `candidates/hybrid-image-production-architect/` | 실제 입력을 변환한 첫 정적 후보 사례 | 예제 |
| `evals/` | 정적 검사와 런타임 평가 기록 | 증거 |
| `fixtures/` | 원본 규칙 추적과 감사용 표본 | 근거 |
| `reports/` | 사람이 읽는 설계 보고서 | 설명 |

## 초보 사용자가 알아야 할 상태

- `STATIC_CANDIDATE`: 파일 구조와 계약을 정적으로 검사한 후보입니다.
- `DISCOVERY_CONFIRMED`: 새 작업에서 Skill 목록에 실제로 보인 상태입니다.
- `VERIFIED_RESULT`: 발견·발동·작업·안전·회귀 검증까지 통과한 결과입니다.

정적 검사 통과만으로 설치나 실행 성공을 주장하지 않습니다. 설치, 전역 배포,
외부 실행, 커밋과 푸시는 각각 별도 권한과 검증 경계를 유지합니다.

## 정본과 이전 경로

2026-07-20에 아래 두 작업 폴더를 이 폴더로 통합했습니다.

- `skills/gpt를 이용해서 Skills-모드 만들기/`
- `skills/[userfile]/# 260720_gpt를 이용해서 Skills-모드 만들기/`

두 폴더에는 byte 단위 완전 중복 파일이 없었지만, 이름과 목적이 겹쳐 정본이
불명확했습니다. 통합 판단과 제거한 낡은 문서의 해시는
`evals/mia-skill-compiler/workspace-consolidation-2026-07-20.json`에 기록했습니다.

`.agents/`는 임시 설치 영역이므로 이 작업대의 정본이나 커밋 대상이 아닙니다.
