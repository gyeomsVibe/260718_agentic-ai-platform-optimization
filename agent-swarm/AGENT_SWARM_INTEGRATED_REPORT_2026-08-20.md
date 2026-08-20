# 3대 AI 도구 상호 오케스트레이션 통합 최종보고서

> **작성일**: 2026-08-20
> **스킬**: MIA 전략절차 (Strategic Hypothesis Verification) — 기획 → 검토 → 실행 → 검증
> **입력 자료 3건**
> 1. `260726_'워크스페이스' agent-swarm_ 에이전트 스웜 (Agent Swarm) 12_33am.md` (이하 **자료 A**)
> 2. `클로드끼리 복붙 셔틀 오늘부로 해고.docx` + 카드뉴스 이미지 7장 (이하 **자료 B**)
> 3. `# 2608010 코덱스로 안티그래비티를 조종하기.docx` + 스크린샷 2장 (이하 **자료 C**)
> **검증 방식**: 공식 문서 웹 리서치 + 이 노트북(MSI GL75 / Windows 11) 실측 명령 실행

---

## 0. 결론 요약 (Executive Summary)

**한 줄 결론**: 자료 A가 2026-07-26에 설계한 "agent-swarm 폴더를 3대 AI의 대화방으로 만든다"는 원안은 **폐기(Pivot)한다.** 그 사이 도구들이 에이전트 간 통신을 제품 기능으로 내장했고, 파일 기반 자작 메시지 버스는 이제 열등한 구현이 되었다. 다만 **이 노트북은 Windows라서 자료 B의 클로드↔클로드 네이티브 메시징을 쓸 수 없다.** 따라서 실제로 작동 가능한 유일한 경로는 **Codex를 오케스트레이터, Antigravity(`agy`)를 실행자, Claude Code를 세션 내부 병렬 처리자로 두는 3층 구조**다.

### 핵심 실측 사실 5가지

| # | 사실 | 근거 | 영향 |
|---|---|---|---|
| 1 | **Claude Code 크로스세션 메시징은 네이티브 Windows에서 지원되지 않는다** | 공식 문서 "Claude Code doesn't offer cross-session messaging on native Windows" | 자료 B의 핵심 기능이 이 PC에서 **작동 불가** |
| 2 | 이 PC의 Claude Code는 **v2.1.220**, 요구 버전은 **v2.1.224 이상** (최신 v2.1.237) | `claude --version` 실측 | 업그레이드해도 OS 제약이 남음 |
| 3 | 이 PC에 **WSL2 배포판이 하나도 설치되어 있지 않다** | `wsl -l -v` → "설치된 배포가 없습니다" | 우회로도 즉시 사용 불가 (별도 설치·승인 필요) |
| 4 | **Antigravity CLI(`agy`) v1.1.16이 설치·인증 완료 상태로 정상 동작한다** | `agy --version`, `agy models` (모델 15종 조회 성공), `agy mcp list` | 자료 C의 경로는 **오늘 당장 가능** |
| 5 | Codex CLI **v0.148.0**이 `mcp`, `mcp-server`, `remote-control`, `exec` 서브커맨드를 모두 보유 | `codex --help` 실측 | Codex가 오케스트레이터 자리에 적합 |

### 자료 3건의 관계 — 같은 문제의 세 층

```mermaid
flowchart LR
  A["자료 A · 2026-07-26<br/>사람이 만든 협업 프로토콜<br/>(Loop방지·JSON규격·HITL)"]
  B["자료 B · 2026-08<br/>동종 도구 A2A의 제품화<br/>(Claude ↔ Claude)"]
  C["자료 C · 2026-08<br/>이종 도구 오케스트레이션 실전<br/>(Codex → Antigravity)"]
  A -->|"규칙이 제품 기능으로 흡수됨"| B
  A -->|"규칙이 여전히 필요한 영역"| C
  B -->|"Windows 미지원 → 대체 필요"| C
```

- **자료 A** = 프로토콜 설계도 (What rules)
- **자료 B** = 동종 도구 간 통신이 제품 기능이 된 사건 (Vendor-internal A2A)
- **자료 C** = 이종 도구 간 통신을 사용자가 직접 엮은 실전 사례 (Cross-vendor orchestration)

세 자료는 경쟁 관계가 아니라 **한 스택의 세 층**이다. 통합 설계는 §4에 있다.

---

## 1. 기획 (Frame the Opportunity)

### 1.1 결정 과제

> "3대 AI 도구(Antigravity, Claude Code, Codex)가 서로 대화하며 협업하게 만들려면, 2026-08-20 현재 **이 노트북에서** 무엇을 어떻게 구성해야 하는가? 그리고 그 로직은 **스킬·글로벌 룰·플러그인 중 무엇으로** 만들어야 하는가?"

### 1.2 목표 성과 (Measurable Success Signal)

