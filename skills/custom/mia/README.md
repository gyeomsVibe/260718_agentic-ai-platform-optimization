# MIA 사용자 제작 Skills (Custom MIA Agent Skills)

> 윤겸스 소유의 MIA(Modular Intelligence Architect) 시리즈 Agent Skill 정본과 제작 작업대를 통일 관리합니다.
> 이 디렉터리는 3대 AI 에이전트(Antigravity, Claude Code, Codex) 공용 커스텀 스킬의 **정통 소스(Canonical Source)**입니다.

---

## 📦 커스텀 MIA 스킬 카탈로그 (Skill Catalog)

| 스킬 폴더 | 스킬명 (Name) | 트리거 및 용도 | 주요 파일 |
|---|---|---|---|
| [`mia-skill-compiler/`](mia-skill-compiler/) | `mia-skill-compiler` | `$mia-skill-compiler` / 새 Agent Skill 구체화 및 정밀 컴파일 | `SKILL.md`, `references/` |
| [`mia-skill-forge/`](mia-skill-forge/) | `mia-skill-forge` | `$mia-skill-forge` / GPT·챗봇·문서를 정적 Agent Skill 후보로 변환 | `SKILL.md`, `references/` |
| [`plan-review-execute/`](plan-review-execute/) | `plan-review-execute` | `MIA모드 발동` / 기획·검토·실행·검증 4단계 프로세스 | `SKILL.md`, `agents/`, `plugin/` |
| [`compiler-workbench/`](compiler-workbench/) | `compiler-workbench` | MIA 스킬 후보 실험실, evals, fixtures, reports | `candidates/`, `evals/`, `fixtures/` |

---

## ⚙️ 관리 규칙 및 배포 경계 (Management Policy)

1. **정본 원칙 (Canonical Source)**:
   - 모든 MIA 커스텀 스킬의 정본은 오직 `skills/custom/mia/<skill-name>/` 아래에 위치합니다.
   - `.agents/skills/`, `.claude/skills/`, `.codex/skills/`, `~/.gemini/config/skills/` 등 플랫폼 폴더의 파일은 동기화된 타깃본(Target)입니다.
2. **폴더 명명 규칙**:
   - 스킬 폴더명은 반드시 소문자 케밥케이스(`kebab-case`)를 사용합니다.
3. **단일 정본 관리**:
   - 정본 변경 시 `npm run check` 또는 동기화 스크립트로 전역 플랫폼에 일괄 배포합니다.
