---
meta:
  contentType: Reference
report_id: repository-sync-handoff-20260720-001
status: CLOSED
repository: gyeomsVibe/260718_agentic-ai-platform-optimization
branch: main
work_sha: a80174695f452c8611ace876c49328827cfb90b4
handoff_sha: 0b05c4592d72a50f45591f11819fbde544d9d2cb
prepared_on: 2026-07-20
---

# 자동동기화와 GitHub handoff를 어떻게 이어받는가

이 보고서는 SAFE-SYNC 자동동기화 규칙과 GitHub handoff 파일럿의 구현 결과를 다음 에이전트에게 전달합니다. 수신자는 `work_sha`에서 구현을 확인하고 `handoff_sha`에서 활성 인계가 원격에 존재하는지 확인한 뒤 작업을 재개합니다.

## 보고서의 목적과 독자

이 문서는 Claude Code, Codex, Antigravity가 같은 저장소에서 작업을 이어받을 때 사용합니다. 목표는 다음 에이전트가 추가 질문 없이 기준점, 검증 명령, 남은 위험, 다음 행동을 찾게 하는 것입니다.

이 보고서는 다음 내용을 다룹니다:

- 사건 기반 SAFE-SYNC 자동동기화 규칙
- GitHub를 검증 가능한 handoff 지점으로 사용하는 방식
- 세 가지 handoff 구조 대안과 채택 결과
- 두 커밋 인계 프로토콜과 확정 SHA
- SELFREFINE 검증 로직과 실행 결과
- 다음 작업과 별도 승인 경계

## 확정된 저장소 상태

다음 값이 이번 인계의 기준점입니다:

| 항목 | 확정값 |
|---|---|
| 저장소 | `gyeomsVibe/260718_agentic-ai-platform-optimization` |
| 브랜치 | `main` |
| 작업 구현 커밋 | `a80174695f452c8611ace876c49328827cfb90b4` |
| 활성 handoff 커밋 | `0b05c4592d72a50f45591f11819fbde544d9d2cb` |
| 활성 인계 ID | `repository-sync-20260720-001` |
| 최종 검증 | `npm run check` 통과 |
| 인계 상태 | `HANDOFF_READY` |

`work_sha`는 구현 결과를 고정합니다. `handoff_sha`는 작업 기준점, 검증 증거, 남은 일, 승인 경계, 다음 행동을 원격에 고정합니다.

## 구현 커밋의 흐름

구현은 다음 순서로 정제됐습니다:

| 커밋 | 역할 |
|---|---|
| `ce109f0` | 원격 선행·분기 시 자동 rebase와 merge를 금지하고 SAFE-SYNC 흐름을 명확히 함 |
| `f66415f` | 자동동기화 정본, MIA 연구보고서, README 탐색 경로를 추가함 |
| `f801108` | GitHub handoff의 세 대안, 상태 기계, 레코드 계약, SELFREFINE 회로를 설계함 |
| `a801746` | 루트 `handoff/`, JSON Schema, 검증기, 템플릿, 도구 발견 규칙을 구현함 |
| `0b05c45` | 검증된 `work_sha`를 참조하는 활성 handoff 레코드를 원격에 게시함 |

각 커밋은 이전 결정을 보존합니다. 공개 이력을 재작성하거나 force push하지 않았습니다.

## SAFE-SYNC 자동동기화 규칙

SAFE-SYNC는 타이머가 아니라 실제 변경 사건으로 시작합니다. 변경이 없으면 검사, 커밋, 네트워크 요청을 실행하지 않습니다.

### 실행 조건

다음 사건 중 하나가 있어야 시작합니다:

- 에이전트가 소유한 파일 변경과 검증을 완료함
- 사용자가 현재 변경의 동기화를 명시적으로 요청함
- handoff 레코드를 원격에 확정해야 함

### 안전 게이트

동기화 주체는 다음 순서로 판정합니다:

1. 기준 HEAD, 브랜치, 작업 트리 상태, 소유 경로를 기록합니다.
2. 저장소별 단일 동기화 주체가 임대를 획득합니다.
3. 변경을 에이전트 소유, 사용자 소유, 출처 불명으로 분류합니다.
4. 비밀정보, 머신 설정, 캐시, 로그, 예상하지 못한 바이너리를 제외합니다.
5. 저장소가 선언한 검증 명령을 실행합니다.
6. `git fetch` 후 로컬과 원격 커밋 수를 판정합니다.
7. 원격 선행 또는 분기 상태면 자동 병합하지 않고 중단합니다.
8. 소유 경로만 명시적으로 스테이징합니다.
9. staged diff와 민감 경로를 다시 검사합니다.
10. 커밋 후 재-fetch해 원격 기준점이 바뀌지 않았는지 확인합니다.
11. 일반 push만 실행하고 로컬 HEAD와 원격 브랜치의 일치를 확인합니다.

