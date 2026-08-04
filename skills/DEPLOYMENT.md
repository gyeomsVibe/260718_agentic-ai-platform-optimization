# 도구별 Skill 배포 정본

> 어느 Skill을 어느 도구에 올렸고 **왜 그렇게 정했는지**의 정본입니다.
> 규격·검증 절차는 [`custom/mia/AUTHORING_HANDBOOK.md`](custom/mia/AUTHORING_HANDBOOK.md)가,
> 외부 반입 출처는 [`external/`](external/)이 정본입니다.
>
> 최종 갱신: 2026-08-05 (3대 도구 CLI 실측 + 선별 배포 완료)

## 1. 대원칙 — 전부 다 올리지 않는다

**스킬이 많을수록 목록 컨텍스트가 커지고 오발동이 늘어난다.** 저장소가 2026-07-19부터
지켜 온 원칙이다. 따라서 배포 판단은 세 질문을 통과해야 한다.

1. **실사용 근거가 있는가** — 워크스페이스 실측 기준. 취향이나 "있으면 좋을 것" 은 근거가 아니다
2. **그 도구가 이미 덮지 못하는가** — 내장 명령·기존 스킬·서브에이전트와 중복이면 올리지 않는다
3. **트리거가 충돌하지 않는가** — 같은 요청에 두 경로가 경쟁하면 둘 다 신뢰할 수 없어진다

## 2. 도구별 루트 (2026-08-05 실측 확정)

**공용 경로는 없다.** 세 도구 CLI에 각각 스킬 목록을 나열시켜 확인했다.

| 도구 | 읽는 루트 | 확인 명령 |
|---|---|---|
| Claude Code | `~/.claude/skills` | `claude -p` |
| Codex | `~/.codex/skills` + `~/.agents/skills` | `codex exec` |
| Antigravity | `~/.gemini/config/skills`, `~/.gemini/skills`, `~/.gemini/config/plugins/*/skills` | `agy --print` |

`~/.agents/skills` 는 오래 "3대 도구 공용" 으로 문서화됐으나 **Codex 전용**이다.
Claude Code·Antigravity 는 이 경로의 40개 중 **0개**를 인식한다.

## 3. 실사용 패턴 (2026-08-05 실측)

배포 근거로 쓴 수치다. 추정이 아니다.

| 지표 | 값 |
|---|---|
| 최근 30일 수정 파일 | `.md` **666** · `.png` 700 · `.json` 345 · `.js` 206 · `.py` 58 · `.ps1` 49 · `.jsx` 49 |
| 활성 프로젝트 6종의 구성 | 전부 문서(md 4~138) + React 3/6 + Python 3/6 |
| package.json 39개 중 | react 11 · vitest 7 · next 4 · express 4 · **supabase 0 · playwright 0 · docker 0** |
| 도구 사용량 | Codex 세션 44 · Claude Code 프로젝트 2 · Antigravity 대화 12 |

**결론: 문서 작성이 1순위, React 웹앱과 Python 스크립트가 2순위, 스킬·에이전트 엔지니어링이
상시 배경.** 인프라(Docker/K8s/Terraform)와 Supabase, E2E 는 실사용 근거가 없다.

## 4. 배포 결과

### Claude Code `~/.claude/skills` — 3개 → **11개**

| 추가한 Skill | 근거 |
|---|---|
| `vibe-check` | **글로벌 `CLAUDE.md` L92가 이 스킬 사용을 지시하는데 Claude Code가 볼 수 없었다.** 깨진 규칙을 복구 |
| `writing-guidelines` | 문서가 1순위 활동(.md 666/30일). 산문 품질 검토를 덮는 내장 기능 없음 |
| `python-refactor` | 활성 프로젝트 3/6이 Python. 내장 Python 전용 스킬 없음 |
| `error-path-analysis` | 에러 경로·빈 상태·오프라인 UX 진단. 내장 대체재 없음 |
| `web-design-guidelines` | React 11/39. `frontend-design-specialist` 에이전트의 자체 체크리스트를 100+ 규칙 감사로 보강 |
| `product-thinking` | 컨셉 설계. `mia-strategic`(가설 검증)과 층위가 다름 |
| `skill-repair` | 이 저장소 자체가 스킬 엔지니어링 |
| `accidental-data-loss-prevention` | 글로벌 룰 P2·P3(비가역 작업 승인)와 정렬 |

