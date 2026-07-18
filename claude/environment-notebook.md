# 🤖 Claude Code 에이전트 환경설정 기록 (노트북)

> 이관: `260713_pc-optimization` 워크스페이스에서 완전 이동 (2026-07-19). 문서 내 일부 상대 링크(optimization_result.md, scratch/ 등)는 구 워크스페이스 기준이라 연결되지 않을 수 있다.

> 대상 환경: **노트북** (MSI GL75 9SDK / Windows 11 Enterprise LTSC 2024)
> 기록일: 2026-07-13 · 최종 조사 기준
> 이 문서는 본 노트북의 Claude Code(에이전트 CLI) 환경설정을 재현·복구·정리할 수 있도록 남기는 기록이다.

---

## 1. 개념 정리 (학습모드)

Claude Code의 "확장" 은 크게 **세 층위**로 나뉜다. 이 구분을 알아야 무엇을 어디서 지우는지 헷갈리지 않는다.

| 층위 | 무엇인가 | 어디서 관리하나 | 리소스 성격 |
|---|---|---|---|
| **① 로컬 플러그인** | 마켓플레이스에서 로컬에 설치한 스킬·명령·에이전트 묶음 | `claude plugin` CLI (내가 직접 제어 가능) | 컨텍스트 토큰 |
| **② 로컬 MCP 서버** | 로컬 설정에 등록된 외부 도구 서버 | `claude mcp` CLI / `/mcp` | 프로세스·연결 |
| **③ 계정 커넥터 번들** | claude.ai 계정에 연결되어 로그인 시 주입되는 업무용 번들 | **claude.ai 웹 설정에서만** 관리 | 목록·연결시도 오버헤드 |

> 핵심: **①②는 이 PC 로컬에서 제어**되지만, **③은 claude.ai 계정 쪽**에 있어 CLI로 못 지운다. (아래 4장 참조)

---

## 2. 로컬 플러그인 구성 (① 층위)

**마켓플레이스 2곳**에서 설치됨:
- `claude-plugins-official` — Git(github.com/anthropics/claude-plugins-official)
- `anthropic-agent-skills` — GitHub(anthropics/skills)

**설치된 9개 중 7개 활성 / 2개 비활성** (2026-07-13 정리 결과 · `pr-review-toolkit`은 이후 완전 제거되어 목록에서 사라짐)

| 플러그인 | 상태 | 구성 | 판단 근거 |
|---|---|---|---|
| `security-guidance` | ✅ 활성 | 훅 4 (모델 컨텍스트 비용 0) | 보안 리뷰, **사용 최다(1,491+회)** — 필수 |
| `code-review` | ✅ 활성 | 스킬 1 | 코드 리뷰 핵심, `/code-review` |
| `commit-commands` | ✅ 활성 | 스킬 3 | 커밋/푸시/PR — 상시 사용 |
| `feature-dev` | ✅ 활성 | 스킬 1 + 에이전트 3 | 기능 개발 워크플로우 |
| `document-skills` | ✅ 활성 | docx/pdf/pptx/xlsx | 문서 생성 |
| `claude-api` | ✅ 활성 | 스킬 1 | Claude API 레퍼런스 (AI 앱 개발) |
| `frontend-design` | ✅ 활성 | 스킬 1 | UI 구현 (경량) |
| `plugin-dev` | ⛔ 비활성 | 스킬 8 + 에이전트 3 | 플러그인 개발자용 — **해당 없음**, 최대 비용 |
| `example-skills` | ⛔ 비활성 | 데모 | 샘플/예제 — 불필요 |
| `pr-review-toolkit` | 🗑️ 제거됨 | 에이전트 6 | code-review·feature-dev와 **중복** → 비활성 후 완전 제거됨(목록에 없음) |

**되돌리기(재활성화):**
```bash
claude plugin enable plugin-dev@claude-plugins-official
claude plugin enable example-skills@anthropic-agent-skills
# pr-review-toolkit 은 목록에서 제거되어 enable 불가 → 필요 시 재설치:
#   claude plugin marketplace 로 claude-plugins-official 재동기화 후 사용
```

**다시 끄기(비활성화):**
```bash
claude plugin disable <이름>@<마켓플레이스>
```
> ⚠️ 이 CLI 버전은 `disable`/`enable`만 제공하고 완전 삭제(uninstall)는 없다. `disable` = 컨텍스트 미로딩 = 리소스 절약이며 가역적이다.

---

## 3. 로컬 MCP 커넥터 (② 층위)

`claude mcp list` 기준:

| 커넥터 | 상태 | 비고 |
|---|---|---|
| `claude.ai Notion` | ✅ 연결됨 | 실제 사용 중 |
| `claude.ai Canva` | ⚠️ 인증 필요 | 미사용이면 정리 대상 |

관리: 대화형 터미널에서 `claude` 실행 → `/mcp` 로 연결/해제.

---

## 4. 계정 커넥터 번들 15종 (③ 층위) — 학습모드 삭제 가이드

이 15개는 **전부 사용 이력 0회**이면서 수십 개의 업무용 MCP 서버를 목록에 올린다.
로컬 설정 파일에 없고 **claude.ai 계정**에서 주입되므로 **CLI로는 못 지운다. claude.ai 웹에서 직접 제거해야 한다.**

### 4-1. 전체 목록과 권장 조치

이 사용자(1인 개발 · PC 최적화 · AI 에이전트/바이브코딩 · Notion·GitHub 사용) 기준.