| 지표 | 현재 | 목표 |
|---|---|---|
| 사람이 도구 간 복붙하는 횟수 | 작업 1건당 다수 | 0회 (기계 경로로 대체) |
| 사람 승인이 필요한 지점 | 불명확·산발적 | 명시적 게이트 3개 이하 |
| 도구 간 통신의 감사 가능성 | 없음 (채팅창 스크롤) | 파일로 남는 로그 100% |
| 무한 루프 발생 시 정지 | 사람이 눈치채야 함 | 제품 내장 스로틀 + 룰 이중 방어 |

### 1.3 Non-goals (이번에 하지 않는 것)

- 3대 도구를 **동시 상시 구동**하는 자동화 (토큰·전력·주의력 비용 대비 효용 미검증)
- `--dangerously-skip-permissions`를 **기본값**으로 삼는 무인 운전
- WSL2 설치, 외부 MCP 브리지 설치 (§8 승인 필요 항목으로 분리)

### 1.4 Evidence Map

| 구분 | 내용 |
|---|---|
| **검증된 사실** | §0 표 5건, §2 각 자료별 검증 표 |
| **가설** | ① Codex→Antigravity 24시간 반복 루프가 실제로 비용 대비 가치가 있다 ② MCP 계층이 파일 버스보다 유지비가 싸다 |
| **불확실성** | 외부 MCP 브리지(별 2~6개 수준)의 신뢰성, Antigravity 무인 실행의 파일 오염 범위 |
| **불확실성 축소 방법** | §5 최소 실험 3건 |

---

## 2. 전수분석 — 자료별 사실 검증

### 2.1 자료 A: agent-swarm 글로벌 룰 (2026-07-26 설계)

자료 A는 5개 조항군을 제시했다. **13개월이 아니라 3주 만에** 그중 상당수가 제품 내장 기능으로 흡수되었다. 조항별 판정:

| 조항 | 원안 요지 | 2026-08 현재 상태 | 처리 |
|---|---|---|---|
| **1.1 Max Turns** (최대 5턴) | 대화 5회 제한 | Claude Code가 **송신자별 rate limit + 동일 반복 메시지 드롭 + 미읽음 50건 상한**을 내장. "message loop between two sessions therefore stops on its own" | 🔄 **하향 조정** — 제품에 위임하고, 룰은 "턴 수"가 아니라 "목표 미달 시 중단"으로 재작성 |
| **1.2 No Repetition** | 앵무새 금지 | 제품이 짧은 시간창 내 동일 메시지를 자동 드롭 | ✅ **유지** (의미 중복까지는 제품이 못 잡음) |
| **1.3 Self-Termination** | `[STATUS: COMPLETED/FAILED]` 선언 | 제품 기능 없음. 순수 프롬프트 규약 | ✅ **유지 — 여전히 핵심** |
| **2.1 JSON Output Only** | JSON 규격 강제 | ⚠️ **정면 충돌** — 크로스세션 메시지는 **plain text only**로 제한됨. `agy`는 `--output-format json`·`--json-schema` 지원 | 🔧 **분리** — 도구 호출 결과에는 JSON 강제(agy), 세션 간 메시지에는 텍스트 요약 |
| **2.2 Role Definition** | `[Role: X \| Step: n/m]` 머리표 | 제품이 발신자 세션명 + 회신 주소를 자동 첨부 | 🔄 **간소화** — 이름은 제품이, 단계 표기만 룰로 |
| **2.3 Context Chain** | 요약 + ID만 참조 | 제품이 이미 강제 — "never conversation history or files" | ✅ **제품과 일치, 유지** |
| **3.1 Conciseness** | 미사여구 금지 | 제품 기능 없음 | ✅ **유지** |
| **3.2 Lazy Evaluation** | 요청 안 한 것 나열 금지 | 제품 기능 없음 | ✅ **유지** |
| **4.1 Escalation Trigger** | 교착 3회·권한 밖 에러·예산 초과 시 `[CALL_HUMAN]` | 제품이 **권한 프롬프트를 수신 세션에서 그대로 발동**하고, 타 세션 메시지는 **승인으로 인정하지 않음** | ✅ **유지 + 강화** — 제품 보증과 룰이 같은 방향 |
| **4.2 Human Handover** | 3줄 요약 보고 | 제품 기능 없음 | ✅ **유지** |
| **5.1 Data-Driven Priority** | 로그·공식문서·벤치마크 우선 | 제품 기능 없음 | ✅ **유지 — 글로벌 룰 P4와 동일 사상** |
| **5.2 Alternative Proposal** | 단순 거절 금지 | 제품 기능 없음 | ✅ **유지** |

**자료 A 핵심 판정 — 원안의 치명적 전제 오류 1건**

> 원문: *"처음 작업을 하는 ai는 누구든 가장먼저 'agent-swarm' 워크스페이스를 만들어서 3대 AI 도구들의 의사소통공간으로 활용하게 만든다."*

이 전제는 **폐기해야 한다.** 이유:

1. **도구가 서로의 파일을 감시하지 않는다.** 폴더에 메시지를 써도 상대가 폴링하지 않으면 전달되지 않는다. 폴링을 시키면 3대 도구가 유휴 상태에서 토큰을 계속 태운다 — 자료 A 자신의 §3(토큰 최적화)과 모순.
2. **이미 더 나은 전달 경로가 존재한다.** Claude Code는 세션별 UDS 소켓, Antigravity는 `agy` CLI + MCP, Codex는 MCP 클라이언트/서버 양방향. 파일 버스는 이들보다 느리고 신뢰성이 낮다.
3. **실측**: `agent-swarm/` 폴더는 2026-08-20 현재 **완전히 비어 있다.** 7월 26일에 설계된 뒤 3주 넘게 아무 도구도 이 폴더를 쓰지 않았다 — 설계가 실행되지 않았다는 경험적 증거다.

→ **`agent-swarm/`의 새 정체성**: 메시지 버스(❌)가 아니라 **프로토콜 정본 + 오케스트레이션 감사 로그 보관소(✅)**. 이 보고서가 그 첫 파일이다.

---

### 2.2 자료 B: "클로드끼리 복붙 셔틀 오늘부로 해고" (카드뉴스 7장)

카드별 사실 검증. 출처는 Claude Code 공식 문서 `cross-session-messaging`.

| 카드 | 주장 | 판정 | 정확한 사실 |
|---|---|---|---|
| 표지·01 | "클로드 코드 창끼리 직접 메시지를 주고받는다. 창마다 같은 설명 복붙 불필요" | ✅ **사실** | v2.1.224+에서 기본 활성. `ListAgents`로 탐색, `SendMessage`로 전달 |
| 02 | "따로 설정할 것 없이 말로 부탁하면 된다. `/list-agents`로 연결된 창 목록 확인" | ✅ **사실** | `/list-agents`(별칭 `/peers`). 대상 지정은 `@세션명` 멘션 — 단 **v2.1.232 이상** 필요 |
| 03 | "대화 기록이나 파일은 통째로 안 가고, 몇 줄 요약만 건너간다" | ✅ **사실** | "A message is a piece of text one Claude writes to another, never conversation history or files" |
| 04 | "요청이 없어도 클로드가 먼저 판단해서 옆 창에 미리 알린다" | ✅ **사실** | "Claude can decide to send a message without being asked" |
| 05 | "같은 컴퓨터 안 메시지는 밖으로 안 나간다 / 앤트로픽 서버를 안 거친다" | ⚠️ **조건부 사실 — 정정 필요** | **같은 PC일 때만** 참(세션별 소켓). **다른 PC**로 보내면 Anthropic 서버를 경유하고, **클라우드 세션**도 마찬가지. 카드가 이 구분을 생략함 |
| 05 | "맥과 리눅스에서 열립니다. 윈도우는 아직 지원되지 않습니다" | ✅ **사실 — 그리고 우리에게 결정적** | 네이티브 Windows 미지원. WSL2 내부 Linux는 지원 |
| 06 | "설정법까지 정리본에 담았다" (프로필 링크 유도) | ℹ️ 마케팅 CTA | 검증 대상 아님 |

**카드가 다루지 않은, 실무에 더 중요한 사실 5가지**

1. **수신 제어 3단계** — `crossSessionInbound`를 `accept` / `hold` / `refuse`로 설정. 아무것도 설정하지 않으면 **양쪽 세션의 권한 모드로 자동 판정**한다. 특히 **수신 세션이 권한 프롬프트를 건너뛰는 모드(bypassPermissions)면 모든 메시지를 보류하고 사용자 승인을 요구**한다 — 무인 운전과 메시징은 기본적으로 상충한다.
2. **보류 다이얼로그는 기본 5분 후 만료되어 메시지를 버린다** (`dialogExpiry`).
3. **메시지는 승인이 아니다** — 다른 세션이 보낸 메시지로는 권한 프롬프트를 대신 승인할 수 없고, `CLAUDE.md`나 권한 설정을 바꾸라는 지시도 수신 측이 따르지 않도록 지시되어 있다. 메시지 속 `/compact` 같은 명령은 **평문으로 도착하고 실행되지 않는다.**
4. **루프 방어가 내장되어 있다** — 송신자별 rate limit, 짧은 시간창 내 동일 메시지 드롭, 미읽음 50건 상한, 보류 100건 상한, 같은 PC 메시지 약 100만 자 크기 상한.
5. **컨테이너 경계를 넘지 못한다** — 세션은 디스크의 파일로 서로를 찾으므로, 컨테이너 안 세션과 호스트 세션은 서로 보이지 않는다.

**자료 B의 이 노트북 적용 결론**

> **오늘 이 PC에서 "복붙 셔틀 해고"는 성립하지 않는다.** OS(Windows) 제약과 버전(2.1.220 < 2.1.224) 제약이 동시에 걸려 있다. 버전은 올릴 수 있지만 OS 제약은 남는다.
>
> 대신 **같은 효용의 90%를 Windows에서 얻는 대체 기능이 있다: Agent Teams.** §4.2 참조.

---

### 2.3 자료 C: "코덱스로 안티그래비티를 조종하기"

