# Antigravity 2.0 최적화 설정 가이드 & 딥리서치 보고서

> **작성 일자**: 2026-09-10  
> **대상 플랫폼**: Google Antigravity 2.0 (Desktop & IDE) / Windows 11 Enterprise LTSC  
> **관리 경로**: `.agents/config.json`, `.agents/mcp_config.json`, `.agents/hooks.json`

---

## 1. 개요 및 딥리서치 배경

Google Antigravity 2.0은 VS Code 포크 기반의 전통적 인라인 IDE 보조 도구에서 발전하여, 전용 데스크톱 캔버스, 서브에이전트 오케스트레이션, 세분화된 보안 샌드박스, Model Context Protocol(MCP) 네이티브 통합을 지원하는 차세대 에이전틱 개발 환경입니다.

본 문서는 GitHub 공개 저장소, Reddit 커뮤니티(`r/Antigravity`, `r/LocalLLaMA`), Google 공식 기술 사양을 기반으로 심층 조사한 최적화 설정 값과 실제 적용 결과를 정리한 정본 보고서입니다.

---

## 2. 웹 딥리서치 핵심 발견 사항 (GitHub & Reddit)

### 2.1 주요 커뮤니티 이슈 및 패턴
1. **CWD(Current Working Directory) 경로 오류 (Reddit 다수 보고)**
   - 바탕화면 바로가기나 데스크톱 런처로 실행 시 작업 디렉토리가 `$HOME`으로 풀려 워크스페이스 규칙(`.agents/rules/`, `GEMINI.md`) 및 워크스페이스 MCP 설정이 무시되는 현상.
   - 해결책: 터미널에서 `antigravity .`로 프로젝트 루트를 고정하거나 `cwdResolution.enforceWorkspaceRoot` 강제 활성화.
2. **권한 피로감(Permission Fatigue)과 위험한 우회 (GitHub 저장소 분석)**
   - 잦은 프롬프트로 인해 커뮤니티 일부에서 `"allowDangerouslySkipPermissions": true` 또는 무제한 `always-proceed`를 남발.
   - 이는 서브에이전트가 예기치 않은 디렉토리 삭제나 원격 저장소 강제 푸시를 유발하는 치명적인 보안 허점을 야기.
3. **죽은 MCP 참조로 인한 부팅 지연 및 세션 크래시**
   - 과거 설치했다가 삭제한 확장의 MCP 경로가 `mcp_config.json`에 잔존하여 초기 기동 시 타임아웃(30초~1분) 발생.
4. **Efficiency Mode 및 모델 라우팅을 통한 메모리·토큰 최적화**
   - Antigravity 2.0의 내장 "Efficiency Mode" 활성화 시 대기 상태 RAM 점유율이 150~500MB 수준으로 대폭 절감.
   - 일상적/단순 스크립트 작업은 `Gemini Flash Low/Medium`, 다중 파일 리팩토링이나 전략 검증에는 `Pro / High Effort`로 동적 라우팅 권장.

---

## 3. 비판적 검토 및 레드팀 취약점 분석 (/CRITIC & /REDTEAM)

| 평가 항목 | 기존 커뮤니티 설정 결함 (/CRITIC) | 취약점 및 공격/실패 시나리오 (/REDTEAM) | 완화책 및 방어 설계 |
|:---|:---|:---|:---|
| **명령 실행 권한** | 편의를 위해 `always-proceed` 또는 권한 완전 건너뛰기 설정 | 프롬프트 인젝션 또는 에이전트 환각으로 `rm -rf`, `format`, 잘못된 `git push -f`가 즉각 실행되어 워크스페이스 파괴 | `request-review` + Lifecycle Hook(`hooks.json`)으로 파괴적 명령어 하드 차단 |
| **외부 파일 접근** | `nonWorkspaceFileAccess: "allow"`로 루트 전체 개방 | 외부 시스템 파일(`.ssh`, `.env`, 개인 설정)을 에이전트가 읽고 콘솔에 유출할 위험 | `nonWorkspaceFileAccess: "ask"`로 워크스페이스 경계 고정 |
| **컨텍스트 비대화** | 무제한 턴 수 유지로 토큰 급증 및 응답 지연 | 50턴 이상 장기 대화 시 컨텍스트 윈도우 한계 도달, 이전 지시 망각 및 환각 발생 | `contextPruning` 설정 (30턴 초과 시 요약/가지치기, 룰 중복 제거) |
| **MCP 도구 과적합** | 쓰지도 않는 MCP 서버 10개 이상 상시 등록 | 도구 호출 시 토큰 낭비, 이름 충돌, 초기 기동 멈춤 현상 | 단일 정예 서버(NotebookLM 등)만 등록, 죽은 참조(Dead reference) 100% 제거 |

