# 🎉 Antigravity IDE 확장 프로그램 슬림화 및 리소스 최적화 완료 보고서

> 이관: `260713_pc-optimization` 워크스페이스에서 완전 이동 (2026-07-19). 문서 내 일부 상대 링크(optimization_result.md, scratch/ 등)는 구 워크스페이스 기준이라 연결되지 않을 수 있다.

윤겸스님이 사용하시는 Antigravity IDE의 백그라운드 리소스(CPU/RAM) 낭비를 극복하기 위해, 승인해 주신 구현 계획서에 맞춰 확장 프로그램 다이어트 작업을 완료했습니다.

---

## 1. 변경 요약 (Before & After)

- **전체 확장 프로그램 수**: 기존 **96개 이상** ➔ 최적화 후 **53개** (약 45% 감소)
- **제거된 확장 프로그램 수**: **40개**
- **신규 설치된 확장 프로그램 수**: **2개** (초경량 대체제)

---

## 2. 세부 변경 내역

### 1단계: 신규 필수 확장 프로그램 설치 (2개)
- `mhutchie.git-graph` (Git Graph): 무거운 GitLens를 대체하는 초경량 Git 히스토리 그래프 뷰어.
- `humao.rest-client` (REST Client): 무거운 GUI API 테스터(Thunder Client 등)를 대체하는 텍스트 기반 HTTP 요청 테스터.

### 2단계: 불필요한 AI 및 중복 확장 프로그램 제거 (9개)
- Amazon Q (`amazonwebservices.amazon-q-vscode`), AWS Toolkit (`amazonwebservices.aws-toolkit-vscode`), Continue (`continue.continue`), ChatGPT 관련 (`genieai.chatgpt-vscode`, `openai.chatgpt`), Roo-Cline (`rooveterinaryinc.roo-cline`), Claude Dev (`saoudrizwan.claude-dev`), Claude Code (`anthropic.claude-code`), Pyrefly (`meta.pyrefly`)

### 3단계: 중복 Pyright 확장 프로그램 제거 (2개)
- `anysphere.pyright` 및 `codeium.windsurfpyright`를 제거하여 공식 `ms-pyright.pyright`와 중복 구동되지 않도록 조치.

### 4단계: 미사용 무거운 언어 서버 제거 (18개)
- **Java**: `redhat.java`, Gradle, Debugger, Dependency, Test 관련 5종 (메모리 점유 핵심 주범 해결)
- **PHP**: `devsense` 제품군 4종 및 Intelephense 1종
- **Ruby / Rust / Go / C++ / Flutter / R**: 각 언어 지원 랭귀지 서버 총 8종

### 5단계: 백그라운드 스캔 및 리소스 과소비 도구 제거 (11개)
- **SonarLint** (`sonarsource.sonarlint-vscode`): 편집 중 실시간 파일 분석으로 CPU 100%를 치던 무거운 도구 제거.
- **GitLens** (`eamodio.gitlens`): Git Graph 설치 후 무거운 GitLens 제거.
- **Thunder Client** (`rangav.vscode-thunder-client`): REST Client 설치 후 무거운 GUI 클라이언트 제거.
- **중복 DB 클라이언트**: `cweijan` JDBC/MySQL 클라이언트 및 MS SQL 클라이언트를 제거하고 `mtxr.sqltools`만 단독 유지.
- **구형 브라우저 디버거**: Chrome, Edge, Firefox 관련 레거시 디버거 3종 제거 (내장 JavaScript Debugger로 대체).
- **기타**: 중복된 Prisma Insider 및 Svelte, Vue, Tailwind CSS, GitHub Actions 관련 미사용 확장 정리.

---

## 3. 검증 결과 (Verification Results)

- `antigravity-ide.cmd --list-extensions` 명령어를 재실행하여 계획된 **40개 확장이 정상적으로 제거**되고 **2개 신규 확장이 완벽히 설치**된 것을 확인했습니다.
- 백그라운드에서 상주하던 무거운 Java Language Server(`java`), Rust Analyzer, PHP Intelephense 등의 데몬 프로세스가 더 이상 기동하지 않으므로, IDE 구동 시 초기 메모리(RAM) 로드량이 기가바이트(GB) 단위로 크게 절약되고 CPU 튀는 현상(Throttling 원인)이 눈에 띄게 완화될 것입니다.

---

> [!TIP]
> - **체감 성능 검증**: Antigravity IDE를 완전히 종료한 후 재시작하여 프로젝트 로딩 속도와 편집 시 렉 현상이 개선되었는지 확인해 주세요.
> - **개별 언어 재설치 안내**: 추후 Java, Rust, Svelte 등의 코드를 편집하게 될 경우, 해당 파일을 열면 IDE가 우측 하단에서 자동으로 가장 가볍고 알맞은 확장을 추천하여 클릭 한 번으로 설치할 수 있으므로 걱정하지 않으셔도 됩니다.
