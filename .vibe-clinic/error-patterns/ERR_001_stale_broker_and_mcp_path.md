# ERR_001: 낡은 브로커/워커 선언 잔존 및 MCP 서버 등록 경로 불일치 결함

## 1. 결함 요약 (Failure Summary)
- **증상 1 (Warning)**: `vibe-clinic` 진단 `declaration-check`에서 `broker.json`이 status="RUNNING" (PID: 19000), `antigravity.json` / `claude.json`이 status="ready"로 선언되어 있으나 실제 OS 프로세스가 존재하지 않아(Dead PID, 2505분 경과) 선언과 실측 간 불일치 경고(Health 80%) 발생.
- **증상 2 (Error)**: Antigravity MCP 로딩 시 `vibe-clinic` MCP 경로가 `.../-antigravity-workspace/260709_vibe-clinic/...`로 잘못 등록되어 있어 `MODULE_NOT_FOUND` 에러 발생.

## 2. 근본 원인 (Root Cause)
1. 세션 종료 또는 시스템 재시작 후 `csc.py` 워커 및 브로커의 종료 훅(`release()`)이 미수행된 채 파일 상에 "RUNNING" 및 "ready" 선언이 잔존함.
2. 워크스페이스 디렉터리 구조 개편 시 Antigravity `mcp_config.json` 내의 절대 경로가 변경 전 디렉터리(`-antigravity-workspace`)를 참조하고 있었음.

## 3. 교정 조치 (Remediation)
1. `python csc.py broker stop`을 실행하여 브로커 선언을 정상 종료 상태로 정리.
2. `c3p-council-orchestrator/.agent-swarm/workers/` 내 비활성 워커(`antigravity.json`, `claude.json`)의 상태 메타데이터를 `"status": "stopped"`로 동기화.
3. `~/.gemini/antigravity/mcp_config.json`의 `vibe-clinic` 경로에서 redundant `-antigravity-workspace/`를 제거하여 정본 경로(`D:/D_Workspace_NB/-agentic-ai-workspace/260709_vibe-clinic/backend/mcp-server/index.js`)로 교정.
4. 루트 워크스페이스에 `.vibe-clinic/diagnostics/01_platform_gate.clinic.js`를 신설하여 `npm run check` 통합 게이트와 연동.

## 4. 검증 결과 (Verification)
- `c3p-council-orchestrator`: 5 passed, 0 warnings, 0 errors (Health 100% OK).
- 루트 워크스페이스: `01_platform_gate.clinic.js` 통과 (Health 100% OK).
- `npm run check`: exit 0 전수 통과.
