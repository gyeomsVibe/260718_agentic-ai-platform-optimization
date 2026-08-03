# Gyeom Pet Overlay

> 공식 Codex Pet 설치본이 아닌 보조 오버레이입니다. 이 도구의 `8×9` 아틀라스는
> Codex Pet v2의 `8×11` 스프라이트 시트와 호환되거나 서로 대체되지 않습니다.
> 공식 설치 규격은 [커스텀 펫 매뉴얼](../../../custom-pet-manual/)을 확인하세요.

Codex의 서명된 네이티브 Pet을 수정하지 않고, Gyeom의 생활·교감·업무 행동을
투명한 항상 위 Windows 오버레이로 재생하는 Companion입니다.

대기 중에는 호흡과 눈깜빡임이 계속 재생됩니다. 약 4초 뒤부터 두리번거리기,
기지개, 하품, 인사, 검토가 차례로 나타나고 매 동작이 끝나면 기본 대기로
돌아옵니다. 새 생활 동작은 높이 256픽셀의 별도 투명 셀을 사용합니다. 따라서
팔을 위로 뻗는 기지개에서도 몸을 작게 줄이지 않고, 기존 캐릭터와 같은 몸 높이와
발 기준선을 유지합니다.

기존 9개 업무 상태는 각각의 느린 재생 속도를 유지하고, 새 생활 동작은 동작별
자연스러운 시간을 사용합니다. 전역 속도 배율로 모든 행동을 똑같이 늘이지
않습니다.

## 실행

`Start-GyeomPetOverlay.cmd`를 더블클릭합니다.

- 왼쪽 드래그: 위치 이동
- 오른쪽 클릭: 생활·교감·업무 행동 직접 선택, 전체 데모, 자동 생활 동작 켜기/끄기
- `Esc`: 종료

## 상태 전환

별도 터미널에서 다음처럼 실행합니다.

```powershell
.\Set-GyeomPetState.ps1 -State running
.\Set-GyeomPetState.ps1 -State review -DurationMs 3000
.\Set-GyeomPetState.ps1 -State idle-yawn
.\Set-GyeomPetState.ps1 -State idle-stretch
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

## 60초 상품성 검수

1. 오버레이를 실행하고 자동 생활 동작을 켠다.
2. 60초 동안 호흡·눈깜빡임, 두리번거리기, 기지개, 하품, 인사, 검토가 각각
   보이는지 기록한다.
3. 다음 두 명령으로 업무 상태와 복귀를 확인한다.

```powershell
.\Set-GyeomPetState.ps1 -State running -DurationMs 3000
.\Set-GyeomPetState.ps1 -State review -DurationMs 3000
```

4. 60초 동안 여섯 상태가 모두 보이고, 크기 튐 없이 기본 자세로 복귀하며,
   창 이동·우클릭 메뉴·Esc 종료가 정상 동작하면 MVP 통과다.

자동 검증용으로는 아래처럼 관측 기록 JSON을 남길 수 있다.

```powershell
powershell.exe -NoProfile -STA -File .\GyeomPetOverlay.ps1 `
  -AutoCloseAfterSeconds 60 -DiagnosticsOut .\qa\sixty-second-observation.json
```

이 JSON은 상태 전환 횟수를 증명하지만, 화면에서의 체감 품질은 사람이 함께
확인해야 한다.

- `assets/spritesheet-normalized.png`: 기존 9개 상태 아틀라스
- `assets/life-motions.png`: 호흡·하품·기지개·두리번거리기 생활 모션 아틀라스
- `qa/life-motion-ab-contact-sheet.png`: 이전 기준선과 새 실화면의 A/B 검수표
