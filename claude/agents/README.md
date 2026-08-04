# Claude Code 서브에이전트 정본

> 배포 대상: `~/.claude/agents/`. **이 폴더가 정본이고 배포본은 사본이다.**
> 배포본만 편집하지 마라 — 그 사고 기록이
> [SOURCE.md 5절](../../skills/external/eli-kardis/vibe-coding-skills/SOURCE.md)에 있다.

## 유래

[eli-kardis/vibe-coding-skills](../../skills/external/eli-kardis/vibe-coding-skills/SOURCE.md)(MIT)의
에이전트 12개에서 **4개를 선별해 재작성**한 파생물이다. 원본은 어느 경로에도 배포된 적이 없었다.

## 선별 결과 (2026-08-04)

선별 기준은 ⓐ 워크스페이스 실측 기술 스택, ⓑ 내장 기능과의 중복이다.

### 배포 (4개)

| 에이전트 | model | 근거 |
|---|---|---|
| `api-architect` | opus | express 4/39 프로젝트. 대응 내장 기능 없음 |
| `frontend-design-specialist` | sonnet | react 11/39, next 4/39. `artifact-design`은 아티팩트 전용이라 실제 앱 UI를 못 덮음 |
| `test-writer` | sonnet | vitest 7/39. 테스트 작성 전담 내장 에이전트 없음 |
| `technical-writer` | haiku | 문서 비중이 큰 저장소. `/init`은 CLAUDE.md만 다룸 |

### 제외 (8개)

| 에이전트 | 제외 근거 |
|---|---|
| `devops-engineer` | **Docker 0건, Terraform 0건, K8s 0건** — 대상 자체가 없음 |
| `supabase-db-specialist` | **package.json 39개 중 supabase 의존성 0개** |
| `security-specialist` | 내장 `/security-review`와 중복 |
| `architecture-reviewer` | 내장 `/code-review`·`simplify`와 중복 |
| `project-planner` | 내장 `Plan` 에이전트와 중복 |
| `product-strategist` | `product-thinking` 스킬과 중복 |
| `ux-researcher` | `product-thinking` + `error-path-analysis`와 중복 |
| `performance-optimizer` | 호출 빈도 낮고 `simplify`가 부분 대체 |

제외본 원본은 `.agents/agents/`(git 비추적)에 그대로 있다. 삭제하지 않았다.

## 정제 시 제거한 것

원본 12개 모두 **해소되지 않는 의존성**을 프런트매터에 갖고 있었다. 이 PC는 플러그인 0개
설치, `~/.claude/skills/`에 MIA 3개뿐이다(2026-08-04 실측).

- `skills:` 항목 전부 — `superpowers:*`, `document-skills:*`는 플러그인 미설치.
  `security-audit`·`web-design-guidelines` 등은 `~/.agents/skills/`에 있으나 Claude Code는
  `~/.claude/skills/`를 읽으므로 발견되지 않는다.
- `debate:` 블록 전부 — `debate` 스킬이 Claude Code에서 발견되지 않는다. 죽은 메타데이터.

**허위 능력 주장 제거**: 원본 `frontend-design-specialist`는 "접근성 규칙 100+를 자동 적용"을
표방했으나 근거였던 `web-design-guidelines` 스킬이 해소되지 않는다. 자체 체크리스트를 본문에
넣고, 실제 확인한 항목만 보고하도록 능력 경계를 명시했다.

**실측 기반 재조준**: `test-writer`는 Playwright 전제였으나 워크스페이스에 Playwright는
0/39이고 vitest가 7/39다. vitest 우선으로 바꾸고, E2E는 러너 부재를 먼저 보고하도록 했다.
`api-architect`의 Supabase Auth 절은 의존성 0개라 제거했다.

## 공통 추가

원본에 없던 **안전 경계** 절을 4개 모두에 넣었다 — 승인 없는 외부 실행 금지, 비밀정보
비노출, 미검증 사항을 검증했다고 보고 금지. 저장소 글로벌 룰(P2·P4·P7)과 정렬한다.

## 배포·검증

```bash
cp claude/agents/*.md ~/.claude/agents/
```

```powershell
# 배포본 정합성 (기대값: 불일치 0)
$a="claude\agents"; $b="$env:USERPROFILE\.claude\agents"
Get-ChildItem "$a\*.md" -Exclude README.md | ForEach-Object {
  $t=Join-Path $b $_.Name
  "{0,-34} {1}" -f $_.Name, ((Test-Path $t) -and (Get-FileHash $_).Hash -eq (Get-FileHash $t).Hash)
}
```

배포 후 **새 세션**에서 에이전트 목록에 4개가 보이는지 확인해야 실제 발견이 증명된다.
파일 해시 일치는 설치 무결성만 증명한다.