`git add .`, `git add -A`, 자동 `pull --rebase`, 자동 merge, force push는 사용하지 않습니다. 소유권이나 민감성이 불명확하면 변경을 보존한 채 `BLOCKED`로 보고합니다.

### 원격 위상에 따른 행동

`git rev-list --left-right --count HEAD...origin/main` 결과를 다음처럼 판정합니다:

| 결과 | 상태 | 행동 |
|---|---|---|
| `0 0` | 동일 | 다음 게이트 진행 |
| `N 0` | 로컬 선행 | 커밋 출처와 승인 범위 확인 후 진행 |
| `0 N` | 원격 선행 | 중단·보고 |
| `N M` | 분기 | 중단·보고 |

## GitHub에 부여한 handoff 역할

GitHub는 백업 저장소와 작업 인계 지점을 함께 맡습니다. 로컬 설명만으로 완료를 주장하지 않고, 커밋 SHA와 원격 레코드로 같은 상태를 다시 확인하게 합니다.

### 세 가지 대안의 결정

세 대안을 다음처럼 정리했습니다:

| 대안 | 역할 | 결정 |
|---|---|---|
| A. 루트 `handoff/` | 로컬·GitHub 공통 기술 정본 | 채택 |
| B. `shared/repository-sync/handoff/` | 동기화 설계와 가까운 문서 위치 | 설계 자료 전용 |
| C. GitHub Issue·Pull Request 전용 | 담당자, 대화, 알림, 라벨 | 파일럿 이후 선택 계층 |

루트 `handoff/`는 네트워크가 없어도 에이전트가 발견할 수 있습니다. GitHub Issue와 Pull Request는 협업 상태를 보강하지만 기술적 정본을 대체하지 않습니다.

### handoff 확정 조건

다음 조건이 모두 참일 때 `HANDOFF_READY`입니다:

1. `work_sha`가 원격 브랜치에 존재합니다.
2. handoff 레코드가 별도 커밋으로 원격 브랜치에 존재합니다.
3. 레코드의 `owned_paths`가 작업 범위와 일치합니다.
4. 검증기와 저장소 전체 검사가 통과합니다.
5. 수신자가 `work_sha`, 위험, 승인 경계, `next_action`을 확인할 수 있습니다.

작업 커밋과 handoff 레코드를 분리하면 레코드가 검증된 작업 SHA를 정확히 참조할 수 있습니다. 이번 구현은 `a801746`을 먼저 push하고, 이를 참조하는 `0b05c45`를 두 번째로 push했습니다.

## SELFREFINE 품질 회로

SELFREFINE은 문장을 반복해서 늘리는 방식이 아닙니다. 최대 두 단계로 사실 오류와 재개 장애를 제거합니다.

### 1차 검사에서 사실과 안전성을 확인함

검증기는 다음 항목을 검사합니다:

- 필수 필드, 허용 상태, 문자열과 배열 자료형
- `base_sha`와 `work_sha`의 Git 조상 관계
- `work_sha`의 로컬과 원격 존재
- 저장소 상대 경로만 사용한 `owned_paths`
- `work_sha` 이후 커밋·staged·미커밋 변경까지 포함한 최신성
- `completed`와 `remaining`의 모순
- 절대 경로, 개인 홈 경로, 개인 키, 토큰 형태

초기 검증기는 `work_sha..HEAD`만 비교해 미커밋 변경을 놓쳤습니다. SELFREFINE에서 이를 발견해 `work_sha`와 작업 트리 전체를 비교하도록 수정했습니다.

### 2차 검사에서 수신자 재개 가능성을 확인함

검증기는 수신자가 다음 정보를 찾을 수 있는지 확인합니다:

- 저장소, 브랜치, 기준 SHA
- 소유 경로와 건드리면 안 되는 경로
- 실행한 검증과 성공 기준
- 가장 먼저 실행할 행동 한 가지
- 인계를 다시 검증할 사건
- 별도 승인이 필요한 작업

진실성, 안전성, 최신성 중 하나라도 실패하면 인계를 `HANDOFF_READY`로 유지하지 않습니다.

## 구현 파일과 역할

다음 파일이 운영 계약을 구성합니다:

