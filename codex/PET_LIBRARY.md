# 나만의 커스텀 반려동물(Pet) 자료실

상태: `VERIFIED_RESULT`
대상: Codex App 반려동물 커스터마이징의 설계·프롬프트·시각 QA·복구 기록

## 이 자료가 Codex 섹션에 있는 이유

반려동물은 Codex App 인터페이스를 개인화하는 작업이다. 생성 프롬프트만이 아니라 런타임 제약, 설치 절차, 시각 검수(QA), 실패 복구 기록이 함께 있어야 재현 가능하다. 따라서 플랫폼 공용 자료가 아닌 `codex/`의 운영 자산으로 관리한다.

## 빠른 탐색

| 시작점 | 용도 | 권장 사용 시점 |
| --- | --- | --- |
| [custom-pet-manual/](custom-pet-manual/) | 런타임 제약과 이미지 뷰어 문제 해결을 포함한 기본 매뉴얼 | 새 Pet 제작 또는 설치 전 |
| [사용자 문서 보관함](https://github.com/gyeomsVibe/260718_agentic-ai-platform-optimization/tree/main/codex/%23%20%5B문서%5D%20나만의%20커스텀%20반려동물%20만들기) | 기획·제작 흐름을 설명하는 사용자 문서 | 전체 과정을 빠르게 이해할 때 |
| [MIA_GYEOM_PET_OPTIMIZATION_DECISION_2026-07-16.md](MIA_GYEOM_PET_OPTIMIZATION_DECISION_2026-07-16.md) | 최적화 판단과 품질 기준 | 작업 방향을 다시 결정할 때 |
| [HANDOFF_GYEOM_PET_2026-07-16.md](HANDOFF_GYEOM_PET_2026-07-16.md) | 다음 작업자를 위한 인수인계 | 기존 작업을 이어갈 때 |
| [pet-repair-20260717/](pet-repair-20260717/) | 반복 보정의 프롬프트·행별 재시도·QA 이력 | 특정 포즈나 시선 오류를 복구할 때 |
| [pet-rebuild-20260718/](pet-rebuild-20260718/) | 재구축 후보와 최종 시각 QA 결과 | 새 기준으로 다시 제작·선정할 때 |

## 권장 읽기 순서

1. `custom-pet-manual/README.md`와 `RUNTIME_STATUS_LIMITS.md`로 런타임 제약을 확인한다.
2. MIA 결정 문서와 인수인계 문서로 기존 품질 기준·미해결 항목을 파악한다.
3. `pet-repair-20260717/`의 프롬프트·QA 기록에서 유사 실패 사례를 찾는다.
4. `pet-rebuild-20260718/`의 QA 결과를 기준으로 새 결과물을 비교한다.

## 보존 및 정리 원칙

- 프롬프트, 원본 자산, 파생 시트, QA 결과는 하나의 검증 단위로 보존한다.
- 생성물만 남기고 QA 기록을 삭제하지 않는다. 시각 선택의 근거가 사라진다.
- 동일 자산의 중복 제거는 해시 비교와 참조 경로 확인을 마친 별도 커밋에서만 수행한다.
- 로그인 정보, 토큰, 세션 데이터, 캐시 파일은 포함하지 않는다.
- 대용량 자산은 GitHub 파일 제한을 사전 점검한 뒤 추가한다.

## 이전 무결성 기록

2026-07-19 기준으로 기존 `260713_pc-optimization` 저장소가 추적하던 아래 문서는 이 자료실의 동일 경로와 Git blob 해시가 일치함을 확인했다.

- `custom-pet-manual/README.md`
- `custom-pet-manual/RUNTIME_STATUS_LIMITS.md`
- `custom-pet-manual/codex-image-viewer-sandbox-fix/README.md`

대상 저장소 커밋 `bb275a6`와 원격 푸시, 원본 저장소의 삭제 커밋 `36b7ee8`과 원격 푸시까지 확인했다.
