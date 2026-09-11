# MIA — 플랫폼 전수조사·슬림화 감사 결정문

- 작성일: 2026-07-19
- 상태: `VERIFIED_RESULT` (제거 실행 + 잔여 수치 검증 완료)
- 범위: 세 도구의 Skills · 플러그인 · IDE 확장 · MCP/앱 연결 전수조사 후 불필요 항목 제거
- 복원 지점: **`~/skills-quarantine-20260719/`** (스킬 85폴더 + MCP 설정 백업 — 삭제가 아니라 격리)

---

## 1. 전수조사 결과 (제거 전)

| 영역 | 수량 | 비고 |
|---|---|---|
| Claude 스킬 (`~/.claude/skills`) | 54 | |
| Codex 스킬 (`~/.codex/skills`) | 33 | |
| Antigravity 스킬 (`~/.gemini/antigravity/skills`) | 31 | |
| Gemini CLI 스킬 (`~/.gemini/skills`) | 20 | 거의 전부 GCP 팩 |
| 범용 스킬 (`~/.agents/skills`) | 54 | |
| Antigravity MCP | 5 | cloudrun·notebooks·visualization·vibe-clinic·notebooklm |
| Claude MCP | 4 | Notion·Canva(계정)·vibe-clinic·notebooklm |
| Codex MCP | 3 | node_repl(내장)·vibe-clinic·notebooklm |
| Antigravity IDE 확장 | 54 | 기존 96→53 슬림화 이력 있음 |

## 2. 제거 내역과 근거

### A. GCP 데이터 엔지니어링 스킬 팩 17종 × 5개 위치 = 85폴더 격리 ✂️

**제거 대상**: bigquery-data-transfer-service, building-data-apps, data-autocleaning,
dataform-bigquery, dbt-bigquery, developing-with-bigquery, discovering-gcp-data-assets,
federate-lakehouse-catalog, gcloud-auth-verification, gcp-composer-troubleshooting,
gcp-data-pipelines, gcp-dataflow, gcp-pipeline-orchestration,
gcp-pipeline-resource-provisioning, gcp-spark, ml-best-practices, notebook-guidance

**근거**:
1. **사용 근거 0**: D드라이브 워크스페이스 40개 전수 검색 — dbt/dataform/BigQuery
   프로젝트 파일(`dbt_project.yml`, `*.sqlx`, `workflow_settings.yaml`) **0건**.
   실제 작업은 GPT 챗봇·블로그·웹앱·크롤링·플랫폼 관리 성격.
2. **컨텍스트 낭비**: 스킬 설명은 **매 세션 시작 시** 컨텍스트에 로드된다. 안 쓰는
   17종의 긴 설명이 세 도구 모두에서 토큰을 소모하고 스킬 목록을 혼잡하게 함.
3. **오발동 위험**: `ml-best-practices`는 "data analysis"라는 말만 나와도 강제
   발동(CRITICAL RULE)하며 BigQuery ML로 유도 — 로컬 파이썬 분석과 충돌.
   `notebook-guidance`도 BigQuery 전용 매직(%%bqsql)을 강제.
4. **가역성**: `publisher: google` 공식 팩(Apache-2.0) — 격리 보관 + 재설치 용이.

**유지한 동일 팩 스킬** (범용 가치): `accidental-data-loss-prevention`(파괴 명령
안전장치 — 안전 스킬은 유지 원칙), `managing-python-dependencies`(파이썬 일반),
`skill-repair`(스킬 수리 도구).

### B. Antigravity MCP 서버 3종 제거 ✂️

| 서버 | 근거 |
|---|---|
| `notebooks` | **죽은 참조** — 의존하는 datacloud 확장이 IDE에 없음(확인됨). 시작 시 로딩 실패·지연만 유발. 2026-07-13에도 같은 이유로 제거했는데 재유입된 것 |
| `visualization` | 위와 동일한 죽은 참조 |
| `cloudrun` | Cloud Run 배포 이력 0 — 세션마다 `npx` 다운로드·프로세스 기동 오버헤드만 발생 |

유지: `vibe-clinic`(자가진단, 실사용) · `notebooklm`(리서치 파이프라인, 실사용).
백업: `~/skills-quarantine-20260719/mcp_config.json.bak`

### C. Antigravity IDE 확장 5종 제거 ✂️

| 확장 | 근거 |
|---|---|
| `gitlab.gitlab-workflow` | GitLab 미사용 (GitHub만 사용 — gh CLI·원격 저장소 전부 GitHub) |
| `ms-python.black-formatter` | Ruff 일원화 원칙과 중복 (데스크톱 슬림화에서 확립한 기준을 노트북에도 적용) |
| `ms-python.isort` | 위와 동일 — Ruff가 임포트 정렬 포함 |
| `magicstack.magicpython` | 구식 하이라이터 — `ms-python.python` 내장 기능과 중복 |
| `ms-vscode.cmake-tools` | C/C++ CMake 프로젝트 없음 |

> 제거는 `antigravity-ide --uninstall-extension`으로 수행 — IDE 재시작 시 잔여 폴더가 정리된다.

### D. 제거하지 않고 보류·문서화한 것

| 항목 | 판단 |
|---|---|
| Claude 계정 커넥터 `Canva` (인증 만료 방치) | **CLI로 제거 불가** — claude.ai 계정 레벨. [claude.ai 설정](https://claude.ai/settings) 웹에서 직접 해제 필요 (절차: `claude/environment-notebook.md` 4장) |
| `vscodevim.vim` | 사용 여부 불확실 — 키 입력 방식이 통째로 바뀌는 확장이라 오판 시 비용 큼. 사용 안 하면 다음 정리 때 제거 |
| `ms-dotnettools.vscode-dotnet-runtime` | 다른 확장의 숨은 의존성일 가능성 — 보류 |
| Codex `node_repl` MCP | 앱 내장 런타임 — 필수 유지 |
| `hatch-pet`(Codex) 및 개인 제작 스킬 전부 | 실사용 확인 — 유지 |

## 3. 결과 (제거 후 검증됨)

| 위치 | 이전 → 이후 |
|---|---|
| Claude 스킬 | 54 → **37** |
| Codex 스킬 | 33 → **16** |
| Antigravity 스킬 | 31 → **14** |
| Gemini CLI 스킬 | 20 → **3** |
| 범용 스킬 | 54 → **37** |
| Antigravity MCP | 5 → **2** (죽은 참조 0) |
| IDE 확장 | 54 → **49** (잔여 폴더는 IDE 재시작 시 정리) |

**총 격리: 스킬 85폴더 + MCP 3항목 + 확장 5종.**

## 4. 복원 방법 (후회 시 1분)

```
# 스킬 복원 (예: Claude에 dbt-bigquery 되돌리기)
cp -r ~/skills-quarantine-20260719/claude/dbt-bigquery ~/.claude/skills/

# MCP 설정 통째로 복원
cp ~/skills-quarantine-20260719/mcp_config.json.bak ~/.gemini/antigravity/mcp_config.json

# 확장 재설치
antigravity-ide --install-extension gitlab.gitlab-workflow
```

## 5. 재발 방지 수칙

- 새 스킬 팩이 "전체 설치"를 제안해도 **쓸 것만 골라 설치** (`-s` 옵션).
- 분기 1회 이 감사를 반복: ① 스킬 수 세기 ② 최근 안 쓴 것 격리 ③ MCP 죽은 참조 점검.
- 격리 폴더는 6개월 무사용 시(2027-01 이후) 완전 삭제해도 안전.