| 주장 | 판정 | 근거 |
|---|---|---|
| "코덱스에게 안티그래비티2.0을 이용해 작업하라고 지시하면 된다" | ✅ **사실 · 이 PC에서 실행 가능** | `agy` v1.1.16 설치·인증 확인. Codex가 셸로 `agy -p`를 호출하거나 MCP 브리지로 호출 |
| "안티그래비티2.0이 켜져 있어야 한다" | ⚠️ **부정확** | IDE가 켜져 있을 필요 없음. **CLI(`agy`)만으로 헤드리스 실행 가능** — `agy -p "프롬프트"`. 단 헤드리스는 캐시된 자격증명을 쓰므로 그 PC에서 **한 번은 대화형 로그인**이 필요 (이 PC는 완료 상태) |
| "질문 없이 원샷으로 일하게 세팅 수정해 달라고 요청하라" | ⚠️ **작동하지만 위험** | 실체는 `--dangerously-skip-permissions`(전체 자동 승인) 또는 `--mode accept-edits`. §8 위험 항목 |
| "24시간 동안 이 작업을 지시하고, 결과 분석 후 다시 지시하며 반복" | ⚠️ **기술적으로 가능 · 통제 설계 필수** | 스크린샷에서 "Iteration 10", "목표: 앞으로 24시간 동안 C:\hom..." 확인. 이것이 **자료 A의 Rule 1.1(최대 5턴)을 정면으로 위반**하는 구성 |
| "모델을 작업에 맞게 바꿔가며 일한다. 3.6 하이/미디엄/로우, 오퍼스, 소넷" | ✅ **사실** | `agy models` 실측: `gemini-3.7/3.6/3.5-flash-{high,medium,low}`, `gemini-3.1-pro-{high,low}`, `claude-sonnet-4-6`, `claude-opus-4-6-thinking`, `gpt-oss-120b-medium` — 총 15종 |
| "화면 명령 때는 3.1 프로를 쓴다" | ✅ **스크린샷 일치** | Antigravity IDE 하단 모델 선택기 "Gemini 3.1 Pro (High)" 확인 |
| "폰에서 호출 중심으로 코덱스가 일한다" | ✅ **사실** | 스크린샷 하단 "AlonicsPC에서 작업", 모델 "GPT-5.6-Sol 중간". Codex `remote-control`(start/stop/pair) 서브커맨드 실측 확인 — 폰에서 페어링해 PC 세션을 조종 |
| "안티그래비티가 지시를 어기면 코덱스가 발견하고 수정한다" | ✅ **사실 · 그리고 이것이 이 구조의 핵심 가치** | 스크린샷: *"안티그래비티가 '파일 생성 금지' 지시에도 자체 결과 파일 1개를 만든 표시가 보입니다... git status에는 새 변경이 없으므로 우선 파일 위치를 확인하고"* — **교차 검증(cross-verification) 루프가 실제로 작동한 증거** |

**자료 C의 진짜 발견**

카드뉴스식 "신기하다"를 걷어내면, 자료 C가 실증한 것은 **감독자-실행자 분리(supervisor-executor separation)** 다. 같은 모델이 자기 작업을 검토하면 앵커링에 걸리지만, **다른 벤더의 모델이 검토하면 지시 위반을 잡아낸다.** 이것은 Claude Code 공식 문서가 Agent Teams의 대표 사용례로 드는 "경쟁 가설 조사(competing hypotheses)"와 같은 원리이며, 2026년 멀티에이전트 연구가 지목하는 최대 실패 모드("아무도 태스크를 소유하지 않아 서로 재계획만 반복")를 **소유권을 한 명에게 고정**함으로써 회피한다.

---

## 3. 검토 (Make the Decision Auditable)

### 3.1 대안 3가지

