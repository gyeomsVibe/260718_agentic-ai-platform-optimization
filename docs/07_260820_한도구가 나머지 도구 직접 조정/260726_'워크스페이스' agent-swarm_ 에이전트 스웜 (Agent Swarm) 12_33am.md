# **260726\_'워크스페이스' agent-swarm/ 에이전트 스웜 (Agent Swarm) 12:33am**

## **\#  니가 안티그래비와 로컬 워크스페이스 안에서 각 3자 ai들이 서로 대화할 수 있니?**

AI 에이전트들이 모여 협업하는 'agent-swarm' 워크스페이스의 효율성을 극대화하기 위한 글로벌 룰(Global Rules) 로직입니다.  
\- **에이전트 스웜 (Agent Swarm)** \~로직을 웹딥리서치를 이용하여 사례, 연구논문, 각 ai 공식 채널, 기사, 블로그, 유튜브, 깃허브 등 커뮤니티를 탐색하여 조사해줘.  
이 로직은 AI들 간의 **무한 루프 방지**, **데이터 규격화**, **토큰(비용) 절약**, 그리고 **인간 관리자와의 소통 가이드라인**을 핵심으로 합니다. 프롬프트나 시스템 설정에 그대로 복사해서 사용할 수 있도록 영어와 한글을 혼용하여 직관적으로 작성했습니다.

## 🤖 \[Global Rules\] Workspace: agent-swarm

## 1\. Loop Prevention & Termination (무한 루프 방지 및 종료 조건)

**Rule 1.1 (Max Turns):** 어떤 태스크도 AI 간의 대화를 최대 5회(Turn) 이상 지속할 수 없다. 5회 이내에 결론을 도출해야 한다.  
**Rule 1.2 (No Repetition):** 이전 에이전트가 한 말이나 코드를 그대로 반복(Parroting)해서는 안 된다. 반드시 새로운 정보나 수정 사항을 추가해야 한다.  
**Rule 1.3 (Self-Termination):** 목적이 달성되었거나 더 이상 진전이 없을 경우, 즉시 \[STATUS: COMPLETED\] 또는 \[STATUS: FAILED\]를 선언하고 대화를 종료한다.

## 2\. Communication Protocol (대화 및 데이터 규격)

**Rule 2.1 (JSON Output Only):** 에이전트 간 데이터나 결과물을 주고받을 때는 텍스트 요약본과 함께 반드시 지정된 JSON 포맷을 포함해야 한다.  
**Rule 2.2 (Role Definition):** 모든 메시지의 서두에 자신의 역할(Role)과 현재 단계(Step)를 명시한다. (예: \[Role: Code Reviewer | Step: 2/3\])  
**Rule 2.3 (Context Chain):** 이전 에이전트의 결과물을 인용할 때는 핵심 요약(Summary)과 데이터 ID만 참조하여 콘텍스트 길이를 최소화한다.

## 3\. Resource & Token Efficiency (리소스 및 토큰 최적화)

**Rule 3.1 (Conciseness):** 친절한 인사말이나 불필요한 미사여구(예: "좋은 의견입니다", "감사합니다")는 생략한다. 오직 팩트, 코드, 논리적 반박만 전송한다.  
**Rule 3.2 (Lazy Evaluation):** 상대 AI가 요청하지 않은 과도한 배경 지식이나 잠재적 문제점까지 미리 나열하지 않는다. 질문을 받은 핵심에만 집중한다.

## 4\. Human-In-The-Loop (인간 관리자 개입 조건)

**Rule 4.1 (Escalation Trigger):** 다음 3가지 상황에서는 AI 간 대화를 즉시 중단하고 인간 관리자에게 이스컬레이션(\[CALL\_HUMAN\])해야 한다.  
동일한 논쟁이 3회 이상 평행선을 달릴 때 (Deadlock)  
API 오류 등 시스템 권한 밖의 에러가 발생했을 때  
예산/비용 임계치를 초과하는 대규모 연산이 필요할 때  
**Rule 4.2 (Human Handover):** 인간에게 보고할 때는 \[문제 상황\], \[AI들이 시도한 해결책\], \[선택 가능한 대안 A/B\]를 3줄 이내로 요약하여 전달한다.

## 5\. Conflict Resolution (의견 충돌 해결 로직)

**Rule 5.1 (Data-Driven Priority):** 에이전트 간 의견이 충돌할 경우, 주관적 추론보다 '실제 실행 데이터(Log)', '공식 문서(Documentation)', '벤치마크 점수'를 가진 에이전트의 의견을 우선순위로 둔다.  
**Rule 5.2 (Alternative Proposal):** 상대방의 의견을 기각(Reject)할 때는 반드시 대안(Alternative)을 함께 제시해야 한다. 단순 거절은 허용되지 않는다.  
\---  
프로젝트를 시작하자마자, 계획을 세우기전에 처음 작업을 하는 ai는 누구든 가장먼저 "agent-swarm" 워크스페이스를 만들어서 3대 AI 도구 (Antigravity, Claude Code, Codex) 들의 의사소통공간으로 활용하게 만든다. 로직도 연구해줘.  
\- 가장 우선시 되는 것은 무조건 이 **에이전트 스웜 (Agent Swarm)** 로직을 3대 AI 도구 (Antigravity, Claude Code, Codex)들이 100% 활용하여 프로젝트의 협업을 최적화하는 거다.  
\- 이 로직을 스킬로 만들어야 하나? 아니면 글로벌 룰 또는 플로그인으로 만들어야 최적화할 수있나? 연구해줘  
\- **MIA 전략절차 스킬 수행해줘** \- 이제 연구를 시작하자.