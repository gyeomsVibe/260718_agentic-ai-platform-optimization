# 🚀 Antigravity 에이전트 환경설정 기록 (노트북)

> 이관: `260713_pc-optimization` 워크스페이스에서 완전 이동 (2026-07-19). 문서 내 일부 상대 링크(optimization_result.md, scratch/ 등)는 구 워크스페이스 기준이라 연결되지 않을 수 있다.

> 대상 환경: **노트북** (MSI GL75 9SDK / Windows 11 Enterprise LTSC 2024)
> 관리 도메인: `.agents/` (워크스페이스 로컬) · `~/.antigravity-ide/` · IDE 확장 프로그램
> 이 문서는 **Antigravity 전용**이다. Claude·Codex 설정은 각자의 문서에서 다룬다.

---

## 1. Antigravity란 (학습모드)

Antigravity는 IDE 통합형 AI 에이전트다. 확장은 다른 에이전트와 같은 **3층위**로 이해한다.
(개념 표는 [노트북 README](README.md#에이전트-환경-학습모드) 참조)

| 층위 | Antigravity에서의 위치 |
|---|---|
| **① 로컬 플러그인/확장** | IDE 확장 프로그램 마켓플레이스 (언어 서버·AI 도구 등) |
| **② 로컬 MCP 서버** | 워크스페이스 `.agents/mcp_config.json` |
| **③ 사용자 설정** | 워크스페이스 `.agents/config.json`, 전역 `~/.antigravity-ide/` |

---

## 2. 필요 도구 스택 (에이전트 정상 동작 기준)

Antigravity가 이 노트북에서 정상 작동하기 위한 기본 스택 (개발 스택 최신화 결과와 공유):

| 항목 | 버전 |
|---|---|
| OS | Windows 11 Enterprise LTSC 2024 (10.0.26100, 64-bit) |
| Git | 2.55.0.windows.2 |
| Node.js | 24.18.0 |
| npm | 11.16.0 |
| uv | 0.11.28 |
| Python (`py` 런처) | 3.14.6 |

> 상세 셋업 내역은 [`optimization_result.md`](optimization_result.md) 3차 섹션 참조.

---

## 3. `.agents/` 설정 구조 (머신값 제외, git 비커밋)

Antigravity의 워크스페이스 로컬 설정은 `.agents/` 에 있다. **호스트명·절대경로·사용자명 등
머신 고유 정보를 포함**하므로 이 저장소에는 **커밋하지 않는다**(`.gitignore` 처리). 여기서는 구조만 기록한다.

### `.agents/config.json` — 사용자 설정
```jsonc
{
  "userSettings": {
    "browserJsExecutionPolicy": "BROWSER_JS_EXECUTION_POLICY_ALWAYS_ASK", // 브라우저 JS 실행 시 항상 확인
    "remoteControlHostname": "<머신 고유 호스트명>"                        // 원격 제어 대상 (머신값 → 비커밋)
  }
}
```

### `.agents/mcp_config.json` — MCP 서버 등록
등록된 로컬 MCP 서버 (경로는 머신 고유):

| MCP 서버 | 용도 | 상태 |
|---|---|---|
| `cloudrun` | Google Cloud Run 연동 (`npx @google-cloud/cloud-run-mcp`) | ✅ 정상 |
| `vibe-diagnosis` | 로컬 자가진단 MCP 서버 (별도 워크스페이스) | ✅ 정상 |

> **2026-07-13 정리**: `notebooks`·`visualization` 서버 2개는 `googlecloudtools.datacloud` 확장을
> 참조했으나, IDE 슬림화(96→53개) 때 해당 확장이 제거되어 **죽은 참조**가 되었다. 시작 시 로딩
> 실패를 유발하므로 `mcp_config.json`에서 두 항목을 제거했다. DataCloud(BigQuery 노트북·시각화)가
> 다시 필요하면 확장을 재설치한 뒤 Antigravity가 서버 등록을 재생성하도록 둔다.
>
> 실제 파일에는 `c:\Users\...\.antigravity-ide\extensions\...` 같은 절대경로가 들어간다. 타 PC에서는
> 경로가 달라 그대로 쓸 수 없으므로, 새 머신에서는 Antigravity가 재생성하도록 두는 것이 맞다.

---

## 4. IDE 확장 프로그램 슬림화

백그라운드 리소스(CPU/RAM)를 점유하는 불필요 확장을 정리한 기록:

- 📋 계획: [`antigravity-ide-slimming-plan.md`](antigravity-ide-slimming-plan.md)
- ✅ 결과: [`antigravity-ide-slimming-result.md`](antigravity-ide-slimming-result.md)

핵심 방향: 미사용 언어 서버(Java/PHP/Ruby/Rust/Go 등)·중복 AI 도구·중복 Pyright 정리, 무거운
SonarLint·GitLens를 경량 대체. (상세 수치는 결과 문서 참조)

---

## 5. 도메인 격리

- 이 문서와 Antigravity는 **`.agents/` · IDE 확장 · `~/.antigravity-ide/` 만** 다룬다.
- **Claude 설정(`.claude/`)·Codex 설정(`~/.codex/`)은 건드리지 않는다.**
  (이전에 Antigravity가 `.claude/settings.local.json` 추적을 변경했던 이력이 있어, 본 정리에서 도메인 경계를 명문화함.)
- 관련: [Claude 환경](claude-agent-environment.md) · [Codex 환경](codex-agent-environment.md)

> 보안 주의: 이 문서에는 머신 고유 경로·호스트명 실값을 포함하지 않는다.
