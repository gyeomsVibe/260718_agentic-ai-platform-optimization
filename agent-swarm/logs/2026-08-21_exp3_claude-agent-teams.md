# 실험 3 — Claude Code Agent Teams (Windows 대체 경로 검증)

- **일시**: 2026-08-21 00:40 ~ 00:45 KST
- **환경**: Claude Code v2.1.220 / Windows 11 네이티브 / 프로젝트 `.claude/settings.local.json`
- **판정**: ❌ **FAIL — 이 버전·이 OS에서 팀메이트 간 상호 메시징은 성립하지 않는다**
- **롤백**: 완료 (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`를 `"0"`으로 되돌림)

---

## 설계

`.claude/settings.local.json`의 `env`에 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"`을 넣고
(`.claude/`는 gitignore 대상이라 커밋되지 않음, 원본은 백업),
읽기 전용 과제를 가진 에이전트 2명(`alpha`, `beta`)을 띄워 **alpha가 beta에게 직접 메시지를 보낼 수 있는지** 측정했다.

## 수용 기준 대비 결과

| 기준 | 결과 |
|---|---|
| 팀메이트 간 메시지 왕복 | ❌ **실패** |
| 리드의 결론 통합 | ➖ 해당 없음 (왕복이 성립하지 않음) |
| 읽기 전용 제약 준수 | ✅ 양쪽 모두 준수 (파일 생성·수정·삭제 0건, git 쓰기 0건) |

## 발견 (Findings)

### F8. `SendMessage`는 존재하지만 `ListAgents`는 존재하지 않는다

두 에이전트가 독립적으로 같은 결론에 도달했다.

- `SendMessage` — deferred 목록에 존재, `ToolSearch`로 스키마 로드 후 호출 가능 ✅
- `ListAgents` — **부재.** `ToolSearch`로 `select:ListAgents` 직접 지정 시 아무것도 반환되지 않았고,
  키워드 검색은 `ListPlugins`·`ListSkills`·`notion-search-agents` 등 무관한 도구만 반환했다.

즉 **채널은 열려 있으나 로스터(roster) 조회 수단이 없다.**

### F9. 형제(sibling) 에이전트는 서로를 발견할 수 없다 — 구조적 한계

alpha가 beta에게 보낸 실제 반환값:

```json
{"success":false,
 "message":"No agent named 'beta' is reachable.\nCheck the spelling, or use the agent ID from a background agent's spawn result."}
```

`SendMessage`의 수신자(`to`)는 **팀메이트 이름 또는 스폰 결과에 담긴 `agentId`만** 받는다.
로스터 조회 도구가 없으므로, **스폰 결과를 보유한 주체만 상대를 지정할 수 있다.**
리드(메인 세션)는 자신이 띄운 에이전트의 ID를 갖고 있으므로 리드 → 에이전트 방향은 가능하지만,
에이전트끼리는 서로의 ID를 알 방법이 없다.

> **구조 판정**: 이 버전에서 성립하는 것은 **허브-앤-스포크(hub-and-spoke)** 이지 **팀 메시(team mesh)** 가 아니다.
> 공식 문서가 그림으로 대비시킨 "subagent는 리드에게만 보고 / teammate는 서로 대화" 중, 이 환경은 **여전히 전자**다.

### F10. 원인은 OS가 아니라 버전이다

`Agent` 도구의 입력 스키마에 `name` 파라미터가 없다. 공식 문서는
*"Claude launches a teammate when it calls the Agent tool with a `name`"* 라고 명시한다.
`name`을 넘길 수단이 없으므로 환경변수를 켜도 팀메이트가 생성되지 않고 일반 subagent로 뜬다.

- 크로스세션 메시징(§보고서 F 계열)은 **OS 제약** — Windows에서 원천 불가
- Agent Teams는 **버전 제약** — v2.1.220에 팀메이트 스폰 경로가 없음

전자는 우회 불가, 후자는 **업그레이드로 해소될 가능성이 있다.** 다만 이 PC는 v2.1.220이고 최신은 v2.1.237이므로
업그레이드 후 재검증이 필요하다 (보고서 §8 R5).

### F11. 부수 확인 — 백그라운드 에이전트 자체는 정상 작동한다

alpha 4회 호출 41초 / beta 2회 호출 20초로 각각 완료했고, 읽기 전용 제약을 모두 지켰으며,
지시한 보고 형식을 정확히 따랐다. **병렬 조사 수단으로서의 subagent는 Windows에서 문제없이 쓸 수 있다.**
잃은 것은 "에이전트끼리 토론하게 만드는" 능력뿐이다.

---

## 프로토콜 v2 반영 사항

| 조항 | 추가 내용 | 근거 |
|---|---|---|
| S1.3 (신설) | 이 환경에서 3층(Claude Code)은 **허브-앤-스포크**로 설계한다. 에이전트 간 토론이 필요한 과제는 리드가 순차 중계하거나, 단일 세션 내 순차 검토로 대체한다 | F9 |
| S8 (신설) | 도구 가용성은 **OS 제약과 버전 제약을 구분해 기록**한다. 전자는 우회 설계, 후자는 업그레이드 후 재검증 대상이다 | F10 |

## 다음 재검증 조건

Claude Code를 v2.1.237로 업그레이드한 뒤 `/list-agents` 인식 여부와 `Agent` 도구의 `name` 파라미터 유무를 다시 확인한다.
단, 크로스세션 메시징은 업그레이드로도 Windows에서 열리지 않는다.
