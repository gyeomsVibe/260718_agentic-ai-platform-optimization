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
| 2026-08-07 변경 | **Playwright v1.62.1 전역 설치** (사용자 요청). 브라우저 3종 구동 확인. 아래 5.1 참조 |
| 도구 사용량 | Codex 세션 44 · Claude Code 프로젝트 2 · Antigravity 대화 12 |

**결론: 문서 작성이 1순위, React 웹앱과 Python 스크립트가 2순위, 스킬·에이전트 엔지니어링이
상시 배경.** 인프라(Docker/K8s/Terraform)와 Supabase, E2E 는 실사용 근거가 없다.

## 4. 최적화 배포 결과

2026-08-05 REDTEAM 전수조사로 파일 기반 Skill을 **127개 → 43개**로 정리했다.
상세한 개별 판정과 웹 근거는
[`research/MIA_SKILL_PORTFOLIO_REDTEAM_2026-08-05.md`](research/MIA_SKILL_PORTFOLIO_REDTEAM_2026-08-05.md)가 정본이다.

| 도구 | 정리 전 | 정리 후 | 유지 기준 |
|---|---:|---:|---|
| Claude Code | 11 | **10** | 문서·Python·UX·MIA·안전 최소층 |
| Codex 전역 파일 | 50 | **20** | `.agents/skills` 10 + `.codex/skills` 10 |
| Antigravity | 66 | **13** | config 12 + MIA 플러그인 1 |

### Claude Code 10 → 12 (2026-08-07)

`accidental-data-loss-prevention`, `error-path-analysis`, MIA 3종, `product-thinking`,
`python-refactor`, `vibe-check`, `web-design-guidelines`, `writing-guidelines`.

**추가 2종** — obra/superpowers(MIT)에서 **선별 반입**: `systematic-debugging`,
`receiving-code-review`. 나머지 12종은 트리거 충돌로 제외했다. 판정표와 근거는
[`research/MIA_SKILLS_EXPLORATION_2026-07-19.md`](research/MIA_SKILLS_EXPLORATION_2026-07-19.md)의
"재설치 시도와 Pivot" 절에 있다.

> **플러그인으로 설치하지 않았다.** Claude Code 플러그인은 all-or-nothing 이라
> `using-superpowers`(모든 응답 가로채기)까지 딸려 온다. MIT 라이선스를 근거로 필요한
> `SKILL.md` 만 복사했다. 훅도 실행되지 않는다.

### Codex 20

- `.agents/skills` 10 → **12** (2026-08-07): 안전, 에러 UX, 프론트엔드 디자인,
  Python 의존성/리팩터링, 제품 사고, React 성능, 진단, 웹 감사, 글쓰기
  + superpowers 선별 2종.

> **2단계로 진행했다.** 처음에는 계정 커넥터가 `superpowers:*` 14종을 제공해 같은 이름이
> 두 경로에서 경쟁하므로 넣지 않았다. 사용자가 **Codex 앱에서 superpowers 커넥터를 해제**한
> 뒤(2026-08-07) 중복 사유가 사라져 배포했다. 해제 결과 14종이 목록에서 완전히 사라졌고
> **2% 스킬 컨텍스트 예산 초과 경고도 함께 사라졌다.**
- `.codex/skills` 10: Codex 시스템·제작 Skill 6, `hatch-pet`, MIA 3종.
- 프로젝트 `.agents/skills/mia-strategic`은 저장소 범위 어댑터라 전역본과 별도로 유지한다.

### Antigravity 13 → 15 (2026-08-07)

- `~/.gemini/config/skills` 12 → **14**: Codex 공통 최소층에서 MIA 전략절차를 제외한 구성 +
  superpowers 선별 2종(`systematic-debugging`, `receiving-code-review`).
- `~/.gemini/config/plugins/mia-modular-intelligence-architect` 1: `mia-strategic`.
- 레거시 `~/.gemini/skills`, `~/.gemini/antigravity-ide/skills`는 중복본을 모두 격리해 0개다.

## 5.1 Playwright 설치 (2026-08-07)

