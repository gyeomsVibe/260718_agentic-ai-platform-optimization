# Codex 작업·관리 섹션

> **Codex**는 OpenAI가 만든 AI 코딩 에이전트(데스크톱 앱)입니다. 이 폴더는 Codex를
> 잘 쓰기 위한 **환경설정 기록**, **앱 문제해결**, 그리고 Codex 앱을 개인화하는
> **커스텀 반려동물(Pet) 제작 자료**를 모아 둡니다.

## 이 섹션은 크게 3덩어리

| 덩어리 | 무엇인가 | 진입 문서 |
|---|---|---|
| 🧩 **환경설정** | Codex의 플러그인·MCP·계정 연동 구조와 정리 원칙, 샌드박스 문제해결 | [environment-notebook.md](environment-notebook.md) |
| 🐾 **커스텀 반려동물** | 내 캐릭터를 Codex 앱 안에서 움직이는 펫으로 만드는 전 과정 | [PET_LIBRARY.md](PET_LIBRARY.md) |
| 🛠 **앱 진단·패치** | Codex 샌드박스 권한·이미지 다운로드 등 앱 문제의 진단·복구 도구와 기록 | [docs/](docs/) |

---

## 🧩 환경설정

| 문서 | 내용 |
|---|---|
| [environment-notebook.md](environment-notebook.md) | 노트북 환경설정 기록 — `~/.codex/` 구조, "안 쓰는 건 비활성화" 정리 원칙, **트러블슈팅 3건**(샌드박스에서 `gh` 인증 실패 해결, 압축 파일 미리보기 우회, write-root 권한(ACL) 체크리스트) |

> 데스크톱 환경 기록은 아직 없습니다 (필요하면 `environment-desktop.md`로 추가).
> 세 도구가 함께 쓰는 전역 규칙·자동화는 [`../shared/`](../shared/)에 있습니다.

## 🐾 커스텀 반려동물 (Custom Pet)

**"반려동물"이 뭔가요?** Codex 앱 화면 구석에서 움직이는 작은 캐릭터입니다. 내 캐릭터
그림을 여러 동작(대기·달리기·인사·점프 등)의 **스프라이트 시트**로 만들어 넣으면, 앱이
작업 상태에 맞춰 그 캐릭터를 움직입니다. 그림 한 장이 아니라 "모든 동작에서 같은 캐릭터를
유지하는 일"이 핵심이라 제작·검수·복구 기록이 함께 필요합니다.

**여기부터 보세요 → [PET_LIBRARY.md](PET_LIBRARY.md)** (펫 자료 전체의 안내판)

| 자료 | 무엇인가 | 언제 보나 |
|---|---|---|
| [PET_LIBRARY.md](PET_LIBRARY.md) | 펫 자료 전체의 **단일 진입점**(목차·읽는 순서) | 무엇부터 볼지 모를 때 |
| [custom-pet-manual/](custom-pet-manual/) | 초보자용 제작·설치 매뉴얼과 현재 런타임 규격 | 새로 만들거나 설치하기 전 |
| [pet-repair-20260717/](pet-repair-20260717/) · [pet-rebuild-20260718/](pet-rebuild-20260718/) | 복구·재제작 이력과 시각 QA | 특정 오류를 재현하거나 기준을 바꿀 때 |
| [MIA_GYEOM_PET_OPTIMIZATION_DECISION_2026-07-16.md](MIA_GYEOM_PET_OPTIMIZATION_DECISION_2026-07-16.md) · [HANDOFF_GYEOM_PET_2026-07-16.md](HANDOFF_GYEOM_PET_2026-07-16.md) | 의사결정·인수인계 기록 | 이전 작업의 이유를 확인할 때 |

## 🛠 앱 진단·패치

Codex 앱 자체에서 겪은 문제(파일 쓰기 거부·이미지 다운로드·압축 미리보기)를 **진단·복구**하는
도구와 기록입니다. 위험한 앱 바이너리 패치는 폐기하고, **순정 앱 유지 + 권한(ACL) 복구** 정공법을 씁니다.

**여기부터 보세요 → [docs/](docs/)** (샌드박스·앱 진단 섹션의 안내판)

| 자료 | 내용 |
|---|---|
| [docs/](docs/) | 샌드박스·앱 진단 **섹션 진입점** — 원인 설명, 도구 사용법, [4/4] 판정 방식 |
| [docs/…검증 완료 보고서 (Walkthrough).md](<docs/1.Codex 샌드박스 오류 및 미리보기 난제 검증 완료 보고서 (Walkthrough).md>) | 문제 원인·조치·검증 결과 **완료 보고서** |
| [codex-sandbox-check.ps1](codex-sandbox-check.ps1) | **자가진단 스크립트** — app.asar 무결성·gh 인증·폴더 권한·로그 에러 4단계 점검 (PS 5.1·pwsh 7 공용) |
| [`../fix-sandbox-acl.bat`](../fix-sandbox-acl.bat) | **권한 복구 배치** — `CodexSandboxUsers` 수정 권한·소유권 일괄 재지정(관리자 권한) |
| [HANDOFF_CLAUDE_CODE_CODEX_DOWNLOAD_FIX_2026-07-19.md](HANDOFF_CLAUDE_CODE_CODEX_DOWNLOAD_FIX_2026-07-19.md) | 이미지 다운로드 이슈의 분석 근거와 승인 경계(인수인계) |

> ⚠️ 이전의 `codex-image-download-fix-20260719/`(ASAR 패치) 방식은 스토어 서명 손상 위험으로 **삭제**됨.
> 로컬 파일 다운로드가 필요할 땐 미리보기 대신 실제 파일을 export 하는 것이 원칙입니다
> (루트 [AGENTS.md](../AGENTS.md)의 아티팩트 전달 수칙 참조).
