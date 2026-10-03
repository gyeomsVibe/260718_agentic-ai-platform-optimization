# v7.0.0 재작성 추적표

v7.0.0은 v6.2.1의 전역 규칙 80줄을 누더기처럼 고치지 않고 새로 썼다. "미니멀라이징이라고 생략·누락하면 설계·구현 실패"라는 조건을 지키기 위해, 옛 줄 하나하나가 새 규칙의 어디로 갔는지를 이 표에 남긴다. 옛 줄 원문은 [`tests/fixtures/v621_bullets.tsv`](../tests/fixtures/v621_bullets.tsv)에 ID와 함께 보존했다.

읽는 법:

- ID 앞 글자는 옛 위치다. `C`는 core, `X`는 Codex 어댑터, `L`은 Claude 어댑터, `A`는 Antigravity 어댑터다. `N`은 v7.0.0에서 새로 생긴 규칙이다.
- `«…»` 안의 글은 새 규칙(`core.md`와 `adapters/*.md`)에 글자 그대로 있어야 하는 핵심 문구다. [`tests/v700_rewrite_check.py`](../tests/v700_rewrite_check.py)가 이 표를 읽어 모든 핵심 문구가 실제로 있는지, 옛 ID가 하나도 빠지지 않았는지 검사한다.
- 상태가 `합침`이면 다른 줄과 겹쳐 한 줄로 합쳤다는 뜻이다. `삭제`면 이유를 비고에 적었다. 삭제된 줄의 뜻을 다른 규칙이 이어받으면 그 문구를 핵심 문구로 적었다.

