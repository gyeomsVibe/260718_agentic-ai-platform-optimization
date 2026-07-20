# Shared — 3개 플랫폼 공용 자료

> Claude Code · Codex · Antigravity가 **함께 쓰는** 규칙·플러그인 배포 어댑터·자동화를 모아 둡니다.
> 특정 도구 하나에만 해당하는 자료는 각 도구 폴더(`claude/`·`codex/`·`antigravity/`)에 있습니다.

## 먼저 알아둘 개념

- **정본(Source of Truth)**: "원본은 여기 하나뿐"이라는 뜻. 규칙을 여러 곳에 복사해 두면
  서로 어긋나므로, **한 곳(정본)에서만 고치고** 스크립트로 각 도구에 배포합니다.
- **어댑터 → dist**: 공통 규칙(`core.md`)에 도구별 특성(`adapters/`)을 얹어, 각 도구가
  실제로 읽는 최종 파일(`dist/`)을 자동 생성합니다. **`dist/`를 직접 고치지 마세요.**

## 항목

| 항목 | 내용 |
|---|---|
| [global-rules/](global-rules/) | 전역 행동 규칙 영문 정본 v2.0.1 — `core.md` + 도구별 어댑터 → `dist/`(CLAUDE.md·AGENTS.md·GEMINI.md) 생성. 동기화: `scripts/sync-global-rules.ps1` |
| [global-rules/history.md](global-rules/history.md) | 글로벌 룰 작성·적용 이력 |
| [platform-auto-update/OPERATIONS.md](platform-auto-update/OPERATIONS.md) | Codex·Claude Code·Antigravity 로그인 자동업데이트 운영 가이드 및 검증 절차 |
| [platform-auto-update/](platform-auto-update/) | Windows 시작 프로그램이 실행하는 VBS 스크립트 정본과 처음 사용하는 사람을 위한 알림·점검 안내 |
| [plugins/mia-modular-intelligence-architect/](plugins/mia-modular-intelligence-architect/) | MIA 플러그인 패키지·배포 어댑터. Skill 정본을 읽어 각 플랫폼 배포본을 확인·동기화합니다. |
| [../skills/plan-review-execute/](../skills/plan-review-execute/) | MIA `plan-review-execute`의 유일한 편집 정본 (Claude·Codex 어댑터 포함) |

> 장착 위치: Claude `~/.claude/CLAUDE.md` · Codex `~/.codex/AGENTS.md` · Antigravity `~/.gemini/GEMINI.md`
> 규칙 수정은 반드시 이 정본에서 하고 sync 스크립트로 배포한다. dist를 직접 고치지 않는다.
