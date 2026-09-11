# MIA 3대 AI 도구 Skill 포트폴리오 REDTEAM

> 조사일: 2026-08-05
> 대상: Claude Code · Codex · Antigravity의 로컬 전역 Skill, Antigravity Skill 플러그인,
> Codex 앱 Skill 플러그인
> 방식: MIA 전략절차(Frame → Review → Execute → Verify) + REDTEAM 반증 + 웹 딥리서치
> 상태: 파일 기반 정리 완료, Codex 앱 플러그인 제거와 3개 CLI 발동 검증은 환경 오류로 미완료

## 1. 결론

파일 기반 배포는 **SKILL.md 127개 → 43개(-66.1%)**로 줄였다. 삭제하지 않고
`C:\Users\Kimyoongyeom\.mia-skill-backups\20260805-redteam-optimization-01`로 격리해
원상 복구할 수 있다.

| 도구 | 정리 전 | 정리 후 | 핵심 조치 |
|---|---:|---:|---|
| Claude Code | 11 | **10** | 현재 환경과 계약이 다른 `skill-repair` 격리 |
| Codex 전역 파일 | 50 | **20** | `.agents/skills` 40 → 10, `.codex/skills` 10 유지 |
| Antigravity | 66 | **13** | config 19 → 12, 레거시 중복 6 → 0, 플러그인 41 → 1 |
| 합계 | **127** | **43** | 84개 Skill을 복구 가능한 백업으로 이동 |

Codex의 앱/커넥터 플러그인 11종은 제거 도구를 호출했지만 전부
`No handler registered for tool: uninstall_plugin`으로 실패했다. 캐시 폴더는 설치 상태의 정본이
아니므로 수동 삭제하지 않았다.

## 2. MIA Frame — 무엇을 최적화했나

가설은 “Skill 수가 많아질수록 본문 전체가 매번 들어가서 무거워진다”였다. 웹 근거로 수정한
정확한 가설은 다음과 같다.

1. 세 도구 모두 **점진적 공개(Progressive Disclosure)**를 사용하므로 모든 본문이 상시 들어가지는 않는다.
2. 대신 이름·설명은 선택 문맥에 들어가므로, 수가 많거나 설명이 겹치면 오발동·선택 노이즈가 증가한다.
3. 발동 뒤에는 Skill 본문이 문맥에 남거나, 서브에이전트에는 본문이 선적재될 수 있어 장문 Skill은 비용이 크다.
4. 따라서 단순 개수보다 **중복 트리거, 실사용 근거, 출처, 환경 적합성, 부작용**을 함께 봐야 한다.

판정 렌즈는 아래 다섯 가지다.

| 렌즈 | 질문 |
|---|---|
| Value | 최근 작업이나 저장소 구조에 실제 사용 근거가 있는가 |
| Overlap | 내장 기능·다른 Skill·서브에이전트와 같은 트리거를 경쟁하는가 |
| Provenance | 공식/검증된 상류와 라이선스·버전 추적이 가능한가 |
| Safety | 외부 쓰기·배포·삭제·설치 등 부작용을 자동 유발할 수 있는가 |
| Portability | 해당 도구의 경로·명령·설정 계약과 맞는가 |

## 3. MIA Review — 전수 실측

### 3.1 로컬 물리 트리

- 정리 전: `SKILL.md` **127개**, 이름 **87종**, 내용 해시 **90종**.
- 교차 도구 중복 이름: **20종**.
- 내용 드리프트: `mia-strategic`, `security-audit`, `vibe-check`.
- Antigravity에는 같은 내용의 레거시 복사본 6개가 물리 폴더 세 곳에 중복돼 있었다.
- Codex의 MIA 3종은 `.agents/skills`와 `.codex/skills`에 SHA-256 동일본이 이중 배포돼 있었다.
- 127개 중 publisher 표기가 없는 것이 116개, license 미표기가 110개였다.

### 3.2 워크스페이스 사용 근거

- 최근 활동은 Markdown 문서가 1순위이고 React·Python이 2순위다.
- `package.json` 39개 실측에서 React 11, Vitest 7, Next.js 4, Express 4였고
  Supabase·Playwright·Docker 의존성은 0이었다.
- Claude Code 구조화 로그에서 직접 호출 근거가 있었던 것은
  `error-path-analysis`, MIA 3종, `product-thinking`, `python-refactor`, `vibe-check`,
  `web-design-guidelines`, `writing-guidelines`였다.
- Codex 세션의 직접 Skill 호출은 중첩 도구 호출이 로그에 드러나지 않아 부재 증거로 쓰지 않았다.

### 3.3 웹 딥리서치 근거

