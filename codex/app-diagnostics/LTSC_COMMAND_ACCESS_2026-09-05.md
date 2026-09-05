# Windows 11 LTSC 명령별 접근 진단

## 판정과 범위

Windows 11 Enterprise LTSC 2024 (EnterpriseS, 24H2, 26100.8875)를 실측했다.
LTSC 자체가 반복 거부의 근본원인이라는 증거는 확보되지 않았다. LTSC 고유의
호환성 또는 이 장치의 보안 정책이 기여할 가능성까지 배제한 것은 아니다.

동일한 `Get-CimInstance Win32_OperatingSystem` 조회가 샌드박스 안에서는 접근
거부, 승인된 밖의 실행에서는 성공했다. 이는 실행 컨텍스트에 따른 접근 차이의
증거다. 어느 WMI ACL, 토큰 권한 또는 조직 정책이 최종적으로 거부했는지는 미확인이다.
레지스트리의 OS 버전 필드 조회는 샌드박스 안에서 성공했다.

## 앞선 진단에 대한 비판

- `setup refresh ... errors=[]`는 초기화 결과다. 개별 명령이나 앱 전체의 성공을 보증하지 않는다.
- 8월 24일 기록의 실패 대상은 `D:\`였다. 과거 `C:\tmp` 사례를 모든 접근 거부에 적용하면 안 된다.
- 기존 진단기는 그룹 이름 포함 여부를 유효 접근 권한으로 취급하고, 감지한 오류에
  명시적 비영 종료 코드를 반환하지 않는다. 이를 전체 정상 판정에 사용하지 않는다.
- 기존 진단기의 인증 파일 검사와 재귀 ACL 복구는 이번 조사에 실행하지 않았다.

## 최소 개선

`Test-CodexCommandAccess.ps1`은 정해진 읽기 전용 조회만 실행한다.
기본 `OsRegistry`는 OS 버전 확인용이며, `OsCim`은 WMI 접근 비교용이다.
성공은 종료 코드 0, 실행 실패는 1이다. 원문 오류·자격증명은 출력하지 않는다.
샌드박스 종류를 자동 추정하거나 스스로 승격하지 않는다.

```powershell
pwsh -NoProfile -File codex/app-diagnostics/Test-CodexCommandAccess.ps1
pwsh -NoProfile -File codex/app-diagnostics/Test-CodexCommandAccess.ps1 -Probe OsCim
```

실패한 경우 같은 명령을 정식 승인 절차로 밖에서 비교한다. 실패한 프로그램의
종료 코드는 호출자가 즉시 확인한다. 자동으로 재귀 ACL 변경, 보안 기능 해제,
OS 교체를 하지 않는다. 새로 거부되는 명령은 대상·실행 컨텍스트·종료 코드와
함께 따로 분류한다. 이 두 probe의 성공을 다른 명령의 성공으로 일반화하지 않는다.

## 실행 검증

- 기본 OsRegistry 실제 실행: 종료 코드 0, EnterpriseS / 24H2 / 26100.8875.
- 별도 PowerShell 프로세스에서 접근 거부 예외 주입: Failed JSON 및 종료 코드 1 확인.
- `npm run check`: 종료 코드 0. 기존 skills audit 경고 20건은 남아 있음.
- Git 상태 조회의 전역 ignore 접근 경고도 승인된 밖의 동일 조회에서는 사라졌다.
  이 역시 실행 컨텍스트 차이를 보여주며, OS 전체 고장의 근거가 아니다.

## 판단을 바꿀 증거

동일한 정책과 Codex 버전에서 일반 Windows 11은 성공하지만 LTSC만 실패하거나,
실패 시각과 일치하는 AppLocker/WDAC/WMI 정책 이벤트 또는 공식 호환성 결함이
확인되면 LTSC/정책 가설의 우선순위를 높인다. 현재 그런 대조 실험은 수행하지 않았다.

## 공식 근거

- [Microsoft LTSC 2024](https://learn.microsoft.com/en-us/windows/whats-new/ltsc/whats-new-windows-11-2024):
  24H2와 유사한 기능 기반이며 일부 일반 채널 앱·Store 지원이 제한될 수 있음.
- [OpenAI Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox):
  Windows 11 권장, elevated sandbox의 낮은 권한 사용자 및 정책 경계 설명.
- [OpenAI 승인 및 보안](https://learn.chatgpt.com/docs/agent-approvals-security):
  승인 정책과 실행 권한의 구분, workspace-write 내부 보호 경로 설명.
