# MIA 사용자 제작 Skills 카탈로그

> MIA(Modular Intelligence Architect) 시리즈의 실행 정본과 제작/테스트 워크벤치를 통일 관리합니다.

---

## 📂 카탈로그 디렉터리 구성

| 디렉터리 | 스킬 명칭 | 한글명 / 풀네임 | 역할 및 내용 |
|---|---|---|---|
| [`1_mia-skill-compiler/`](1_mia-skill-compiler/) | `mia-skill-compiler` | MIA 스킬 컴파일러 | 아이디어·GPT·문서·코드·URL·기존 스킬을 조사·PRD·후보 생성·검증하는 스킬 제작 워크벤치 (candidates·evals·fixtures·reports). 정본은 `candidates/mia-skill-compiler/`. |
| [`2_mia-vaccine-test/`](2_mia-vaccine-test/) | `mia-vaccine-test` | MIA 백신테스트 | 실패를 일부러 만들어(주입·변이·실사용) 숨은 결함을 찾고, 확정 결함마다 vibe-clinic 진단으로 항체를 남겨 재발을 막는 스킬. |
| [`3_mia-strategic/`](3_mia-strategic/) | `mia-strategic` | **'MIA 전략절차' 스킬** | **전략적 가설 검증 스킬 (Strategic Hypothesis Verification Skill)** — 기획·검토·실행·검증 4단계. 구 `plan-review-execute` 를 개명. |

> `mia-skill-forge` 는 `mia-skill-compiler` 에 흡수·폐기되어 전역에서 제거했다. 이력은
> `1_mia-skill-compiler/candidates/mia-skill-forge/` 에만 남긴다(워크벤치 기록).

---

## 🚀 3대 AI 에이전트 전역 설치 (통일 완료: 2026-07-25)

정본은 **이 카탈로그**다. 아래 세 도구의 전역 스킬 폴더에 정본을 그대로 배포한다.

| 에이전트 | 전역 스킬 경로 |
|---|---|
| Claude Code | `~/.claude/skills/<스킬>/` |
| Antigravity (Gemini) | `~/.gemini/config/skills/<스킬>/` |
| Codex | `~/.codex/skills/<스킬>/` |

- 배포 규약: 각 도구의 `skills/<스킬>/SKILL.md` (이중 중첩 `<스킬>/<스킬>/` 금지)
- 로컬 워크스페이스 사본: `.agents/skills/`
- **활성화 정본 3대 스킬**: `mia-skill-compiler` · `mia-vaccine-test` · `mia-strategic`
- 배포본은 SKILL.md 외 `references/`·`agents/openai.yaml` 을 함께 포함한다.
