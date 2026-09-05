# 사용자 제작 Skills — 처음 보는 사람의 입구

> Skill은 AI가 반복 작업을 같은 기준으로 수행하게 만드는 작은 절차 묶음입니다. 이 폴더에는
> 윤겸스가 직접 설계하고 유지하는 정본만 둡니다. 외부 제작자의 Skill은 수정했더라도
> [`../external/`](../external/)에서 출처와 함께 관리합니다.

## 무엇부터 보면 되나요?

| 하고 싶은 일 | 첫 문서 |
|---|---|
| Skill을 사용하고 싶다 | [전체 사용 매뉴얼](../MANUAL.md) |
| 짧은 `/명령`으로 답변 방식을 바꾸고 싶다 | [Slash Prompt Modes 30초 사용법](slash-prompt-modes/README.md) |
| Skill을 처음부터 만들거나 개선하고 싶다 | [스킬 만들기 상위원칙 바이블](mia/1_mia-skill-compiler/candidates/mia-skill-compiler/references/skill-creation-bible.md) |
| MIA Skill을 실제 파일로 만들고 배포하고 싶다 | [MIA 제작 실무 교본](mia/AUTHORING_HANDBOOK.md) |

바이블은 “왜 그렇게 설계하는가”, 실무 교본은 “어떤 파일을 만들고 무엇을 검사하는가”를
맡습니다. 같은 규칙을 두 문서에 복제하지 않습니다.

## 현재 제품군

| 제품군 | 역할 |
|---|---|
| [`mia/`](mia/) | MIA 시리즈 실행 Skill, 생성 도구, 평가 증거 |
| [`slash-prompt-modes/`](slash-prompt-modes/) | MIA와 독립된 10개 슬래시 프롬프트 모드의 정본·어댑터·검증 증거 |

`legacy-harness/`는 과거 자산을 보존한 격리 영역이며, 현재 활성 제품군이나 새 Skill의
복사 원본이 아닙니다.

## 라이선스를 먼저 확인하세요

GitHub에서 보인다는 사실만으로 다른 사람이 복제·수정·배포해도 된다는 뜻은 아닙니다.

| 범위 | 상태 | 의미 |
|---|---|---|
| [`mia/`](mia/) | [MIT](mia/LICENSE.md) | MIA 사용자 제작 범위. 활성 Skill frontmatter도 `license: MIT`로 검사 |
| [`slash-prompt-modes/`](slash-prompt-modes/) | [MIT](slash-prompt-modes/LICENSE.md) | 이 독립 Skill 폴더에만 적용 |
| [`legacy-harness/`](legacy-harness/) | 출처·권리 재확인 전 공개 라이선스 미부여 | 임의로 MIT를 덮지 않는 보존 영역 |
| [`../external/`](../external/) | 외부 항목별 `SOURCE.md` | 원 저작자의 라이선스와 고지 의무를 그대로 추적 |

새 사용자 제작 Skill은 공개·배포 전에 저작권자, 적용 경로, SPDX 식별자, 라이선스 원문,
제3자 예외를 확정해야 합니다. 모르면 `MIT`를 추측해 넣지 말고 승격을 보류합니다.

## 새 Skill을 넣는 기준

```text
custom/<제품군>/<skill-name>/
├─ SKILL.md        # 사람이 직접 수정하는 실행 정본
├─ agents/         # 플랫폼 메타데이터가 필요할 때만
├─ references/     # 본문에서 분리한 지식 모듈
├─ scripts/        # 반복적이고 결정적인 실행이 필요할 때만
└─ assets/         # 결과물에 복사·사용할 재료가 있을 때만
```

저장소에서 사람에게 안내할 README·평가·배포 기록은 제품군의 관리용 래퍼로 둘 수 있지만,
AI가 읽는 런타임 번들에는 기능에 필요한 파일만 포함합니다.

- 한 Skill의 정본은 하나만 둡니다.
- 생성된 어댑터와 패키지 복제본에는 직접 수정 금지 여부를 표시합니다.
- 후보, 평가 자료, 실제 실행 Skill을 같은 폴더 단계에 섞지 않습니다.
- 전역 설치 폴더를 정본으로 삼거나 저장소에 복사해 넣지 않습니다.
- 사용자 소유·배포 가능 Skill은 `license`와 라이선스 원문 없이 출고하지 않습니다.

외부 자료를 참고해 새 Skill을 만들었다면 참고 자료의 출처와 채택·수정·제외한 규칙을
가까운 추적 파일에 남깁니다. 소유권과 라이선스가 불명확하면 `external/`에서 먼저
검토합니다.
