# 에이전틱 AI 플랫폼·로컬 추론 최적화 워크스페이스

> Claude Code · Codex · Antigravity와 Ollama 로컬 추론 환경을 빠르고 안정적으로
> 쓰기 위한 설정·최적화·문제해결 기록을 한곳에 모은 저장소입니다.

## 이 저장소가 처음이라면 (30초 안내)

- **"에이전틱 AI 플랫폼"이 뭔가요?** 사람이 코드를 한 줄씩 치는 대신, 자연어로 시키면
  AI가 대신 파일을 읽고 고치고 실행해 주는 도구입니다. 이 저장소는 그런 도구 **3종**을
  다룹니다: **Claude Code**(터미널형), **Codex**(OpenAI 데스크톱 앱), **Antigravity**(구글 IDE).
- **이 저장소는 앱이 아닙니다.** 실행하는 프로그램이 아니라, 위 3종 도구를 잘 쓰기 위한
  **설정 기록·가이드·문제해결 노트**를 모은 문서 창고입니다.
- **무엇부터 볼까?** 아래 지도에서 관심 있는 폴더의 README를 먼저 여세요. 각 폴더 README가
  "이게 뭔지 모르는 사람"도 이해할 수 있게 다시 설명해 줍니다.
- **AI에게 뭘 시킬 수 있는지 알고 싶다면** → **[Skill 사용 매뉴얼](skills/MANUAL.md)**.
  스킬이 뭔지부터 설명하고, 도구별로 **어떤 문장을 말하면 발동하는지** 그대로 적어 뒀습니다.

## 지금 설치된 상태 (2026-09-05 갱신)

기존 스킬의 2026-08-07 런타임 결과와 새 `slash-prompt-modes`의 2026-09-05 결과를
구분합니다. 숫자는 사용자 범위 Skill 폴더이며, 파일 배치가 곧 실동작 성공이라는 뜻은 아닙니다.

| 도구 | 스킬 | 서브에이전트 | 확인 방법 |
|---|---|---|---|
| Claude Code | **23개** | **4개** | 기존 12개 + 교정된 슬래시 본체·별칭 11개. 정본 일치 |
| Codex | **27개** (+ 계정 커넥터) | — | 기존 16개 + 교정된 슬래시 본체·별칭 11개. 정본 일치 |
| Antigravity | **26개** | — | 기존 15개 + 슬래시 본체·별칭 11개. 새 항목은 구조·해시만 확인 |

새 명령 모드는 [Slash Prompt Modes](skills/custom/slash-prompt-modes/README.md)에서 30초 안에
고를 수 있습니다. REDTEAM 재감사에서 기존 별칭 생성본의 의미 결함을 찾아 생성기를
교정하고 세 사용자 홈에 동시 재배포했습니다. Antigravity 새 IDE 세션 발동과 10개 모드의
플랫폼별 전수 실행도 완료하지 않았으므로 “3대 도구 전체 실동작 완료”로 표시하지 않습니다.

> **공용 스킬 경로는 없습니다.** 도구마다 읽는 폴더가 다릅니다. 한 도구에서 됐다고
> 다른 도구도 되리라 넘겨짚지 마세요 — 자세한 내용은 [DEPLOYMENT.md](skills/DEPLOYMENT.md) 2절.

스킬 파일이 깨지지 않았는지는 루트에서 한 번에 검사합니다.

```powershell
npm run skills:audit
```

## 폴더 지도

| 폴더 | 무엇인가 | 언제 보나 |
|---|---|---|
| [claude/](claude/) | **Claude Code** 플랫폼 섹션 — 환경 기록 + [`agents/`](claude/agents/) 서브에이전트 4개 정본 | Claude Code 설정을 재현·복구하거나 서브에이전트를 고칠 때 |
| [codex/](codex/) | **Codex** 플랫폼 섹션 — 환경설정, 샌드박스 문제해결, **커스텀 반려동물(Pet) 제작**, 앱 패치 | Codex 설정·앱 문제·펫 커스터마이징 |
| [antigravity/](antigravity/) | **Antigravity** 플랫폼 섹션 — 환경설정, IDE 확장 슬림화(다이어트) | Antigravity IDE를 가볍게 만들 때 |
| [ollama/](ollama/) | **Ollama** 로컬 추론 섹션 — D: 모델 저장, GPU 최적화, 초보자용 실행법 | 인터넷 없이 로컬 모델을 실행하거나 설치를 복구할 때 |
| [mcp/](mcp/) | **MCP 섹션** — AI 도구에 외부 기능을 연결하는 서버들 (현재 NotebookLM) | AI에 외부 자료·도구를 붙일 때 |
| [skills/](skills/) | **모든 Skill의 정본** — [사용 매뉴얼](skills/MANUAL.md) · [배포 정본](skills/DEPLOYMENT.md) · `custom/mia` 제작 Skill · `external` 외부 도입 · 조사 기록 | 스킬을 **쓰거나** 찾고·수정하고·검증할 때 |
| [shared/](shared/) | **3플랫폼 공용 기반시설** — 전역 규칙과 자동업데이트 | 세 도구가 함께 쓰는 규칙·자동화를 손볼 때 |
| [handoff/](handoff/) | **GitHub 인계 정본** — 활성 인계, 완료 기록, 계약, SELFREFINE 검증기 | 다른 에이전트가 검증된 기준점에서 작업을 이어받을 때 |

