# 유료 토큰 0 호출의 무승인 실행과 토큰예산 절약 모드 (v5.28.0 근거)

> 작성: Claude(사용자 위임으로 Codex 권한 대행), 2026-09-28. 사용자 지시를 규칙으로 옮기면서 근거를 조사하고, 보안·예산상 위험한 경우를 가려낸 기록입니다.
> 표기: **사실**(출처에서 확인), **추론**(사실에서 끌어낸 판단), **미측정**(아직 재 보지 않음).

## 1. 무엇이 문제였나 (초보자용)

AI 도구가 외부 도구(MCP 서버, 셸 명령 등)를 부를 때마다 "이거 실행해도 될까요?"라고 묻는 창을 **승인 창(approval prompt)**이라고 합니다.
안전해 보이지만 두 가지 문제가 있습니다.

1. **병목·실패**: 사람이 자리에 없으면 도구가 멈춥니다. 사람이 볼 수 없는 비대화형 실행(`codex exec`)에서는 아예 자동 거부됩니다.
   - 사실(이 PC, 2026-09-28): `codex exec`로 olla 도구를 부르자 `MCP tool call requires approval, but approval policy is never`로 실패했습니다(13,297토큰, 32초 낭비). 설정을 고친 뒤 같은 호출은 `[올라마] OK`로 성공했습니다(13,269토큰, 31초).
   - 사실: 다른 저장소에서도 같은 일이 보고됐습니다. 거부가 "서버가 죽은 것"과 구별되지 않아 도구 증거 없이 작업이 진행됐고, 서버별 `default_tools_approval_mode = "approve"`로 해결했습니다. `--dangerously-bypass-approvals-and-sandbox`는 금지했습니다. ([LeonJoeeee/devstandard#358](https://github.com/LeonJoeeee/devstandard/issues/358))
2. **승인 피로(approval fatigue)**: 창이 많을수록 사람은 읽지 않고 누릅니다.
   - 사실: Anthropic 원격 측정에서 사용자는 승인 창의 약 93%를 승인합니다. ([Anthropic, Claude Code auto mode](https://anthropic.com/engineering/claude-code-auto-mode))
   - 사실: 40,000회 이상 게임 실행·409,000건 판단을 분석한 실험에서 사람은 악성 명령의 약 1/3을 승인했습니다. ([The Register, 2026-08-06](https://www.theregister.com/ai-and-ml/2026/08/06/humans-in-the-loop-miss-a-third-of-dangerous-ai-coding-agent-requests/5284236))
   - 사실: 공격자가 일부러 승인 창을 반복시켜 위험한 명령을 섞는 "승인 피로 악용" 패턴이 보고됐습니다. ([WorkOS](https://workos.com/blog/approval-fatigue-agent-governance))

결론(추론): **사람의 판단이 결과를 바꾸는 곳만 묻고, 나머지는 규칙 안에서 자동으로 돌려야** 승인 창이 오히려 안전해집니다.

## 2. 어떤 호출을 무승인으로 할까 — 판별 기준

사용자 지시는 "토큰이 0인 모든 호출은 승인 없이"입니다. 그대로 적용하면 위험한 구멍이 있습니다.

- 반례(레드팀): `rm -rf`, `git push --force`, 비밀값 파일 읽기는 **유료 토큰을 0개** 씁니다. "토큰 0"만으로는 안전하지 않습니다.

그래서 규칙은 이렇게 좁혔습니다.

| 구분 | 무승인 | 이유 |
|---|---|---|
| 로컬 모델 olla 도구(`local_read_map`·`local_draft`·`local_search`) | 예 | 로컬 계산, 외부 전송 없음, 파일을 바꾸지 않음 |
| 읽기·검색·테스트·빌드 | 예 | 되돌릴 필요가 없거나 작업 폴더 안에서만 바뀜 |
| 삭제, push·배포·게시, 결제, 계정·자격증명·권한·시스템 설정 | **아니오** | 전역 규칙의 "사람 확인 목록". 토큰과 무관하게 되돌리기 어렵거나 외부에 영향 |
| 비밀값(.env·키·토큰·쿠키) 읽기 | **아니오** | 전역 규칙이 금지 |
| 거부 규칙(deny)·샌드박스 | 그대로 | 무승인은 "묻지 않음"이지 "막힌 것을 풂"이 아님 |

그리고 무승인은 **각 도구의 허용 규칙(allow)**으로 설정합니다. 승인 전체를 끄는 옵션(`--dangerously-bypass-approvals-and-sandbox`, `--dangerously-skip-permissions`)은 쓰지 않습니다.

## 3. 세 도구에 실제로 넣은 설정 (2026-09-28)

| 도구 | 파일 | 설정 | 확인 |
|---|---|---|---|
| Codex | `~/.codex/config.toml` | `[mcp_servers.olla]` 아래 `default_tools_approval_mode = "approve"` | 실호출 성공(`mcp: olla/local_draft (completed)`) |
| Claude Code | `~/.claude/settings.json` | `permissions.allow`에 `mcp__olla__local_read_map`·`local_draft`·`local_search` (이미 있었음) | 이 세션에서 실호출 성공 |
| Antigravity | `~/.gemini/antigravity-cli/settings.json`의 `permissions.allow`, `~/.gemini/config/config.json`의 `globalPermissionGrants.allow` | `mcp(olla/*)` | 미확인: Antigravity가 한도(LIMITED) 상태 |

- Codex 값의 뜻(사실): `approval_mode = "approve"`는 "미리 승인됨, 묻지 않음"입니다. ([openai/codex#20289](https://github.com/openai/codex/issues/20289), [Codex MCP 문서](https://learn.chatgpt.com/docs/extend/mcp?surface=cli))
- Antigravity 문법(사실): `mcp(server/*)`는 해당 서버의 모든 도구를 허용합니다. 설정하지 않은 MCP 도구는 기본이 Ask입니다. ([Antigravity MCP 문서](https://antigravity.google/docs/mcp/))
- 백업: 바꾸기 전 파일은 `260916_agentic-ai-env-diet/.work/backup_20260928/`에 있습니다.

## 4. 토큰예산 절약 모드 — 올라마를 항상 먼저

사실(논문): 싼 모델부터 부르고 품질 검사를 통과하지 못할 때만 비싼 모델로 넘기는 **연쇄 호출(cascade)**은 비용을 크게 줄입니다.
FrugalGPT는 최대 98%, RouteLLM은 GPT-4 품질의 95%에서 85% 절감을 보고했습니다. 구조화 추출·분류·요약처럼 작은 모델이 잘하는 일에서는 품질 손실이 거의 없습니다. ([라우팅·연쇄 호출 조사 논문](https://arxiv.org/abs/2603.04445))

규칙으로 옮긴 모양:

1. 기계적 단계(파일 지도, 요약, 추출, 초안, 커밋 메시지, 분류)는 **로컬 모델 먼저**.
2. 유료 모델은 **판단·설계·최종 인수**만.
3. 판정은 **어떤 모델이 했는지가 아니라 최종 결과물의 관문**으로. 로컬 결과가 관문을 못 넘으면 같은 원인 2회 뒤 직접 하거나 유료 모델로 **한 번만** 넘기고 기록합니다.
4. 검증 비용이 더 싸면 모델 없이 결정적 추출(정규식·파서)이 먼저입니다.

주의(추론): 연쇄 호출의 절감은 **품질 검사기가 믿을 만할 때만** 성립합니다. 여기서는 그 검사기가 각 작업의 고정 인수 명령(테스트·원문 대조)입니다.
미측정: 이 저장소에서 절약 모드가 실제로 유료 토큰을 얼마나 줄이는지는 아직 통제 비교로 재지 않았습니다. 전역 규칙에 따라 "미측정(UNMEASURED)"으로 둡니다.

## 5. 남은 위험

- olla `local_read_map`·`local_draft`는 경로만 주면 어떤 파일이든 읽을 수 있습니다. 결과는 로컬에만 머물지만, 비밀값 파일 경로를 넘기지 않는 것은 부르는 쪽 규칙("비밀값을 읽지 않는다")에 의존합니다.
- Antigravity 허용 규칙이 실제로 적용되는지는 한도가 풀린 뒤 실호출로 확인해야 합니다.
- Claude auto mode도 위험 행동의 17%를 놓칩니다(사실, Anthropic). 무승인 범위를 넓힐수록 거부 규칙과 샌드박스가 마지막 방어선입니다.
