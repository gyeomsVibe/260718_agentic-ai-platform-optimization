# 260718_agentic-ai-platform-optimization

Claude Code / Codex / Antigravity 세 플랫폼의 최적화·유지관리 워크스페이스.
플랫폼별 작업은 `claude/`, `codex/`, `antigravity/` 폴더에서 관리한다.

## 저장소 동기화 원칙

- 이 워크스페이스에서 사용자가 요청한 저장소 변경을 완료하면, 검증 후 현재 GitHub
  원격 브랜치와 동기화 상태를 확인하고 필요한 커밋·푸시까지 수행한다.
- 전역 Skill 설치, 배포, 계정·권한·외부 서비스 변경은 저장소 동기화와 별개다. 해당
  범위는 영향과 복구 방법을 설명한 뒤 별도 승인을 받아야 한다.

## NotebookLM MCP 운영 수칙

이 워크스페이스에는 `notebooklm-mcp` MCP 서버(jacob-bd/notebooklm-mcp-cli, 쿠키+내부 API 방식)가
세 플랫폼 공용으로 연결되어 있다. MCP 관련 자료는 모두 `mcp/` 섹션에서 관리한다.
상세 설계: `mcp/notebooklm/MIA_NOTEBOOKLM_MCP_OPTIMIZATION_2026-07-19.md`

- **캐시 우선**: NotebookLM에 질의하기 전에 `mcp/notebooklm/research-vault/`를 먼저 검색하고,
  새 답변은 그 폴더의 `README.md` 형식으로 저장한다. (무료 쿼터 50쿼리/일)
- **적재적소**: 로컬 파일은 직접 읽는다. NotebookLM은 외부 문서 코퍼스 질의,
  웹 리서치 축적, 오디오/비디오 생성에만 사용한다.
- **인증 만료 시** (2~4주 주기): `nlm login` 재실행. 이 PC는 Chrome이 RUNASADMIN
  플래그라 실행 불가 → `auth.browser=edge` 설정 유지 (Edge로 로그인).
- **파손 시 복구 순서**: ① `nlm login` 재실행 → ② `uv tool upgrade notebooklm-mcp-cli`
  → ③ 예비 서버(PleasePrompto `npx notebooklm-mcp@latest`)로 전환.
- **업그레이드 주의**: NotebookLM UI/API 개편 뉴스 후 24~72시간 기다렸다가 업그레이드.

---

# Workspace artifact delivery

- Do not rely on the Codex image-preview download button for local files. The
  current Windows app does not reliably download local-path image sources.
- Keep the canonical artifact inside this workspace.
- When 윤겸스 asks to download or retain an artifact, export the actual file and
  a ZIP bundle to `C:\Users\Kimyoongyeom\Downloads\Codex-Exports` after the
  required filesystem approval.
- Report the absolute export path, file count, size, and verification result.
- A preview image is evidence for review, not the downloadable deliverable.
- Codex does not preview ZIP contents. Open the exported ZIP in Explorer or an
  archive app; do not present the Codex ZIP preview as a failed download.
- Make exported HTML artifacts standalone: copy their local assets into the
  export bundle and verify every relative asset path after copying.
