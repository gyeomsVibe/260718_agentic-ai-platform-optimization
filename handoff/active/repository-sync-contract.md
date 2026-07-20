---
handoff_id: repository-sync-contract-20260720-001
status: STALE
workstream: repository-sync-contract
objective: Phase 2A의 원격 증명과 소유 경로 계약을 다음 검증 단계로 전달한다
repository: gyeomsVibe/260718_agentic-ai-platform-optimization
branch: main
base_sha: 83e31223e151cd247241b013468a28b2a06cf7f9
work_sha: be0caee225d97885ba11ca7bea8043ddc8b2f913
owned_paths:
  - handoff/README.md
  - handoff/active/repository-sync.md
  - handoff/schemas/
  - handoff/scripts/
  - handoff/tests/
  - package.json
  - shared/repository-sync/MIA_GITHUB_HANDOFF_DESIGN_2026-07-20.md
completed:
  - 원격 활성 handoff blob과 work_sha를 분리 검증하는 명령을 추가함
  - base_sha와 work_sha 사이의 실제 변경이 owned_paths에 포함되는지 강제함
  - 원격 불일치와 소유권 누락을 포함한 통합 테스트 4개를 통과함
remaining:
  - 인계 2커밋 프로토콜을 사용자 명시 요구형으로 좁힌 정책 변경을 새 기준점에서 반영함
  - Claude Code와 Codex와 Antigravity에서 같은 인계를 10회 재개 검증함
  - 저장소별 읽기 전용 SAFE-SYNC 드라이런을 두 저장소에 적용함
verification:
  - npm run check 통과
  - npm run handoff:verify-remote은 이 레코드 push 뒤 실행해야 함
decisions:
  - 원격 검증은 로컬 계약 검사와 분리해 push 전후의 순환을 제거함
  - 이전 repository-sync 인계는 STALE로 보존하고 새 계약 workstream을 별도 생성함
risks:
  - 동기화 lease는 아직 협력 규칙이며 런타임 잠금으로 구현되지 않음
  - 교차 플랫폼 재개와 두 저장소 드라이런은 아직 관측되지 않음
approvals_required:
  - 두 대상 저장소의 실제 경로 확정 후 Phase 2B 읽기 전용 드라이런 승인
  - GitHub Issue Form과 Ruleset 변경 전 별도 승인
next_action: npm run handoff:check를 실행해 repository-sync-contract 기준점을 재검증한다
revalidate_when:
  - owned_paths가 work_sha 이후 변경됨
  - origin/main 이력이 교체되거나 활성 handoff blob이 원격과 달라짐
  - 더 최신 repository-sync-contract handoff_id가 생성됨
---

# Repository sync 계약 강화 인계 (오래된 기준점)

이 인계는 `be0caee`에서 구현한 Phase 2A 계약 강화의 이전 기준점입니다. 인계 발동 조건이
사용자 명시 요구형으로 변경되어 새 기준점이 발행되기 전까지 재개 기준으로 사용하지 않습니다.

## 완료 근거

- 원격 blob 검증은 로컬에만 수정된 활성 handoff를 거부합니다.
- 실제 작업 변경이 `owned_paths` 밖에 있으면 `HANDOFF_READY`를 거부합니다.
- `STALE`은 기존 파일을 삭제하지 않고 재발행이 필요함을 나타냅니다.

## 다음 행동

새 인계가 명시적으로 요청된 경우에만 `npm run handoff:check`를 실행합니다. 일반 작업은
SAFE-SYNC의 단일 작업 커밋·push로 마무리합니다.
