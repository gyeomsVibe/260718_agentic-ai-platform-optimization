# MIA 사용자 제작 Skills 카탈로그

> MIA(Modular Intelligence Architect) 시리즈의 실행 정본과 제작/테스트 워크벤치를 통일 관리합니다.

## 📖 새 스킬을 만들거나 고치기 전에

**[제작 교본 — AUTHORING_HANDBOOK.md](AUTHORING_HANDBOOK.md) 를 먼저 읽는다.**

3대 도구 중 가장 엄격한 Codex 기준으로 고정한 제작 절차·준수 규격·검증 회로가 담겨 있고,
`scripts/validate-skill-manifests.py` 가 이를 배포 단계에서 강제한다. 규격 위반은 배포가 중단된다.

| 알고 싶은 것 | 문서 |
|---|---|
| 제작 절차·규격·검증 회로 | [AUTHORING_HANDBOOK.md](AUTHORING_HANDBOOK.md) ← **진입점** |
| 설계 철학 (20개 불변 원칙) | [skill-creation-bible.md](1_mia-skill-compiler/candidates/mia-skill-compiler/references/skill-creation-bible.md) |
| 플랫폼별 설치 경로·어댑터 계약 | [platform-skill-contracts.md](1_mia-skill-compiler/candidates/mia-skill-compiler/references/platform-skill-contracts.md) |
| 결함 주입·변이 진단 프로토콜 | [vaccine-protocol.md](2_mia-vaccine-test/references/vaccine-protocol.md) |

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

## 🚀 3대 AI 에이전트 전역 설치

정본은 **이 카탈로그**다. 아래 세 도구의 전역 스킬 폴더에 정본을 그대로 배포한다.

| 에이전트 | 전역 스킬 경로 |
|---|---|
| Claude Code | `~/.claude/skills/<스킬>/` |
| Antigravity (Gemini) | Compiler·Vaccine은 `~/.gemini/config/skills/<스킬>/`, Strategic은 `~/.gemini/config/plugins/mia-modular-intelligence-architect/` |
| Codex | `~/.codex/skills/<스킬>/` |

- 배포 규약: 각 도구의 `skills/<스킬>/SKILL.md` (이중 중첩 `<스킬>/<스킬>/` 금지)
- 로컬 워크스페이스 사본: `.agents/skills/`
- **활성화 정본 3대 스킬**: `mia-skill-compiler` · `mia-vaccine-test` · `mia-strategic`
- 배포본은 SKILL.md 외 `references/`·`agents/openai.yaml` 을 함께 포함한다.

현재 정합성을 확인하거나 승인된 전역 배포를 수행할 때는 카탈로그 동기화 도구를 사용한다.

```powershell
./scripts/sync-mia-catalog.ps1 -Mode Check
./scripts/sync-mia-catalog.ps1 -Mode Apply
```

`Apply`는 기존 설치본을 `~/.mia-skill-backups/<timestamp>/`에 보존한 뒤 정확한 정본으로
교체한다. 현재 작업에서 실제 발견되는 공용 사용자 경로 `~/.agents/skills/`와 워크스페이스
`.agents/skills/`도 함께 맞춘다. 파일 일치는 다음 새 작업의 런타임 발견을 대신하지 않는다.