> **왜 이렇게 나눴나?** `claude/`·`codex/`·`antigravity/`는 **도구 하나에만** 해당하는 자료,
> `mcp/`·`shared/`는 **세 도구가 함께** 쓰는 자료입니다. 개별 MCP는 최상위에 흩어 두지 않고
> 반드시 `mcp/` 아래 하위 폴더로 넣습니다 (예: `mcp/notebooklm/`).

## 워크스페이스와 GitHub 최신성 동기화

이 저장소는 시간 간격으로 반복 실행하지 않고, 에이전트가 실제 변경을 완료했을 때만
SAFE-SYNC를 실행합니다. 이번 실행이 소유한 경로만 검증하고 명시적으로 스테이징하며,
사용자 변경·비밀정보·머신 설정은 자동 커밋에서 제외합니다. 원격이 앞서거나 분기됐으면
자동 rebase, merge, force push를 하지 않고 중단해 보고합니다.

- [SAFE-SYNC 개념·가이드·운영 매뉴얼](shared/repository-sync/README.md)
- [MIA 심화 연구보고서](shared/repository-sync/MIA_WORKSPACE_GITHUB_SYNC_RESEARCH_2026-07-20.md)

계정의 모든 저장소에는 이 장문 규칙을 복사하지 않습니다. 이 문서를 정본으로 유지하고,
활성 저장소에는 원격·브랜치·검증 명령·제외 경로·승인 수준만 선언하는 얇은 어댑터를
파일럿부터 선택적으로 적용합니다.

일반 작업은 SAFE-SYNC 작업 커밋을 원격에 올리는 것으로 끝납니다. 윤겸스가 인계 또는 플랫폼 간 재개를 명시적으로 요청한 경우에만 [handoff 정본](handoff/)이 `work_sha`, 검증 결과, 남은 일, 다음 행동을 별도 인계 커밋으로 고정합니다. 그때 작업 커밋과 handoff 레코드가 모두 원격에 존재하고 수신자가 기준점을 재검증하면 인계가 확정됩니다.

## 자료를 새로 넣는 기준

- 실행 Skill, 후보, 플러그인 패키지, 평가 증거는 출처와 관계없이 `skills/` 아래에서
  분류합니다.
- 직접 만든 Skill은 `skills/custom/`, 외부에서 가져온 Skill은 `skills/external/`에 둡니다.
- `shared/`에는 Skill을 두지 않습니다. 세 플랫폼 공통 규칙과 자동화만 둡니다.
- 사용자 홈의 전역 설치본은 배포 결과입니다. 이 저장소의 정본을 대신하지 않습니다.

## 루트 운영 파일

GitHub는 폴더보다 루트 파일을 먼저 보여 줍니다. 아래 파일은 흩어진 문서가 아니라,
저장소를 열자마자 각 도구가 자동 발견해야 하는 최소 운영 파일입니다.

| 파일 | 루트에 있어야 하는 이유 |
|---|---|
| [README.md](README.md) | 사람에게 저장소 구조와 시작 위치를 안내합니다. |
| [AGENTS.md](AGENTS.md) | Codex가 프로젝트 규칙을 자동 발견합니다. |
| [CLAUDE.md](CLAUDE.md) | Claude Code가 프로젝트 규칙을 자동 발견합니다. |
| [.gitignore](.gitignore) | 임시 설치본, 의존성, 비밀정보 파일의 커밋을 막습니다. |
| [package.json](package.json) | 저장소 검증 명령과 검사 도구 버전을 고정합니다. |
| [package-lock.json](package-lock.json) | 같은 검사 도구 버전을 다시 설치하게 합니다. |
| [eslint.config.mjs](eslint.config.mjs) | 저장소 JavaScript·설정 파일의 정적 검사 범위를 정합니다. |
| [tsconfig.json](tsconfig.json) | TypeScript 엄격 검사 기준과 검증 입력을 지정합니다. |

한 번에 검사하려면 저장소 루트에서 실행합니다.

```powershell
npm run check
```

이 파일들을 하위 폴더로 옮기면 GitHub 화면은 짧아지지만 자동 규칙 발견과 표준 `npm`
명령이 깨질 수 있으므로 루트에 유지합니다. 실제 자료는 상위 분류 폴더에만 둡니다.

## 최근 변경 (최신성 기록)

문서와 실제 환경이 어긋나면 그 문서는 **틀린 안내**가 됩니다. 실측으로 뒤집힌 내용은
지우지 않고 **정정 기록을 남깁니다.** 무엇이 언제 왜 바뀌었는지 추적하기 위해서입니다.

