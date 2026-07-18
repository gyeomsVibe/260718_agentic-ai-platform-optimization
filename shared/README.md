# Shared — 3개 플랫폼 공용 자료

Claude Code · Codex · Antigravity가 함께 쓰는 정본(Source of Truth)과 플러그인을 관리한다.

| 항목 | 내용 |
|---|---|
| [global-rules/](global-rules/) | 전역 행동 규칙 영문 정본 v2.0.1 — `core.md` + 도구별 어댑터 → `dist/`(CLAUDE.md·AGENTS.md·GEMINI.md) 생성. 동기화: `scripts/sync-global-rules.ps1` |
| [global-rules-writing-plan.md](global-rules-writing-plan.md) | 글로벌 룰 작성 계획 문서 |
| [platform-auto-update.md](platform-auto-update.md) | Codex·Claude Code·Antigravity 로그인 자동업데이트 운영 가이드 및 검증 절차 |
| [platform-auto-update/](platform-auto-update/) | Windows 시작 프로그램이 실행하는 VBS 스크립트 정본과 처음 사용하는 사람을 위한 알림·점검 안내 |
| [plugins/mia-modular-intelligence-architect/](plugins/mia-modular-intelligence-architect/) | MIA 플러그인 v1.0.0 — 기획·검토·실행 모드(`plan-review-execute` 스킬) 정본. 동기화: `scripts/sync-mia-skills.ps1` |
| [skills/plan-review-execute/](skills/plan-review-execute/) | plan-review-execute 스킬 (Claude용 CLAUDE-SKILL.md, Codex용 openai.yaml 포함) |

> 장착 위치: Claude `~/.claude/CLAUDE.md` · Codex `~/.codex/AGENTS.md` · Antigravity `~/.gemini/GEMINI.md`
> 규칙 수정은 반드시 이 정본에서 하고 sync 스크립트로 배포한다. dist를 직접 고치지 않는다.