| 파일 | 역할 |
|---|---|
| `handoff/README.md` | handoff 상태, 확정 지점, 실행 순서, 수신자 절차 |
| `handoff/active/repository-sync.md` | 현재 repository-sync 인계의 정본 |
| `handoff/schemas/handoff.schema.json` | 필수 필드와 허용 상태 계약 |
| `handoff/scripts/validate-handoff.mjs` | SELFREFINE 1차·2차 검사 구현 |
| `handoff/templates/HANDOFF.md` | 새 workstream 인계 작성 템플릿 |
| `shared/repository-sync/README.md` | SAFE-SYNC 자동동기화 정본 |
| `shared/repository-sync/MIA_GITHUB_HANDOFF_DESIGN_2026-07-20.md` | 대안 비교와 handoff 설계 근거 |
| `AGENTS.md`·`CLAUDE.md` | 작업 시작 시 활성 인계를 발견하는 규칙 |
| `package.json` | `handoff:check`와 전체 검사 연결 |

## 실행한 검증과 결과

다음 검증을 실제로 실행했습니다:

| 검증 | 결과 |
|---|---|
| `npm run handoff:check` | 활성 레코드 1개 `PASS` |
| `npm run check` | TypeScript, ESLint, handoff 검사 통과 |
| `git diff --check` | 통과 |
| `work_sha`의 `origin/main` 포함 관계 | 확인 |
| 원격 활성 레코드 존재 | 확인 |
| 로컬 HEAD와 `origin/main` 일치 | `0b05c45`로 일치 |
| 민감 경로와 절대 경로 검사 | 통과 |

Git 설정의 사용자 전역 ignore 파일은 샌드박스에서 읽지 못해 경고가 출력됐습니다. 저장소 검사와 커밋 결과에는 영향을 주지 않았습니다.

## 남은 위험과 승인 경계

다음 항목은 아직 완료하지 않았습니다:

- Claude Code, Codex, Antigravity에서 같은 활성 인계를 10회 재개하는 교차 플랫폼 파일럿
- Antigravity가 이 저장소의 프로젝트 규칙을 발견하는 방식의 실측
- GitHub Issue Form, Pull Request 템플릿, handoff 상태 라벨 생성
- 기존 `HANDOFF_*` 문서의 분류, 이동, 이름 변경
- GitHub Ruleset과 필수 상태 검사의 적용

Issue Form과 Pull Request 템플릿 생성, 기존 사용자 문서 이동, Ruleset 변경은 각각 별도 승인을 받습니다. 인계 레코드는 이 승인 범위를 확장하지 않습니다.

## 실패 시 복구 방법

인계 검증이 실패하면 다음 순서로 복구합니다:

1. `npm run handoff:check`의 첫 실패 항목을 확인합니다.
2. 레코드의 상태를 `BLOCKED`로 내립니다.
3. `owned_paths`와 `work_sha` 이후 변경을 비교합니다.
4. 원격 선행 또는 분기 상태면 병합하지 않고 사용자에게 보고합니다.
5. 사실 필드만 최소 수정한 뒤 검증을 다시 실행합니다.
6. 같은 실패가 세 번 반복되면 재시도를 중단하고 로그, 원인, 우회 방법을 보고합니다.

이미 push한 인계를 수정해야 하면 새 커밋을 사용합니다. force push나 공개 이력 재작성을 사용하지 않습니다.

## 다음 에이전트의 첫 행동

저장소 루트에서 다음 명령을 실행합니다:

```powershell
npm run handoff:check
```

검사가 통과하면 `handoff/active/repository-sync.md`의 `work_sha`와 `origin/main`의 포함 관계를 확인합니다. 그다음 교차 플랫폼 재개 검증 1회를 기록하며, GitHub Issue·Pull Request 계층은 10회 파일럿이 끝날 때까지 만들지 않습니다.

## 관련 정본과 공식 근거

- [SAFE-SYNC 자동동기화 정본](../../../../shared/repository-sync/README.md)
- [GitHub handoff 설계](../../../../shared/repository-sync/MIA_GITHUB_HANDOFF_DESIGN_2026-07-20.md)
- [Handoff 운영 정본](../../../README.md)
- [활성 repository-sync 인계](../../../active/repository-sync.md)
- [Git 상태의 스크립트용 형식](https://git-scm.com/docs/git-status)
- [Git 양방향 커밋 수 판정](https://git-scm.com/docs/git-rev-list)
- [Git push 안전 규칙](https://git-scm.com/docs/git-push)
- [GitHub 파일 영구 링크](https://docs.github.com/en/repositories/working-with-files/using-files/getting-permanent-links-to-files)
- [GitHub Issue·Pull Request 템플릿](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