- [Claude Code 공식 기능 문서](https://code.claude.com/docs/en/features-overview)는 Skill 설명이
  세션 시작 때 들어가며, 설명이 모호하거나 겹치면 잘못 발동할 수 있다고 설명한다.
- [Claude Code Skill 문서](https://code.claude.com/docs/en/slash-commands)는 수동 Skill에
  `disable-model-invocation: true` 또는 `skillOverrides`를 쓰면 선택 문맥 비용을 0으로 만들 수
  있다고 명시한다.
- [OpenAI Codex 공식 skill-creator](https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md)는
  name/description이 항상 문맥에 있고 본문은 발동 뒤 로드되며, 본문은 500줄 미만으로 유지하라고 한다.
- [Agent Skills 규격](https://agentskills.io/specification)은 `description`을 주 발동 계약으로 정의한다.
- [Antigravity 공식 플러그인 문서](https://www.antigravity.google/docs/plugins)는 플러그인이
  Skill·Rule·MCP·Hook을 묶는 단위이며 전역 경로가 `~/.gemini/config/plugins`임을 확인시킨다.
- [Google DeepMind science-skills](https://github.com/google-deepmind/science-skills)는 신뢰할 수 있는
  공식 상류지만 생명과학·화학 전용 39종이다. 현재 워크스페이스에는 대응 작업 근거가 없다.
- [Vercel 공식 agent-skills](https://github.com/vercel-labs/agent-skills)의 React·웹 디자인·글쓰기
  Skill은 현재 작업 구성과 맞아 유지했다.

## 4. REDTEAM 판정 — 유지

### 4.1 Claude Code 10

`accidental-data-loss-prevention`, `error-path-analysis`, `mia-skill-compiler`, `mia-strategic`,
`mia-vaccine-test`, `product-thinking`, `python-refactor`, `vibe-check`,
`web-design-guidelines`, `writing-guidelines`

판정: 실제 호출 근거가 있거나 글로벌 안전 규칙·MIA 핵심 절차를 구현한다. Claude의 4개
서브에이전트와 직접 역할 충돌도 없다.

### 4.2 Codex 전역 20

`.agents/skills` 유지 10:

`accidental-data-loss-prevention`, `error-path-analysis`, `frontend-design`,
`managing-python-dependencies`, `product-thinking`, `python-refactor`,
`vercel-react-best-practices`, `vibe-check`, `web-design-guidelines`, `writing-guidelines`

`.codex/skills` 유지 10:

`hatch-pet`, `imagegen`, `mia-skill-compiler`, `mia-strategic`, `mia-vaccine-test`,
`openai-docs`, `plugin-creator`, `review-agent`, `skill-creator`, `skill-installer`

판정: 전자는 현재 문서·React·Python 작업의 최소 공통층이고, 후자는 Codex 전용 제작·시스템·
MIA 기능이다. 프로젝트의 `.agents/skills/mia-strategic`은 저장소 범위 어댑터이므로 전역본과
이름이 같아도 유지한다.

### 4.3 Antigravity 13

config Skill 12:

`accidental-data-loss-prevention`, `error-path-analysis`, `frontend-design`,
`managing-python-dependencies`, `mia-skill-compiler`, `mia-vaccine-test`,
`product-thinking`, `python-refactor`, `vercel-react-best-practices`, `vibe-check`,
`web-design-guidelines`, `writing-guidelines`

플러그인 Skill 1: `mia-strategic`

판정: 가장 낮은 사용량을 고려해 공통 최소층만 남겼다. `chrome-devtools-plugin`,
`modern-web-guidance-plugin` 등 Skill 파일이 없는 도구 플러그인은 이번 Skill 정리 범위에서 유지했다.

## 5. REDTEAM 판정 — 격리

### 5.1 Claude Code 1

| Skill | 판정 이유 |
|---|---|
| `skill-repair` | Google 계열 `manifest.json` 복구 계약을 가정해 Claude Code 환경과 맞지 않음 |

### 5.2 Codex `.agents/skills` 30

역할 중복·현재 실사용 근거 없음:

`agent-browser`, `api-review`, `b2b-landing`, `codebase-analyzer`, `debate`,
`dependency-manager`, `ebook-writing`, `frontend-polish`, `idea`, `orchestrate`,
`performance-checker`, `remotion-studio`, `security-audit`, `seo-master`, `site-auditor`,
`start-docs`, `webapp-testing`

현재 저장소의 SAFE-SYNC·권한·부작용 계약과 경쟁:

`commit`, `deploy-safety-guard`, `git-commit-helper`, `retro`, `sync-claude-md`, `sync-workflow`

상류/완결성/환경 결함:

`grill-me`, `grilling`, `korean-privacy-terms`, `skill-repair`

SHA-256 동일 중복본:

`mia-skill-compiler`, `mia-strategic`, `mia-vaccine-test`

### 5.3 Antigravity config 7 + 레거시 중복 6

config 격리:

`api-review`, `frontend-polish`, `git-commit-helper`, `grill-me`, `grilling`,
`security-audit`, `skill-repair`

레거시 동일본 격리:

- `~/.gemini/skills`: `accidental-data-loss-prevention`, `managing-python-dependencies`, `skill-repair`
- `~/.gemini/antigravity-ide/skills`: `api-review`, `frontend-polish`, `python-refactor`

### 5.4 Antigravity 플러그인 40

`android-cli` 1종은 Android 프로젝트 근거가 없어 격리했다.

science 39종은 공식 상류의 품질 문제가 아니라 **도메인 불일치**로 번들 단위 격리했다:

`alphafold-database-fetch-and-analyze`, `alphagenome-single-variant-analysis`, `chembl-database`,
`clinical-trials-database`, `clinvar-database`, `dbsnp-database`, `embl-ebi-ols`,
`encode-ccres-database`, `ensembl-database`, `foldseek-structural-search`, `gnomad-database`,
`gtex-database`, `human-protein-atlas-database`, `interpro-database`, `jaspar-database`,
`literature-search-arxiv`, `literature-search-biorxiv`, `literature-search-europepmc`,
`literature-search-openalex`, `ncbi-sequence-fetch`, `openfda-database`, `opentargets-database`,
`pdb-database`, `predictingthepast`, `protein-sequence-msa`,
`protein-sequence-similarity-search`, `pubchem-database`, `pubmed-database`, `pymol`,
`quickgo-database`, `reactome-database`, `scienceskillscommon`, `string-database`,
`ucsc-conservation-and-tfbs`, `unibind-database`, `uniprot-database`, `uv`,
`credentials`, `workflow-skill-creator`

## 6. Codex 앱 플러그인 판정

유지:

- GitHub: 저장소 작업의 직접 도구.
- Browser·Chrome·Sites·Visualize: 웹 조사·검증·시각 결과물의 공통 기반.
- Documents·PDF·Presentations·Spreadsheets·Template Creator: 문서 중심 작업의 직접 기반.
- Data Analytics·Product Design: 현재 보고서·UI/반려동물 작업에 대응.

제거 대상으로 판정하고 호출한 11종:

`Airtable`, `Base44`, `Figma`, `Gmail`, `Google Calendar`, `Google Drive`, `HeyGen`,
`Notion`, `Supabase`, `Wix`, `Zoom`

11/11 모두 앱 측 `No handler registered for tool: uninstall_plugin`으로 실패했다. 동일 원인 재시도나
캐시 수동 삭제는 하지 않았다. 이들은 Codex 앱의 플러그인 관리 화면/핸들러가 정상화된 뒤 제거해야 한다.

## 7. MIA Execute — 변경과 복구

- 삭제: **0개**.
- 격리 이동: 디렉터리 46개, `SKILL.md` 84개.
- 백업: `C:\Users\Kimyoongyeom\.mia-skill-backups\20260805-redteam-optimization-01`.
- 복구: 백업 내부의 `claude`, `codex-agents`, `antigravity` 구조를 따라 각 원래 사용자 홈
  경로로 필요한 디렉터리만 되돌린다. 전체 일괄 복구는 중복과 오발동을 다시 만든다.

## 8. MIA Verify — 검증 결과

| 검사 | 결과 |
|---|---|
| 이동 전 source/destination preflight | 통과 |
| 이동 후 source 부재 + backup 존재 | 46/46 통과 |
| 백업 파일/Skill/바이트 | **424 / 84 / 4,560,157 B** |
| 백업 트리 SHA-256 | `75DD68B656AA5A8EA96F3AC1BB83FFB9B530015E8E596E0CE687571C1802CE8C` |
| 저장소 `npm run skills:audit` | **exit 0**, 오류 0·경고 11·의도된 설명 드리프트 1 |
| 저장소 `npm run check` | **exit 0** — typecheck·lint·handoff·MIA sync/audit/tests 통과 |
| Claude Code 새 세션 | **실패** — 180초 타임아웃(exit 124) |
| Antigravity 새 세션 | **실패** — 로그 경로 권한 + 미로그인 인증 타임아웃(exit 1) |
| Codex 새 세션 | **실패** — WebSocket/HTTPS 네트워크 차단(exit 1) |

파일 트리·해시 검증은 설치 구조를 증명하지만 런타임 발동을 대신하지 않는다. 세 CLI 실패를
통과로 포장하지 않으며, 인증·네트워크가 정상인 다음 새 세션에서 목록 검증이 남아 있다.

## 9. 재증식 방지 정책

1. 새 Skill은 `실사용 증거 + 기존 기능 공백 + 명확한 트리거 + 출처/라이선스`를 모두 요구한다.
2. 한 플랫폼의 기본 포트폴리오는 **20개 이내**를 목표로 한다. 초과는 번들·프로젝트 범위로 한정한다.
3. 수동 워크플로는 Claude Code에서 `disable-model-invocation: true` 또는 `skillOverrides`를 쓴다.
4. 설치 전 동명 Skill의 모든 루트와 SHA-256을 검사한다.
5. 30일 동안 발동 근거가 없고 내장 대체가 있는 Skill은 삭제가 아니라 격리 후보로 승격한다.
6. 플러그인 캐시는 설치 정본으로 간주하지 않으며, 반드시 플랫폼 관리 명령으로만 제거한다.
