# Skills 섹션 — 세 도구의 "기술 카드" 관리

> **스킬(Skill)이 뭔가요?** AI 에이전트에게 주는 **요리 레시피 카드**입니다.
> "글 감사는 이 80가지 규칙으로 해" 같은 전문 절차를 카드 한 장(폴더 하나)에 적어 두면,
> 에이전트가 관련 작업을 할 때 그 카드를 꺼내 읽고 그대로 따라 합니다.
> 세 도구(Claude Code · Codex · Antigravity) 모두 같은 카드 형식(`SKILL.md` 개방 표준)을 읽습니다.

## 1. 내 PC의 스킬은 어디에 있나

| 도구 | 전역(모든 프로젝트) 위치 | 현재 보유 (2026-07-19 슬림화 후) |
|---|---|---|
| Claude Code | `~/.claude/skills/` | 37종 |
| Codex | `~/.codex/skills/` | 16종 |
| Antigravity | `~/.gemini/antigravity/skills/` | 14종 |
| (범용) | `~/.agents/skills/` | 37종 — 여러 도구가 함께 읽는 새 표준 위치 |

> 안 쓰는 GCP 데이터 팩 17종은 격리 제거했습니다 — 무엇을 왜 뺐는지는
> [MIA_PLATFORM_SLIM_AUDIT_2026-07-19.md](research/MIA_PLATFORM_SLIM_AUDIT_2026-07-19.md) 참조.

> `~`는 내 사용자 폴더(`C:\Users\Kimyoongyeom`)입니다.

## 2. 발동법 — 스킬은 어떻게 켜지나

- **자동 발동**: 요청 내용이 스킬 설명과 맞으면 에이전트가 알아서 꺼내 씁니다.
  예: "이 글 문체 검토해줘" → `writing-guidelines`가 자동 발동.
- **수동 발동**: 이름을 직접 부릅니다.
  - Claude Code: `/스킬이름` (예: `/grill-me`)
  - Codex: `/skills` 로 목록 확인, 또는 `$스킬이름` 멘션
  - Antigravity: 채팅에 스킬 이름을 언급하거나 요청 내용으로 자동 매칭

## 3. 이번에 새로 설치한 스킬 5종 (2026-07-19)

| 스킬 | 무엇을 해주나 | 이렇게 말하면 발동 | 대상 도구 |
|---|---|---|---|
| **grill-me** (+의존: grilling) | 계획을 실행하기 **전에** 에이전트가 나를 집요하게 인터뷰해서 애매한 부분·빠진 결정을 전부 찾아냄. "모르는 걸 모르는" 상태를 없애는 스킬 | "이 계획 그릴미 해줘", `/grill-me` | 3도구 모두 |
| **writing-guidelines** | 문서·블로그·전자책 원고를 **80+ 규칙**으로 감사 (어조, 구조, 타이포그래피) | "이 글 문체 검토해줘", "docs 리뷰해줘" | 3도구 모두 |
| **vercel-react-best-practices** | React/Next.js 코드를 Vercel 엔지니어링의 **성능 규칙 40+**로 점검·작성 | Next.js 코드 작업 시 자동 발동 | 3도구 모두 |
| **frontend-design** | 템플릿 티가 나지 않는 **독창적 UI 디자인** 방향·타이포·색 선택 가이드 (설치 수 67만+, Anthropic 공식) | UI 새로 만들 때 자동 발동 | Codex·Antigravity만* |

> *Claude Code에는 같은 내용의 `frontend-design` 플러그인이 이미 활성화되어 있어 중복 설치하지 않았습니다.

### 활용 예시 (그대로 따라 해보세요)

```
① 새 기능을 만들기 전:  "블로그에 구독 기능을 넣고 싶어. grill-me 해줘."
   → 에이전트가 질문 공세로 요구사항을 확정한 뒤에 만들기 시작합니다.
② 전자책 원고를 쓴 후:  "이 챕터 writing-guidelines로 감사해줘."
③ Next.js 페이지가 느릴 때: "이 페이지 성능 점검해줘."  (react-best-practices 자동 발동)
```

## 4. 스킬 추가·업데이트·제거 (셀프서비스)

[skills.sh](https://skills.sh) 디렉터리에서 찾고, 한 줄로 설치합니다:

```
npx skills find 검색어                          ← 스킬 찾기
npx skills add <소유자/저장소> -g -s <스킬이름> -a claude-code codex antigravity -y --copy
npx skills update                               ← 전체 업데이트
npx skills remove -g -s <스킬이름> -y            ← 제거
```

> `--copy`는 Windows에서 심링크 문제를 피하는 안전 옵션입니다.
> 설치기가 Codex·Antigravity 몫을 `~/.agents/skills/`에 넣는 경우, 확실한 인식을 위해
> `~/.codex/skills/`와 `~/.gemini/antigravity/skills/`에도 복사해 둡니다(이번 적용 방식).

## 5. ⚠️ 보안 수칙 — 스킬은 "에이전트 권한으로 실행되는 남의 지시문"

2026-02 Snyk 조사에서 공개 스킬 3,984개 중 **13.4%가 치명 결함**(멀웨어 배포, 프롬프트
인젝션, 비밀정보 노출)으로 확인됐습니다. 반드시 지키세요:

1. **신뢰 배포자만**: `anthropics/`, `openai/`, `vercel-labs/`, 검증된 유명 개발자(예: mattpocock) 위주.
2. **설치 전 내용 보기**: `npx skills add <저장소> -l` 로 목록만 먼저 확인. 설치 후 `SKILL.md`를 열어
   이상한 명령(curl로 뭘 내려받기, base64, 비밀번호 요구)이 없는지 확인. (이번 5종은 전수 스캔 완료 — 이상 없음)
3. **적을수록 좋다**: 스킬이 많으면 컨텍스트가 무거워지고 잘못 발동할 확률이 올라갑니다.
   "안 쓰는 스킬은 제거"가 원칙입니다.

## 6. 관련 문서

- [MIA_SKILLS_EXPLORATION_2026-07-19.md](research/MIA_SKILLS_EXPLORATION_2026-07-19.md) — 왜 이 5종을 골랐고 무엇을 기각했는지 (리서치 근거·기각 사유)
- [MIA_PLATFORM_SLIM_AUDIT_2026-07-19.md](research/MIA_PLATFORM_SLIM_AUDIT_2026-07-19.md) — 전수조사·슬림화 감사 (제거 근거·복원 방법·재발 방지 수칙)
- [MIA Skill Compiler 작업대](mia-skill-compiler-workbench/) — 초기 아이디어·문서·기존 Skill을 세 도구용 후보로 설계·검증하는 파이프라인
- [plan-review-execute](plan-review-execute/) — 우리가 직접 만든 검증 대상 공용 Skill의 유일한 편집 정본

모든 Skill 정본과 후보는 이 `skills/` 아래에 둡니다. `shared/plugins/` 안의
Skill 파일은 플러그인 패키징·배포에 필요한 생성본이며 직접 수정하지 않습니다.
