# Codex 작업·관리 섹션

> **Codex**는 OpenAI가 만든 AI 코딩 에이전트(데스크톱 앱)입니다. 이 폴더는 Codex를
> 잘 쓰기 위한 자료를 **세 개의 섹션 폴더**로 분류해 둡니다. 낱개 문서를 루트에 흩어 두지 않습니다.

## 섹션 지도

| 섹션 | 무엇인가 | 진입점 |
|---|---|---|
| 🧩 **환경설정** | 플러그인·MCP·계정 연동 구조와 정리 원칙, 샌드박스 트러블슈팅 | [environment-notebook.md](environment-notebook.md) |
| 🛠 **[app-diagnostics/](app-diagnostics/)** | 앱 진단·오류해결·패치 — 진단 스크립트·복구 배치·검증 보고서를 **한 폴더에** | [app-diagnostics/](app-diagnostics/) |
| 🐾 **[custom-pet/](custom-pet/)** | 커스텀 반려동물(Pet) 제작·복구·QA 자료 전체 | [custom-pet/PET_LIBRARY.md](custom-pet/PET_LIBRARY.md) |

---

## 🧩 환경설정

| 문서 | 내용 |
|---|---|
| [environment-notebook.md](environment-notebook.md) | 노트북 환경설정 기록 — `~/.codex/` 구조, "안 쓰는 건 비활성화" 정리 원칙, **트러블슈팅 3건**(샌드박스에서 `gh` 인증 실패 해결, 압축 파일 미리보기 우회, write-root 권한(ACL) 체크리스트) |
| [environment-desktop.md](environment-desktop.md) | 데스크톱 환경설정 기록 |

> 이 두 파일은 다른 저장소·다른 도구 문서에서 링크로 참조하므로 루트에 그대로 둡니다.
> 세 도구가 함께 쓰는 전역 규칙·자동화는 [`../shared/`](../shared/)에 있습니다.

## 🛠 app-diagnostics — 앱 진단·오류해결·패치

Codex 앱 자체의 문제(샌드박스 파일 쓰기 거부·이미지 다운로드·압축 미리보기)를 **진단·복구**하는
도구와 기록을 **한 폴더에** 모았습니다. 위험한 앱 바이너리 패치는 폐기하고 **순정 앱 유지 + 권한(ACL) 복구** 정공법을 씁니다.

**→ [app-diagnostics/](app-diagnostics/)** 에서 시작하세요. 폴더 안에 자가진단 스크립트,
권한 복구 배치, 검증 보고서, 인수인계 문서가 함께 있습니다.

> ⚠️ 이전의 `codex-image-download-fix-20260719/`(ASAR 패치) 방식은 스토어 서명 손상 위험으로 폐기·삭제됨.

## 🐾 custom-pet — 커스텀 반려동물

Codex 앱 화면 구석에서 움직이는 내 캐릭터(펫)를 만드는 전 과정 자료입니다. 그림 한 장이 아니라
"모든 동작에서 같은 캐릭터를 유지하는 일"이 핵심이라 제작·검수·복구 기록이 함께 있습니다.

**→ [custom-pet/PET_LIBRARY.md](custom-pet/PET_LIBRARY.md)** 가 펫 자료 전체의 안내판입니다.

| 자료 | 무엇인가 |
|---|---|
| [custom-pet/PET_LIBRARY.md](custom-pet/PET_LIBRARY.md) | 펫 자료 전체의 **단일 진입점**(목차·읽는 순서) |
| [custom-pet/custom-pet-manual/](custom-pet/custom-pet-manual/) | 초보자용 제작·설치 매뉴얼과 현재 런타임 규격 |
| [custom-pet/pet-repair-20260717/](custom-pet/pet-repair-20260717/) · [custom-pet/pet-rebuild-20260718/](custom-pet/pet-rebuild-20260718/) | 복구·재제작 이력과 시각 QA |
| [custom-pet/MIA_GYEOM_PET_OPTIMIZATION_DECISION_2026-07-16.md](custom-pet/MIA_GYEOM_PET_OPTIMIZATION_DECISION_2026-07-16.md) · [custom-pet/HANDOFF_GYEOM_PET_2026-07-16.md](custom-pet/HANDOFF_GYEOM_PET_2026-07-16.md) | 의사결정·인수인계 기록 |
