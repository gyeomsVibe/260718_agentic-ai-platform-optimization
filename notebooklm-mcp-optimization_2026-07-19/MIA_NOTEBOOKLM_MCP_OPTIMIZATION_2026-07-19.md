# MIA — NotebookLM MCP 연결 최적화 설계

- 작성일: 2026-07-19
- 상태: `VERIFIED_RESULT` (2026-07-19 실행 완료 — 3개 플랫폼 등록 및 실질의 검증 통과)
- 실행 기록: nlm 0.8.9 설치 → Edge 로그인(Chrome은 RUNASADMIN 플래그로 실행 불가, `auth.browser=edge` 고정) → Claude Code/Codex/Antigravity 등록 → 인용 포함 답변 실질의 검증 성공
- 대상 플랫폼: Claude Code / Codex / Antigravity (Windows 11, 본 워크스페이스)

---

## 1. 기획 (Opportunity Brief)

### 목표
Claude Code, Codex, Antigravity 세 플랫폼이 NotebookLM 노트북을 MCP로 직접 질의하여,
인용(Citation) 기반의 근거 있는 답변을 받아오는 리서치 파이프라인을 구축한다.

### 성공 기준
- 세 플랫폼 각각에서 NotebookLM 노트북 질의가 동작한다.
- 인증이 세션 간 유지된다 (매번 로그인하지 않는다).
- 답변에 출처 인용이 포함된다.
- 유지보수 이벤트(UI 개편, 쿠키 만료) 발생 시 복구 절차가 문서화되어 있다.

### 핵심 가치 (왜 하는가)
- 토큰 절약: Claude가 18만 토큰짜리 문서를 직접 읽는 대신, NotebookLM(Gemini)이
  관련 구간만 골라 1,500~3,000 토큰 요약으로 반환한다.
- 환각 억제: 답변이 사용자가 넣은 소스에만 근거(Source Grounding)한다.
- 탭 전환/복붙 제로: `/research` 한 번으로 리서치 → 답변 수신까지 자동화 가능.

---

## 2. 검증된 사실 (Evidence)

