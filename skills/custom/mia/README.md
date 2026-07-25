# MIA 사용자 제작 Skills

> MIA(Modular Intelligence Architect) 시리즈의 실행 정본과 Skill 제작 작업대를
> 한곳에서 관리합니다. GPT 챗봇 파일이나 외부 Skill 원본을 두는 폴더가 아닙니다.

## 어디로 가야 하나요?

| 경로 | 역할 | 수정 대상 |
|---|---|---|
| [`plan-review-execute/`](plan-review-execute/) | 현재 사용 중인 MIA 기획·검토·실행 Skill | 상위 `SKILL.md` 정본 |
| [`compiler-workbench/`](compiler-workbench/) | MIA Skill Compiler 후보, 변환 사례, 평가 증거 | 후보별 정본과 평가 파일 |

쉽게 말하면 `plan-review-execute`는 실제로 쓰는 도구이고,
`compiler-workbench`는 다음 도구를 설계하고 시험하는 작업실입니다.

## 상태와 배포 경계

- 작업대의 후보는 정적 검사를 통과해도 자동으로 실행 Skill이 되지 않습니다.
- `DISCOVERY_CONFIRMED`는 새 작업의 Available skills 목록에서 실제로 확인해야 합니다.
- 전역 설치, 플랫폼 배포, 외부 실행은 각각 영향이 다른 작업입니다. 한 번의 정적 통과로
  모두 승인된 것으로 취급하지 않습니다.
- `.agents/`, `.codex/`, `.claude/`, `.gemini/`의 설치본은 배포 결과이며 정본이 아닙니다.

## 새 MIA 구성요소를 추가할 때

1. 실제 사용 Skill인지, 제작·평가 도구인지 먼저 구분합니다.
2. 실제 사용 Skill은 독립 폴더와 단일 `SKILL.md` 정본을 갖게 합니다.
3. 후보와 평가 증거는 `compiler-workbench`에 둡니다.
4. 외부에서 가져온 Skill 자체는 [`../../external/`](../../external/)에 보관합니다.
5. README에 정본, 생성본, 검사 명령, 설치 경계를 명시합니다.
