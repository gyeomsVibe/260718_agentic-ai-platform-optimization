# 플랫폼 자동업데이트 운영 가이드

상태: `VERIFIED_RESULT`
최종 검증: 2026-07-19 (Asia/Seoul)

## 목표와 범위

Windows 로그인 직후 사용자에게 창을 표시하지 않고 다음 개발 플랫폼의 최신 안정판을 확인한다.

| 순서 | 플랫폼 | 업데이트 방식 | 검증 상태 |
| --- | --- | --- | --- |
| 1 | Codex CLI | npm 전역 설치 갱신 | 성공 (`0.144.6`) |
| 2 | Claude Code | 제품 내장 자동 업데이트 | 활성화 (`2.1.214`) |
| 3 | Antigravity IDE | winget 공식 패키지 조회·무인 갱신 | 최신 상태 |
| 4 | Antigravity 2.0 | winget 공식 패키지 조회·무인 갱신 | 최신 상태 |
| 5 | Antigravity CLI | `agy update` | 성공 (`1.1.4`) |

이 구성은 로그인 후 IDE를 열기 전에 CLI와 앱을 최신화한다. 실행 중인 Windows 바이너리를 강제로 교체하지 않으며, 업데이트가 없으면 정상 종료한다.

## 활성 시작 프로그램

두 항목 모두 현재 사용자(`HKCU`)의 `Software\\Microsoft\\Windows\\CurrentVersion\\Run`에 등록한다. `wscript.exe //B`로 실행하므로 콘솔 창이 표시되지 않는다.

| 레지스트리 값 | 실행 스크립트 | 역할 |
| --- | --- | --- |
| `Codex CLI Logon Updater` | `Update-CodexCliAtLogon.vbs` | `npm install -g @openai/codex@latest --no-audit --no-fund` |
| `Antigravity Sequential Logon Updater` | `Update-AntigravityAtLogon.vbs` | IDE → 2.0 → CLI 순차 갱신 |

현재 활성 스크립트와 로그는 운영 워크스페이스 `260713_pc-optimization/.codex-tools/`에 있다. 이 문서는 구성 원본의 운영 설명서이며, 로그와 npm 캐시는 Git에 포함하지 않는다.

## Windows 완료 알림

Codex CLI와 Antigravity 순차 업데이터는 각 실행이 끝나면 Windows 기본 알림 센터에 토스트 알림을 보낸다. `wscript.exe //B`와 `powershell.exe -WindowStyle Hidden`을 사용하므로 업데이트 중 콘솔 창은 표시하지 않는다.

| 알림 제목 | 표시 내용 | 의미 |
| --- | --- | --- |
| `Codex CLI auto-update` | 업데이트 점검 완료, 건너뜀 또는 실패 코드 | Codex CLI 갱신 결과 |
| `Antigravity auto-update` | IDE·2.0·CLI 각각의 완료, 최신, 건너뜀 또는 실패 상태 | 순차 갱신 결과 |

- `completed`는 업데이트 명령이 정상 종료했음을 뜻하며, 실제 새 버전 설치 여부는 패키지 관리자 로그에서 확인한다.
- `latest`는 winget에서 적용할 업그레이드가 없었다는 정상 상태다.
- 알림이 보이지 않으면 Windows의 **설정 > 시스템 > 알림**에서 `Windows PowerShell` 알림이 허용되어 있는지 확인한다. 알림 센터에서도 최근 결과를 확인할 수 있다.
- 점검용으로는 `cscript //NoLogo <script> /test /notify`를 실행한다. 실제 패키지 갱신은 수행하지 않고 토스트 호출만 시험한다.

## 플랫폼별 동작

### Codex CLI

- npm 전용 캐시를 스크립트 옆 `npm-cache/`에 사용한다. 기본 npm 캐시 권한 문제를 피하기 위한 조치다.
- `codex update`는 Windows에서 실행 중인 `codex.exe` 파일 잠금에 걸릴 수 있으므로 사용하지 않는다.
- 로그인 시 실행하면 IDE·CLI가 시작되기 전이라 교체 충돌을 피할 수 있다.

### Claude Code

- Native 설치본의 내장 자동 업데이트를 사용한다. 별도 시작 프로그램을 만들지 않는다.
- 시작 시와 실행 중에 백그라운드로 업데이트를 확인하며, 다음 실행 때 적용한다.
- 상태 점검: `claude doctor`

### Antigravity

순차 스크립트는 아래 명령을 모두 숨김으로 실행하고 앞 단계가 종료될 때까지 기다린다.

```text
winget upgrade --id Google.AntigravityIDE --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
winget upgrade --id Google.Antigravity --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
agy update
```

- 패키지 `Google.AntigravityIDE`는 Antigravity IDE, `Google.Antigravity`는 Antigravity 2.0이다.
- winget 종료 코드 `-1978335189`는 해당 소스에서 적용할 업그레이드가 없다는 정상 상태로 기록한다.
- CLI는 winget 설치 이력과 무관하게 동작하도록 공식 `agy update` 명령으로 갱신한다.

## 검증 절차

로그인 직후 다음 항목을 확인한다.

```powershell
codex --version
npm list -g @openai/codex --depth=0
claude doctor
agy --version
winget upgrade --id Google.AntigravityIDE --exact --source winget
winget upgrade --id Google.Antigravity --exact --source winget
```

로그 파일:

- `codex-cli-logon-updater.log`
- `antigravity-logon-updater.log`

Antigravity 로그에서 마지막 실행이 `Antigravity IDE is already up to date.`, `Antigravity 2.0 is already up to date.`, `Antigravity CLI update check completed successfully.`이면 정상이다.

## 장애 대응과 롤백

1. 실행 중인 플랫폼을 종료하고 로그의 마지막 종료 코드를 확인한다.
2. winget 오류는 먼저 `winget source update` 후 동일한 `winget upgrade --id ...` 명령으로 재현한다.
3. Codex npm 오류는 전용 캐시 경로의 쓰기 권한과 `npm.cmd` 위치를 확인한다.
4. 자동 실행을 중지해야 하면 해당 `Run` 레지스트리 값만 제거한다. 설치된 IDE·CLI와 사용자 설정은 제거하지 않는다.

## 유지관리 원칙

- 시작 프로그램은 제품별로 하나만 유지한다.
- 새 설치 관리자·패키지 관리자를 추가하지 않는다.
- 로그, 다운로드 캐시, 인증 정보는 저장소에 커밋하지 않는다.
- 활성 스크립트를 다른 워크스페이스로 옮길 때는 레지스트리 경로를 명시적으로 변경하고 `cscript //NoLogo <script> /test`로 먼저 검증한다.