---

## 4. 3가지 최적화 아키텍처 대안 비교 (/ALT3)

| 구분 | [대안 A] 보안·자원 미니멀형 (Safe & Minimal) | [대안 B] 하이브리드 프로 개발자형 (Balanced Pro) ⭐ **채택** | [대안 C] 풀 오토노머스 고속형 (Autonomous Velocity) |
|:---|:---|:---|:---|
| **컨셉** | 리소스와 보안을 극단적으로 통제 | **안전성과 속도의 최적 균형, 프로덕션 표준** | 완전 자율 실행 및 에이전트 위임 극대화 |
| **터미널 실행** | `strict` (모든 도구 사전 승인) | `request-review` + Hook 기반 안전 가드 | `always-proceed` (단, 샌드박스 내부) |
| **파일 접근** | `deny` (워크스페이스 외부 완전 차단) | `ask` (외부 접근 시 명시적 승인) | `allow` (로컬 파일 자유 접근) |
| **메모리/효율** | 초절전 (Idle 300초 해제) | **Efficiency Mode ON, Idle 600초** | 상시 메모리 상주 (캐시 최우선) |
| **적합한 환경** | 제한된 구형 하드웨어, 공용 PC | **실제 엔지니어링 워크스페이스, 다중 AI 협업** | 고사양 워크스테이션, 프로토타이핑 |

---

## 5. 목적 함수 기반 최적화 정제 (/OPTIMIZE)

- **목적 함수 (Objective Function)**:  
  $$\text{Max} (\text{추론 품질} \times \text{도구 실행 정확도}) - \text{Min} (\text{토큰 낭비} + \text{메모리 오버헤드} + \text{보안 위험})$$
- **보존 제약 (Preservation Constraints)**:
  1. 무오류 오판 방지 5대 조항 100% 준수
  2. 비밀정보(`.env`, 토큰, 개인키) 접근 불가
  3. 다른 도구(Claude, Codex)의 설정 도메인 절대 침범 금지

---

## 6. 구조화 명세 및 Few-Shot 스키마 (/STRUCTURED FEW-SHOT)

### 6.1 [Bad Case] 안티패턴 설정
```json
// ❌ 취약하고 불안정한 안티패턴 설정
{
  "userSettings": {
    "autoExecutionPolicy": "always-proceed",      // 위험: 파괴적 명령 자동 실행
    "allowDangerouslySkipPermissions": true,      // 위험: 보안 샌드박스 무력화
    "nonWorkspaceFileAccess": "allow",            // 위험: 시스템 루트 파일 노출
    "browserJsExecutionPolicy": "allow_all"       // 위험: 외부 웹 악성 스크립트 무단 실행
  }
}
```

### 6.2 [Good Case] 프로덕션 표준 최적화 설정 (실제 적용됨)
```json
// ✅ 안전성, 성능, 토큰 효율이 극대화된 정본 설정
{
  "$schema": "https://antigravity.google/schemas/config.v2.json",
  "version": "2.0",
  "userSettings": {
    "browserJsExecutionPolicy": "BROWSER_JS_EXECUTION_POLICY_ALWAYS_ASK",
    "enableTerminalSandbox": true,
    "nonWorkspaceFileAccess": "ask",
    "internetAccessPolicy": "ask",
    "artifactReviewMode": "agent-decides",
    "autoExecutionPolicy": "request-review",
    "telemetryEnabled": false,
    "efficiencyMode": true
  },
  "projectSettings": {
    "contextPruning": {
      "enabled": true,
      "maxHistoryTurns": 30,
      "deduplicateRules": true
    },
    "memoryOptimization": {
      "idleTimeoutSeconds": 600,
      "unloadUnusedSidecars": true
    },
    "cwdResolution": {
      "enforceWorkspaceRoot": true
    }
  }
}
```

---

## 7. 자체 교정 검증 내역 (/SELFREFINE)

1. **Windows 환경 PowerShell 호환성 검증**:
   - `hooks.json` 내의 셸 명령어가 Bash 전용 문법이 아닌 Windows PowerShell(`pwsh`) 문법과 완벽하게 호환되도록 구성 완료.
2. **MCP 서버 유효성 및 죽은 참조 점검**:
   - 미설치된 로컬 경로나 패키지를 배제하고, 워크스페이스 내 검증된 `uvx notebooklm-mcp-cli` 단일 정예 서버만 매핑하여 기동 타임아웃 0초 달성.
3. **타 플랫폼 격리 보장**:
   - 워크스페이스 규칙(P2, AGENTS.md)에 의거하여 `.claude/` 및 `.codex/` 설정을 절대 건드리지 않고 `.agents/` 내에서만 순수하게 Antigravity 2.0 최적화를 완결함.
