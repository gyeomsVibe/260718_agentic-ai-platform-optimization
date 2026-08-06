# Claude Code 플러그인 설치·관리 기록 (노트북)

> **플러그인(Plugin)이 뭔가요?** Claude Code에 기능을 더하는 **스킬·명령 묶음**입니다.
> 마켓플레이스(플러그인 상점)에서 설치하며, 설치하면 관련 작업 때 Claude가 알아서 꺼내 씁니다.
> 이 문서는 **이 노트북의 Claude Code에 실제로 설치된 플러그인**의 정본 기록입니다.
> (플러그인 3층위 개념은 [README.md](README.md) 참조 · 노트북과 데스크톱은 별개 PC)

## 1. 현재 설치된 플러그인 (user scope, ✔ enabled)

> ⛔ **2026-08-04 실측: 아래 표의 두 플러그인이 이 노트북에 없습니다.** 기록이 현재 상태와
> 다릅니다. 표는 2026-07-23 시점 기록으로 보존하되, **현재 상태의 근거로 쓰지 마세요.**
>
> 확인한 근거 3가지 (기기: `DESKTOP-73UOPO2` / `GL75 9SDK` = 이 노트북)
> 1. `~/.claude/plugins/` 에 `data/pdf-viewer-inline` 뿐 — `superpowers`·`frontend-design` 디렉터리 없음
> 2. `~/.claude/settings.json` 에 `enabledPlugins` 키 자체가 없음
> 3. 세션 런타임의 사용 가능 스킬 목록에 `superpowers:*` 와 `frontend-design` 미등장
>    (`anthropic-skills:*`, `pdf-viewer:*` 는 등장)
>
> **영향**: 이 두 플러그인의 스킬을 참조하던 설정은 전부 미해소 상태입니다. 실제로
> `.agents/agents/` 서브에이전트 12개가 `superpowers:writing-plans`,
> `document-skills:frontend-design` 등을 참조했으나 하나도 발견되지 않아,
> [`agents/README.md`](agents/README.md) 정제 시 해당 참조를 모두 제거했습니다.
>
> **소실 경위 조사 완료 (2026-08-06)** — 아래 §6 참조. 요약하면 **플러그인 서브시스템
> 전체가 2026-08-02에 초기화**됐습니다. 행위자는 특정하지 못했습니다.

| 플러그인 | 버전 | 마켓플레이스 | 구성 | 상시 토큰 | 역할 |
|---|---|---|---|---|---|
| ~~**superpowers**~~ | 6.1.1 | `superpowers-dev` (obra/superpowers) | 스킬 14개 + SessionStart 훅 | ~715 tok | 계획·TDD·병렬 에이전트·코드리뷰·디버깅 등 핵심 워크플로우 |
| ~~**frontend-design**~~ | (official) | `claude-plugins-official` | 스킬 1개 | ~78 tok | UI "AI 슬롭" 제거, 사람이 만든 듯한 독창적 디자인 |

> 무거운 스킬(subagent, writing-skills 등)은 **호출 시에만** 로드되어 평소 부담이 적습니다.
> 플러그인 스킬은 **세션 시작 시 로드** → 설치·변경 후 **Claude Code 재시작**해야 반영됩니다.

## 2. 등록된 마켓플레이스

| 마켓 | 출처 |
|---|---|
| `claude-plugins-official` | git · anthropics/claude-plugins-official |
| `anthropic-agent-skills` | github · anthropics/skills |
| `superpowers-dev` | github · obra/superpowers |

## 3. 설치 배경 (2026-07-23, 영상 근거)

"유명한 Claude Code 플러그인" 소개 영상(6종)을 전수분석하고 **필요한 것만 선별 설치**했습니다.
선정·기각의 상세 근거와 재평가 기록은 [`../skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md`](../skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md)의 "재평가(2026-07-23)" 절에 있습니다.

**설치 안 한 것과 이유 (중복·리스크 회피):**
- **Code Review / Security Review** → Claude Code **내장 `/code-review`·`/security-review`** + Superpowers가 커버 → 재설치 불필요
- **Claude Memo** → 기존 `~/.claude` 메모리 + CLAUDE.md 체계와 중복
- **Stack (gstack)** → 자동 배포·23스킬 대형팩 + Store 무결성 충돌 → **No-Go** (판단 근거는 skills 문서 참조)

