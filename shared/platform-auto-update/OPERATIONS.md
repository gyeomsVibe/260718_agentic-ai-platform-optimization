# 플랫폼 자동업데이트 운영 가이드

상태: `VERIFIED_RESULT`
최종 검증: 2026-07-30 (Asia/Seoul) — 저장소 경로 이동에 따른 예약 작업 경로 재등록 및 무음(`//B`) 보강

## 목표와 범위

Windows 로그인 직후 사용자에게 창을 표시하지 않고 다음 개발 플랫폼의 최신 안정판을 확인한다.

자동업데이트 대상은 **3대 AI 도구(Antigravity·Claude Code·Codex)의 CLI와 Antigravity IDE**이며,
여기에 개발 필수 도구인 **GitHub CLI**를 함께 갱신한다.

| 대상 | 업데이트 방식 | 실행 주체 |
| --- | --- | --- |
| Antigravity IDE + 2.0 + CLI | winget(IDE·2.0) + `agy update`(CLI) | 예약 작업 `Antigravity Daily Update` |
| Codex CLI | npm 전역 설치 갱신 (`@openai/codex`) | 예약 작업 `Codex CLI Daily Update` |
| GitHub CLI | winget 무인 갱신 (`GitHub.cli`) | 예약 작업 `GitHub CLI Daily Update` |
| Claude Code | 제품 **내장** 자동 업데이트 | 별도 스크립트 없음 (Claude Code 자체 처리) |

- Claude Code CLI는 Native 설치본이 스스로 업데이트하므로 외부 스크립트를 두지 않는다.
- Codex 데스크톱 앱(스토어)도 자체 업데이트한다. 위 `Codex CLI`는 npm 설치본 CLI만 대상이다.
- 이 구성은 실행 중인 Windows 바이너리를 강제 교체하지 않으며, 업데이트가 없으면 정상 종료한다.

## 활성 예약 작업 (Scheduled Tasks)

현재 방식은 **Windows 작업 스케줄러의 일일 정시 작업 3개**다. (과거 로그온 Run 키·시작 감시
방식은 앱 시작 병목의 주원인으로 확인되어 폐지했다 — 아래 "하루 1회 정시 갱신 체계" 참조.)
모두 `wscript.exe //B`(무음 배치)로 실행하므로 콘솔 창이나 오류 대화상자가 뜨지 않는다.

| 예약 작업 | 시각 | 실행 스크립트 |
| --- | --- | --- |
| `Antigravity Daily Update` | 15:10 | `Update-AntigravityAtLogon.vbs` (IDE → 2.0 → CLI) |
| `Codex CLI Daily Update` | 15:00 | `Update-CodexCliAtLogon.vbs` (npm 전역 갱신) |
| `GitHub CLI Daily Update` | 15:20 | `Update-GitHubCliDaily.vbs` (winget 갱신) |

- 등록·해제·경로 재설정은 정본 설치 스크립트 [`scripts/Install-PlatformDailyUpdaters.ps1`](scripts/Install-PlatformDailyUpdaters.ps1)로 한다.
  이 스크립트는 자신이 놓인 위치(`$PSScriptRoot`) 기준으로 작업을 재등록하므로,
  **저장소를 옮긴 뒤 새 위치에서 한 번 실행하면 세 작업의 경로가 모두 교정된다.**
- 로그와 npm 캐시는 스크립트 옆에 자동 생성되며 Git에 포함하지 않는다.

> **2026-07-30 경로 교정**: 저장소가 이전 경로에서 `-agentic-ai-workspace\...`로 이동해
> 세 작업이 옛 경로를 가리켜 실패했고, `//B`가 없던 GitHub CLI 작업만 "스크립트 파일을 찾을 수
> 없습니다" 대화상자를 띄웠다. 설치 스크립트의 wscript 인자에 `//B`를 추가하고 현재 위치에서
> 재실행해 세 작업 경로를 교정했다. 세 작업 모두 `LastTaskResult=0x0`(성공) 검증 완료.

처음 사용하는 사람은 [README.md](README.md)를 먼저 읽는다. 자동 실행 흐름, 알림 의미, 가장 쉬운 점검 방법을 비개발자 기준으로 설명한다.

## Windows 완료 알림

Codex CLI와 Antigravity 순차 업데이터는 각 실행이 끝나면 Windows 기본 알림 센터에 토스트 알림을 보낸다. `wscript.exe //B`와 `powershell.exe -WindowStyle Hidden`을 사용하므로 업데이트 중 콘솔 창은 표시하지 않는다.

| 알림 제목 | 표시 내용 | 의미 |
| --- | --- | --- |
| `Codex CLI auto-update` | 업데이트 점검 완료, 건너뜀 또는 실패 코드 | Codex CLI 갱신 결과 |
| `Antigravity auto-update` | IDE·2.0·CLI 각각의 완료, 최신, 건너뜀 또는 실패 상태 | 순차 갱신 결과 |

- `completed`는 업데이트 명령이 정상 종료했음을 뜻하며, 실제 새 버전 설치 여부는 패키지 관리자 로그에서 확인한다.
- `latest`는 winget에서 적용할 업그레이드가 없었다는 정상 상태다.
- `0x8A15002B`는 winget의 `UPDATE_NOT_APPLICABLE`, 즉 적용할 업데이트가 없다는
  정상 상태다. 예약 작업은 이 값을 실패 코드처럼 표시할 수 있으므로, GitHub CLI
  작업은 `winget.exe`를 직접 실행하지 않고 `Update-GitHubCliDaily.vbs` 래퍼를 통해
  실행해야 한다. 래퍼는 이 종료 코드를 성공으로 정규화한다.
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
4. 자동 실행을 전부 중지하려면 `Install-PlatformDailyUpdaters.ps1 -Remove`를 실행한다(세 작업 언등록). 특정 작업만 끄려면 `schtasks /change /tn "<작업명>" /disable`. 설치된 IDE·CLI와 사용자 설정은 제거하지 않는다.

## 유지관리 원칙

- 시작 프로그램은 제품별로 하나만 유지한다.
- 새 설치 관리자·패키지 관리자를 추가하지 않는다.
- 로그, 다운로드 캐시, 인증 정보는 저장소에 커밋하지 않는다.
- 활성 스크립트를 다른 워크스페이스로 옮기면 새 위치에서 `Install-PlatformDailyUpdaters.ps1`을 한 번 실행해 예약 작업 경로를 재등록하고, `cscript //NoLogo <script> /test`로 먼저 검증한다.

### 하루 1회 정시 갱신 체계 (2026-07-19 최종)

- Claude Code 자체는 Native 설치본의 내장 업데이트를 계속 사용한다.
- 로그온 트리거(Run 키)와 "Claude Code 시작 감시"(15초 폴링 + 열 때 winget)는
  **앱 시작 병목의 주원인**으로 확인되어 전부 폐지했다.
- 현재 방식 — 작업 스케줄러 일일 정시 실행 (30일 사용 로그 분석으로 15시대 선정):
  `Codex CLI Daily Update`(15:00) · `Antigravity Daily Update`(15:10) ·
  `GitHub CLI Daily Update`(15:20). 꺼져 있던 날은 다음 부팅 때 1회 보충 실행.
- 상세 설계·근거: [README.md](README.md)의 "하루 1회 정시 갱신 체계" 절.
- 점검: `schtasks /query /tn "Codex CLI Daily Update"` (다른 두 작업 동일).
