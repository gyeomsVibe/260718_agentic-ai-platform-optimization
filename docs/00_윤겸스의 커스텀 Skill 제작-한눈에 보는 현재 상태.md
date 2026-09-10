\## 한눈에 보는 현재 상태



윤겸스의 커스텀 Skill 제작은 \*\*기초 설계와 후보 제작은 상당히 진행됐지만, 핵심 신제품인 “MIA Skill Compiler”는 아직 세 도구에서 실제로 검증되지 않은 후보 단계\*\*입니다.



쉽게 말해:



\- `plan-review-execute`는 지금 쓰는 \*\*MIA 기획·검토·실행 도구\*\*입니다.

\- `MIA Skill Compiler`는 아이디어를 받아 새 Skill을 만들어 주려는 \*\*차세대 제작기\*\*입니다.

\- 제작기는 설계·평가표까지 준비됐지만, Codex·Claude Code·Antigravity에서 “정말 보이고, 호출되고, 안전하게 동작하는지”는 아직 증명되지 않았습니다.



\## 지금 만들어진 것



| 구분 | 현재 상태 | 쉬운 설명 |

|---|---|---|

| MIA 기획·검토·실행 | 사용 중 | `MIA모드 발동` 시 기획 → 검토 → 실행 → 검증 흐름을 안내합니다. |

| MIA Skill Compiler | 후보 제작 완료 | 아이디어·GPT 설계·문서·코드·기존 Skill을 받아 공통 Agent Skill 후보로 만들도록 설계했습니다. |

| 빠른 제작 로직 | 설계 반영 | 기본은 빠른 경로(FAST)로 진행하고, 정말 필요한 경우에만 심층 조사·대안 비교를 하게 했습니다. |

| 10개 사고 모드 | 설계 반영 | SELFREFINE, REDTEAM, ELI10, DEEPDIVE, ALT3, CRITIC, OPTIMIZE, STEPBYSTEP, EXPERT, 구조화 Few-Shot을 지원하도록 계약했습니다. |

| 안전장치 | 설계 반영 | Skill 생성과 전역 설치·외부 실행·배포를 같은 권한으로 묶지 않고, 설치 직전에 별도 승인을 요구합니다. |

| 평가 시나리오 | 작성 완료 | Compiler 후보에는 명시 호출·비발동·안전·예산·품질·플랫폼 경계를 검사하는 39개 사례가 있습니다. |



근거: \[전체 Skill 지도](https://github.com/gyeomsVibe/260718\_agentic-ai-platform-optimization/blob/main/skills/README.md), \[MIA 사용자 제작 Skill 안내](https://github.com/gyeomsVibe/260718\_agentic-ai-platform-optimization/blob/main/skills/custom/mia/README.md), \[현재 MIA 실행 Skill](https://github.com/gyeomsVibe/260718\_agentic-ai-platform-optimization/blob/main/skills/custom/mia/plan-review-execute/SKILL.md)



\## 가장 중요한 미완료 항목



`MIA Skill Compiler`의 평가 기록은 현재 `awaiting\_discovery\_confirmation`입니다. 즉, “파일을 잘 작성했다”는 단계이지 “세 도구에서 실제로 작동한다”는 단계는 아닙니다. \[평가 계약](https://github.com/gyeomsVibe/260718\_agentic-ai-platform-optimization/blob/main/skills/custom/mia/compiler-workbench/evals/mia-skill-compiler/cases.json)



아직 확인해야 할 것은 다음입니다.



\- Codex, Claude Code, Antigravity 각각의 새 작업에서 Skill 목록에 실제로 나타나는지

\- `$mia-skill-compiler` 명시 호출이 정확히 발동하는지

\- 일반 문장에는 오발동하지 않는지

\- 설치·덮어쓰기·외부 API 실행 요청에서 멈추고 별도 승인을 요구하는지

\- 만든 Skill 후보가 기존 Skill보다 실제로 나은지



현재 Codex의 Available skills에는 `plan-review-execute`는 보이지만 `mia-skill-compiler`는 보이지 않습니다. 따라서 Compiler를 “완성·성공”이라고 부르면 안 됩니다.



\## 예전 Forge는 어떻게 됐나



`mia-skill-forge`는 폐기된 쓰레기 자료가 아니라, 이전 후보와 회귀 검사 근거로 남아 있습니다. 새 중심 이름과 설계는 \*\*MIA Skill Compiler\*\*이며, Forge는 호환성·오발동 방지 검증에 사용됩니다. \[Compiler 작업대](https://github.com/gyeomsVibe/260718\_agentic-ai-platform-optimization/blob/main/skills/custom/mia/compiler-workbench/README.md), \[Forge 평가 기록](https://github.com/gyeomsVibe/260718\_agentic-ai-platform-optimization/blob/main/skills/custom/mia/compiler-workbench/evals/mia-skill-forge/cases.json)



\## 다음 한 걸음



문서를 더 늘리는 것보다, Compiler를 각 플랫폼의 \*\*임시 Skill 위치에만 설치\*\*한 뒤 아래 순서로 실측하는 것이 맞습니다.



1\. 새 작업에서 Skill 노출 확인  

2\. 명시 호출 1건 실행  

3\. 오발동·설치 승인·안전 거부 사례 실행  

4\. 세 플랫폼 결과를 분리 기록  

5\. 통과한 범위만 정식 승격 검토  



이 단계는 전역 설치와 외부 실행을 건드리므로, 실행 직전에 대상·복구 방법을 명시한 별도 승인이 필요합니다.



이번 브리핑은 GitHub `main` 원격을 읽기 전용으로 조사한 결과이며, 워크스페이스 변경·커밋·푸시는 하지 않았습니다.

