# MIA — 내게 맞는 Skills 탐색·적용 결정문

- 작성일: 2026-07-19
- 상태: `VERIFIED_RESULT` (5종 설치 + Claude Code 세션에서 실시간 등록 확인)
- 대상: Claude Code · Codex · Antigravity (노트북, Windows 11)

## 1. 기획 — 무엇을 찾았나

**목표**: 세 도구에서 공통으로 쓸 수 있는 검증된 외부 스킬을 찾아, 사용자 프로필
(비개발자 바이브코더 · 문서/전자책/블로그 · Next.js 웹 · 플랫폼 유지관리)에 맞는 것만
선별 설치한다.

**전제 현황(조사됨)**: 이미 Claude 50종 · Codex 28종 · Antigravity 20종 보유.
→ 따라서 "많이 추가"가 아니라 **빈틈만 메우는 소수 정예 추가**가 옳다 (Net Complexity 원칙).

## 2. 핵심 사실 (웹 딥리서치 결과)

- **SKILL.md 개방 표준**: Anthropic이 시작한 스킬 형식이 2025-12 개방 표준화되어
  세 도구 모두 같은 스킬을 읽는다. 크로스툴 설치기는 Vercel의
  [skills.sh](https://skills.sh) / [`npx skills`](https://github.com/vercel-labs/skills) (70+ 에이전트 지원).
- **설치 위치**: Claude `~/.claude/skills/` · Codex `~/.codex/skills/` ·
  Antigravity `~/.gemini/antigravity/skills/` · 범용 `~/.agents/skills/`.
- **인기 상위**: frontend-design(68만 설치), grill-me(59만), vercel-react-best-practices(56만),
  web-design-guidelines(47만, **이미 보유**), agent-browser(56만, **이미 보유**), tdd(47만).
- [openai/skills](https://github.com/openai/skills) 카탈로그는 **폐기(deprecated)** → OpenAI Plugins로 이동. 참고만.

## 3. /CRITIC — 실패사례·맹점 (가장 중요)

1. **공급망 공격이 실재**: [Snyk ToxicSkills 조사(2026-02)](https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/) —
   공개 스킬 3,984개 중 **13.4%(534개)가 치명 결함**(멀웨어, 프롬프트 인젝션, 비밀 노출),
   36.8%는 결함 1개 이상. ClawHub에선 악성 스킬 1,184개 확인, Claude Code 사용자를 노린
   조직적 멀웨어 캠페인도 보고됨. → **신뢰 배포자 + 설치 전 검수 필수.**
2. **스킬 비대화**: 스킬이 많을수록 목록 컨텍스트가 커지고 오발동이 늘어난다.
   이미 50종을 보유한 상태에서 대형 팩(Superpowers 20+종) 추가는 역효과.
3. **의존 관계 함정**: `grill-me`는 내부적으로 `grilling` 스킬을 호출한다 —
   단독 설치하면 조용히 실패한다. (이번에 발견하여 의존까지 함께 설치)
4. **설치 경로 파편화**: `npx skills`는 Codex·Antigravity 몫을 신표준 `~/.agents/skills/`에
   넣지만, 이 PC의 기존 스킬은 구위치에서 동작 중 → 구위치에도 미러링해 인식을 보장.

## 4. 검토 — 선정과 기각

### 선정 (5종) — 판단 기준: 기존 50종과 비중복 + 사용자 실작업 적합 + 신뢰 배포자

| 스킬 | 출처 | 선정 이유 |
|---|---|---|
| grill-me + grilling | mattpocock/skills (177K★) | 실행 전 요구사항 인터뷰 — "모르는 걸 모르는" 사용자의 최대 리스크(애매한 지시로 잘못 만들기)를 정면으로 해소 |
| writing-guidelines | vercel-labs/agent-skills | 전자책·블로그·문서 작업에 직결 (80+ 산문 감사 규칙). 기존 스킬에 산문 전용 감사 없음 |
| vercel-react-best-practices | vercel-labs/agent-skills | Next.js 프로젝트 성능 규칙 40+. 기존 performance-checker(빌드 점검)와 상호보완 |
| frontend-design | anthropics/skills | UI 독창성 가이드. Claude엔 플러그인으로 기존재 → **Codex·Antigravity에만** 설치(중복 방지) |

### 기각 (이유 기록)

| 후보 | 기각 사유 |
|---|---|
| Superpowers (20+종 팩) | 이미 50종 보유 — 대형 팩은 비대화·오발동 리스크가 이득보다 큼 |
| tdd, improve-codebase-architecture | 개발자용 심화 — 기존 codebase-analyzer·code-review와 중복 |
| Caveman (토큰 65% 절감) | 출력을 뼈대만 남김 — 설명이 필요한 비개발자 사용자와 충돌 |
| claude-mem | Claude 전용 + 이미 자동 메모리 운용 중 |
| web-design-guidelines, agent-browser | **이미 보유** |
| handoff | 자체 HANDOFF 문서 문화가 이미 있음 |

## 5. 실행 기록

```
npx skills add mattpocock/skills        -g -s grill-me grilling -a claude-code codex antigravity -y --copy
npx skills add vercel-labs/agent-skills -g -s writing-guidelines vercel-react-best-practices -a (동일) -y --copy
npx skills add anthropics/skills        -g -s frontend-design -a codex antigravity -y --copy
+ ~/.codex/skills/, ~/.gemini/antigravity/skills/ 에 미러 복사 (구위치 인식 보장)
```

- 보안 검수: 5종 전수 — 악성 패턴(curl/wget/eval/base64) 0건, 외부 URL은 공식 문서 링크뿐.
- frontmatter(name/description) 정상 → 세 도구 모두 로드 가능 형식.

## 6. 검증

- **Claude Code**: 설치 직후 현재 세션에 `grilling`·`writing-guidelines`·`vercel-react-best-practices`가
  실시간 등록됨 — **동작 확인(VERIFIED)**.
- **Codex / Antigravity**: 파일 배치 완료. 앱 재시작 후 스킬 목록(`/skills` 등)에서 확인 필요 — **미검증(재시작 필요)**.

## 7. 운영 수칙 (유지관리)

- 분기 1회 `npx skills update`로 갱신, 안 쓰는 스킬은 `npx skills remove`.
- 새 스킬 추가 시: 신뢰 배포자 확인 → `-l`로 목록 조회 → 설치 → `SKILL.md` 검수 → 이 문서에 기록.
- 스킬 문제 발생 시 `skill-repair` 스킬(기보유)로 수리.