### Antigravity `~/.gemini/config/skills` — 16개 → **19개**

이미 `vibe-check`·`writing-guidelines`·`python-refactor`·`skill-repair`·
`accidental-data-loss-prevention` 을 보유하고 있어 결손분만 채웠다.
사용량이 가장 낮은 도구(대화 12건)이므로 추가를 최소화했다.

| 추가한 Skill | 근거 |
|---|---|
| `error-path-analysis` · `web-design-guidelines` · `product-thinking` | 위와 동일. 이 3개만 없었음 |

### Codex — 변경 없음

`~/.agents/skills` 40개 + `~/.codex/skills` 4개를 이미 인식한다. 추가할 것이 없다.

## 5. 올리지 않은 것과 이유

| Skill | 제외 근거 |
|---|---|
| `commit`, `retro`, `sync-claude-md`, `sync-workflow` | 저장소의 SAFE-SYNC 게이트·handoff 체계와 **충돌**. 이들은 `.claude/session-notes.md`·`CLAUDE.md` 를 독자 규칙으로 고친다 |
| `codebase-analyzer` | 내장 `/code-review` + `simplify` 와 중복 |
| `security-audit` | 내장 `/security-review` 와 중복 |
| `api-review`, `frontend-polish` | 신규 서브에이전트 `api-architect`·`frontend-design-specialist` 와 중복 |
| `agent-browser`, `webapp-testing` | **Playwright 0/39** — 실행 기반이 없다 |
| `seo-master`, `site-auditor`, `performance-checker`, `b2b-landing` | 배포된 사이트·랜딩 작업 근거 없음 |
| `korean-privacy-terms` | **한국어 이용약관 템플릿 0바이트(상류 결함)**. 기본값에서 빈 법률 문서를 만든다 |
| `debate`, `orchestrate` | 내장 Agent 도구와 중복. 이 저장소는 명시 요청 없는 에이전트 스폰을 금지한다 |
| `ebook-writing`, `remotion-studio`, `idea`, `dependency-manager` | 활성 프로젝트에 대응 작업 근거 없음 |

제외본은 삭제하지 않았다. `~/.agents/skills` 에 그대로 있고 Codex 에서는 계속 쓸 수 있다.

## 6. 검증 결과 (2026-08-05)

| 검사 | 결과 |
|---|---|
| 배포 충돌 | 0건 (대상 경로에 동명 스킬 없음) |
| SHA-256 무결성 | 11/11 일치 |
| 엄격 감사 `npm run skills:audit` | **오류 0건** (exit 0) |
| Claude Code 발동 | `claude -p` 지목 확인 → **8/8 있음** |
| Antigravity 발동 | `agy --print` 지목 확인 → **3/3 있음** |
| `npm run check` | exit 0 |

파일 복사는 설치 무결성만 증명한다. 위 두 CLI 확인이 **발동 근거**다.

## 7. 남은 위험

- **Codex 어댑터 미비**: 새로 배포한 8개 중 `agents/openai.yaml` 을 가진 것은 없다.
  Claude Code·Antigravity 는 이 파일을 쓰지 않으므로 현재 영향은 없다. 다만 이들을
  Codex 루트로 옮기면 표시·발동 계약 미이행 경고가 뜬다.
- **정본 이원화**: 배포본 3벌(claude / antigravity / codex-agents)이 각자 존재한다.
  한쪽만 고치면 드리프트가 생긴다 — 2026-05-28에 실제로 그 사고가 있었다
  ([SOURCE.md 5절](external/eli-kardis/vibe-coding-skills/SOURCE.md)). 고칠 때는
  `~/.agents/skills` 를 원본으로 삼고 세 곳에 함께 반영한 뒤 `npm run skills:audit` 을 돌린다.
- **오발동 미측정**: 목록에 노출되는 것과 적절한 때만 발동하는 것은 다르다.
  Claude Code 스킬이 3개에서 11개로 늘었으므로, 실사용에서 엉뚱하게 발동하면 줄여야 한다.
