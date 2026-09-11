# 🛠️ Antigravity IDE 확장 프로그램 리소스 최적화 및 슬림화 계획서

> 이관: `260713_pc-optimization` 워크스페이스에서 완전 이동 (2026-07-19). 문서 내 일부 상대 링크(optimization_result.md, scratch/ 등)는 구 워크스페이스 기준이라 연결되지 않을 수 있다.

이 최적화 계획은 노트북 환경(Intel i7-9750H / 32GB RAM)에서 다중 에이전트 및 IDE 작업 시 발생하는 CPU 스파이크와 메모리 누수를 제어하기 위해, **백그라운드에서 리소스를 대거 점유하는 불필요한 확장 프로그램들을 정리하고 필수적인 경량 확장 프로그램으로 대체**하기 위한 계획입니다.

---

## User Review Required

> [!IMPORTANT]
> - **프로그래밍 언어 서버 정리**: 현재 프로젝트 스택(Python, Node.js, Shell 등) 외에 백그라운드에서 항시 실행되며 RAM/CPU를 소모하는 타 언어 서버(Java, PHP, Ruby, Rust, R, Go, Dart/Flutter) 확장을 정리합니다. 
> - **중복 AI 에이전트 정리**: Antigravity IDE 자체의 강력한 AI 지원 외에 중복 설치되어 포트 충돌 및 메모리를 점유하는 타사 AI 도구(Amazon Q, Continue, ChatGPT, Roo Cline 등)를 정리합니다.
> - **가비지/중복 도구 정리**: 중복 실행되는 Pyright(3개 설치됨)를 공식 버전 1개로 통일하고, 무겁고 주기적인 파일 스캔을 유발하는 SonarLint, GitLens를 가벼운 대체제로 전환합니다.

---

## Open Questions

> [!NOTE]
> - 혹시 현재 작업 공간에서 **Java, PHP, Rust, Ruby, Go, Flutter, R** 중 활발히 개발 중인 언어가 있다면 알려주세요. 해당 언어 지원은 삭제 대상에서 제외하겠습니다. (따로 말씀이 없으시면, 노트북 최적화 스택인 **Python 및 Node.js(JavaScript/TypeScript)** 스택을 핵심으로 두고 나머지는 모두 슬림화하겠습니다. 추후 해당 언어 작업 시 VS Code가 원클릭 설치를 제안하므로 즉시 복구 가능합니다.)

---

## Proposed Changes

### Antigravity IDE Extensions

#### [MODIFY] Extensions Configuration (`~/.gemini/antigravity-ide`, 로컬 전용)

**1. 삭제 대상 확장 프로그램 (총 39개) 및 삭제 사유**

- **중복 AI 비서 및 에이전트 (9개)**
  - `amazonwebservices.amazon-q-vscode` / `amazonwebservices.aws-toolkit-vscode` (Amazon Q & AWS 툴킷 - 백그라운드 상주 및 인증 검사)
  - `continue.continue` (Continue - 백그라운드 로컬 LLM 프로세스 유지)
  - `genieai.chatgpt-vscode` / `openai.chatgpt` (ChatGPT 관련 중복 도구)
  - `rooveterinaryinc.roo-cline` / `saoudrizwan.claude-dev` (Roo-Cline 및 Claude Dev - 중복 실행)
  - `anthropic.claude-code` (Claude Code IDE 연동 - 중복)
  - `meta.pyrefly` (Python AI 중복)

- **중복 Pyright 및 언어 서버 (2개)**
  - `anysphere.pyright` / `codeium.windsurfpyright` (중복 Pyright 제거 ➔ 공식 `ms-pyright.pyright`만 유지)

- **미사용 무거운 언어 서버 (18개)**
  - **Java**: `redhat.java`, `vscjava.vscode-gradle`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-dependency`, `vscjava.vscode-java-test` (Java Language Server는 RAM을 가장 많이 소모함)
  - **PHP**: `devsense.composer-php-vscode`, `devsense.intelli-php-vscode`, `devsense.phptools-vscode`, `devsense.profiler-php-vscode`, `bmewburn.vscode-intelephense-client`
  - **Ruby**: `shopify.ruby-lsp`
  - **Rust**: `rust-lang.rust-analyzer`
  - **Go**: `golang.go`
  - **C/C++**: `llvm-vs-code-extensions.vscode-clangd`
  - **Dart/Flutter**: `dart-code.dart-code`, `dart-code.flutter`
  - **R**: `reditorsupport.r`, `reditorsupport.r-syntax`

- **백그라운드 스캔 및 리소스 과소비 도구 (6개)**
  - `sonarsource.sonarlint-vscode` (SonarLint - 실시간 파일 정적 분석으로 CPU 100% 유발 주범)
  - `eamodio.gitlens` (GitLens - 무겁고 백그라운드 인덱싱 부하가 큼 ➔ 가벼운 Git Graph로 대체)
  - `cweijan.dbclient-jdbc` / `cweijan.vscode-mysql-client2` (무거운 JDBC 기반 DB 클라이언트 ➔ `mtxr.sqltools`만 유지)
  - `msjsdiag.debugger-for-chrome` / `ms-edgedevtools.vscode-edge-devtools` / `firefox-devtools.vscode-firefox-debug` (구형 브라우저 디버거 ➔ 내장 JS Debugger로 대체)
  - `prisma.prisma-insider` (중복 Prisma 도구 ➔ `prisma.prisma` 정식 버전 유지)

- **미사용 웹 프레임워크 지원 (4개 - 필요시 재설치 권장)**
  - `svelte.svelte-vscode`, `vue.volar`, `bradlc.vscode-tailwindcss`, `github.vscode-github-actions`

**2. 신규 설치 대상 확장 프로그램 (총 2개 - 초경량 대체제)**

- `mhutchie.git-graph` (Git Graph - GitLens 대비 극히 가벼운 커밋 히스토리 비주얼라이저)
- `humao.rest-client` (REST Client - 무거운 GUI 기반 Thunder Client를 완벽히 대체하는 텍스트 기반 초경량 API 요청 도구)

---

## Verification Plan

### Automated Steps
- **설치 목록 재조회**: `antigravity-ide.cmd --list-extensions`를 재구동하여 삭제가 완료되었는지, 그리고 신규 필수 확장이 잘 탑재되었는지 확인합니다.
- **IDE 프로세스 모니터링**: 명령어 `antigravity-ide.cmd -s` 혹은 Windows 작업 관리자 조회를 통해 불필요한 백그라운드 프로세스(예: `java`, `rust-analyzer` 등)의 유휴 CPU/RAM 소모가 감소했는지 점검합니다.

### Manual Verification
- IDE를 재실행한 뒤, 로딩 속도 향상 여부와 반응 지연(렉) 개선 여부를 윤겸스님이 직접 체감 검증합니다.
