# Gyeom Pet Overlay

Codex의 서명된 네이티브 Pet을 수정하지 않고, Gyeom의 표준 9개 행동을
투명한 항상 위 Windows 오버레이로 재생하는 보조 도구입니다.

## 실행

`Start-GyeomPetOverlay.cmd`를 더블클릭합니다.

- 왼쪽 드래그: 위치 이동
- 오른쪽 클릭: 9개 행동 직접 선택 또는 데모 시작
- `Esc`: 종료

## 상태 전환

별도 터미널에서 다음처럼 실행합니다.

```powershell
.\Set-GyeomPetState.ps1 -State running
.\Set-GyeomPetState.ps1 -State review -DurationMs 3000
.\Set-GyeomPetState.ps1 -State failed -DurationMs 2500
.\Set-GyeomPetState.ps1 -Clear
```

`-DurationMs`를 지정하면 시간이 지난 뒤 `idle`로 돌아갑니다. 이 상태 파일
인터페이스는 이후 로컬 자동화가 안전하게 연결할 수 있는 경계입니다. 현재
Codex 데스크톱은 Pet 작업 상태를 외부에 제공하지 않으므로, 이 도구는 Codex의
서명된 앱 파일을 수정하거나 작업 내용을 읽지 않습니다.

## 데모 검수

```powershell
powershell.exe -NoProfile -STA -File .\GyeomPetOverlay.ps1 -Demo
```

`assets/spritesheet.png`은 검증된 8×9 Gyeom 표준 아틀라스입니다.
