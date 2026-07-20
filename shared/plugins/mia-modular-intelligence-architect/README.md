# MIA · Modular Intelligence Architect

이 폴더는 MIA의 플러그인 패키지·배포 어댑터이자 버전 관리 대상이다.
공통 로직은 저장소의 [`skills/plan-review-execute/SKILL.md`](../../../skills/plan-review-execute/SKILL.md)에서만 수정한다.

`scripts/sync-mia-skills.ps1 -Mode Check`는 배포 상태를 확인한다.
`-Mode Apply -MigrateAntigravity`는 Skill 정본을 Codex·Claude·Antigravity 플러그인에
배포하고 기존 Antigravity 독립 전역 스킬을 제거한다. 이 전환 뒤 Antigravity는
플러그인의 `skills/plan-review-execute/SKILL.md`만 사용한다.

플러그인 내부의 `skills/plan-review-execute/SKILL.md`는 패키징용 배포본이다.
Codex와 Claude는 각각의 플랫폼 형식에 맞는 설치본을 사용하며, Claude에는 전체
공통 본문을 포함한 어댑터를 배포한다.
