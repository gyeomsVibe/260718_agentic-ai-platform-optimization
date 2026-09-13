# 저장소 위생 검사 (Repository Hygiene)

> 특정 섹션에 속하지 않고 **저장소 전체에 걸쳐 반복된 사고 유형**을 `npm run check` 단계에서 막는 검사만 둡니다.
> 섹션 고유 규칙은 각 섹션의 테스트에 둡니다(예: `skills/custom/mia/tests/`).

## 왜 필요한가

이 PC의 Windows PowerShell 5.1 은 BOM 이 없는 UTF-8 파일을 시스템 코드페이지(CP949)로 읽습니다.
그 결과 한글이 깨지고, 스크립트가 파싱되지 않거나 JSON 이 망가집니다. PowerShell 7(`pwsh`)은
같은 파일을 정상으로 읽기 때문에 **한쪽 환경에서만 확인하면 결함이 드러나지 않습니다.**

실제로 일어난 일:

| 날짜 | 사고 |
|---|---|
| 2026-08-02 | BOM 없는 복구 스크립트가 5.1 에서 파싱 실패 → 권한 문제로 오진 |
| 2026-09-13 | 슬래시 별칭 생성기가 5.1 에서 한글을 깨뜨려 `~/.claude/commands` 10개 손상 |
| 2026-09-13 | 한글이 든 `.ps1` 9개가 BOM 없이 추적되고 있었음(`sync-global-rules.ps1` 은 5.1 에서 파싱 불가) |
| 2026-09-13 | `sync-global-rules.ps1` 이 JSON 을 인코딩 지정 없이 읽어 5.1 에서 `ArgumentException` 으로 중단 |

앞의 사고들은 모두 **파일 하나씩 고쳐졌을 뿐 같은 유형을 막는 장치가 없어서** 다른 파일에서 반복됐습니다.

## 검사 항목

`tests/powershell-encoding.test.mjs` (`npm run hygiene:test`, `npm run check` 에 포함)

1. **한글이 든 추적 `.ps1` 은 UTF-8 BOM 을 가진다.**
2. **`Get-Content` 를 인코딩 지정 없이 `ConvertFrom-Json` 에 넘기지 않는다.**
   5.1 에서 한글이 CP949 로 오독되면 두 가지 중 하나가 일어납니다.
   - **조용히 깨진 값으로 읽힘** — 예외가 없어 발견이 가장 어렵습니다(2026-09-13 재현: `"대기 상태"` → `?湲??곹깭`).
   - **JSON 이 망가져 `ArgumentException`** — `-ErrorAction SilentlyContinue` 로도 막히지 않아 스크립트가 중단됩니다.
   `-Encoding UTF8` 을 붙이거나 `[IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)` 로 읽으세요.

검사는 `git ls-files` 로 **추적 중인 파일만** 봅니다. 로컬 임시 파일이나 무시 대상은 대상이 아닙니다.

## 새 스크립트를 추가할 때

```powershell
# 한글이 들어간 .ps1 을 BOM 포함으로 저장
$t = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
[IO.File]::WriteAllText($path, $t, (New-Object Text.UTF8Encoding($true)))
```

5.1 과 `pwsh` 양쪽에서 실행 확인하는 것이 가장 확실합니다.