| | **대안 A — 파일 버스** (자료 A 원안) | **대안 B — 네이티브 A2A 총력** (자료 B 노선) | **대안 C — MCP 오케스트레이션 계층** (자료 C 확장) |
|---|---|---|---|
| 구조 | `agent-swarm/`에 JSON 메시지를 쓰고 각 도구가 읽음 | WSL2 설치 → Ubuntu 안에서 Claude Code 세션들끼리 네이티브 메시징 | Codex가 오케스트레이터, `agy`가 실행자, Claude Code는 세션 내부 병렬 |
| **Value** | ▲ 낮음 — 아무도 폴더를 읽지 않아 3주간 미사용 | ● 중간 — 클로드끼리만 해결. Antigravity·Codex는 여전히 고립 | ★ **높음 — 3대 도구를 실제로 연결하고, 교차 검증까지 얻음** |
| **Feasibility** | ● 가능하나 폴링 비용 | ▲ **낮음 — WSL2 미설치 + 워크스페이스가 `D:\` 네이티브 경로 + 컨테이너/WSL 경계 문제** | ★ **높음 — `agy`·`codex` 모두 설치·인증 완료 상태** |
| **Viability** | ▲ 유휴 토큰 소모가 자료 A 자신의 §3과 모순 | ● 개발 환경 이중화 유지비 큼 | ● **토큰비 상승 있음. 승인 게이트로 통제 가능** |
| **Risk** | ● 낮음 (아무 일도 안 일어남) | ● 중간 (환경 이주 실패 시 롤백 비용) | ▲ **높음 — 무인 자동승인이 최대 위험. 완화책 §8** |
| 판정 | ❌ **No-Go** | ⏸ **Research More** | ✅ **Go** |

### 3.2 Decision Gate

> **Go — 대안 C.** 단, 자료 C의 원형(24시간 무인 반복 + 전체 자동승인)을 그대로 쓰지 않고 **승인 게이트 3개를 삽입한 형태**로 채택한다.
> **Pivot — 자료 A.** `agent-swarm/`을 메시지 버스에서 프로토콜 정본·감사 로그 보관소로 전환.
> **Research More — 대안 B.** WSL2 이주는 별도 과제로 분리 (§8).

---

## 4. 통합 설계 — MIA Swarm v2

### 4.1 3층 구조

```mermaid
flowchart TD
  H["👤 윤겸스<br/>승인 게이트 3개만 담당"]

  subgraph L1["1층 · 오케스트레이션 (Codex)"]
    CX["Codex CLI v0.148<br/>목표 분해 · 지시 · 결과 검토 · 위반 적발"]
  end

  subgraph L2["2층 · 실행 (Antigravity)"]
    AG["agy CLI v1.1.16<br/>headless -p · 모델 15종 선택<br/>대량·반복 작업 수행"]
  end

  subgraph L3["3층 · 심층 분석 (Claude Code)"]
    CC["Claude Code v2.1.x<br/>Agent Teams (in-process)<br/>세션 내부 병렬 조사·리뷰"]
  end

  AS["📁 agent-swarm/<br/>프로토콜 정본 + 감사 로그"]

  H -->|"게이트 1: 목표 승인"| CX
  CX -->|"agy -p / MCP 호출"| AG
  AG -->|"JSON 결과 (--output-format json)"| CX
  CX -->|"교차 검증: 지시 위반 적발"| AG
  H -->|"게이트 2: 파괴적 작업 승인"| CX
  CX -.->|"복잡한 조사 위임"| CC
  CC -.->|"합의된 결론"| CX
  CX -->|"게이트 3: 커밋·푸시 전 보고"| H
  CX --> AS
  CC --> AS
```

### 4.2 Windows 가용성 매트릭스 (이 노트북 실측 기준)

| 기능 | 이 PC에서 | 근거 | 대체안 |
|---|---|---|---|
| Claude Code **크로스세션 메시징** | ❌ **불가** | 네이티브 Windows 미지원 + v2.1.220 | ↓ Agent Teams |
| Claude Code **Agent Teams** (in-process) | ✅ **가능** | in-process 모드는 "any terminal, no extra setup". `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필요 | — |
| Claude Code **Agent Teams** (split panes) | ❌ 불가 | tmux/iTerm2 필요. "not supported in Windows Terminal" | in-process 사용 |
| Claude Code **subagents** | ✅ 가능 | 이미 이 세션에서 사용 중 | — |
| **`agy` headless 실행** | ✅ **가능·인증완료** | `agy models` 성공 | — |
| **Codex → agy 셸 호출** | ✅ **가능** | 두 CLI 모두 PATH 등록 | — |
| **Codex ↔ Claude Code (MCP)** | ✅ 가능 | `claude mcp serve` + `codex mcp add` 실측 확인 | — |
| **Codex 폰 원격조종** | ✅ 가능 | `codex remote-control start/pair` | — |
| 외부 브리지 `codex-agy-bridge` | ❌ 부적합 | macOS/tmux 전용, `agy 1.0.8` 대상 (우리는 1.1.16 — 버전 드리프트) | 직접 셸 호출 |
| 외부 브리지 `mcp-server-google-antigravity` | ⚠️ 가능하나 보류 | Windows 지원 명시(8.3 단축경로 처리 포함)·MIT. 단 **star 2개 수준의 저성숙도** | §8 승인 후 검토 |

### 4.3 프로토콜 v2 — 자료 A의 재작성본

**설계 원칙: 제품이 보증하는 것은 룰에서 뺀다. 제품이 못 하는 것만 룰로 남긴다.**

