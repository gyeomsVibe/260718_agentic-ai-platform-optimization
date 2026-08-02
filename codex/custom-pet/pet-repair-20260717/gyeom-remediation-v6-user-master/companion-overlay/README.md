# Gyeom Pet Overlay

> 공식 Codex Pet 설치본이 아닌 보조 오버레이입니다. 이 도구의 `8×9` 아틀라스는
> Codex Pet v2의 `8×11` 스프라이트 시트와 호환되거나 서로 대체되지 않습니다.
> 공식 설치 규격은 [커스텀 펫 매뉴얼](../../../custom-pet-manual/)을 확인하세요.

Codex의 서명된 네이티브 Pet을 수정하지 않고, Gyeom의 표준 9개 행동을
투명한 항상 위 Windows 오버레이로 재생하는 Companion MVP입니다.

대기 중에는 `idle`의 눈깜빡임 루프를 유지하고, 약 8초 뒤부터 입력 기다림,
주변 살피기, 가벼운 인사를 순서대로 실행한 뒤 다시 대기로 돌아옵니다. 현재
보유한 자산에는 하품 행이 없으므로 하품은 이 MVP의 기능으로 표기하지 않습니다.
모든 9개 행동은 원본 캐릭터의 크기와 가로세로 비율을 1:1 픽셀 배율로
유지합니다. 점프나 웅크림처럼 자세 때문에 외곽 높이가 달라지는 프레임을 억지로
확대하지 않습니다. 모든 프레임은 기본 자산보다 약 60% 느리게 재생해, 동작을
읽을 수 있지만 슬로모션처럼 보이지 않도록 조정했습니다. 상품 완성본은 `waving`
4프레임과 `review` 6프레임을 전체 행 단위로 다시 제작해 손 연속성, 검토 의미,
크기와 기준선을 함께 검증했습니다.

## 실행

`Start-GyeomPetOverlay.cmd`를 더블클릭합니다.

- 왼쪽 드래그: 위치 이동
- 오른쪽 클릭: 9개 행동 직접 선택, 9개 동작 데모, 대기 성격 루프 켜기/끄기
- `Esc`: 종료

## 상태 전환

별도 터미널에서 다음처럼 실행합니다.

```powershell
.\Set-GyeomPetState.ps1 -State running
.\Set-GyeomPetState.ps1 -State review -DurationMs 3000
.\Set-GyeomPetState.ps1 -State failed -DurationMs 2500
.\Set-GyeomPetState.ps1 -Clear
.\Set-GyeomPetState.ps1 -State idle -PersonalityEnabled $false
```

`-DurationMs`를 지정하면 시간이 지난 뒤 `idle`로 돌아갑니다. 이 상태 파일
인터페이스는 이후 로컬 자동화가 안전하게 연결할 수 있는 경계입니다. 현재
Codex 데스크톱은 Pet 작업 상태를 외부에 제공하지 않으므로, 이 도구는 Codex의
서명된 앱 파일을 수정하거나 작업 내용을 읽지 않습니다.

## 데모 검수

```powershell
powershell.exe -NoProfile -STA -File .\GyeomPetOverlay.ps1 -Demo
```

## 2분 상품성 검수

1. 오버레이를 실행하고 대기 성격 루프를 켠다.
2. 2분 동안 눈깜빡임, 입력 기다림, 주변 살피기, 가벼운 인사가 각각 보이는지
   기록한다. `idle`의 반복 프레임도 변화 1회로 센다.
3. 다음 두 명령으로 업무 상태와 복귀를 확인한다.

```powershell
.\Set-GyeomPetState.ps1 -State running -DurationMs 3000
.\Set-GyeomPetState.ps1 -State review -DurationMs 3000
```

4. 2분 동안 다섯 번 이상 명확한 변화가 보이고, 창 이동·우클릭 메뉴·Esc 종료가
   정상 동작하면 MVP 통과다.

자동 검증용으로는 아래처럼 관측 기록 JSON을 남길 수 있다.

```powershell
powershell.exe -NoProfile -STA -File .\GyeomPetOverlay.ps1 `
  -AutoCloseAfterSeconds 120 -DiagnosticsOut .\qa\two-minute-observation.json
```

이 JSON은 상태 전환 횟수를 증명하지만, 화면에서의 체감 품질은 사람이 함께
확인해야 한다.

`assets/spritesheet.png`은 검증된 8×9 Gyeom 표준 아틀라스입니다.
