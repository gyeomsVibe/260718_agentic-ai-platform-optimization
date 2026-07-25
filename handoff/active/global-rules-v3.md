---
handoff_id: global-rules-v3-20260721-001
status: STALE
workstream: global-rules-v3
objective: 세 도구의 공통 글로벌 룰 v3 배포 기준점과 다음 런타임 검증 행동을 전달한다
repository: gyeomsVibe/260718_agentic-ai-platform-optimization
branch: main
base_sha: b761320f93f4614b762e996daa9c2524f724f424
work_sha: a4560d2513647661be157a0e9ee4b6ffcaecf390
owned_paths:
  - shared/global-rules/
completed:
  - 영문 정본을 P0부터 P7까지의 우선순위 구조로 재구성함
  - 사용자 검토용 한글 해설본과 정본 중복 및 버전 일치 검사를 추가함
  - Antigravity와 Claude Code와 Codex의 전역 파일에 v3을 적용하고 SHA-256 일치를 확인함
remaining:
  - 새 작업에서 세 플랫폼이 v3을 발견하고 P1 언어 규칙과 SAFE-SYNC를 따르는지 관측함
verification:
  - sync-global-rules.ps1 Apply와 Check에서 세 플랫폼 RuntimeMatches True 확인
  - npm run check 통과
  - work_sha와 origin/main 일치 확인
decisions:
  - 공통 정본은 짧은 P0부터 P7 우선순위 계층으로 유지하고 상세 절차는 스킬과 경로 규칙으로 분리함
  - 한글 해설본은 사용자 검토용으로만 보관하고 실행 정본은 영어 Markdown으로 유지함
  - Markdown 규칙은 행동 지침이며 강제 조건은 각 도구의 권한과 Hook과 Sandbox로 분리함
risks:
  - 파일 일치는 런타임 행동 준수를 증명하지 않으므로 세 플랫폼의 새 작업에서 발견과 준수를 별도 검증해야 함
  - 다음 정본 변경 뒤 Apply를 생략하면 저장소 정본과 실제 전역 파일이 달라질 수 있음
approvals_required:
  - 다음 전역 규칙 Apply와 도구 설정 변경 전 사용자 승인
  - 계정과 권한과 플러그인과 MCP 변경 전 별도 사용자 승인
next_action: 세 플랫폼에서 새 작업을 하나씩 시작해 v3 발견과 한국어 응답 및 SAFE-SYNC 준수 사례를 기록한다
revalidate_when:
  - shared/global-rules/가 work_sha 이후 변경됨
  - origin/main 이력이 교체되거나 더 최신 global-rules-v3 handoff가 생성됨
---

# 글로벌 룰 v3 인계

이 레코드는 `a4560d2`에서 확정한 글로벌 룰 v3의 작업 범위와 세 플랫폼 배포 상태를
전달합니다. 수신자는 먼저 `npm run handoff:check`와
`npm run handoff:verify-remote`를 실행한 뒤, `next_action`의 교차 플랫폼 관측을
진행합니다.

## 완료 근거

- 영문 실행 정본은 [core.md](../../shared/global-rules/core.md)에 있고, 사용자용
  해설은 [GLOBAL_RULES.ko.md](../../shared/global-rules/GLOBAL_RULES.ko.md)에 있습니다.
- Build와 Apply와 Check는 모두 통과했습니다. 세 런타임 파일은 각 생성 배포본과
  SHA-256으로 일치합니다.
- 이전 전역 파일은 배포 시 생성된 사용자 홈의 시간별 백업에 보존했습니다.

## 남은 위험

이 인계는 파일 배포 정합성을 증명합니다. 새 작업에서 각 도구가 규칙을 실제로
발견하고 준수하는지는 아직 관측하지 않았습니다. 규칙을 수정하거나 도구 설정을
바꾸기 전에는 현재 승인 경계를 다시 확인해야 합니다.
