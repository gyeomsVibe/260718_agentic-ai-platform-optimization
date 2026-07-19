# GPT를 이용해서 Skills-모드 만들기

> ChatGPT 커스텀 챗봇(설계항해·제작항해)으로 세 도구(Claude Code · Codex · Antigravity)용
> **최상급 Skill을 설계·제작**하는 섹션입니다.

## 핵심 아이디어 — 2단계 분업

```
[1단계: ChatGPT 챗봇]            [2단계: 로컬 에이전트 (Claude Code 등)]
설계항해 → 스킬 PRD·아키텍처       설치 → 실제 발동 테스트 → 검증
제작항해 → SKILL.md 초안 생산  ──→  VERIFIED_RESULT 판정 → 3도구 배포
        (STATIC_CANDIDATE)              (이 저장소 skills/ 수칙 적용)
```

챗봇은 스킬을 **실행할 수 없으므로** 정적 후보(STATIC_CANDIDATE)까지만 만들고,
실행 검증은 로컬 에이전트가 맡습니다. 이 분업이 두 도구의 강점을 모두 살립니다.

## 문서

| 문서 | 내용 |
|---|---|
| [MIA_GPT_CHATBOT_SKILLS_CAPABILITY_REVIEW_2026-07-20.md](MIA_GPT_CHATBOT_SKILLS_CAPABILITY_REVIEW_2026-07-20.md) | **챗봇 역량 검토 보고서** — "이 챗봇으로 얼마나 훌륭한 Skill을 만들 수 있는가?" /CRITIC·/REDTEAM 분석과 보강 권고 |
| [MIA_GPT_CHATBOT_SKILLS_IMPLEMENTATION_PLAN_2026-07-20.md](MIA_GPT_CHATBOT_SKILLS_IMPLEMENTATION_PLAN_2026-07-20.md) | **실제 구현 계획** — 후보군 선별, 데이터 추출·제외 기준, `mia-skill-forge` 단계별 제작·평가·승격 계획 |
| [MIA_SKILL_FORGE_USER_GUIDE_2026-07-20.md](MIA_SKILL_FORGE_USER_GUIDE_2026-07-20.md) | **사용자 학습 가이드** — Skill을 처음 접하는 사람을 위한 개념·사용법·최적화 절차·결과 판독법 |
| [기획·검토·실행 모드 보고서](<../[userfile]/%23%20260720_gpt를 이용해서 Skills-모드 만들기/기획·검토·실행 모드 보고서.md>) | 사용자 작업 폴더 — MIA(plan-review-execute) 스킬 정본 설계 보고서 (이 파이프라인의 첫 후보 사례) |

## 챗봇 원본 위치 (로컬)

- 설계항해 v2.1 (PRD Pack Commander): `D:\D_Workspace_NB\(Ai) Prompt Engineering\1. 설계항해_VibeBlueprint_GPT_PRD_Packager\260708_설계항해 (設計航海)_v2.1\`
- 제작항해 v4.7 R2 (Package A Production Commander): `...\2. 제작항해 (製作航海)_VibeBlueprint GPT Builder\260701_제작항해 (製作航海)_v4.7_모듈_재설계\`

> 챗봇 지시문 원문은 개인 자산이라 이 저장소에는 커밋하지 않습니다. 경로만 기록합니다.

## 운영 원칙

- 챗봇 산출물은 `STATIC_CANDIDATE`로 받습니다.
- 공통 `SKILL.md`와 플랫폼별 확장을 분리합니다.
- 로컬 에이전트가 구조·보안·발동·실행·회귀를 검증합니다.
- 관찰 증거가 합격 기준을 충족할 때만 `VERIFIED_RESULT`로 승격합니다.