| # | 번들 | 정체 (묶인 대표 커넥터) | 권장 | 이유 |
|---|---|---|---|---|
| 1 | **bio-research** | bioRxiv, ClinicalTrials, ChEMBL, PubMed, Consensus, BioRender, Owkin, Synapse, Wiley | 🗑️ 삭제 | 생명과학 논문·신약 연구용. 무관 |
| 2 | **legal** | Atlassian, Box, DocuSign, Egnyte, Slack | 🗑️ 삭제 | 법무·계약·NDA 검토용 |
| 3 | **marketing** | Ahrefs, Klaviyo, Similarweb, Supermetrics | 🗑️ 삭제 | 마케팅 캠페인·SEO·이메일 |
| 4 | **finance** | BigQuery | 🗑️ 삭제 | 회계 결산·감사·재무제표 |
| 5 | **sales** | (CRM 계열) | 🗑️ 삭제 | 영업 파이프라인·아웃리치 |
| 6 | **human-resources** | (HR 계열) | 🗑️ 삭제 | 채용·인사평가·온보딩 |
| 7 | **customer-support** | Guru, HubSpot, Intercom | 🗑️ 삭제 | 고객 티켓·응대 |
| 8 | **operations** | (운영 계열) | 🗑️ 삭제 | 프로세스·리스크·런북 |
| 9 | **product-management** | Amplitude, Figma, Fireflies, Pendo, Similarweb | 🗑️ 삭제 | 제품 스프린트·로드맵 |
| 10 | **enterprise-search** | (기업 검색) | 🗑️ 삭제 | 사내 지식 통합 검색 |
| 11 | **small-business** | Canva 등 | 🗑️ 삭제 | 소상공인 경영 관리 |
| 12 | **data** | Definite, Hex, BigQuery | ⚖️ 선택 | BI·대시보드 안 하면 삭제 |
| 13 | **design** | Figma | ⚖️ 선택 | Figma 쓰면 유지, 아니면 삭제 |
| 14 | **engineering** | Datadog, GitHub, PagerDuty | ⚖️ 선택 | GitHub만 쓸모(로컬 code-review와 중복), Datadog/PagerDuty는 운영 모니터링용 → 대체로 삭제 |
| 15 | **productivity** | Asana, ClickUp | ⚖️ 선택 | Asana/ClickUp 안 쓰면 삭제 (Notion은 별도 ②층에 있음) |

> **요약**: 1~11번 **11개 무조건 삭제**, 12~15번 **4개는 실제 사용하는 커넥터가 있을 때만 유지**.

### 4-2. 삭제 절차 (claude.ai 웹) — 따라하기

1. 브라우저에서 **https://claude.ai** 접속 후 로그인 (gyeomsVibe / yoongyeomkim0515@gmail.com 계정)
2. 좌측 하단 **프로필 아이콘** 클릭 → **Settings(설정)**
3. **Connectors(커넥터)** 탭 진입 *(플랜에 따라 "Capabilities" 또는 "Directory"로 표기될 수 있음)*
4. 위 표의 **🗑️ 삭제** 11개 번들을 찾아 각 항목의 **비활성화 토글 OFF** 또는 **연결 해제(Disconnect/Remove)**
5. ⚖️ 선택 4개는 본인이 그 커넥터를 실제 쓰는지 판단해 결정
6. 설정 저장 후, 다음 Claude Code 세션을 새로 시작하면 목록에서 사라진다

### 4-3. 대화형 CLI로 확인하는 법 (보조)
```bash
claude        # 대화형 실행
/mcp          # 연결된 커넥터 상태 확인·개별 인증 해제
```
> 비대화형(자동) 세션에서는 `/mcp` UI를 못 띄우므로 에이전트가 대신 제거할 수 없다. 위 웹 절차가 근본 해법이다.

### 4-4. 현재 부하 참고
15개 모두 **"인증 필요(Needs authentication)"** = 미연결 idle 상태. 상시 백그라운드 프로세스는 아니며, 시작 시 나열·연결시도 오버헤드와 목록 혼잡이 주 비용이다. 정리하면 세션 시작이 깔끔·가벼워진다.

---

## 5. 에이전트 개발 도구 스택 & 자동 실행 권한

노트북 환경에서 에이전트(Antigravity)가 정상 작동하는 데 필요한 시스템 기본 사양 및 도구 스택 버전입니다.

- **OS**: Microsoft Windows 11 Enterprise LTSC (Version: 10.0.26100, 64-bit)
- **Git**: `2.55.0.windows.2`
- **Node.js**: `v24.18.0`
- **npm**: `11.16.0`
- **uv (Python 패키지 관리자)**: `0.11.28`
- **Python**: `3.14.6`

### 자동 실행 권한 설정 (.claude/settings.local.json)
안전한 조회 및 자동 테스트를 수행하기 위해 허용된 명령어 패턴 목록은 루트 경로의 [`.claude/settings.local.json`](../.claude/settings.local.json) 파일에 정의되어 관리됩니다.

---

## 6. 관련 기록
- 개발 스택(파이썬·노드·git 등): [`optimization_result.md`](optimization_result.md) 3차 섹션
- 전원/발열 최적화: [`optimization_result.md`](optimization_result.md), [`scratch/cpu_boost_optimizer.ps1`](scratch/cpu_boost_optimizer.ps1)
- 상위 통합 개요: [`../README.md`](../README.md)

> 보안 주의: 이 문서에는 토큰·비밀키·머신ID 등 민감정보를 포함하지 않는다. `.credentials.json` 등 인증 파일은 조회·수정하지 않았다.