## 4. 관리 명령 (설치·확인·롤백)

```bash
claude plugin list                                  # 설치 목록
claude plugin marketplace add <owner/repo>          # 마켓 등록
claude plugin install <plugin>@<marketplace>        # 설치
claude plugin details <plugin>                      # 구성·토큰 비용 확인
claude plugin disable <plugin>                       # 끄기(가역)
claude plugin uninstall <plugin>@<marketplace>       # 제거
```

## 5. 사용법 (재시작 후)

- **자동 발동**: 요청이 스킬 설명과 맞으면 알아서 발동. 예: "이 기능 만들기 전에 계획부터"(writing-plans),
  "TDD로 구현해줘"(test-driven-development), "병렬 에이전트로 리뷰해줘"(dispatching-parallel-agents), UI 작업 시 frontend-design.
- **진입점**: Superpowers는 `using-superpowers` 스킬이 안내자 역할.

## 6. 소실 경위 조사 (2026-08-06)

### 확인된 사실

| 증거 | 값 |
|---|---|
| `superpowers@superpowers-dev` 사용 이력 | **usageCount 105**, 마지막 사용 **2026-07-30 18:25** |
| `~/.claude/plugins/` 최종 변경 | **2026-08-02 13:47** — 현재 `data/pdf-viewer-inline` 만 남음 |
| Claude Code 버전 갱신 | 2026-08-02 15:52, `2.1.214 → 2.1.220` |
| `settings.json.pre-rebuild.20260802-161707` | **26바이트** — 08-02 16:03 시점 설정이 사실상 빈 파일 |
| `claude plugin list` | `No plugins installed` |
| `claude plugin marketplace list` | **`No marketplaces configured`** |
| `.claude.json` 잔존물 | `superpowers@superpowers-dev` **사용 통계 키만** 남음. 설치·등록 정보 없음 |

### 판정

**플러그인 서브시스템 전체가 2026-08-02에 초기화됐습니다.** 설치본(`plugins/`), 활성화
설정(`settings.json`), **마켓플레이스 등록까지** 모두 사라졌고 사용 통계만 남았습니다.

부분 손상이 아니라 전면 초기화입니다. 그래서 재설치하려면 마켓플레이스 등록부터 다시 해야 합니다.

### 행위자 — 특정하지 못함

다음을 모두 뒤졌으나 원인 행위를 찾지 못했습니다.

- Claude Code 세션 기록(2026-08-01~03, 4건) — `plugin uninstall`·`superpowers` 언급 **0건**
- Codex 세션 기록 동기간 — `superpowers` 매치는 전부 Codex 자체 커넥터 추천 목록
  (`superpowers@openai-curated-remote`)이며 Claude Code 플러그인과 **무관**
- `history.jsonl` — 플러그인 관련 명령 **0건**
- 워크스페이스 스크립트에서 `pre-rebuild` 명명 사용처 **0건**

**시간 순서만 관측됐습니다.** `plugins/` 변경(13:47) → 버전 갱신(15:52) → 빈 설정 백업(16:17).
13:47이 15:52보다 앞서므로 **버전 갱신이 원인이라고 단정할 수 없습니다.** 추측을 사실로
기록하지 않습니다.

### 재설치하려면

마켓플레이스 등록이 사라졌으므로 2단계입니다.

```bash
claude plugin marketplace add obra/superpowers
```

```bash
claude plugin install superpowers@superpowers-dev
```

**재설치 여부는 미결입니다.** 판단 근거는
[`../skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md`](../skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md)의
재재평가 절에 있습니다. 그 문서의 "실사용 의존도가 낮다" 논거는 이번 조사로 **철회**됐습니다
(105회 사용). 나머지 논거는 유효합니다.

## 관련
- 플러그인 3층위 개념·계정 커넥터 정리: [environment-notebook.md](environment-notebook.md)
- 스킬 탐색·슬림화 정본: [`../skills/`](../skills/)
