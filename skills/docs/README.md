# Skills Documentation Index

이 폴더는 \skills/\ 섹션의 배포, 매뉴얼, 기획서, 검증 결과 및 분석 문서를 시간순 및 목적별로 정리·색인하는 정본 저장소입니다.

## 📑 타임라인 및 일련 문서 (Chronological & Milestone Series)

| 번호 | 문서명 | 작성/개정일 | 주요 내용 |
|---|---|---|---|
| **01** | [01_DEPLOYMENT.md](01_DEPLOYMENT.md) | 2026-07-20 | 3대 AI 도구별 Skill 선별 배포 현황 및 근거 (정본) |
| **02** | [02_MANUAL.md](02_MANUAL.md) | 2026-08-05 | 초보자용 Skill 사용 매뉴얼, 호출 트리거 및 도구별 실행법 |
| **03** | [03_260719_MIA_PLATFORM_SLIM_AUDIT.md](03_260719_MIA_PLATFORM_SLIM_AUDIT.md) | 2026-07-19 | 플랫폼 스킬 슬림화 1차 감사 기록 |
| **04** | [04_260719_MIA_SKILLS_EXPLORATION.md](04_260719_MIA_SKILLS_EXPLORATION.md) | 2026-07-19 | MIA 에이전트 스킬 생태계 탐색 및 구조 설계서 |
| **05** | [05_260805_MIA_SKILL_PORTFOLIO_REDTEAM.md](05_260805_MIA_SKILL_PORTFOLIO_REDTEAM.md) | 2026-08-05 | 스킬 포트폴리오 레드팀 검증 및 위험도 분석 |
| **06** | [06_260806_MIA_TRIGGER_VERIFICATION_PLAN.md](06_260806_MIA_TRIGGER_VERIFICATION_PLAN.md) | 2026-08-06 | 스킬 트리거 발동 검증 계획 및 시험 설계 |
| **07** | [07_260911_MIA_SKILL_COMPILER_IMPLEMENTATION_PLAN.md](07_260911_MIA_SKILL_COMPILER_IMPLEMENTATION_PLAN.md) | 2026-09-11 | MIA Skill Compiler 및 skill-creation-bible 최적화 정제 구현 계획서 (Alternative 2) |
| **08** | [08_260911_MIA_SKILL_COMPILER_FULL_ANALYSIS_REPORT.md](08_260911_MIA_SKILL_COMPILER_FULL_ANALYSIS_REPORT.md) | 2026-09-11 | MIA Skill Compiler 3대 도구 최적화 정제 및 KMGS-QVRC 체계 전수분석 종합보고서 |
| **09** | [09_260804_MODULAR_INTELLIGENCE_AGENT_CONCEPT.md](09_260804_MODULAR_INTELLIGENCE_AGENT_CONCEPT.md) | 2026-08-04 | 모듈형 인공지능 에이전트(Modular Intelligence Agent) 개념 정리 |
| **10** | [10_260806_MIA_TRIGGER_VERIFICATION_LEDGER.json](10_260806_MIA_TRIGGER_VERIFICATION_LEDGER.json) | 2026-08-06 | 스킬 트리거 발동 검증 원장 (기계 판독용 JSON, 06 계획서의 결과 기록) |
| **11** | [11_260905_GPT_CHEATKEY_MODES_REVISED_SOURCE.md](11_260905_GPT_CHEATKEY_MODES_REVISED_SOURCE.md) | 2026-09-05 | P1. GPT 실전 치트키 모드 검증형 개정판 (slash-prompt-modes 원자료) |
| **12** | [12_260905_GPT_CHEATKEY_MODES_ANALYSIS_REPORT.md](12_260905_GPT_CHEATKEY_MODES_ANALYSIS_REPORT.md) | 2026-09-05 | GPT 실전 치트키 모드 전수분석 및 독립 Skill 설계 근거 |

## 🧭 문서 작성 및 관리 원칙
- **`skills/` 섹션의 문서 보관소는 이 `skills/docs/` 하나뿐입니다.** 보고서·분석·원자료·검증 원장을 위해 `research/`, `reports/`, `analysis/` 같은 별도 폴더를 만들지 않습니다. 2026-09-13에 `skills/research/` 6개 파일을 이 폴더(07~12)로 통합했고, 같은 폴더가 다시 생기면 `npm run check`(`skills:test`)가 실패합니다.
- 새 문서는 이 폴더에 다음 순차 번호(`13_`, `14_`, ...)와 날짜 접두어(`YYMMDD_`)로 생성하고, 생성 직후 이 README 목차에 등재합니다.
- 파일명에는 공백·대괄호를 쓰지 않습니다. 링크가 URL 인코딩으로 깨지기 쉽기 때문입니다.
- Skill 실행 패키지 안의 `references/`·`validation-evidence/`는 해당 Skill과 함께 배포되는 자료이므로 이 규칙의 대상이 아닙니다.