```
[MIA Swarm Protocol v2]  — agent-swarm/ 정본

■ S1. 소유권 (Ownership) — v1에 없던 최우선 조항
S1.1 모든 태스크에는 소유자 에이전트가 정확히 1개다. Codex가 기본 소유자다.
S1.2 소유자만 목표를 재정의한다. 실행자(Antigravity)는 재계획하지 않고 결과와 실패를 보고한다.
     ※ 근거: 2026 멀티에이전트 연구가 지목한 1위 실패모드 = "아무도 소유하지 않아 서로 재계획"

■ S2. 종료 (Termination)
S2.1 모든 위임에는 반복 상한과 시각 마감이 함께 붙는다. 둘 중 먼저 오는 것이 이긴다.
S2.2 목표 달성 또는 진전 정지 시 [STATUS: COMPLETED] / [STATUS: FAILED]를 선언하고 즉시 종료한다.
S2.3 같은 원인으로 3회 실패하면 재시도를 멈추고 증거·근본원인·대안을 보고한다. (글로벌 룰 P4와 동일)
     ※ v1의 "최대 5턴"은 삭제 — Claude Code가 rate limit·중복 드롭·미읽음 50건 상한으로 이미 보증

■ S3. 데이터 규격 (Format) — v1 Rule 2.1을 분리 적용
S3.1 도구 호출 결과: 기계 판독 가능 형식 강제. agy는 --output-format json (+ 필요시 --json-schema).
S3.2 에이전트 간 메시지: 평문 요약. Claude Code 크로스세션 메시지는 규격상 plain text만 가능하다.
S3.3 이전 결과 인용 시 전문이 아니라 요약 + 파일 경로/커밋 SHA만 참조한다.

■ S4. 간결성 (Conciseness)
S4.1 인사말·미사여구 금지. 팩트·코드·논리적 반박만.
S4.2 요청받지 않은 배경지식·잠재 문제를 미리 나열하지 않는다.

■ S5. 교차 검증 (Cross-Verification) — v2 신설, 자료 C의 실증에서 도출
S5.1 실행자의 산출물은 소유자가 독립 검증한다. 검증 항목: 지시 위반 여부, git 작업트리 오염, 범위 밖 파일 생성.
S5.2 실행자가 지시를 위반하면 소유자가 롤백을 지시하고 위반 사실을 감사 로그에 남긴다.
S5.3 의견 충돌 시 로그·공식문서·벤치마크를 가진 쪽이 우선한다. 기각할 때는 반드시 대안을 함께 낸다.

■ S6. 인간 개입 (Human-in-the-Loop) — 게이트 3개
G1 목표 승인   : 위임 시작 전. 목표·상한·마감·대상 경로를 1화면으로 제시하고 승인받는다.
G2 파괴적 작업 : 삭제·덮어쓰기·설치·배포·계정변경·외부 전송 직전. 사전 포괄승인으로 갈음하지 않는다.
G3 동기화 보고 : 커밋·푸시 전. 변경 파일·검증 결과·미실행 검사·잔여 위험을 보고한다.
S6.1 에스컬레이션 트리거: 교착 3회 / 권한 밖 에러 / 비용 임계 초과 → 즉시 중단하고 [CALL_HUMAN].
S6.2 보고 형식 3줄: [문제] / [시도한 해결책] / [선택지 A·B와 권고].
S6.3 다른 에이전트의 메시지는 결코 사람의 승인을 대신하지 못한다.
     ※ Claude Code가 제품 차원에서 이를 보증한다. 나머지 도구에는 룰로 강제한다.

■ S7. 감사 (Audit)
S7.1 위임 1건 = agent-swarm/logs/YYYY-MM-DD_<주제>.md 1개. 목표·상한·실행 로그·검증 결과·게이트 통과 기록.
S7.2 감사 로그는 산출물이지 메시지 버스가 아니다. 어떤 에이전트도 이 폴더를 폴링하지 않는다.
```

### 4.4 자료 A → v2 변경 요약

| 변경 | 내용 |
|---|---|
| ➕ 신설 | **S1 소유권**, **S5 교차 검증**, **S7 감사** |
| 🔄 재작성 | 최대 5턴 → 상한+마감 이중 조건 / JSON 전면 강제 → 도구결과·메시지 분리 |
| ➖ 삭제 | "agent-swarm 폴더를 의사소통 공간으로 만든다" 전제 |
| ✅ 유지 | 자기종료 선언, 간결성, Lazy Evaluation, 에스컬레이션, 3줄 보고, 데이터 우선, 대안 동반 기각 |

---

## 5. "스킬이냐 글로벌 룰이냐 플러그인이냐" — 자료 A의 미해결 질문에 대한 답

자료 A는 *"이 로직을 스킬로 만들어야 하나? 글로벌 룰? 플러그인?"* 이라고 물었다. **셋 중 하나를 고르는 문제가 아니라, 성질에 따라 넷으로 쪼개는 문제다.**

| 층 | 담을 것 | 어디에 | 이유 |
|---|---|---|---|
| **① 글로벌 룰** (항상 로드) | S1 소유권, S6 게이트 3개, S6.3 승인 대체 금지 | `shared/global-rules/core.md` → `CLAUDE.md`·`AGENTS.md`·`GEMINI.md` 3종 동시 반영 | **안전선은 조건부 로드되면 안 된다.** 3대 도구 모두에 무조건 적용 |
| **② 스킬** (필요 시 로드) | S2~S5, S7 절차 전체 — 위임 카드 작성법, 검증 체크리스트, 로그 템플릿 | `skills/custom/mia/mia-swarm/` | 프로젝트 CLAUDE.md 원칙: *"반복 절차와 도메인 상세는 스킬에, 글로벌은 안정적 기본값만"* |
| **③ MCP** (실제 연결) | 도구 간 실제 호출 경로 | `codex mcp add`, `agy mcp add`, `claude mcp serve` | **룰은 연결을 만들지 못한다.** 자료 A가 놓친 층 |
| **④ 플러그인** (배포) | ①+②를 다른 PC/사람에게 옮길 때만 | 나중 | 1인 워크스페이스에는 아직 불필요한 포장. **지금은 하지 않는다** |

