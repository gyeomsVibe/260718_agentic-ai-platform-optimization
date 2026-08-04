# legacy-harness — Antigravity 시절 로컬 자산 보존

> 윤겸스가 직접 작성했으나 외부 패키지 사본 위에 겹쳐져 있던 자산의 **저장소 정본**입니다.
> 활성 규칙이 아니라 **보존 사본**입니다.

## 왜 여기 있나

`D:\D_Workspace_NB\-agentic-ai-workspace\.agents\`는 외부 패키지
[eli-kardis/vibe-coding-skills](../../external/eli-kardis/vibe-coding-skills/SOURCE.md) 사본인데,
그 위에 시점이 다른 로컬 자산이 겹쳐 있었습니다.

| 파일 | mtime | 상류 존재 |
|---|---|---|
| `rules/Antigravity harness Protocol.clinerules` | 2026-04-25 | ✗ |
| `rules/Python Antigravity Harness Rules.clinerules` | 2026-04-25 | ✗ |
| `rules/harness.md` | 2026-05-10 | ✗ |
| `rules/safety.md` | 2026-05-10 | ✗ |
| `api-review/SKILL.md` | 2026-05-11 | ✗ |
| `frontend-polish/SKILL.md` | 2026-05-11 | ✗ |
| `python-refactor/SKILL.md` | 2026-05-11 | ✗ |

상류 저장소는 skills 24개 / agents 12개이고 `rules/`가 없습니다(2026-08-04 실측).
위 7개는 외부 자산이 아니므로 eli-kardis에게 귀속시키지 않습니다. 원래 위치가
git 비추적 폴더(`.gitignore:13`)라 저장소에 아무 흔적도 없던 상태여서 여기로 분리했습니다.

## 현재 지위

**`rules/` 4개 — 대체됨 (SUPERSEDED)**

`shared/global-rules/core.md`가 글로벌 agent 규칙의 정본입니다. 이 4개 파일의 내용은
core.md의 P2(권한·안전), P4(작업·검증)에 흡수되었고, core.md에만 있는 무오류 오판 방지
5대 조항은 여기에 없습니다. **참조하지 마세요.** 규칙 변천 근거로만 보존합니다.

**Skill 3개 — 휴면 (DORMANT)**

`~/.agents/skills/`에 배포되어 있어 3대 도구에서 발동 가능한 상태입니다. 다만
`api-review`는 `security-audit`과, `frontend-polish`는 `web-design-guidelines`·
`frontend-design`과 범위가 겹칩니다. 정리 여부는 미결이며, 판단 전까지 원본을 여기 보존합니다.

## 배포본과의 관계

이 폴더는 **읽기 전용 보존 사본**입니다. `~/.agents/skills/`나 `.agents/`를 여기서
자동 동기화하지 않습니다. 내용을 고치려면 어느 쪽이 정본인지 먼저 정하세요 —
정본을 지정하지 않은 채 배포본만 편집한 사고가
[SOURCE.md 5절](../../external/eli-kardis/vibe-coding-skills/SOURCE.md)에 기록되어 있습니다.
