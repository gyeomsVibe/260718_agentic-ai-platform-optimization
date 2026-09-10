# [기획/실행] 전체 로컬 워크스페이스 경로·이름 최적화 변경 및 전수 최신성 동기화

로컬 워크스페이스 경로 및 이름이 `D:\D_Workspace_NB\-google-workspace`에서 `D:\D_Workspace_NB\-agentic-ai-workspace`로 변경되었습니다.
이에 따라 로컬 워크스페이스 내 전 프로젝트 문서, 설정 파일, 스크립트, MCP 전역 설정, `.git` 레포지토리 연동 상태를 전수 분석하여 최신 경로/이름으로 일괄 치환 및 동기화를 진행합니다.

---

## User Review Required

> [!IMPORTANT]
> - 전역 Antigravity/Gemini CLI 설정 (`C:\Users\Kimyoongyeom\.gemini\config\mcp_config.json` 및 `projects/*.json`) 내 구 경로 참조가 존재하므로 최신 경로(`-agentic-ai-workspace`)로 수정합니다.
> - 로컬 워크스페이스 하위 29개 프로젝트 내 `-google-workspace` 문자열 참조(설명서, 셸 스크립트, JSON 매니페스트, 핸드오프 문서 등)를 일괄 최신화합니다.
> - Git Repository 원격(GitHub `https://github.com/gyeomsVibe`)과 로컬 레포지토리 동기화 상태를 점검하고, SAFE-SYNC 게이트 준수 하에 동기화를 완료합니다.

---

## Open Questions

> [!NOTE]
> 특별히 명시할 추가 질문은 없으며, 모든 경로는 안전하게 대치(Replacement) 및 검증을 거쳐 동기화됩니다.

---

## Proposed Changes

### 1. 전역 설정 (Global Configuration)

#### [MODIFY] [mcp_config.json](file:///C:/Users/Kimyoongyeom/.gemini/config/mcp_config.json)
- MCP 서버 등록 경로 중 `-google-workspace`를 `-agentic-ai-workspace`로 변경.

#### [MODIFY] [Global Projects JSONs](file:///C:/Users/Kimyoongyeom/.gemini/config/projects/)
- `projects/*.json` 내 `folderUri`의 `-google-workspace`를 `-agentic-ai-workspace`로 변경.

---

### 2. 로컬 워크스페이스 문서 및 스크립트 (Local Workspace Files)

#### [MODIFY] 워크스페이스 공통 및 프로젝트 내부 텍스트 파일
- `d:\D_Workspace_NB\-agentic-ai-workspace` 하위의 모든 텍스트 파일(README, WORKSPACE_MAP, HANDOFF, PS1 스크립트, JSON 등) 내 `-google-workspace`를 `-agentic-ai-workspace`로 일괄 업데이트.

---

### 3. Git 및 GitHub 동기화 (Git Repositories & GitHub Sync)

#### [VERIFY & SYNC] 로컬 Git 저장소 및 GitHub `gyeomsVibe`
- 각 로컬 레포지토리의 `git status` 및 `git remote -v` 상태 점검.
- 최신 변경 사항에 대해 SAFE-SYNC 게이트 검증 후 커밋 및 원격 동기화.

---

## Verification Plan

### Automated Verification
- 스크립트를 통한 전수 스캔: `rg -i -e "-google-workspace" "d:\D_Workspace_NB\-agentic-ai-workspace"` 실행 시 잔재 0건 확인.
- `rg -i -e "-google-workspace" "C:\Users\Kimyoongyeom\.gemini\config"` 실행 시 잔재 0건 확인.

### Manual Verification
- IDE 프로젝트 목록 및 MCP 서버 정상 로딩 확인.
- Git remote 상태 및 커밋 이력 정상 확인.
