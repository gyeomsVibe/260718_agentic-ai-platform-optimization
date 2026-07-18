# Gyeom v2 installation Red-team report

검증 일자: 2026-07-19

## 설치 결과

- 설치 경로: `C:\Users\Kimyoongyeom\.codex\pets\gyeom-v2`
- 설치 파일: `pet.json`, `spritesheet.webp`
- 설치 spritesheet SHA-256:
  `FD597CEB99805A618410F6E29E24EE36BAD2D7324EAE4D529909D5B3A3DB94C8`
- 원본과 설치본의 SHA-256: 일치
- 설치본 strict atlas validation: 통과

## Codex 앱 계약 교차검증

확인한 앱 빌드:
`OpenAI.Codex_26.715.4045.0_x64__2p2nqsd0c76g0`

앱 내부에서 확인한 v2 계약:

- v1 높이: 1872
- v2 높이: 2288
- 공통 너비: 1536
- `spriteVersionNumber: 2`일 때 11행 사용

표준 상태 행 순서:

| 행 | 앱 상태 | 프레임 |
|---:|---|---:|
| 0 | idle | 6 |
| 1 | running-right | 8 |
| 2 | running-left | 8 |
| 3 | waving | 4 |
| 4 | jumping | 5 |
| 5 | failed | 8 |
| 6 | waiting | 6 |
| 7 | running | 6 |
| 8 | review | 6 |
| 9–10 | 16개 look direction | 16 |

후보 아틀라스의 행·프레임 배치는 이 계약과 일치한다.

## 설치본 재검증

- 형식: WebP RGBA
- 크기: 1536×2288
- 셀: 192×208, 8열×11행
- sprite version: 2
- transparent RGB residue: 0 pixels
- 오류: 0
- 경고: 0

## 남은 수동 런타임 검증

Codex 앱 자체는 자동 UI 조작 금지 대상이므로 다음 항목은 사용자가 설정 화면에서
직접 수행해야 한다.

1. Settings → Pets에서 새로고침한다.
2. `Gyeom` 하나만 표시되는지 확인하고 선택한다.
3. 새 작업에서 수행 중, 입력 대기, 완료, 실패 상태를 각각 유발한다.
4. 화면 이동으로 좌·우 달리기와 점프, 포인터 이동으로 16방향 시선을 확인한다.

UI 런타임 확인 전까지 판정은 `설치 성공 / 런타임 검증 대기`이다.
