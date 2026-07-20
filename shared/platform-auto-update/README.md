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
| [OPERATIONS.md](OPERATIONS.md) | 명령, 로그, 복구 방법을 포함한 상세 운영 가이드다. |

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

## 하루 1회 정시 갱신 체계 (2026-07-19 최종 재설계)

모든 자동업데이트는 **로그온마다가 아니라 하루 1회**, 작업 스케줄러가 정시에 실행한다.
Claude Code의 **자체 업데이트**만 제품 내장 기능으로 유지한다.

| 작업 스케줄러 이름 | 시각 | 무엇을 갱신 |
|---|---|---|
| `Codex CLI Daily Update` | 매일 **15:00** | Codex CLI (npm) |
| `Antigravity Daily Update` | 매일 **15:10** | Antigravity IDE·2.0·CLI (winget) |
| `GitHub CLI Daily Update` | 매일 **15:20** | GitHub CLI (winget) |

> **왜 15시대인가?** 30일 부팅·종료 이벤트 분석 결과: 부팅 피크가 **14시**(49회 중 11회),
> 사용 창은 14시~새벽 3시, 오전은 거의 꺼져 있음. 15:00은 ① 켜져 있을 확률이 가장 높은
> 구간의 시작이고 ② 부팅 피크 1시간 뒤라 시작 경합이 없다. 10분 시차로 npm·winget이
> 서로 겹치지 않는다.

- 그날 15시에 PC가 꺼져 있었으면 **다음에 켜질 때 한 번 보충 실행**된다(StartWhenAvailable).
- 점검: `schtasks /query /tn "Codex CLI Daily Update"` (다른 두 작업도 동일)
- 로그온 Run 레지스트리 키와 "Claude Code 시작 감시" 방식(15초 폴링 + 열 때 winget)은
  시작 병목을 만들어 **모두 폐지**됨. 구 스크립트
  ([Update-GitHubCliOnClaudeStart.vbs](scripts/Update-GitHubCliOnClaudeStart.vbs) ·
  [Install-GitHubCliClaudeStartUpdater.ps1](scripts/Install-GitHubCliClaudeStartUpdater.ps1))는
  이력 참고용 — **다시 등록하지 말 것**.
- `/test` 점검 모드는 언제나 즉시 응답한다.
