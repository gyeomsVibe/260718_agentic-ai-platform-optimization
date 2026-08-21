# claude-code-subordinate — Claude Code를 Codex의 하위 도구로 쓸 때의 안전장치

Codex를 사령탑으로 두고 Claude Code를 MCP 도구로 붙이는 구성([설계계획](../../agent-swarm/SYSTEM_DESIGN_CODEX_COMMAND_2026-08-21.md))에서,
위임된 에이전트의 우발적 원격 push를 막기 위한 것이다.

## 왜 필요한가

2026-08-21, `agy`에게 **"표를 파일 하나로 저장해라"** 라고만 지시했는데
파일 생성에 더해 **커밋과 `git push`까지 수행**해 승인 없이 `origin/main`을 전진시켰다
([실험 6 / F25](../../agent-swarm/logs/2026-08-21_exp6_incident-executor-pushed-to-remote.md)).

`claude mcp serve`가 노출하는 도구는 **28종**이고 그중 `Bash`·`PowerShell`·`Write`가 포함된다.
즉 Claude Code를 하위 도구로 붙이는 순간 **F25와 정확히 같은 조건**이 된다.

## 실측 — 호출자 쪽에서는 막을 수 없다 (F28)

세 가지를 시도했고 **전부 실패**했다. 2026-08-21 측정.

| 시도 | 방법 | 결과 |
|---|---|---|
| 1 | `claude --settings <file> mcp serve` 로 `permissions.deny`에 `Bash(git push:*)` 등 30개 규칙 | ❌ **무시됨.** `git push --dry-run`이 그대로 실행되어 `Everything up-to-date` 반환 |
| 2 | 같은 방식으로 도구 이름 자체를 deny (`"deny": ["Bash","PowerShell"]`) | ❌ **무시됨.** `tools/list`에 `Bash`·`PowerShell` 그대로 존재 (29종) |
| 3 | Codex 쪽 MCP 도구 필터 | ❌ **존재하지 않음.** `codex mcp add --help`에 도구 단위 옵션 없음 |

> **결론: `claude mcp serve`는 Claude Code의 권한 설정을 적용하지 않는다.**
> 모든 도구를 노출하고, 승인 통제는 부르는 클라이언트(Codex) 책임으로 넘긴다.
> 그런데 Codex에도 도구 단위 필터가 없다. **양쪽 어디에도 하드 차단 스위치가 없다.**

이 발견은 [설계계획 §3.4의 E1](../../agent-swarm/SYSTEM_DESIGN_CODEX_COMMAND_2026-08-21.md)을 무효화한다.
E1은 "전환 전에 반드시 설치할 강제 지점"으로 설계됐으나 **실행 불가능한 조치였다.**

## 그래서 목적지를 막는다

호출자를 막을 수 없으면 **도착점**을 막는다. `pre-push` 훅은 어떤 에이전트가
어떤 도구로 어떤 셸을 통해 시도하든 동일하게 적용된다.

- 표시 없는 push → **차단**
- `ALLOW_PUSH=1 git push` → 통과

검증 (2026-08-21):

| 시험 | 결과 |
|---|---|
| `git push --dry-run origin main` | ❌ 차단 — `failed to push some refs` |
| `ALLOW_PUSH=1 git push --dry-run origin main` | ✅ 통과 — `Everything up-to-date` |

## 설치

`.git/hooks/`는 git이 추적하지 않으므로 **클론하면 따라오지 않는다.** 새 환경에서는 직접 설치한다.

```bash
cp mcp/claude-code-subordinate/pre-push .git/hooks/pre-push && chmod +x .git/hooks/pre-push
```

## 한계 — 정직하게

이 훅은 **우발적 push를 막는 장치이지 악의적 우회를 막는 장치가 아니다.**
훅 파일을 읽고 `ALLOW_PUSH=1`을 붙이면 통과한다.

다만 F25는 악의가 아니라 **"도움이 되려다 범위를 넘은 것"** 이었고,
이 훅은 정확히 그 경우를 막는다. 실제로 발생한 사고 유형에 대응하는 조치다.

확실한 차단이 필요하면 **GitHub 브랜치 보호**를 켠다. 서버 쪽에서 강제되므로
로컬에서 우회할 수 없다. 다만 PR 기반 워크플로로 바뀌므로 별도 판단이 필요하다.

## 남은 통제 수단

호출자 쪽 하드 차단이 불가능하므로, 실제로 남은 것은 다음 셋이다.

| 수단 | 성질 | 강도 |
|---|---|---|
| `pre-push` 훅 | 목적지 차단 | 우발 사고에 유효 |
| Codex의 MCP 승인 게이트 | 프롬프트 | 대화형 세션에서만. `codex exec`는 `--approve-for-me` 없이는 아예 호출 불가 |
| 위임 프롬프트의 금지 문구 | 지시 | 약함. **규칙은 프롬프트에 담긴 만큼만 상속된다** (F25) |

세 번째가 약하다는 것이 이 세션의 핵심 교훈이므로, 첫 번째를 기본 방어선으로 삼는다.