> **핵심**: 자료 A는 ③ MCP 층의 존재를 몰랐기 때문에 "폴더 대화방"이라는 대체재를 발명해야 했다. ③이 있으면 폴더 버스는 필요 없다.

---

## 6. 실행 (Deliver the Smallest Useful Proof)

승인 전이므로 **아직 아무것도 실행하지 않았다.** 아래는 제안하는 최소 검증 실험이다.

### 실험 1 — Codex → Antigravity 단발 위임 (가장 작은 증명)

- **목적**: 자료 C의 경로가 이 PC에서 실제로 작동하는지 확인
- **방법**: Codex에게 안전한 읽기 전용 과제 1건을 `agy -p --output-format json`으로 위임시키고, Codex가 결과를 검증하게 한다
- **수용 기준**: ① 결과가 JSON으로 회수됨 ② 프로젝트 git 작업트리에 변경 0건 ③ Codex가 결과를 요약 보고
- **상한**: 1회, 10분. 자동승인 플래그 **미사용**
- **롤백**: 불필요 (읽기 전용)

### 실험 2 — Codex의 지시 위반 적발 능력 검증

- **목적**: 자료 C의 최대 가치인 교차 검증이 재현되는지 확인
- **방법**: `agy`에 "파일 생성 금지" 제약을 건 과제를 주고, Codex가 산출물과 `git status`를 대조해 위반을 잡아내는지 관찰
- **수용 기준**: 위반이 발생하면 Codex가 **사람보다 먼저** 지적한다
- **상한**: 2회 반복, 20분

### 실험 3 — Claude Code Agent Teams (Windows 대체 경로 검증)

- **목적**: 크로스세션 메시징 없이도 병렬 협업이 되는지 확인
- **방법**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 설정 후, 읽기 전용 조사 과제에 팀메이트 3명 투입
- **수용 기준**: 팀메이트가 서로 메시지를 주고받고 리드가 결론을 통합
- **주의**: 실험적 기능. 팀메이트당 컨텍스트 창이 따로 있어 **토큰 소모가 크게 증가**한다. 세션 재개(`/resume`) 시 in-process 팀메이트는 복원되지 않는다
- **롤백**: 환경변수를 `0`으로 되돌리면 즉시 원복 (재시작 불필요)

---

## 7. 검증 (Close the Learning Loop)

| 실험 | 성공 임계치 | 판정 시 조치 |
|---|---|---|
| 1 | JSON 회수 성공 + git 오염 0 | 통과 → 실험 2 / 실패 → MCP 브리지 검토(§8) |
| 2 | 위반 1건 이상 자동 적발 | 통과 → S5를 정식 채택 / 실패 → 교차 검증을 사람 검토로 되돌림 |
| 3 | 팀메이트 간 메시지 왕복 확인 | 통과 → 3층 확정 / 실패 → Claude Code는 단일 세션 + subagent로 축소 |

**측정할 것**: 실험당 소요 시간, 토큰 소모 증가율, 사람 개입 횟수, 적발된 위반 건수.
**Iterate / Scale / Stop 판단**은 세 실험이 모두 끝난 뒤 이 문서에 추가 기록한다.

---

## 8. 위험 및 별도 승인이 필요한 항목