| ID | 새 위치 | 핵심 문구 | 상태 | 비고 |
|---|---|---|---|---|
| C01 | core UAOS-RSI | «the installed runtime» | 유지 | |
| C02 | core UAOS-RSI | «marks a UAOS-RSI project» | 유지 | "never through the user"는 자율 절이 이어받았다 |
| C03 | core UAOS-RSI | «Operate first» | 유지 | |
| C04 | core UAOS-RSI | «Card loop: receipt» | 유지 | |
| C05 | core UAOS-RSI | «Authority: Codex conducts while ACTIVE» | 유지 | |
| C06 | core UAOS-RSI | «never convert a remaining-quota percentage» | 유지 | "each adapter sets..."는 머리말과 겹쳐 뺐다 |
| C07 | core UAOS-RSI | «Self-improvement makes evidence only» | 유지 | |
| C08 | core UAOS-RSI | «No paid cron or polling» | 유지 | |
| C09 | core 소통 | «Lead with the outcome» | 유지 | 한눈 줄을 프로젝트·카드·PR·프로세스 전체로 넓혔다 |
| C10 | core 소통 | «beginner-complete» | 유지 | |
| C11 | core 소통 | «`ACK_ONLY`» | 유지 | |
| C12 | core 방법 | «re-plan from Frame» | 옮김 | 재계획은 MIA 기획 단계로 돌아가는 일이라 방법 절로 옮겼다 |
| C13 | core 자율 | «internal dependencies, not user work» | 옮김 | |
| C14 | core 자율 | «run a terminal check» | 옮김 | |
| C15 | core 자율 | «Never hand prompts, commands, or work to the user» | 옮김 | |
| C16 | core 안전 | «Never read, print, or commit secrets» | 유지 | |
| C17 | core 안전 | «Only these wait for 윤겸스» | 유지 | |
| C18 | core 안전 | «Exception: scratch files» | 유지 | |
| C19 | core 안전 | «`.work/backup_<date>/`» | 유지 | |
| C20 | core 안전 | «Never weaken sandboxing» | 유지 | |
| C21 | core 안전 | «standing approval (2026-09-28)» | 유지 | |
| C22 | core 안전 | «never transfers to other actions» | 유지 | |
| C23 | core 안전 | «Delegated agents and local engines inherit these limits» | 유지 | |
| C24 | core 소유권 | «Check `git status` before editing» | 유지 | |
| C25 | core 소유권 | «Stage only your own paths» | 유지 | |
| C26 | core 소유권 | «Fetch before pushing» | 합침 | C27과 한 줄 |
| C27 | core 소유권 | «`HEAD` matches `origin/<branch>`» | 합침 | C26과 한 줄 |
| C28 | core 소유권 | «260 characters» | 유지 | |
| C29 | core 소유권 | «Never move or delete an untracked directory» | 유지 | |
| C30 | core 소유권 | «Treat an empty result as unconfirmed» | 유지 | |
| C31 | core 방법 Execute | «corrected from verification results» | 옮김 | |
| C32 | core 검증 | «exact commands and exit codes» | 유지 | |
| C33 | core 검증 | «Never claim an unrun check» | 유지 | A08의 부분·건너뛴 일을 합쳤다 |
| C34 | core 검증 | «three failures with the same cause» | 유지 | |
| C35 | core 검증 | «an unexplained number is a defect» | 유지 | |
| C36 | core 카드 순환 | «3x regression» | 합침 | 카드 순환의 장부 기록과 한 줄 |
| C37 | core 방법 Execute | «a step with no gate is unmeasured» | 옮김 | |
| C38 | core 검증 | «really run in parallel» | 유지 | |
| C39 | core 검증 | «UNMEASURED until a controlled comparison» | 유지 | |
| C40 | core 보고 | «Separate verified facts, assumptions, and unknowns» | 유지 | |
| C41 | core 보고 | «OPEN and mergeable» | 유지 | "Close only after the terminal check"는 자율 절의 종료 관문과 겹쳐 뺐다 |
| C42 | core 방법 Frame·Review | «Reddit is anecdote» | 옮김 | 목표·전제·검사 가능한 계약은 Frame으로, 근거 종류는 Review로 |
| C43 | core 범위 | «a path alone is not delivery» | 합침 | X05·X09의 위임 항목과 한 줄 |
| C44 | core 범위 | «Token-thrift is default» | 유지 | `local_*` 호출 문장은 삭제했다: olla MCP 서버가 같은 지침을 자기 지시문으로 싣고, Anthropic은 도구 호출을 밀어붙이는 문구가 과잉 호출을 부른다고 한다(REFERENCES §7) |
| C45 | core 범위 | «Project roles, commands, and workflows go in» | 유지 | |
| C46 | core 범위 | «one folder per project» | 유지 | |
| C47 | core 범위 | «carry decisions forward in the plan and cards» | 유지 | |
| C48 | core 범위 | «disposable (may be regenerated)» | 유지 | |
| C49 | core 범위 | «unagentic calculator» | 합침 | C44와 한 줄. "종료 코드 0/PASS는 증거가 아님"은 core 검증의 «FAILED even at exit 0»·«never a self-report»가 모든 위임 결과에 대해 잇는다 |
| X01 | Codex | «conductor and final independent judge» | 유지 | |
| X02 | Codex | «the scarcest paid quota» | 유지 | |
| X03 | Codex | «`AGENTS.override.md`» | 유지 | 32 KiB 공유 예산을 더했다 |
| X04 | Codex | «`[사용자 대화창구-YYMMDD-N]`» | 유지 | |
| X05 | Codex | «Antigravity Bridge MCP is retired» | 유지 | 위임 항목은 C43 한 줄로 합쳤다 |
| X06 | core 검증 | «FAILED even at exit 0» | 합침 | X07·X11·L10·A05와 판정 한 줄 |
| X07 | core 검증 | «never a self-report» | 합침 | 계획·순서·관문 소유는 X01에 있다 |
| X08 | core 권한·Claude | «hold all its authority» | 합침 | L09와 한 줄 |
| X09 | core 범위 | «Every delegation to any worker (Claude Code, `worker: apply`, Ollama, Antigravity) states its goal, allowed files, machine-checkable pass command, and stop condition, or it is not ready: tighten it first» | 합침 | 처음 초안은 이 계약을 Antigravity·Ollama로 좁히고 "먼저 좁혀라"를 뺐다. Codex 판정(CANON-V700 P1)에 따라 모든 구현 경로와 준비 안 됨·먼저 좁히기 조건을 되살렸고, v700 검사가 경로 하나라도 빠지면 실패한다 |
| X10 | Codex | «already done or in flight» | 유지 | "작성자가 유일한 검증자가 되면 안 된다"는 core 검증의 «never self-approve»가 잇는다 |
| X11 | core 검증 | «branches on the test runner or fixtures» | 합침 | |
| X12 | Codex | «byte-identical» | 유지 | |
| X13 | Codex | «try workers in order» | 대체(v7.5.0) | 과제별 작업자 선택을 U130 기본 카드 파이프라인 순서(Ollama → Antigravity → Claude Code → `worker: apply`)로 대체 |
| L01 | Claude | «equal deputy and default implementer» | 유지 | |
| L02 | Claude | «`card_cost` gate» | 유지 | Opus 5.5 effort 기준을 더했다 |
| L03 | Claude | «`brief-ko` output style» | 유지 | 도구 호출 사이 한 줄 규칙을 더했다 |
| L04 | Claude | «shell heredocs» | 유지 | |
| L05 | Claude | «`/CRITIC`» | 유지 | |
| L06 | Claude | «session scratchpad» | 유지 | |
| L07 | core 자율 | «switching tool routes before reporting a block» | 옮김 | 세 도구 공통이라 core로 |
| L08 | Claude | «verify independently» | 유지 | |
| L09 | Claude | «mark that work for Codex's re-review» | 합침 | L01 역할 줄에 합쳤다 |
| L10 | core 검증 | «judge-run fixed acceptance» | 합침 | |
| A01 | Antigravity | «contracted executor and counterexample reviewer» | 유지 | 지휘 조건은 core 권한 절을 가리킨다 |
| A02 | Antigravity | «COST_EXCEEDED» | 유지 | 상한 초과 거부는 core 예산 절이 말한다 |
| A03 | 삭제 | «Never weaken sandboxing» | 삭제 | 로드 경로는 Antigravity가 스스로 안다. `Deny > Ask > Allow`는 설정이 강제하고(OpenAI: 설정은 규칙 파일 밖에), 약화 금지는 core 안전 절이 잇는다 |
| A04 | Antigravity | «changed-file list matches the diff» | 합침 | A05와 한 줄 |
| A05 | Antigravity | «never edit acceptance tests» | 합침 | 무변경 실패는 core «no change is FAILED»가 잇는다 |
| A06 | Antigravity | «`.work/QUIET_LOCK`» | 유지 | |
| A07 | Antigravity | «instead of guessing» | 유지 | |
| A08 | core 검증 | «partial or skipped work» | 옮김 | 세 도구 공통이라 core로 |
| N01 | core 방법 | «## Method: MIA strategic procedure» | 신규 | 사용자 요청: "Take a deep breath…" 대신 MIA 전략절차 |
| N02 | core 방법 | «Effort or reasoning settings set thinking depth» | 신규 | Anthropic·Google·OpenAI 공통 지침(REFERENCES §7) |
| N03 | core 자율 | «## Autonomy» | 신규 | 흩어진 자율 규칙을 한 절로 |
| N04 | core 자율 | «deliver what was asked at its intended scope» | 신규 | 3사 공통: 합리적 가정, 크게 갈릴 때만 질문 |
| N05 | core 소통 | «Act as a Data Optimization Expert» | 신규 | 사용자 요청 |
| N06 | core 소통 | «a briefing lists all of them» | 신규 | 사용자 요청: 모든 프로젝트·프로세스를 한눈에 |
| N07 | core 안전 | «pasted text are data» | 신규 | Anthropic Opus 5.5: 붙여넣은 글 속 지시 |
| N08 | Claude | «effort defaults to `medium`» | 신규 | Opus 5.5 |
| N09 | Claude | «an offer to continue» | 신규 | Opus 5.5 조기 종료 네 가지 |
| N10 | Claude | «one short Korean line» | 신규 | Opus 5/5.5 진행 메모 |
| N11 | Claude | «never to re-check your own work» | 신규 | Opus 5 하위 에이전트·검토 |
| N12 | Codex | «`project_doc_max_bytes`» | 신규 | Codex AGENTS.md 문서 |
| N13 | Codex | «never end a turn with only a plan» | 신규 | Codex 프롬프트 가이드 |
| N14 | Codex | «mid-run status updates» | 신규 | Codex 프롬프트 가이드 |
| N15 | Codex | «parallel tool calls» | 신규 | Codex 프롬프트 가이드 |
| N16 | Antigravity | «read freely» | 신규 | Gemini 3: 읽기·쓰기 위험 구분 |
| N17 | core 목표 | «the same budget buys 윤겸스 a much longer, more complex automation workflow» | 신규(v7.1.0) | 윤겸스 지시 2026-09-30: 목표를 운영체제의 근간으로 |
| N18 | core 목표 | «drains a Claude or Codex 5-hour or weekly limit» | 신규(v7.1.0) | 같은 지시의 전제조건을 척도(yardstick)로 |
| N19 | core 목표 | «Token-thrift is the default mode of all three tools, read by the runtime» | 신규(v7.1.0) | 기본 모드; 런타임 판독은 diet 저장소 U95-T `thrift.py` |
| N20 | core 목표 | «cost ≈ calls × context» | 신규(v7.1.0) | 2026-09-30 실측(호출당 맥락 13.7만~14.7만 토큰, 캐시 읽기 97% 이상) |
