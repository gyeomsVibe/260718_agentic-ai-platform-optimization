# SOURCE — eli-kardis / vibe-coding-skills

> 외부 Skill 반입 계약([`../../README.md`](../../README.md)) 필수 항목 기록.
> 이 문서는 **정본이 아니라 출처 원장**입니다. 원본 파일은 저장소 밖의
> `D:\D_Workspace_NB\-agentic-ai-workspace\.agents\`(git 비추적)에 있습니다.

## 1. 출처

| 항목 | 값 | 확인 방법 |
|---|---|---|
| 원 제작자 | `eli-kardis` | `.claude-plugin/plugin.json` `author` |
| 원본 저장소 | https://github.com/eli-kardis/vibe-coding-skills | 2026-08-04 접속, 공개 저장소 존재 확인 |
| 배포 형태 | Claude Code 플러그인 (`.claude-plugin/plugin.json`) | 로컬 파일 실측 |
| 반입 버전 | `1.0.0` | `plugin.json` `version` |
| 커밋 해시 | **미확인** | 로컬 사본에 `.git` 없음 (clone이 아닌 파일 복사). 상류 커밋 총 2개 |
| 반입 일자 | **2026-05-23 (추정)** | 상류 유래 파일 전체의 mtime. 반입 로그 없음 → 추정치 |
| 확인자 / 확인일 | 김윤겸 / 2026-08-04 | 본 전수분석 |

## 2. 라이선스

- **MIT** (`plugin.json` `license`, 상류 저장소 라이선스 표기 일치)
- 재배포·수정 허용. 저작권 고지와 라이선스 전문 보존 필요.
- 하위 포함물 중 별도 라이선스를 자체 보유한 항목:
  - `skills/korean-privacy-terms/LICENSE`, `NOTICE`
  - `skills/webapp-testing/LICENSE.txt`
  - 이 두 항목은 상위 MIT와 별개로 각자의 조건을 따릅니다.

## 3. 무결성

- 파일별 SHA-256: [`MANIFEST.sha256`](MANIFEST.sha256) (169개 파일, `<sha256>  <bytes>  <상대경로>` 형식)
- 매니페스트 자체 SHA-256: `fc8a76c0bc935671cfd10fce1b7d94b033b3ea229205e61bb10ce537aa65b592`
- 기준 시점: 2026-08-04
- 재검증 방법:
  ```powershell
  $root="D:\D_Workspace_NB\-agentic-ai-workspace\.agents"
  Get-ChildItem -Recurse -Force -File $root | Sort-Object FullName | ForEach-Object {
    "{0}  {1}  {2}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $_.Length,
      ($_.FullName.Substring($root.Length+1) -replace '\\','/')
  }
  ```

## 4. 상류 대비 로컬 차이

상류는 **skills 24개 / agents 12개**입니다(2026-08-04 저장소 페이지 실측). 로컬 사본은 skills 폴더가 27개입니다.

### 상류에 없는 로컬 추가분 — 외부 자산 아님

| 경로 | mtime | 처리 |
|---|---|---|
| `skills/api-review/` | 2026-05-11 | [`../../../custom/legacy-harness/`](../../../custom/legacy-harness/)로 분리 보관 |
| `skills/frontend-polish/` | 2026-05-11 | 〃 |
| `skills/python-refactor/` | 2026-05-11 | 〃 |
| `rules/` 4개 파일 | 2026-04-25 ~ 05-10 | 〃 |

윤겸스가 직접 작성한 Antigravity 시절 자산이 상류 사본 위에 겹쳐진 상태였습니다.
eli-kardis에게 귀속시키지 않으며, 저장소 정본은 `skills/custom/legacy-harness/`입니다.

### 유지 / 수정 / 제외

- **유지**: 상류 파일 166개 원본 그대로.
- **제외**: 없음.
- **수정**: 3건. 아래 4-1절.

### 4-1. 반입 후 로컬 수정 (2026-08-04)

[`MANIFEST.sha256`](MANIFEST.sha256)는 **수정 이전의 반입 실측 기준선**입니다. 아래 3개 파일은
그 이후 변경되었으므로 매니페스트와 대조하면 불일치가 나옵니다. **정상입니다.**

| 파일 | 변경 | 이유 |
|---|---|---|
| `skills/product-thinking/SKILL.md` | **신규 생성** (4,713 B) | 상류에 `SKILL.md`가 없어 영구 미발동 상태였음. `references/concept-lesson.md`만 존재 |
| `skills/korean-privacy-terms/SKILL.md` | 상단에 로컬 가드 블록 추가 | 0바이트 한국어 이용약관 템플릿으로 **빈 법률 문서가 조용히 생성**되는 것을 차단 |
| `README.md` | 개수·설치 안내 정정 | 24개 표기 → 27개, 실패하는 `/plugin marketplace add` 안내 수정, 미배포 에이전트 12개 명시 |

수정 3건은 모두 **스테이징(`.agents/`)과 배포본(`~/.agents/skills/`) 양쪽에 동일 적용**했습니다
(README.md는 배포 대상 아님). 5절 사고의 재발을 막기 위해 한쪽만 고치지 않았습니다.

상류에 이 수정들을 역제안(upstream PR)하지 않았습니다. 필요하면 별도 판단 사항입니다.

## 5. 배포본 드리프트 사건 (2026-05-28) — 해소됨

`~/.agents/skills/`(3대 도구 공용 배포 경로)의 11개 `SKILL.md`가 스테이징본과 불일치했습니다.
원인은 **배포본에만 실행된 "Claude → Codex" 문자열 일괄 치환**입니다.

| 파일 | 변경 줄 | 순수 치환 여부 |
|---|---|---|
| `agent-browser`, `b2b-landing`, `commit`, `debate`, `korean-privacy-terms`, `remotion-studio`, `retro`, `site-auditor`, `start-docs`, `sync-workflow` | 6·1·3·2·4·1·6·8·7·3 | **예** — 아래 규칙의 역변환으로 완전 복원 |
| `sync-claude-md` | 27 | **아니오** — `CLAUDE.md → AGENTS.md` 포팅이 추가됨 |

적용된 치환 규칙: `.claude` → `.Codex`, `CLAUDE.local.md` → `Codex.local.md`,
`sync-claude-md` → `sync-Codex-md`, `Claude` → `Codex`.

확인된 실질 파손:
1. `sync-claude-md`: 프런트매터 `name: sync-Codex-md` ↔ 폴더명 불일치 + 대문자 사용 → **발동 불가**
2. `commit`: 커밋 트레일러가 `Co-Authored-By: Codex Opus 4.6 <noreply@anthropic.com>`로 변경.
   Codex는 OpenAI 제품이며 해당 식별자는 실존하지 않음 → git 이력에 허위 저작자 주입 위험
3. `agent-browser`: 실존하지 않는 "Codex in Chrome" 참조 6곳
4. 3대 도구 **공용** 경로의 문서가 Codex 전용 경로로 하드코딩됨

**처리 (2026-08-04)**: 11개 파일 전부 스테이징본으로 원복. 재검증 결과 150/150 파일 SHA 일치,
`.Codex`·`Codex Opus`·`Codex in Chrome`·`sync-Codex-md` 잔존 0건.
순수 치환이 아니었던 `sync-claude-md` 변형본은
[`evidence/sync-claude-md.codex-variant-2026-05-28.md`](evidence/sync-claude-md.codex-variant-2026-05-28.md)에 원문 보존.

## 6. 보안 검토

정적 검토 범위: `*.sh`, `*.py`, `*.json`, `*.tsx` 전체.

| 점검 항목 | 결과 |
|---|---|
| 원격 다운로드 (`curl`, `wget`) | 없음 |
| 동적 실행 (`eval`, `base64 -d`) | 없음 |
| 파괴적 명령 (`rm -rf`), 권한 상승 (`sudo`) | 없음 |
| 자격 증명·토큰·`process.env` 접근 | 없음 |
| 외부 전송 엔드포인트 | 없음 |
| 심볼릭 링크 | 없음 |
| `install.sh` 동작 | 로컬 `cp`만 수행. 기존 대상은 덮어쓰지 않고 skip |

**남은 위험**

1. `install.sh`는 `~/.claude/skills`·`~/.claude/agents`에 **전역 설치**합니다. CLAUDE.md P2상 별도 승인 대상이며, bash 전용이라 이 PC(Windows)에서 네이티브 실행 불가입니다.
2. 커밋 해시 미확인 → 상류의 특정 시점과 바이트 단위로 대조할 수 없습니다. 무결성 기준선은 2026-08-04 로컬 매니페스트뿐입니다.
3. `skills/web-design-guidelines/scripts/audit.sh`(18 KB)와 `skills/webapp-testing/scripts/*.py`는 정적 검토만 통과했습니다. **격리 환경 런타임 평가 미수행.**
4. `korean-privacy-terms`는 법률 문서를 생성합니다. 산출물의 법적 적합성은 검토 범위 밖이며, 동봉된 `DISCLAIMER.md`가 적용됩니다.

## 7. 검증 상태

**`STATIC_REVIEWED`**

| 등급 | 충족 | 근거 |
|---|---|---|
| `IMPORTED_UNREVIEWED` | ✅ | 출처·라이선스·매니페스트 확보 |
| `STATIC_REVIEWED` | ✅ | 구조·명령·권한·비밀정보 접근 정적 검토 완료 (6절) |
| `RUNTIME_EVALUATED` | ❌ | 격리 환경 발동·안전 동작 평가 미수행 |
| `APPROVED` | ❌ | 설치 승인 없음 |

`~/.agents/skills/`에 이미 배포되어 있다는 사실은 **승인이 아닙니다.** 반입 계약 밖에서 발생한
기존 상태이며, 본 문서로 사후 등록한 것입니다.

## 8. 업데이트 정책

- **자동 업데이트: 금지.** `~/.agents/.skill-lock.json`이 이 패키지를 추적하지 않으므로
  `npx skills` 계열 갱신 대상이 아닙니다.
- 갱신 절차: 상류 저장소 확인 → 새 매니페스트 생성 → 본 문서 3·4절 대조 → 변경분 재검토 →
  등급 재부여. 상류가 갱신되면 **재검토 전까지 `STATIC_REVIEWED`를 유지하지 않습니다.**
- 배포본(`~/.agents/skills/`)을 직접 수정하지 않습니다. 5절 사건이 정확히 그 위반이었습니다.