| 사실 | 출처 |
|---|---|
| Google 공식 NotebookLM MCP 서버는 **없음**. 요청 이슈(2026-02)에 공식 응답 없음 | [google/mcp#19](https://github.com/google/mcp/issues/19) |
| 공식 API는 **Enterprise 전용** (Google Cloud, VPC-SC/CMEK) — 개인 사용 불가 | [Google Cloud Docs](https://docs.cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs/api-notebooks) |
| 소비자용 연결은 전부 비공식 2가지 방식: ① 브라우저 자동화(Patchright 스텔스) ② 쿠키 추출 + 내부(undocumented) API | 각 저장소 README |
| 무료 티어 한도: 채팅 50쿼리/일, 노트북당 소스 50개, 오디오 3개/일. Pro($19.99): 500쿼리/일 | [notebooklm-guide.com](https://notebooklm-guide.com/notebooklm-system-limits-benchmarks) |
| 2026-04 NotebookLM UI 개편 때 주요 MCP 서버들 패치까지 **24~72시간** 소요 | [MCP.Directory 가이드](https://mcp.directory/blog/notebooklm-mcp-complete-guide-2026) |

### 후보 구현체 4종 비교

| 구현체 | 방식 | 강점 | 약점 | 유지보수 |
|---|---|---|---|---|
| [jacob-bd/notebooklm-mcp-cli](https://github.com/jacob-bd/notebooklm-mcp-cli) | 쿠키 추출 + 내부 API | 가볍고 빠름(쿼리 시 브라우저 불필요), `nlm setup add claude-code` 원커맨드, CLI+MCP 통합, Windows 지원, 쿠키 자동 갱신 | 쿠키 2~4주 만료, 내부 API 파손 리스크 | 활발 |
| [PleasePrompto/notebooklm-mcp](https://github.com/PleasePrompto/notebooklm-mcp) | 브라우저 자동화 | 가장 대중적, `npx notebooklm-mcp@latest` 간단 설치, 문서/트러블슈팅 충실, 멀티계정 | 쿼리마다 브라우저 구동(무겁고 느림), DOM 셀렉터 파손 리스크 | 활발 |
| [roomi-fields/notebooklm-mcp](https://github.com/roomi-fields/notebooklm-mcp) | 브라우저 자동화 + REST API | 기능 최다(Studio 생성 33 엔드포인트), 멀티계정 TOTP 자동 재인증, Claude 플러그인 설치, n8n/Zapier 연동 | 가장 무거움, 과잉 기능 | v2.2.0 (2026-07) 월간 릴리스 |
| [teng-lin/notebooklm-py](https://github.com/teng-lin/notebooklm-py) | Python 내부 API | 순수 라이브러리 사용 가능, Claude Code/Codex용 SKILL.md 제공, 웹 UI에 없는 기능 노출 | Python 스택 추가 필요 | v0.7.3 (2026-06-30) 활발 |
| [jackc1111/antigravity-notebooklm-mcp](https://github.com/jackc1111/antigravity-notebooklm-mcp) | RPC 클라이언트 | Antigravity 명칭 | 커밋 6개, PoC 수준 | **비활성 — 제외** |

---

## 3. /CRITIC — 실패사례 · 실행난제 · 맹점 (가장 중요한 자료)

### 실패사례 (커뮤니티에서 실제 보고된 것)
1. **로그인 루프**: 인증 성공 후에도 로그인 화면으로 계속 리다이렉트.
   원인은 Chrome 프로필 잠금(ProcessSingleton) 또는 세션 만료.
   → 해결: Chrome 전체 종료 → `re_auth` → 안 되면 `cleanup_data` 후 재인증.
2. **UI 개편 시 일제 파손**: 2026-04 개편 때 모든 브라우저 자동화 서버의 DOM 셀렉터가
   깨졌고 패치까지 1~3일 소요. 이 기간 동안 파이프라인 전체가 정지된다.
3. **Chrome 실행 실패 (Windows 포함)**: "Failed to launch chrome / exit code 21".
   → 해결: `BROWSER_CHANNEL=chromium`으로 번들 Chromium 강제.
4. **인용(footnotes) 빈 값**: 노트북에 소스가 없거나 셀렉터가 구버전일 때 발생.
5. **쿠키 만료 (2~4주)**: 내부 API 방식은 주기적으로 `nlm login` 재실행 필요.

### 실행난제
- **쿼터 소진**: 무료 50쿼리/일은 에이전트가 반나절이면 소진한다. 에이전트는 사람보다
  훨씬 빠르게 질의를 반복하므로 캐싱 없이는 실사용 불가 수준.
- **3개 플랫폼 동시 접속**: 세 클라이언트가 동시에 브라우저 프로필을 열면 프로필 잠금
  충돌. 브라우저 자동화 방식의 고질적 문제 (쿠키 방식은 해당 없음).
- **계정 리스크**: Google ToS상 자동화는 위반 소지가 있고, 봇 감지 시 계정 플래그
  가능성. 모든 저장소가 "전용 계정 사용"을 권장한다.

### 맹점 (블라인드 스팟)
- **NotebookLM을 거치는 게 항상 이득은 아니다**: 로컬 코드/문서는 Claude가 직접 읽는
  것이 더 빠르고 정확하다. NotebookLM 경유가 이득인 경우는 ① 대형 외부 문서 코퍼스
  ② 웹 리서치 결과 축적 ③ 멀티미디어(오디오/비디오) 생성일 때뿐이다.
- **답변 재사용 안 하면 쿼터 낭비**: 같은 질문을 세 플랫폼이 각각 던지면 쿼터 3배 소모.
  답변을 로컬 markdown vault에 캐싱하는 설계가 필수다.
- **비공식 의존성의 이중 파손 경로**: 브라우저 방식은 UI 변경에, 쿠키 방식은 내부 API
  변경에 깨진다. 어느 쪽이든 Google이 바꾸면 깨진다 — 단일 구현체에 올인하면 안 된다.

---

## 4. 검토 (Decision Memo)

### 옵션 비교
- **A. 쿠키 + 내부 API 방식** (jacob-bd/notebooklm-mcp-cli)
  - 가치: 높음 (빠름, 가벼움, 3개 플랫폼 공용 등록 간단)
  - 난제: 쿠키 2~4주 만료 → `nlm login` 재실행으로 복구 (1분 작업)
- **B. 브라우저 자동화 방식** (PleasePrompto)
  - 가치: 중간 (안정적 커뮤니티, 그러나 무겁고 프로필 잠금 충돌 리스크)
  - 난제: 3개 플랫폼 동시 사용 시 프로필 충돌, 쿼리 지연 수 초~수십 초
- **C. Enterprise 공식 API**: 개인 환경 부적합 — 기각
- **D. 연결 안 함 (수동 복붙)**: 비용 0이지만 목표(자동화) 미달 — 기각

### 결정 게이트: **Go (옵션 A 주력 + B 예비)**
- 근거: Windows 11 + 3개 플랫폼 동시 사용 환경에서는 쿼리 시 브라우저가 필요 없는
  쿠키 방식이 자원·충돌·지연 모두에서 우위. 내부 API 파손 시 B(브라우저 방식)로
  전환하는 이중화로 단일 실패 지점을 제거한다.
- 재검토 조건: 내부 API 파손이 월 1회 이상 반복되면 B를 주력으로 승격.

---

## 5. 최적화 설계 (실행 계획 — 승인 후 진행)

### 아키텍처
```
[NotebookLM (전용 Google 계정 권장)]
        ▲ 쿠키 인증 (2~4주 지속, 자동 갱신)
        │
[notebooklm-mcp-cli  — 단일 서버, uv tool 설치]
        │ stdio MCP
   ┌────┼─────────┐
Claude Code   Codex   Antigravity
(nlm setup add) (json config) (mcp config)
        │
        ▼
[답변 캐시 vault: 본 워크스페이스 /research-vault/*.md]
```

### 실행 단계 (승인 필요 항목 표시)
1. ⚠️ **[설치 승인 필요]** `uv tool install notebooklm-mcp-cli` (또는 `pipx`)
2. `nlm login` — 브라우저 창에서 Google 로그인 1회 (쿠키 자동 추출·저장)
3. Claude Code 등록: `nlm setup add claude-code`
4. Codex 등록: `nlm setup add json`으로 스니펫 생성 → `~/.codex/config.toml` 반영
5. Antigravity 등록: 동일 스니펫을 Antigravity MCP 설정에 반영
6. 검증: 각 플랫폼에서 테스트 노트북 질의 → 인용 포함 답변 확인
7. `research-vault/` 폴더 생성 + "질의 전 vault 먼저 검색" 규칙을 CLAUDE.md/AGENTS.md에 추가

### 운영 수칙 (인사이트)
- **쿼터 예산제**: 무료 50쿼리/일 기준, 캐시 우선 조회로 실질 소모를 억제.
  본격 사용 시 Pro($19.99/월, 500쿼리/일) 업그레이드가 멀티계정 로테이션보다
  ToS 리스크가 낮고 단순하다.
- **전용 계정 분리**: 자동화용 Google 계정을 본계정과 분리해 플래그 리스크를 격리.
- **버전 고정**: `@latest` 대신 검증된 버전을 고정하고, UI/API 개편 뉴스 후 24~72시간
  기다렸다가 업그레이드 (얼리 업그레이드가 오히려 파손 창구).
- **파손 시 복구 순서**: ① `nlm login` 재실행 → ② 패키지 업데이트 확인 →
  ③ 예비(PleasePrompto `npx notebooklm-mcp@latest`)로 전환.
- **적재적소**: 로컬 파일은 직접 읽기, NotebookLM은 외부 문서 코퍼스·웹 리서치
  축적·멀티미디어 생성에만 사용.

---

## 6. 리스크 요약

| 리스크 | 영향 | 완화책 |
|---|---|---|
| Google 내부 API 변경 | 질의 전면 중단 | 예비 구현체(B) 전환 절차 문서화 |
| 쿠키 만료 (2~4주) | 일시 중단 | `nlm login` 1분 재인증 |
| ToS 위반/계정 플래그 | 계정 제재 | 전용 계정, 과도한 자동 연속질의 금지 |
| 쿼터 소진 (50/일) | 당일 사용 불가 | vault 캐싱, 필요 시 Pro 업그레이드 |

## 참고 자료 (전체)
- 공식: [NotebookLM Enterprise API](https://docs.cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs/api-notebooks), [NotebookLM FAQ](https://support.google.com/notebooklm/answer/16269187?hl=en), [google/mcp#19](https://github.com/google/mcp/issues/19)
- GitHub: [jacob-bd/notebooklm-mcp-cli](https://github.com/jacob-bd/notebooklm-mcp-cli), [PleasePrompto/notebooklm-mcp](https://github.com/PleasePrompto/notebooklm-mcp) ([troubleshooting](https://github.com/PleasePrompto/notebooklm-mcp/blob/main/docs/troubleshooting.md)), [roomi-fields/notebooklm-mcp](https://github.com/roomi-fields/notebooklm-mcp), [teng-lin/notebooklm-py](https://github.com/teng-lin/notebooklm-py)
- 커뮤니티: [MCP.Directory 2026 가이드](https://mcp.directory/blog/notebooklm-mcp-complete-guide-2026), [XDA 활용기](https://www.xda-developers.com/notebooklm-connects-to-claude-through-mcp/), [Medium — Antigravity 연동](https://medium.com/google-cloud/integrate-notebooklm-with-gemini-cli-google-antigravity-or-other-agents-with-mcp-cd83b575dc39), [NotebookLM 한도표](https://notebooklm-guide.com/notebooklm-system-limits-benchmarks), [한국 활용 사례(gpters)](https://www.gpters.org/nocode/post/notebooklm-mcp-you-can-ThxDeeqDEkMI0aT)
