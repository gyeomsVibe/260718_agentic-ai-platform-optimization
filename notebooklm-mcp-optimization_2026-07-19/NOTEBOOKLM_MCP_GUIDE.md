# NotebookLM MCP 쉬운 사용설명서

> 처음 보는 사람도 따라 할 수 있게 쓴 안내서입니다.
> "MCP가 뭔지도 모르겠다" 상태에서 시작해도 괜찮습니다.

---

## 1. 이게 뭔가요? (비유로 이해하기)

**NotebookLM**은 구글이 만든 "내 자료 전용 사서(司書)"입니다.
PDF, 웹페이지, 유튜브 영상 같은 자료를 노트북(서재)에 넣어두면,
질문했을 때 **그 자료 안에서만** 근거를 찾아 답해 줍니다.
인터넷에 떠도는 아무 말을 가져오지 않아서 헛소리(환각)가 거의 없습니다.

**MCP(Model Context Protocol)** 는 AI 도구들끼리 연결하는 **표준 전화선**입니다.

이 둘을 합치면:

```
나: "Claude야, 내 NotebookLM 서재에서 ○○ 찾아봐줘"
      ↓ (MCP 전화선)
Claude Code → NotebookLM 사서에게 질문 → 근거 있는 답변 + 출처
```

즉, **Claude Code / Codex / Antigravity 안에서 나가지 않고**,
내 NotebookLM 자료에 질문하고 출처 달린 답을 받는 것. 이게 전부입니다.

## 2. 왜 쓰나요? (안 쓸 때와 비교)

| 상황 | MCP 없이 | MCP 있으면 |
|---|---|---|
| 자료 질문 | 브라우저 열기 → NotebookLM 접속 → 질문 → 답 복사 → 붙여넣기 | 채팅창에 한 문장 |
| 답변 근거 | AI가 기억에 의존 (틀릴 수 있음) | 내 자료에서 인용 [1][2] 표시 |
| 토큰 비용 | 문서 전체를 AI에게 먹임 (수만 토큰) | 요약된 답만 받음 (수천 토큰) |

## 3. 준비물

