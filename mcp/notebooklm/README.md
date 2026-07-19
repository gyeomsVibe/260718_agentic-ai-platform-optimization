# NotebookLM MCP

> 내 구글 **NotebookLM**(자료 전용 AI 사서)을 Claude Code · Codex · Antigravity에서
> 직접 질문할 수 있게 연결한 MCP입니다. 상태: **연결 완료·검증됨** (2026-07-19).

## 한 줄 요약

브라우저를 열지 않고, AI 채팅창에서 "내 NotebookLM 서재에서 ○○ 찾아줘"라고 하면
**출처가 달린 답**을 받아옵니다. 내가 넣은 자료 안에서만 답하므로 헛소리(환각)가 적습니다.

## 무엇부터 볼까

| 문서 | 용도 | 대상 |
|---|---|---|
| [NOTEBOOKLM_MCP_GUIDE.md](NOTEBOOKLM_MCP_GUIDE.md) | **설치·연결·사용법·고장대처**를 담은 사용설명서 | MCP를 처음 쓰는 사람 — 여기부터 |
| [MIA_NOTEBOOKLM_MCP_OPTIMIZATION_2026-07-19.md](MIA_NOTEBOOKLM_MCP_OPTIMIZATION_2026-07-19.md) | 왜 이 도구를 골랐는지, 위험·복구 절차를 담은 설계 근거 | 판단 배경·유지보수를 알고 싶을 때 |
| [research-vault/](research-vault/) | 받은 답변을 저장해 두는 **캐시 폴더** (쿼터 절약) | 자동으로 채워짐 — 규칙은 폴더 README |

## 핵심만 (자세한 건 위 가이드)

- **연결 방식**: `notebooklm-mcp-cli`(쿠키+내부 API 방식)를 세 플랫폼에 공용 등록.
- **한도**: 무료 티어는 하루 질문 50개. 그래서 받은 답은 `research-vault/`에 캐싱해
  같은 질문을 반복하지 않습니다.
- **인증 만료**: 쿠키는 2~4주마다 만료 → `nlm login` 재실행(1분)으로 복구. 이 PC는
  Chrome이 관리자 강제 실행이라 **Edge로 로그인**(`nlm config set auth.browser edge`)합니다.
- **고장 시 복구**: ① `nlm login` → ② `uv tool upgrade notebooklm-mcp-cli` →
  ③ 예비 서버(`npx notebooklm-mcp@latest`)로 전환.