사용자 요청으로 설치했다. **`agent-browser`·`webapp-testing` 을 제외했던 근거("실행 기반
없음")가 해소됐다.** 필요해지면 두 스킬의 재반입을 검토할 수 있다.

| 항목 | 값 |
|---|---|
| 패키지 | `@playwright/test@1.62.1` — **전역** (`npm ls -g` 확인) |
| 브라우저 | Chromium 1234 · Firefox 1538 · WebKit 2336 |
| 캐시 위치 | `%LOCALAPPDATA%\ms-playwright` — 총 **2,543 MB** |
| 디스크 영향 | C 드라이브 여유 123 → **121 GB** |
| 구동 확인 | 스모크 테스트 **6/6 통과** (2 케이스 × 3 브라우저), exit 0 |

**브라우저 캐시는 이 설치 전부터 있었다.** vibe-clinic 대시보드의 `playwright-core`,
Python `playwright` 패키지, Antigravity 확장이 이미 공유 중이었다. Chromium 계열만 있었고
Firefox·WebKit 을 이번에 추가했다.

**프로젝트에서 쓰는 법** — 러너만 추가하면 된다. 브라우저는 공용 캐시를 재사용한다.

```bash
npm install -D @playwright/test
```

**되돌리기**: `npm rm -g @playwright/test`. 브라우저 캐시는 다른 도구가 공유하므로
지우지 않는다.

> **한글 픽스처 함정**: HTML 에 `<meta charset="utf-8">` 이 없으면 WebKit 이 Latin-1 로 읽어
> 한글이 깨진다. Chromium·Firefox 는 UTF-8 로 추측해 통과하므로 **그 둘만 돌리면 결함이
> 숨는다.** 이번 스모크 테스트에서 실제로 겪었고 `test-writer` 정본에 규칙으로 넣었다.

## 5. 격리 기준과 복구

격리 대상은 다음 중 하나 이상에 해당했다.

1. 내장 기능·다른 Skill·서브에이전트와 트리거가 겹침.
2. 최근 작업·프로젝트 의존성에서 사용 근거가 없음.
3. 상류·라이선스·실행 계약이 불명확하거나 현재 도구와 맞지 않음.
4. SAFE-SYNC·권한·부작용 규칙과 경쟁함.
5. 다른 활성 루트와 SHA-256이 같은 물리 중복본임.

삭제는 0개다. 격리한 `SKILL.md` 84개는 아래 백업에 있다.

`C:\Users\Kimyoongyeom\.mia-skill-backups\20260805-redteam-optimization-01`

필요한 Skill만 백업의 도구별 하위 구조를 따라 원래 경로로 되돌린다. 전체 일괄 복구는
중복과 오발동을 다시 만든다.

## 6. 검증 결과 (2026-08-05)

| 검사 | 결과 |
|---|---|
| 이동 preflight·사후 경로 확인 | **46/46 통과** |
| 파일 기반 활성 수 | **127 → 43** |
| 엄격 감사 `npm run skills:audit` | **exit 0**, 오류 0·경고 11 |
| `npm run check` | **exit 0**, 전체 게이트 통과 |
| Claude Code 새 세션 | **미통과** — 180초 타임아웃(exit 124) |
| Antigravity 새 세션 | **미통과** — 로그 권한·미로그인 인증 타임아웃(exit 1) |
| Codex 새 세션 | **미통과** — WebSocket/HTTPS 네트워크 차단(exit 1) |

파일 구조와 해시가 맞는다는 사실을 런타임 발동 성공으로 바꿔 말하지 않는다. 인증·네트워크가
정상인 다음 새 세션에서 도구별 목록 확인이 남아 있다.

## 6.1 런타임 재확인 (2026-08-06) — §6의 미통과 3건 중 2건 해소

`bc9a700` 시점에는 인증·네트워크 문제로 세 도구 모두 런타임 검증에 실패했다. 조건이 바뀐 뒤
다시 확인했다.

| 도구 | 결과 | 근거 |
|---|---|---|
| **Codex** | ✅ **14/14 정합** | `codex exec` — 12개 노출 + `mia-skill-compiler`·`mia-vaccine-test` 2개는 `allow_implicit_invocation: false` 설계대로 은닉. `failed to load skill` **0건** |
| **Antigravity** | ✅ **13/13 인식** | `agy --print` — config 12 + 플러그인 1(`mia-strategic`). 격리한 `science` 39종·`android-cli`가 목록에서 사라진 것까지 확인 |
| **Claude Code** | ✅ 10/10 | 명시 트리거 17문구 + 자동 안전 3사례. [검증 원장](research/trigger-verification-2026-08.json) |

**세 도구 모두 `bc9a700` 슬림화가 런타임에 반영됐다.** 파일 배치와 실제 인식이 일치한다.

### `openai.yaml` 없이도 Codex 는 로딩한다

`~/.agents/skills` 10개는 `agents/openai.yaml` 이 없어 감사 경고가 뜬다. 그러나 위 검증에서
**10개 전부 Codex 목록에 노출됐다.** 즉 이 경고는 **표시·정책 계약 미이행이지 로딩 실패가 아니다.**

**어댑터를 만들지 않기로 결정했다.** 근거 셋:

1. 10개 모두 **비파괴 계열**이다. 은닉이 필요한 스킬이 없으므로 기본값(노출)이 곧 의도한 정책이다.
2. 런타임에서 정상 동작이 실증됐다. 어댑터 10개는 기능 이득이 0이다.
3. 외부 반입 스킬이라 저장소 정본이 없다. 배포본에만 어댑터를 넣으면 드리프트만 늘어난다.

파괴 계열 스킬을 이 루트에 추가할 때는 **반드시** 어댑터와 `allow_implicit_invocation: false`
를 함께 넣는다. 그때는 경고를 무시하지 않는다.

## 7. 남은 위험

### 스테이징 사본 — 표시 완료 (2026-08-06)

`D:\D_Workspace_NB\-agentic-ai-workspace\.agents\skills` 에 **슬림화 이전 27개**가 남아 있다.
현재 Codex 배포본은 **10개**다. 이 폴더는 정본이 아니라 2026-05-23 반입 시점의 staging
사본이며([SOURCE.md](external/eli-kardis/vibe-coding-skills/SOURCE.md)) **과거 기록으로만 유효하다.**

**단순 구버전이 아니다.** 27개와 10개가 겹치는 것은 4개뿐이다
(`error-path-analysis`, `product-thinking`, `python-refactor`, `web-design-guidelines`).
나머지 6개는 다른 출처에서 왔다. 여기서 복사하면 정리한 23개가 되살아나고 현재 쓰는 6개는
그대로 남아 **목록이 33개로 불어난다.**

되돌림 경로는 둘이다. `skills/` 직접 복사와 **`install.sh`** (`~/.claude/skills`·`~/.claude/agents`
에 27+12개를 복사한다).

**조치**: 삭제하지 않고 **경고 표시만** 했다. `MANIFEST.sha256` 이 이 파일들의 SHA-256 을
가리키므로 지우면 반입 시점 원본과 대조할 수단이 사라진다.

| 위치 | 내용 |
|---|---|
| `.agents/README.md` 최상단 | 되돌림 경로 2개와 배포본 차이표 |
| `.agents/skills/_STALE_DO_NOT_SYNC.md` | 27 vs 10 상세 대조, 제외 근거 요약, 복구 절차 |

복구가 필요하면 staging 이 아니라 `~/.mia-skill-backups/20260805-redteam-optimization-01` 에서
필요한 것만 되돌리고 `npm run skills:audit` 로 확인한다.

- **Codex 앱 플러그인**: 사용 근거가 없는 커넥터 11종 제거 호출이 모두
  `No handler registered for tool: uninstall_plugin`으로 실패했다. 캐시를 직접 지우지 않았다.
- **Claude 자동발동**: 지금은 10개로 작지만, 수동 전용 워크플로가 생기면
  `disable-model-invocation: true` 또는 `skillOverrides`로 목록 문맥에서 숨긴다.
- **배포본 드리프트**: 정본은 `skills/` 아래다. 사용자 홈 배포본을 직접 고치지 말고 정본 수정 →
  대상 도구 재배포 → `npm run skills:audit` 순서를 지킨다.
