# Claude Code 플러그인 설치·관리 기록 (노트북)

> **플러그인(Plugin)이 뭔가요?** Claude Code에 기능을 더하는 **스킬·명령 묶음**입니다.
> 마켓플레이스(플러그인 상점)에서 설치하며, 설치하면 관련 작업 때 Claude가 알아서 꺼내 씁니다.
> 이 문서는 **이 노트북의 Claude Code에 실제로 설치된 플러그인**의 정본 기록입니다.
> (플러그인 3층위 개념은 [README.md](README.md) 참조 · 노트북과 데스크톱은 별개 PC)

## 1. 현재 설치된 플러그인 (user scope, ✔ enabled)

| 플러그인 | 버전 | 마켓플레이스 | 구성 | 상시 토큰 | 역할 |
|---|---|---|---|---|---|
| **superpowers** | 6.1.1 | `superpowers-dev` (obra/superpowers) | 스킬 14개 + SessionStart 훅 | ~715 tok | 계획·TDD·병렬 에이전트·코드리뷰·디버깅 등 핵심 워크플로우 |
| **frontend-design** | (official) | `claude-plugins-official` | 스킬 1개 | ~78 tok | UI "AI 슬롭" 제거, 사람이 만든 듯한 독창적 디자인 |

> 무거운 스킬(subagent, writing-skills 등)은 **호출 시에만** 로드되어 평소 부담이 적습니다.
> 플러그인 스킬은 **세션 시작 시 로드** → 설치·변경 후 **Claude Code 재시작**해야 반영됩니다.

## 2. 등록된 마켓플레이스

| 마켓 | 출처 |
|---|---|
| `claude-plugins-official` | git · anthropics/claude-plugins-official |
| `anthropic-agent-skills` | github · anthropics/skills |
| `superpowers-dev` | github · obra/superpowers |

## 3. 설치 배경 (2026-07-23, 영상 근거)

"유명한 Claude Code 플러그인" 소개 영상(6종)을 전수분석하고 **필요한 것만 선별 설치**했습니다.
선정·기각의 상세 근거와 재평가 기록은 [`../skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md`](../skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md)의 "재평가(2026-07-23)" 절에 있습니다.

**설치 안 한 것과 이유 (중복·리스크 회피):**
- **Code Review / Security Review** → Claude Code **내장 `/code-review`·`/security-review`** + Superpowers가 커버 → 재설치 불필요
- **Claude Memo** → 기존 `~/.claude` 메모리 + CLAUDE.md 체계와 중복
- **Stack (gstack)** → 자동 배포·23스킬 대형팩 + Store 무결성 충돌 → **No-Go** (판단 근거는 skills 문서 참조)

## 4. 관리 명령 (설치·확인·롤백)

```bash
claude plugin list                                  # 설치 목록
claude plugin marketplace add <owner/repo>          # 마켓 등록
claude plugin install <plugin>@<marketplace>        # 설치
claude plugin details <plugin>                      # 구성·토큰 비용 확인
claude plugin disable <plugin>                       # 끄기(가역)
claude plugin uninstall <plugin>@<marketplace>       # 제거
```

## 5. 사용법 (재시작 후)

- **자동 발동**: 요청이 스킬 설명과 맞으면 알아서 발동. 예: "이 기능 만들기 전에 계획부터"(writing-plans),
  "TDD로 구현해줘"(test-driven-development), "병렬 에이전트로 리뷰해줘"(dispatching-parallel-agents), UI 작업 시 frontend-design.
- **진입점**: Superpowers는 `using-superpowers` 스킬이 안내자 역할.

## 관련
- 플러그인 3층위 개념·계정 커넥터 정리: [environment-notebook.md](environment-notebook.md)
- 스킬 탐색·슬림화 정본: [`../skills/`](../skills/)
