# vibe-coding-skills (eli-kardis) — 로컬 운용 기록

> 외부 Skill 패키지 1건에 대한 반입 등록입니다. 출처·라이선스·무결성·보안 검토는
> [`SOURCE.md`](SOURCE.md)가 정본입니다.

## 이 폴더가 정본이 아닌 것

계약의 표준 구조는 `external/<publisher>/<skill-name>/`이지만, 이 반입물은 **Skill 27개를
담은 패키지 하나**입니다. 27개 폴더를 만들어 원본을 복제하는 대신 패키지 단위로 1건 등록하고,
원본 파일은 저장소 밖에 두었습니다. 저장소에는 **원장과 증거만** 둡니다.

| 역할 | 위치 | git |
|---|---|---|
| 원본 파일 169개 | `D:\D_Workspace_NB\-agentic-ai-workspace\.agents\` | 비추적 (`.gitignore:13`) |
| 배포본 | `~/.agents/skills/` (3대 도구 공용 경로) | 비추적 |
| **출처 원장** | `SOURCE.md` | 추적 |
| **무결성 기준선** | `MANIFEST.sha256` | 추적 |
| **드리프트 증거** | `evidence/` | 추적 |

원본을 저장소로 옮기지 않는 이유: `.agents/`는 이미 `.gitignore` 대상이고, MIT 외부 코드
1.22 MiB를 정본 저장소에 복제하면 상류 갱신 시 정본이 둘로 갈라집니다.

## 구성 (실측 2026-08-04)

- 파일 169개 / 폴더 68개 / 1,283,227 B
- `skills/` 27개 폴더 — 상류 24개 + 로컬 추가 3개
- `agents/` 12개 `.md` — **어느 경로에도 배포된 적 없음** (`~/.claude/agents/` 비어 있음)
- `rules/` 4개 — 로컬 자산, 배포 이력 없음
- 로컬 추가분 3+4개는 [`../../../custom/legacy-harness/`](../../../custom/legacy-harness/)로 분리 보관

## 검증 방법

```powershell
# 1. 원본 무결성 — MANIFEST.sha256과 대조 (SOURCE.md 3절의 재생성 명령 사용)
# 2. 스테이징 ↔ 배포본 일치 확인
$a="D:\D_Workspace_NB\-agentic-ai-workspace\.agents\skills"; $b="$env:USERPROFILE\.agents\skills"
$ha=@{}; Get-ChildItem -Recurse -Force -File $a | ForEach-Object { $ha[$_.FullName.Substring($a.Length+1)]=(Get-FileHash $_.FullName -Algorithm MD5).Hash }
$hb=@{}; Get-ChildItem -Recurse -Force -File $b | ForEach-Object { $hb[$_.FullName.Substring($b.Length+1)]=(Get-FileHash $_.FullName -Algorithm MD5).Hash }
@($ha.Keys | Where-Object { -not $hb.ContainsKey($_) -or $hb[$_] -ne $ha[$_] })   # 기대값: 빈 결과
```

```powershell
# 3. 플랫폼 오염 재발 감시 (기대값: 잔존 0건)
Select-String -Path "$env:USERPROFILE\.agents\skills\*\SKILL.md" `
  -Pattern '\.Codex|Codex Opus|Codex in Chrome|sync-Codex-md' -CaseSensitive
```

> ⚠️ **2026-08-05 정정**: 이 문서는 앞서 `~/.agents/skills/`를 "3대 도구가 함께 읽는
> 공용 경로"라고 적었습니다. **틀렸습니다.**
>
> 새 Claude Code 세션(`claude -p`)에 사용 가능 스킬을 나열시킨 결과, `~/.claude/skills/`의
> MIA 3개와 내장 스킬만 보였고 **`~/.agents/skills/`의 40개는 하나도 보이지 않았습니다.**
> Claude Code는 이 경로를 읽지 않습니다.
>
> **3대 도구 CLI 전수 확인 완료 (2026-08-05)**
>
> | 도구 | 확인 명령 | `~/.agents/skills` 40개 |
> |---|---|---|
> | Claude Code | `claude -p` | **0개** |
> | Codex | `codex exec` | **36개 정상 인식** (나머지 4개는 은닉 설계대로) |
> | Antigravity | `agy --print` | **0개** |
>
> **결론: 이 패키지는 Codex 에서만 살아 있습니다.** Claude Code 와 Antigravity 에서는
> 발동되지 않습니다. `~/.agents/skills` 는 공용 경로가 아니라 **Codex 전용 경로**입니다.
> Codex 에서 `failed to load skill` 오류는 0건이었습니다.
>
> 세 도구 모두에서 쓰려면 각 도구의 루트에 따로 배포해야 합니다. 다만 27개를 전부
> 배포하면 목록 비대화로 오발동이 늘어나므로, 필요한 것만 선별하는 편이 낫습니다.

특정 도구 이름·경로를 하드코딩한 편집은 다른 도구에서 오작동하므로, 3번 검사는
배포본을 손댄 뒤 실행합니다.

## 알려진 결함 (상류 원본에 존재)

| 결함 | 영향 | 상태 (2026-08-04) |
|---|---|---|
| `skills/product-thinking/`에 `SKILL.md` 없음 | 영구 발동 불가 | **해소** — `SKILL.md` 신규 작성, 스테이징·배포본 동일 적용 |
| `korean-privacy-terms` 한국어 이용약관 템플릿 2개가 0 바이트 | 기본값 `outputLocale: ko`에서 **빈 법률 문서가 조용히 생성** | **완화** — 조문 창작은 하지 않고, 0바이트 감지 시 중단하는 가드를 `SKILL.md`에 추가. 근본 결함은 상류에 잔존 |
| `README.md`가 24개라 표기 / `marketplace.json` 부재 | 문서 부정확, `/plugin marketplace add` 실패 | **해소** — 로컬 README 정정 |

세부 변경 내역은 [`SOURCE.md` 4-1절](SOURCE.md)에 있습니다.

## 승격 경계

현재 등급 `STATIC_REVIEWED`. 다음 단계인 `RUNTIME_EVALUATED`로 올리려면 격리 환경에서
발동·안전 동작 평가가 필요하며, `~/.claude/`로의 전역 설치는 **별도 승인 대상**입니다.
현재 `~/.agents/skills/` 배포는 계약 밖에서 발생한 기존 상태를 사후 등록한 것이지 승인이 아닙니다.
