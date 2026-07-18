# 🚀 Antigravity 에이전트 환경설정 기록 (데스크톱)

> 이관: `260713_pc-optimization` 워크스페이스에서 완전 이동 (2026-07-19). 문서 내 일부 상대 링크(optimization_result.md, scratch/ 등)는 구 워크스페이스 기준이라 연결되지 않을 수 있다.

> 대상 환경: **데스크톱** (Intel i7-6700K / Windows 10 Pro 64-bit)
> 관리 도메인: `.agents/` (워크스페이스 로컬) · `~/.antigravity-ide/` · IDE 확장 프로그램
> 이 문서는 **Antigravity 전용**이다. Claude 설정은 각자의 문서에서 다룬다.

---

## 1. Antigravity 최적화 학습모드

Antigravity는 IDE 통합형 AI 에이전트로, 개발 시 백그라운드 확장 프로그램들의 상주 점유율이 전체 동작 렉과 전역 컴퓨팅 지연에 막대한 영향을 줍니다.
최적화 격리 관점에서, 본 데스크톱 작업 영역은 불필요한 타 언어 확장팩들을 과감히 걷어내고 에이전트 핵심 구동 부하를 최소화하는 **IDE 다이어트(Slimming)**를 실현했습니다.

| 층위 | Antigravity에서의 위치 |
|---|---|
| **① 로컬 플러그인/확장** | IDE 확장 프로그램 (파이썬 에이전트 특화 구성 완료) |
| **② 로컬 MCP 서버** | 워크스페이스 `.agents/mcp_config.json` (머신 고유값 포함 $\rightarrow$ git 비추적) |
| **③ 사용자 설정** | 워크스페이스 `.agents/config.json` (머신 고유값 포함 $\rightarrow$ git 비추적) |

---

## 2. 필수 도구 스택 (에이전트 정상 동작 기준)

Antigravity 및 로컬 에이전트 구동에 사용 중인 핵심 환경 스택:

| 항목 | 버전 / 상세 |
|---|---|
| OS | Windows 10 Pro 64-bit (10.0.19045) |
| Python | 3.14.5 |
| uv | 0.11.28 (최고속 패키지 관리자) |
| Virtualenv | `.venv` (CPython 3.14.5 interpreter) |
| 가상환경 라이브러리 | `langgraph` (v1.2.9), `pydantic-ai` (v2.9.0), `python-dotenv` (v1.2.2), `langsmith` (v0.10.2) |

---

## 3. IDE 확장 프로그램 슬리밍 (Extension Slimming) 결과

백그라운드에서 JVM(Java Virtual Machine) 프로세스, 인덱싱용 대용량 C++ 분석 서버 등을 띄워 시스템 렉을 유발하던 **22개 확장 프로그램을 일괄 제거**하여 개발 렉을 대폭 단축했습니다.

### 1) 삭제 완료된 확장 프로그램 (총 22개)
- **Java 개발 도구**: `redhat.java`, `vscjava.vscode-java-pack`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-dependency`, `vscjava.vscode-java-test`, `vscjava.vscode-maven`, `vscjava.vscode-gradle` (백그라운드 JVM 메모리 점유 제거)
- **C++/Rust 언어 서버**: `llvm-vs-code-extensions.vscode-clangd`, `rust-lang.rust-analyzer` (인덱서 백그라운드 부하 제거)
- **PHP 관련 도구**: `bmewburn.vscode-intelephense-client`, `devsense.composer-php-vscode`, `devsense.intelli-php-vscode`, `devsense.phptools-vscode`
- **기타 타 언어 툴**: `shopify.ruby-lsp` (Ruby), `reditorsupport.r`, `reditorsupport.r-syntax` (R), `dart-code.dart-code`, `dart-code.flutter` (Flutter/Dart)
- **중복 파이썬 포맷터 및 린터**: `ms-python.black-formatter`, `ms-python.isort` (Ruff 단독 일원화로 제거), `anysphere.pyright` (중복 Pyright 제거)

### 2) 유지된 필수 파이썬 및 에이전트 도구
- `ms-python.python` (공식 파이썬)
- `charliermarsh.ruff` (초고속 통합 린터/포맷터)
- `ms-pyright.pyright` (공식 Pyright 분석기)
- `google.geminicodeassist` (Gemini 공식 서포터)
- `jlcodes.antigravity-cockpit` (IDE 콕핏 대시보드 - 필수)
