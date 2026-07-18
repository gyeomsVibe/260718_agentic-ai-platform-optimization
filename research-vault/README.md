# Research Vault — NotebookLM 답변 캐시

NotebookLM MCP 질의 결과를 저장하는 캐시 폴더. **일일 쿼터(무료 50쿼리) 절약이 목적이다.**

## 규칙
1. NotebookLM에 질의하기 **전에** 이 폴더를 먼저 검색한다 (Grep/Glob).
2. 새 답변을 받으면 아래 형식으로 저장한다.
3. 같은 질문을 다른 플랫폼(Claude Code/Codex/Antigravity)에서 반복하지 않는다.

## 파일 형식
- 파일명: `YYYY-MM-DD_<주제-슬러그>.md`
- 내용:

```markdown
# <질문>
- 노트북: <노트북 제목> (<notebook_id>)
- 일시: YYYY-MM-DD
- conversation_id: <후속 질문용>

## 답변
<answer 본문 — 인용 번호 유지>

## 인용 출처
[1] <cited_text 요약>
```
