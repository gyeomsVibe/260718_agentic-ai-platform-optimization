# Windows 플랫폼 자동업데이트: 처음 보는 사람을 위한 안내

이 폴더는 Windows에 로그인하면 Codex와 Antigravity의 업데이트를 조용히 확인하고, 결과를 Windows 알림으로 알려 주는 구성의 정본이다.

## 한눈에 보기

1. Windows에 로그인한다.
2. 시작 프로그램이 이 폴더의 VBS 스크립트를 백그라운드에서 실행한다.
3. Codex CLI와 Antigravity IDE·2.0·CLI의 업데이트를 순서대로 확인한다.
4. 작업이 끝나면 화면 오른쪽 아래와 알림 센터에 결과가 표시된다.

업데이트가 없다는 알림도 정상이다. 이미 최신 버전이라는 뜻이므로 별도 조치가 필요 없다.

```text
Windows 로그인
  -> 시작 프로그램
  -> VBS 자동업데이트 스크립트
  -> 업데이트 확인 또는 설치
  -> Windows 완료 알림 + 로그 기록
```

## 파일 역할

| 파일 | 하는 일 |
| --- | --- |
| [scripts/Update-CodexCliAtLogon.vbs](scripts/Update-CodexCliAtLogon.vbs) | npm으로 Codex CLI의 최신 버전을 확인하고 Windows 알림을 보낸다. |
| [scripts/Update-AntigravityAtLogon.vbs](scripts/Update-AntigravityAtLogon.vbs) | Antigravity IDE → 2.0 → CLI 순서로 갱신하고 결과를 하나의 알림으로 보낸다. |
| [../platform-auto-update.md](../platform-auto-update.md) | 명령, 로그, 복구 방법을 포함한 상세 운영 가이드다. |

## 알림 읽는 법

| 표시 | 뜻 | 사용자가 할 일 |
| --- | --- | --- |
| `completed` | 확인 또는 업데이트 명령이 정상 종료됐다. | 보통 아무것도 하지 않는다. |
| `latest` | 새로 설치할 업데이트가 없다. | 이미 최신 상태다. |
| `skipped` | 필요한 도구가 설치되어 있지 않아 해당 단계만 건너뛰었다. | 그 도구를 사용한다면 설치 상태를 확인한다. |
| `failed (숫자)` | 해당 단계가 오류 코드와 함께 끝났다. | 알림 센터와 `scripts/logs/`의 최신 로그를 확인한다. |

Codex 알림은 전체 결과 한 줄을 표시한다. Antigravity 알림은 IDE, 2.0, CLI 세 단계의 상태를 함께 표시한다.

## 내가 직접 확인하는 가장 쉬운 방법

PowerShell을 열고 저장소 최상위에서 아래 명령을 실행한다.

```powershell
cscript //NoLogo .\shared\platform-auto-update\scripts\Update-CodexCliAtLogon.vbs /test /notify
cscript //NoLogo .\shared\platform-auto-update\scripts\Update-AntigravityAtLogon.vbs /test /notify
```

두 명령은 실제 업데이트를 설치하지 않는다. 스크립트가 읽히는지와 Windows 알림 호출만 시험한다.

## 알림이 안 보일 때

1. Windows **설정 > 시스템 > 알림**을 연다.
2. `Windows PowerShell` 알림이 허용되어 있는지 확인한다.
3. 화면 오른쪽 아래 알림 영역 또는 알림 센터에서 최근 알림을 확인한다.
4. 여전히 안 되면 `scripts/logs/`에서 가장 최근 `.log` 파일의 마지막 줄을 확인한다.

`logs/`와 `npm-cache/`는 실행할 때 자동으로 만들어지는 로컬 운영 파일이다. GitHub에는 올리지 않는다.

## 주의할 점

- 스크립트 이름이나 폴더 위치를 바꾸면 Windows 시작 프로그램의 경로도 함께 바꿔야 한다.
- 이 구성은 현재 사용자 계정에만 적용된다. 다른 Windows 계정에는 별도로 등록해야 한다.
- Claude Code는 제품 내장 자동업데이트를 사용하므로 이 폴더에 별도 업데이트 스크립트가 없다.

## Claude Code 시작 시 GitHub CLI 갱신

Claude Code의 **자체 업데이트**는 제품 내장 기능으로 유지한다. 별도로 `Claude Code GitHub CLI Update Monitor` 작업 스케줄러가 Claude Code 시작을 감지하면 [scripts/Update-GitHubCliOnClaudeStart.vbs](scripts/Update-GitHubCliOnClaudeStart.vbs)를 실행해 GitHub CLI만 갱신한다.

- 완료: `GitHub CLI update completed`
- 최신: `GitHub CLI is already up to date`
- 실패: 오류 코드와 함께 알림 센터·`scripts/logs/github-cli-claude-start-updater.log`에 기록
- 설치·경로 전환: [scripts/Install-GitHubCliClaudeStartUpdater.ps1](scripts/Install-GitHubCliClaudeStartUpdater.ps1)
- 무변경 점검: `cscript //NoLogo .\shared\platform-auto-update\scripts\Update-GitHubCliOnClaudeStart.vbs /test /notify`
