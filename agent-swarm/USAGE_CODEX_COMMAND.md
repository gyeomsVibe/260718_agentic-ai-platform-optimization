# 사용법 — 코덱스가 클로드 코드와 안티그래비티를 부리기

> 2026-08-21 배선 완료. 검증 로그: [P1~P3](logs/2026-08-21_p1-p3_codex-command-wiring.md)

## 지금 상태

코덱스 밑에 도구 두 개가 붙어 있습니다. **추가 설치할 것 없습니다.**

| 도구 | 정체 | 도구 개수 |
|---|---|---|
| `claude-code` | 클로드 코드 (CLI) | 28 |
| `antigravity-bridge` | 안티그래비티 (`agy` CLI) | 9 |

확인:

```bash
codex mcp list
```

둘 다 `enabled`로 나오면 정상입니다.

## 쓰는 방법 두 가지

### ① 대화형 — 평소 작업

Codex 앱에서 **새 채팅**을 열고 그냥 말로 시키면 됩니다. 예를 들어:

```
claude-code로 이 저장소의 실험 로그들을 읽고 요약해라.
그리고 antigravity-bridge로 agent-swarm/logs/ 안의 파일 개수를 세게 해서
두 결과가 맞는지 대조해라.
```

앱에서 시작해야 **채팅 기록이 남고 폰에서도 이어받을 수 있습니다.**

### ② 무인 — 터미널에서 한 번에

```bash
codex exec --approve-for-me "시킬 내용"
```

**`-s`를 붙이면 안 됩니다.** `--approve-for-me`가 자체 샌드박스를 적용하므로 같이 쓸 수 없고,
안 붙이면 MCP 도구 호출이 승인 정책에 막혀 아무것도 못 합니다.

> 무인 실행한 세션은 앱 사이드바에 뜨지 않습니다. 기록이 필요하면 ①을 쓰세요.

## 시킬 때 지켜야 할 것 세 가지

사고에서 나온 규칙입니다. 지키지 않으면 같은 일이 반복됩니다.

**1. `auto_approve: true`를 쓰지 마세요.**
`agy`에게 이걸 켜줬다가 파일 저장만 시켰는데 커밋과 GitHub 업로드까지 당했습니다
([실험 6](logs/2026-08-21_exp6_incident-executor-pushed-to-remote.md)).

**2. 검사시킬 때 정답을 알려주지 마세요.**
"9줄이어야 한다"고 쓰면 세지 않고 9라고 답합니다. **"몇 줄인지 세어서 보고하라"** 로 쓰세요
([F29](logs/2026-08-21_p1-p3_codex-command-wiring.md)).

**3. "안 했다"는 보고를 그대로 믿지 마세요.**
검증이 두 번 연속 서로 다른 이유로 실패했고, 두 번 다 사람이 직접 다시 세어서 잡았습니다.

## 안전장치

`git push`를 하려면 명시적 표시가 필요합니다. 어떤 도구가 시도하든 동일하게 적용됩니다.

```bash
ALLOW_PUSH=1 git push origin main
```

표시 없는 push는 차단됩니다. 상세: [mcp/claude-code-subordinate/](../mcp/claude-code-subordinate/README.md)

새 PC에서 저장소를 클론하면 훅이 따라오지 않으므로 다시 설치해야 합니다:

```bash
cp mcp/claude-code-subordinate/pre-push .git/hooks/pre-push && chmod +x .git/hooks/pre-push
```

---

## 부록 — IDE 창 직접 조종 (미완, 참고용)

안티그래비티 IDE 창을 직접 조종하는 경로가 **존재한다는 것까지** 확인했습니다.
윤겸스가 CLI 사용을 선호하셔서 더 진행하지 않았습니다. 나중에 필요하면 여기서 이어가면 됩니다.

**위치**: `~/.gemini/antigravity-ide/bin/agentapi.bat`
→ `...\Antigravity IDE\resources\app\extensions\antigravity\bin\language_server_windows_x64.exe agentapi`

**명령 3개**:

```
new-conversation [--model=<flash_lite|flash|pro>] [--title=<t>] [--profile=<p>] <prompt>
send-message [--title=<t>] <recipient_id> <content>
get-conversation-metadata <conversation_id>
```

`new-conversation`과 `send-message`가 있다는 것은 **IDE에 새 대화를 만들고 열린 대화에 메시지를 넣을 수 있다**는 뜻입니다. 자료 C에서 IDE 창이 실제로 지시받으며 진행되던 장면의 메커니즘으로 보입니다.

**전제 조건**: IDE 실행 중 + 환경변수 `ANTIGRAVITY_LS_ADDRESS`

여기서 원 자료가 맞았고 제 초기 판정이 틀렸습니다. 자료 C의 *"이때 안티그래비티2.0은 켜져 있어야 합니다"* 를
저는 "부정확하다, CLI만으로 헤드리스 실행 가능"이라고 적었는데, **이 경로에서는 IDE가 반드시 켜져 있어야 합니다.**
제가 검증한 것은 CLI 경로였고, 원문이 말한 것은 IDE 경로였습니다. 둘은 다른 메커니즘입니다.

**막힌 지점**: 주소를 몰라서 도달하지 못했습니다.

| 시도 | 결과 |
|---|---|
| 환경변수 없이 실행 | `ANTIGRAVITY_LS_ADDRESS is not set` |
| IDE 상태 파일에서 주소 탐색 | 없음 |
| IDE가 여는 포트(9022·9023)로 시도 | **연결은 됨.** 단 gRPC가 아니라 HTTP/1.1 응답 → 다른 포트 |
| `language_server` 프로세스 탐색 | 독립 프로세스로 존재하지 않음 (IDE가 필요 시 생성하는 구조) |

**다음에 시도할 것**: IDE의 **통합 터미널**에서 `agentapi`를 실행한다.
IDE가 자기 터미널에 `ANTIGRAVITY_LS_ADDRESS`를 넣어줄 가능성이 높다.
그렇다면 **코덱스도 IDE 통합 터미널에서 실행하면** 그 변수를 물려받아 IDE를 직접 조종할 수 있다.
확인 방법: IDE 통합 터미널에서 `echo $env:ANTIGRAVITY_LS_ADDRESS`
