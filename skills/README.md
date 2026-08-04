# Skills 관리 안내

> 이 폴더는 Claude Code, Codex, Antigravity에서 사용할 Skill의 정본과 검증 근거를
> 관리합니다. 직접 만든 Skill과 외부에서 가져온 Skill은 섞지 않습니다.

## 30초 안내

- 내가 만든 MIA Skill을 찾거나 고치려면 [`custom/mia/`](custom/mia/)로 갑니다.
- 외부 Skill을 들여오거나 정제하려면 [`external/`](external/)의 반입 계약부터 읽습니다.
- 조사 기록과 선택 근거는 `research/`에 둡니다. 이 파일들은 설치 대상이 아닙니다.
- **어느 Skill을 어느 도구에 올렸는지와 그 근거는 [`DEPLOYMENT.md`](DEPLOYMENT.md)가 정본입니다.**
- 사용자 홈의 배포 위치는 도구마다 다릅니다. **공용 경로는 없습니다.**
  `.claude/skills`(Claude Code) · `.codex/skills`+`.agents/skills`(Codex) ·
  `.gemini/config/skills` 계열(Antigravity). 배포 위치는 저장소 정본을 대신하지 않습니다.

## 분류 기준

| 분류 | 위치 | 소유권 | 직접 수정 위치 |
|---|---|---|---|
| 사용자 제작 | [`custom/`](custom/) | 윤겸스가 설계하고 유지 | 각 Skill의 정본 `SKILL.md` |
| 외부 도입 | [`external/`](external/) | 외부 제작자, 로컬 정제 이력 별도 | 원본 사본과 `SOURCE.md` |
| 조사·근거 | `research/` | 저장소 운영 기록 | 보고서와 감사 기록 |

출처가 불분명하면 먼저 `external/`로 분류합니다. 사용자 제작으로 확인되기 전에는
`custom/`으로 옮기지 않습니다.

이 저장소의 `custom`과 `external`은 소유권을 구분하는 관리 계층입니다. 실제로 배포할
각 Skill 폴더는 공식 규격처럼 `SKILL.md`를 필수 정본으로 갖고, 필요한 경우에만
`scripts/`, `references/`, `assets/`를 둡니다. 자세한 형식은
[Agent Skills 공식 규격](https://agentskills.io/specification)을 따릅니다.

## 폴더 구조

```text
skills/
├─ custom/
│  └─ mia/
│     ├─ plan-review-execute/   # 현재 실행 Skill 정본과 배포 패키지
│     └─ compiler-workbench/    # 새 Skill 후보와 평가 증거
├─ external/                    # 외부 Skill과 출처 추적
└─ research/                    # 설치하지 않는 조사·감사 자료
```

## 상태를 읽는 법

| 상태 | 의미 | 아직 주장할 수 없는 것 |
|---|---|---|
| `STATIC_CANDIDATE` | 파일 구조와 정적 계약을 검사한 후보 | 실제 발견, 발동, 작업 성공 |
| `DISCOVERY_CONFIRMED` | 새 작업의 Available skills에서 실제 노출 확인 | 전체 작업 품질과 안전성 |
| `VERIFIED_RESULT` | 발견·발동·작업·안전·회귀 평가 통과 | 다른 환경에서의 영구적 성공 |

파일이 복사됐다는 사실과 AI가 Skill을 발견했다는 사실은 다릅니다. 새 작업에서
Available skills 노출을 확인하기 전에는 런타임 성공으로 기록하지 않습니다.

## 변경 순서

1. `custom` 또는 `external` 중 소유 분류를 먼저 정합니다.
2. 정본과 출처 파일만 수정합니다. 생성본과 전역 설치본은 직접 고치지 않습니다.
3. 정적 검사와 JSON·YAML 파싱을 실행합니다.
4. 새 작업에서 발견과 명시 발동을 평가합니다.
5. 전역 설치·배포·외부 실행은 영향 범위를 설명하고 별도 승인 후 수행합니다.
6. 검증 결과와 남은 위험을 가까운 `evals/` 또는 README에 기록합니다.

## 관련 문서

- [도구별 배포 정본과 선별 근거](DEPLOYMENT.md)
- [MIA 사용자 제작 Skill](custom/mia/)
- [MIA plan-review-execute 정본](custom/mia/plan-review-execute/)
- [MIA Skill Compiler 작업대](custom/mia/compiler-workbench/)
- [외부 Skill 반입 계약](external/)
- [Skill 조사 기록](research/MIA_SKILLS_EXPLORATION_2026-07-19.md)
- [플랫폼 Skill 슬림화 감사](research/MIA_PLATFORM_SLIM_AUDIT_2026-07-19.md)
- [GitHub README 공식 안내](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)
