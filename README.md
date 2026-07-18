# 260718_agentic-ai-platform-optimization

Claude Code / Codex / Antigravity 세 에이전틱 AI 플랫폼의 최적화·유지관리 워크스페이스.

## 구조

- `claude/` — Claude Code 작업·관리 섹션 (노트북·데스크톱 환경설정 기록)
- `codex/` — Codex 작업·관리 섹션 (환경설정 기록 + 샌드박스 트러블슈팅)
- `antigravity/` — Antigravity 작업·관리 섹션 (환경설정 기록 + IDE 슬림화)
- `shared/` — 3개 플랫폼 공용 정본 (global-rules v2.0.1, MIA 플러그인, 스킬)
- `notebooklm-mcp-optimization_2026-07-19/` — NotebookLM MCP 연결 워크스페이스 (설계·실행 기록)
- `research-vault/` — NotebookLM 질의 답변 캐시 (쿼터 절약용)
- `CLAUDE.md` / `AGENTS.md` — 에이전트 운영 수칙 (NotebookLM MCP 운영 규칙 포함)

> 플랫폼 환경 기록은 `260713_pc-optimization` 워크스페이스에서 2026-07-19에 이관해 왔다.
> 노트북과 데스크톱은 별개 환경이므로 문서를 `-notebook` / `-desktop`으로 구분한다.

## NotebookLM MCP

세 플랫폼 공용으로 `notebooklm-mcp`(jacob-bd/notebooklm-mcp-cli) 서버가 연결되어 있다.
설계 근거와 복구 절차는 `notebooklm-mcp-optimization_2026-07-19/MIA_NOTEBOOKLM_MCP_OPTIMIZATION_2026-07-19.md` 참조.