### 2026-08-07 — 검증 완결과 선별 반입

| 변경 | 내용 |
|---|---|
| **검증** | 명시 트리거 **17개 문구 실행 검증**(17/17). 원시 로그를 저장소에 보존해 증거 등급을 `logged`로 승격 |
| **검증** | 자동 안전장치 **행동 검증 3/3** — 격리 fixture에서 발동·중단·영향설명·승인요청 4축 확인 |
| **검증** | **오발동 측정 6/6 정상** — 경계 요청에 어떤 스킬도 발동하지 않음 |
| **정정** | 안전장치 미발동을 방어 공백으로 의심했으나 **빈 폴더에서 시험한 설계 오류**였음. 현실적 fixture에서 3/3 발동 |
| **정정** | superpowers No-Go 논거 중 "실사용 의존도 낮음"을 **철회**(`usageCount` 105회) |
| **추가** | superpowers 14종 중 **충돌 없는 2종만 선별 반입** — 플러그인은 all-or-nothing이고 `using-superpowers`가 모든 응답을 가로챔 |
| **정리** | Codex 로컬 플러그인 5종 비활성화. 계정 커넥터는 서버 측이라 로컬 제거 불가로 확정 |
| **문서** | [Skill 사용 매뉴얼](skills/MANUAL.md)을 **상황별 역인덱스 우선**으로 재작성 |

### 2026-08-05 — 3대 도구 스킬 실측·정비

| 변경 | 내용 |
|---|---|
| **정정** | `~/.agents/skills`는 "3대 도구 공용 경로"가 **아니었습니다.** 실측 결과 **Codex 전용**이고, Claude Code·Antigravity는 40개 중 **0개**를 인식했습니다 |
| **정정** | `claude/plugins.md`가 설치됐다고 기록한 플러그인 2종(superpowers·frontend-design)이 **실제로는 없었습니다**. `claude plugin list` → `No plugins installed` |
| **복구** | 전역 `CLAUDE.md`가 지시하는 `vibe-check` 스킬을 Claude Code가 **볼 수 없던** 상태를 해소 |
| **추가** | Claude Code 스킬 3 → 11개, 서브에이전트 0 → 4개 / Antigravity 16 → 19개 (실사용 패턴 실측 기반 선별) |
| **추가** | [`npm run skills:audit`](skills/custom/mia/scripts/audit-skill-roots.py) — 9개 폴더 110개 스킬을 최엄격(Codex) 규격으로 전수 감사. `npm run check`에 편입 |
| **판단** | superpowers 재설치 **No-Go** — 14개 스킬 중 12개가 이미 커버되고 트리거가 충돌 ([근거](skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md)) |
| **문서** | [Skill 사용 매뉴얼](skills/MANUAL.md) · [배포 정본](skills/DEPLOYMENT.md) 신설 |

### 2026-08-05 — MIA REDTEAM 스킬 포트폴리오 최적화

| 변경 | 내용 |
|---|---|
| **정리** | 3대 도구 파일 기반 `SKILL.md` **127 → 43(-66.1%)**. 삭제 없이 사용자 홈 백업으로 84개 격리 |
| **중복 제거** | Antigravity 레거시 루트 6개와 Codex MIA SHA-256 동일본 3개 격리 |
| **도메인 축소** | 현재 작업 근거가 없는 Antigravity 과학 39종·Android 1종 플러그인 격리 |
| **문서** | [MIA REDTEAM 전수조사](skills/research/MIA_SKILL_PORTFOLIO_REDTEAM_2026-08-05.md)에 전체 판정·웹 근거·복구 경로 기록 |
| **미완료** | Codex 커넥터 11종 제거는 앱 핸들러 부재로 실패. 3개 CLI 새 세션 검증도 환경 오류로 미통과 |

### 2026-08-04 — 외부 Skill 반입 계약 정비

| 변경 | 내용 |
|---|---|
| **등록** | [eli-kardis/vibe-coding-skills](skills/external/eli-kardis/vibe-coding-skills/SOURCE.md) 반입 등록 (MIT, `STATIC_REVIEWED`) |
| **복구** | 배포본 11개가 "Claude→Codex" 일괄 치환으로 오염돼 있던 것을 원복 |
| **분리** | 상류에 없던 로컬 자산 7건을 [`skills/custom/legacy-harness/`](skills/custom/legacy-harness/)로 보존 |

## 배경 메모

- 이 저장소의 플랫폼 환경 기록은 원래 `260713_pc-optimization` 워크스페이스에 섞여 있던 것을
  2026-07-19에 **에이전트 자료만 골라 이관**해 온 것입니다. PC 디스크·하드웨어 최적화 자료는
  그쪽에 남아 있습니다.
- **노트북**(MSI GL75)과 **데스크톱**(i7-6700K)은 서로 다른 PC이므로, 환경 문서를
  `-notebook` / `-desktop`으로 구분합니다. 한쪽 설정을 다른 쪽에 그대로 적용하지 마세요.
