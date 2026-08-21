# local-agent-runtime — 살아 있는 에이전트 세션

코덱스가 클로드 코드와 안티그래비티를 **대화 상대로** 쓰게 한다.
기존 브리지는 위임 1건마다 새 프로세스를 띄웠지만, 이 런타임은 프로세스를 살려두고
같은 세션에 턴을 이어붙인다. **맥락이 턴 사이에 보존된다.**

설계 배경: [Local Agent Runtime 구현 제안](../../agent-swarm/SYSTEM_DESIGN_CODEX_COMMAND_2026-08-21.md)

## 무엇이 달라지나

| | 기존 브리지 | 이 런타임 |
|---|---|---|
| 프로세스 | 호출마다 새로 띄움 | **유지** |
| 맥락 | 매번 초기화 | **이어짐** |
| 쓰는 느낌 | 심부름 시키기 | **대화하기** |

실측 (2026-08-21):

```
TURN1  "My favourite number is 42. Reply with exactly: OK"   → "OK"
TURN2  "What is my favourite number?"                        → "42"
CONTEXT_CARRIED: yes
```

클로드 코드와 안티그래비티 **양쪽 모두** 동일하게 확인했다.

## 도구 6종

| 도구 | 하는 일 |
|---|---|
| `agent_open` | 세션을 연다. `tool`은 `claude-code` 또는 `antigravity` |
| `agent_send` | 한 턴을 보내고 답이 끝날 때까지 기다린다 |
| `agent_read` | 원본 이벤트를 본다. 턴이 길어질 때 진행 확인용 |
| `agent_list` | 열린 세션 목록 |
| `agent_close` | 세션을 닫는다 |
| `runtime_health` | 런타임 상태와 실행 파일 탐지 결과 |

## 어떻게 되는가 — pexpect 없이

원 제안서는 대화형 CLI를 다루려면 `pexpect` 같은 TUI 자동화가 필요하다고 봤다.
**필요 없다.** 두 CLI 모두 제조사가 NDJSON 양방향 프로토콜을 공식 제공한다.
한 줄에 한 메시지를 넣으면 한 턴이 돌고, 결과가 한 줄로 나온다.

```
claude  --print --input-format stream-json --output-format stream-json --verbose
  입력  {"type":"user","message":{"role":"user","content":[{"type":"text","text":"..."}]}}
  출력  {"type":"system"|"assistant"|"result", ...}

agy  --input-format stream-json --output-format stream-json --sandbox -p ""
  입력  {"event":"user","message":{"content":"..."}}
  출력  {"event":"init"|"step_update"|"result", ...}
```

agy 쪽 스키마는 문서에 없어 오류 메시지를 단서로 역추적했다.
`event`가 빠지면 → `missing the "event" field`, `message`가 문자열이면 →
`cannot unmarshal string into ... streamInputUserMessage`, `content`가 없으면 →
`message has no content`. 세 단계를 거쳐 확정했다.

## 안전 기본값

오늘 사고에서 나온 교훈을 기본값으로 굳혔다.

| 항목 | 값 | 이유 |
|---|---|---|
| agy 샌드박스 | **켜짐** (`--sandbox`) | 실행자 무제한 실행 방지 |
| agy 자동승인 | **꺼짐** — `--dangerously-skip-permissions`를 붙이지 않는다 | 승인 없이 커밋·push한 사고의 직접 원인이었다 |
| `shell` 사용 | **안 함** | Windows에서 `shell:true`는 인자를 이스케이프 없이 이어붙여, 따옴표나 공백이 든 프롬프트를 깨뜨린다 |
| 자식 환경변수 | 그대로 상속 | 두 CLI 모두 자격증명 접근에 필요. 제한이 필요하면 여기부터 손본다 |
| 원격 보호 | 이 런타임 밖 — `pre-push` 훅 | 어떤 경로로 들어오든 동일 적용 ([상세](../claude-code-subordinate/README.md)) |

세션 상한 6개, 턴 대기 상한 180초, 30분 유휴 시 자동 종료.
환경변수 `LAR_MAX_SESSIONS`, `LAR_TURN_TIMEOUT_MS`, `LAR_IDLE_CLOSE_MS`로 조정한다.
실행 파일 경로는 `LAR_CLAUDE_BIN`, `LAR_AGY_BIN`으로 덮어쓸 수 있다.

## 설치

```bash
npm install --omit=optional --ignore-scripts
```

```bash
codex mcp add local-agent-runtime -- node "D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/mcp/local-agent-runtime/index.js"
```

## 쓰는 법

Codex 앱 채팅에서 말로 시키면 된다.

```
local-agent-runtime 으로 claude-code 세션을 열고,
이 저장소의 실험 로그를 읽게 한 뒤,
같은 세션에 이어서 "그중 가장 중요한 발견 3개만 골라라" 라고 물어봐라.
```

두 번째 질문에서 **다시 설명할 필요가 없다는 것**이 이 런타임의 요점이다.

무인 실행은 `codex exec --approve-for-me`를 쓴다. `-s`는 붙이지 않는다.

## 한계

- **세션은 이 런타임이 살아 있는 동안만 유지된다.** MCP 서버가 재시작되면 모든 세션이 사라진다. 영속이 필요하면 각 CLI의 자체 대화 재개 기능(`claude --resume`, `agy --conversation`)을 함께 써야 한다.
- **이미 열려 있는 IDE 창을 조종하지는 못한다.** 안티그래비티 IDE에는 `agentapi`라는 제어 표면이 있으나 주소가 에이전트 실행 컨텍스트 안에서만 노출되어 도달하지 못했다 ([경위](../../agent-swarm/USAGE_CODEX_COMMAND.md)).
- **턴 단위 동시성은 세션당 1개다.** 같은 세션에 `agent_send`를 겹쳐 부르면 순서가 보장되지 않는다. 병렬이 필요하면 세션을 나눈다.