- Windows PC (이 가이드 기준. macOS/Linux도 가능)
- Google 계정 (NotebookLM 쓰는 계정)
- [uv](https://docs.astral.sh/uv/) 설치되어 있을 것 (파이썬 도구 설치 관리자)
  - 없다면 PowerShell에서: `winget install astral-sh.uv`
- Claude Code / Codex / Antigravity 중 쓰는 것 아무거나

## 4. 연결법 (딱 3단계)

### 1단계 — 설치

PowerShell(또는 터미널)을 열고:

```
uv tool install notebooklm-mcp-cli
```

설치가 끝나면 `nlm` 이라는 명령어가 생깁니다. 확인:

```
nlm --version
```

### 2단계 — 구글 로그인 (최초 1회)

```
nlm login
```

- 브라우저 창이 뜹니다 → **평소처럼 구글 로그인**하면 끝.
- 로그인 정보(쿠키)가 내 PC에만 저장되고, 이후 2~4주간 자동으로 쓰입니다.

> ⚠️ **이 PC 전용 주의사항**: Chrome이 "관리자 권한으로 실행" 설정이라
> 자동 실행이 안 됩니다. 아래 한 줄로 **Edge를 쓰도록** 바꿔두었습니다 (이미 적용됨):
> ```
> nlm config set auth.browser edge
> ```

### 3단계 — 내 AI 도구에 연결

쓰는 도구마다 한 줄씩:

```
nlm setup add claude-code     ← Claude Code
nlm setup add codex           ← Codex
nlm setup add antigravity     ← Antigravity
```

**연결 후 해당 앱을 재시작**하면 활성화됩니다. 끝!

정상 연결 확인:

```
nlm doctor
```

## 5. 사용법 (이렇게 말하면 됩니다)

연결이 끝나면, Claude Code(또는 Codex/Antigravity) 채팅창에 **그냥 한국어로** 부탁하세요:

- "내 NotebookLM 노트북 목록 보여줘"
- "'바이브 코딩 학습계획' 노트북에서 **초보자 추천 도구**가 뭔지 찾아줘"
- "이 URL을 ○○ 노트북에 자료로 추가해줘"
- "○○ 노트북 내용으로 팟캐스트(오디오 개요) 만들어줘"

답변에는 `[1] [2]` 같은 **인용 번호와 출처 원문**이 함께 옵니다.

터미널에서 직접 쓰고 싶다면 (선택사항):

```
nlm notebook list                          ← 노트북 목록
nlm notebook query <노트북ID> "질문"        ← 질문하기
```

## 6. 꼭 알아야 할 한도 (무료 기준)

| 항목 | 무료 한도 | 초과하면 |
|---|---|---|
| 하루 질문 수 | **50개** | 다음 날까지 대기 (또는 Pro 업그레이드) |
| 노트북당 자료 수 | 50개 | 자료 정리 필요 |
| 하루 오디오 생성 | 3개 | 다음 날까지 대기 |

**그래서 이 워크스페이스 규칙**: 같은 질문을 반복하지 않도록,
받은 답변은 `research-vault/` 폴더에 저장해 두고 **질문 전에 먼저 검색**합니다.
(에이전트가 자동으로 따르는 규칙 — `CLAUDE.md`/`AGENTS.md`에 적혀 있음)

## 7. 고장났을 때 (자주 겪는 문제 3가지)

### ① "인증이 만료됐다 / 로그인하라고 한다"
쿠키 수명(2~4주)이 다 된 것. **1분 해결**:
```
nlm login
```

### ② "브라우저가 안 뜬다 / WinError 740"
Chrome 관리자 권한 문제. Edge로 지정되어 있는지 확인:
```
nlm config set auth.browser edge
nlm login
```

### ③ "어느 날 갑자기 전부 안 된다"
구글이 NotebookLM을 개편했을 가능성. 순서대로:
1. `nlm login` 재실행
2. `uv tool upgrade notebooklm-mcp-cli` (단, 개편 직후라면 24~72시간 기다렸다 업그레이드)
3. 그래도 안 되면 예비 서버로 전환: `npx notebooklm-mcp@latest`

## 8. 알아두면 좋은 것

- **비공식 도구입니다**: 구글 공식 API가 아니라서 언젠가 깨질 수 있습니다.
  깨져도 위 7-③ 순서로 복구됩니다.
- **자동화 전용 구글 계정**을 따로 만들어 쓰면 더 안전합니다.
- 로컬 파일(내 PC의 코드·문서)은 NotebookLM을 거치지 말고 AI에게 직접 읽히는 게 낫습니다.
  NotebookLM은 **외부 자료 서재**로만 쓰는 게 적재적소입니다.

## 9. 용어 사전 (1분 컷)

| 용어 | 뜻 |
|---|---|
| MCP | AI 도구끼리 연결하는 표준 규격. "AI용 USB 단자"라고 생각하면 됨 |
| MCP 서버 | 그 단자에 꽂는 어댑터 프로그램. 여기선 `notebooklm-mcp` |
| `nlm` | 터미널에서 NotebookLM을 조작하는 명령어 (CLI) |
| 쿠키 | 로그인 상태를 기억하는 열쇠. 2~4주마다 갱신 필요 |
| 인용(Citation) | 답변 근거가 된 자료 원문 표시 `[1]` |
| 쿼터(Quota) | 하루 사용 한도. 무료는 질문 50개/일 |

---

## 더 깊이 알고 싶다면

- 왜 이 도구를 골랐는지, 어떤 위험이 있는지: [MIA_NOTEBOOKLM_MCP_OPTIMIZATION_2026-07-19.md](MIA_NOTEBOOKLM_MCP_OPTIMIZATION_2026-07-19.md)
- 도구 공식 저장소: [jacob-bd/notebooklm-mcp-cli](https://github.com/jacob-bd/notebooklm-mcp-cli)
- 예비 도구: [PleasePrompto/notebooklm-mcp](https://github.com/PleasePrompto/notebooklm-mcp)
