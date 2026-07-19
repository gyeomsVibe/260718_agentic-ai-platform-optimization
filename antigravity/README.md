# Antigravity 작업·관리 섹션

> **Antigravity**는 구글이 만든 IDE 통합형 AI 코딩 에이전트입니다. 이 폴더는
> Antigravity를 **가볍게 유지**하기 위한 환경설정 기록과 IDE 확장 정리(다이어트) 기록을
> 모아 둡니다.

## 왜 "다이어트(슬림화)"가 필요한가

IDE에 확장 프로그램이 많으면, 안 써도 백그라운드에서 CPU·메모리를 잡아먹어 전체가 느려집니다.
특히 Java(JVM), C++/Rust 인덱서 같은 언어 서버는 무겁습니다. 그래서 **안 쓰는 확장을 걷어내
에이전트 핵심 동작만 남기는 것**이 이 섹션의 핵심입니다.

## 문서

| 문서 | 내용 |
|---|---|
| [environment-notebook.md](environment-notebook.md) | 노트북 기록 — `.agents/` 설정 구조, MCP 서버 등록, 죽은 참조 정리 이력 |
| [environment-desktop.md](environment-desktop.md) | 데스크톱 기록 — 확장 **22개 슬림화 결과**, 파이썬 에이전트 스택 |
| [ide-slimming-plan.md](ide-slimming-plan.md) | IDE 확장 슬림화 **계획** (노트북) — 삭제 대상과 사유 목록 |
| [ide-slimming-result.md](ide-slimming-result.md) | IDE 확장 슬림화 **결과** 기록 |

> ⚠️ `.agents/` 설정 파일은 머신 고유 경로·호스트명을 담고 있어 저장소에 커밋하지 않습니다.
> 이 문서들은 구조와 정리 원칙만 기록합니다.

## 관련

- 세 도구 공용 규칙·플러그인: [`../shared/`](../shared/)
- NotebookLM MCP 연결: [`../mcp/notebooklm/`](../mcp/notebooklm/)
