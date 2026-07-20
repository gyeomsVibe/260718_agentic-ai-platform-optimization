# Claude Code 작업·관리 섹션

> **Claude Code**는 Anthropic이 만든 터미널 기반 AI 코딩 에이전트입니다. 이 폴더는
> Claude Code를 가볍고 안정적으로 쓰기 위한 **환경설정 정리 기록**을 모아 둡니다.

## 먼저 알아둘 개념 — 확장은 3층위

Claude Code의 "확장"(기능 추가)은 세 층위로 나뉩니다. 이 구분을 알아야 **무엇을 어디서
끄고 켜는지** 헷갈리지 않습니다.

1. **로컬 플러그인** — 내 PC에 설치한 스킬·명령 묶음 (`claude plugin` 으로 제어)
2. **로컬 MCP 서버** — 내 설정에 등록한 외부 도구 (`claude mcp` 로 제어)
3. **계정 커넥터 번들** — claude.ai 계정에 붙어 로그인 시 딸려오는 업무용 묶음 (**웹에서만** 제거)

> 핵심: 1·2는 내 PC에서 끄지만, 3은 claude.ai 웹 설정에서만 지울 수 있습니다.

## 문서

| 문서 | 내용 |
|---|---|
| [environment-notebook.md](environment-notebook.md) | 노트북(MSI GL75) 기록 — 플러그인 활성/비활성 목록, **안 쓰는 계정 커넥터 번들 15종 삭제 가이드**(웹 절차 포함) |
| [environment-desktop.md](environment-desktop.md) | 데스크톱(i7-6700K) 기록 — 플러그인 정리 내역, 자동 실행 권한 설정 |

> 노트북과 데스크톱은 다른 PC입니다. 한쪽 설정을 다른 쪽에 그대로 적용하지 마세요.

## 관련

- 세 도구 공용 규칙·자동화: [`../shared/`](../shared/)
- NotebookLM MCP 연결: [`../mcp/notebooklm/`](../mcp/notebooklm/)