| # | 항목 | 위험 | 권고 |
|---|---|---|---|
| R1 | **`--dangerously-skip-permissions` 상시 사용** (자료 C의 "질문 없이 원샷") | 전체 도구 승인 자동 통과. 삭제·덮어쓰기·설치도 무승인 통과. 글로벌 룰 P2 정면 위반 | **상시 사용 금지.** 읽기 전용·샌드박스 과제에 한해 건별 승인. 대안: `--mode accept-edits` + `--sandbox` |
| R2 | **24시간 무인 반복 루프** | 비용·파일 오염·되돌리기 어려운 변경 누적. 자료 C 스크린샷에서 이미 "지시 위반 파일 생성" 1건 발생 | 마감 + 반복 상한 이중 조건 필수. 첫 도입은 **1시간·5회** 상한 |
| R3 | **WSL2 설치** (대안 B) | 시스템 설정 변경. 워크스페이스가 `D:\` 네이티브라 경로·성능·권한 이슈 | ⏸ **승인 필요.** 이번 범위 밖 |
| R4 | **외부 MCP 브리지 설치** (`mcp-server-google-antigravity` 등) | star 2~6개 수준 저성숙 패키지가 파일시스템 도구를 노출. 공급망 위험 | ⏸ **승인 필요.** 실험 1이 셸 호출로 성공하면 설치 불필요 |
| R5 | **Claude Code 업그레이드** 2.1.220 → 2.1.237 | 낮음. 다만 Windows에서는 메시징이 여전히 안 열림 | ⏸ 승인 후 진행 권고. Agent Teams 관련 개선 다수 포함 |
| R6 | **Agent Teams 활성화** | 실험적 기능. 명명된 subagent가 팀메이트로 전환되어 **의도치 않은 팀이 생길 수 있고**, subagent 결과를 기다리는 흐름이 멈출 수 있음 | 실험 3에서만 켜고, 끝나면 `0`으로 복귀 |
| R7 | **`crossSessionInbound` 미설정 상태의 무인 운전** | bypassPermissions 세션은 모든 수신 메시지를 보류하고 5분 뒤 폐기 | Windows에서는 해당 없음. WSL 이주 시 반드시 재검토 |

---

## 9. 미실행·미검증 항목 (정직 보고)

- 실험 1·2·3은 **아직 실행하지 않았다.** 승인 대기 상태다.
- `agy -p`로 실제 에이전트 작업을 돌려보지 않았다. 확인한 것은 `--version`, `--help`, `models`, `mcp list` 뿐이다.
- Codex 폰 원격조종은 **서브커맨드 존재만 확인**했고, 페어링을 실제로 수행하지 않았다.
- 자료 B의 크로스세션 메시징은 **이 PC에서 실행 불가**하므로 실측하지 못했다. 판정 근거는 전부 공식 문서다.
- `mcp-server-google-antigravity`의 Windows 동작은 **저장소 문서의 주장**이며, 직접 검증하지 않았다.

---

## 10. 출처

**공식 문서**
- [Message your other Claude Code sessions — Claude Code Docs](https://code.claude.com/docs/en/cross-session-messaging)
- [Orchestrate teams of Claude Code sessions — Claude Code Docs](https://code.claude.com/docs/en/agent-teams)
- [Google Antigravity Blog: Subagents, Hooks, Scheduled Tasks, Agent Management, Voice, and Much More](https://antigravity.google/blog/google-io-2026-feature-deep-dive)
- [Codex CLI — ChatGPT Learn](https://developers.openai.com/codex/cli)
- [Subagents — ChatGPT Learn](https://learn.chatgpt.com/docs/agent-configuration/subagents)

**도구 브리지 (미설치·검토 대상)**
- [mcp-server-google-antigravity (TurkerYakup)](https://github.com/TurkerYakup/mcp-server-google-antigravity)
- [codex-agy-bridge (varadfromeast)](https://github.com/varadfromeast/codex-agy-bridge)
- [antigravity-mcp (Theralley)](https://github.com/Theralley/antigravity-mcp)

**해설·튜토리얼**
- [Antigravity CLI: Orchestrating Parallel AI Agents — DataCamp](https://www.datacamp.com/tutorial/antigravity-cli)
- [Antigravity CLI (agy): Commands, Modes, and Auto-Approve — AI Builder Club](https://www.aibuilderclub.com/blog/antigravity-cli-guide)
- [A Developer's Guide to Agent Hooks in Antigravity CLI — Google Cloud Community](https://medium.com/google-cloud/a-developers-guide-to-agent-hooks-in-antigravity-cli-4c1440febd11)
- [Claude Code Cross-Session Messaging: How It Works — claudefa.st](https://claudefa.st/blog/guide/mechanics/cross-session-messaging)
- [Claude Code Cross-Session Messaging Guide (2026) — explainx.ai](https://explainx.ai/blog/claude-code-cross-session-messaging-list-agents-2026)
- [Add the ability to remote control codex from ChatGPT app — openai/codex Discussion #9200](https://github.com/openai/codex/discussions/9200)

**멀티에이전트 연구·업계 분석**
- [When AI Agents Collide: Multi-Agent Orchestration Failure Playbook for 2026 — nasscom](https://community.nasscom.in/communities/ai/when-ai-agents-collide-multi-agent-orchestration-failure-playbook-2026)
- [6 Multi-Agent Orchestration Patterns for Production (2026) — beam.ai](https://beam.ai/agentic-insights/multi-agent-orchestration-patterns-production)
- [Multi-Agent Coordination in 2026: Trust, Isolation, and the Cost of Getting It Wrong — SudoAll](https://sudoall.com/multi-agent-coordination-2026-playbook/)
- [Agent2Agent vs MCP: 2 Protocols Your 2026 Stack Needs — beam.ai](https://beam.ai/agentic-insights/agent2agent-vs-mcp-2026-ai-agent-stack)
- [Governance Gaps in Agent Interoperability Protocols: What MCP, A2A, and ACP Cannot Express — arXiv](https://arxiv.org/pdf/2606.31498)
- [Security Threat Modeling for Emerging AI-Agent Protocols — arXiv](https://arxiv.org/pdf/2602.11327)

**로컬 실측 (2026-08-20, MSI GL75 / Windows 11)**
- `claude --version` → 2.1.220 · `npm view @anthropic-ai/claude-code version` → 2.1.237
- `wsl -l -v` → 설치된 배포판 없음
- `agy --version` → 1.1.16 · `agy models` → 15종 조회 성공 · `agy mcp list` → notebooklm, vibe-clinic
- `codex --version` → codex-cli 0.148.0 · `codex mcp list` → 4개 · `codex remote-control --help` → start/stop/pair
- `claude mcp --help` → `serve` 서브커맨드 확인
- `ls agent-swarm/` → 비어 있음
