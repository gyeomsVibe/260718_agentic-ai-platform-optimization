<#
    AI 환경 건강검진 (읽기 전용)
    ------------------------------------------------------------------
    이 스크립트는 아무것도 변경하지 않는다. 판정과 보고만 한다.

    설계 근거 — 실제로 겪은 실패에서 역산한 검사 항목:
      1. 문서가 실제 상태와 어긋나 있었다        -> 정션 4중 조건 실측
      2. 파일수/바이트 비교가 거짓 PASS를 냈다   -> 열거오류 0건 강제 증명
      3. .npmrc 를 고쳐도 환경변수가 이겼다      -> 실효값 vs 기재값 대조
      4. 죽은 PATH가 진짜 문제를 가렸다          -> PATH 위생 검사
      5. 정션 대상이 또 정션이면 연쇄 붕괴한다   -> 중첩/순환 검사
      6. 고아 폴더가 조용히 쌓였다               -> 고아 탐지

    경로는 머신 고유값을 하드코딩하지 않는다.
      $U      = $env:USERPROFILE
      $AiRoot = $env:AI_HOME (미설정 시 D:\AI-Models 폴백)

    사용법:  pwsh -File Test-AiEnvHealth.ps1  [-Quiet]
#>
[CmdletBinding()]
param([switch]$Quiet)

$ErrorActionPreference = 'Continue'
$script:Fail = 0
$script:Warn = 0
$U = $env:USERPROFILE
$AiRoot = if ($env:AI_HOME) { $env:AI_HOME } else { 'D:\AI-Models' }

function Section($t) { if (-not $Quiet) { Write-Host "`n=== $t ===" -ForegroundColor Cyan } }
function Ok   ($m) { if (-not $Quiet) { Write-Host "  [PASS] $m" -ForegroundColor Green } }
function Bad  ($m) { $script:Fail++; Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Note ($m) { $script:Warn++; if (-not $Quiet) { Write-Host "  [WARN] $m" -ForegroundColor Yellow } }

<#
  정션 판정은 두 단계로 한다.
  .NET/PowerShell 의 LinkType·Target 속성은 해당 디렉터리를 다른 프로세스가 열어두면
  reparse 조회에 실패해 조용히 빈 값을 돌려준다. 그래서 디렉터리 엔트리에서 바로 읽히는
  ReparsePoint 속성을 1차 근거로 삼고, Target 은 property -> fsutil 순으로 폴백한다.
#>
function Test-FsutilReparse($Path) {
    # fsutil 2차 의견: Mount Point(정션) 태그 0xa0000003 이 보이면 정션이 맞다.
    $raw = fsutil reparsepoint query "$Path" 2>$null
    [bool]($raw | Select-String -Pattern '0xa0000003|Mount Point' -Quiet)
}

function Get-JunctionInfo {
    param([Parameter(Mandatory)][string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return [PSCustomObject]@{ Exists = $false; IsJunction = $false; Target = $null; Source = 'none' } }
    $isJunction = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)

    # 음성 재확인(flapping/일시 조회실패 방지): 속성이 '정션 아님'이면 짧은 재시도 +
    # fsutil 2차 의견으로 확정한다. 진짜 일반폴더면 fsutil 도 정션이 아니라 하므로 FAIL 유지.
    # 일시적 되돌림/조회 글리치면 fsutil 이 바로잡아 거짓 FAIL 을 없앤다. (예약작업 실측 반영)
    if (-not $isJunction) {
        Start-Sleep -Milliseconds 200
        $item2 = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        $isJunction = [bool]($item2.Attributes -band [IO.FileAttributes]::ReparsePoint)
        if (-not $isJunction -and (Test-FsutilReparse $Path)) { $isJunction = $true }
    }

    $target = $item.Target
    if ($target -is [array]) { $target = $target | Select-Object -First 1 }
    $source = 'property'
    if ([string]::IsNullOrWhiteSpace($target) -and $isJunction) {
        $raw = fsutil reparsepoint query "$Path" 2>$null
        $line = $raw | Where-Object { $_ -match 'Print\s*Name|Substitute\s*Name' } | Select-Object -First 1
        if ($line -match ':\s*(.+)$') { $target = $Matches[1].Trim() -replace '^\\\\\?\\', '' }
        $source = 'fsutil'
    }
    [PSCustomObject]@{ Exists = $true; IsJunction = $isJunction; Target = $target; Source = $source }
}

# 정션 계약: C 경로 -> D 실체. 여기가 유일한 진실의 원천이다.
$Contract = @(
    @{ c = "$U\.sonarlint";                                                d = "$AiRoot\.sonarlint" }
    @{ c = "$U\.cache";                                                    d = "$AiRoot\home\.cache" }
    @{ c = "$U\.gradle";                                                   d = "$AiRoot\home\.gradle" }
    @{ c = "$U\.vscode";                                                   d = "$AiRoot\home\.vscode" }
    @{ c = "$U\codex-oversized-rollouts-20260726";                         d = "$AiRoot\home\codex-oversized-rollouts-20260726" }
    @{ c = "$U\.antigravity-ide";                                          d = "$AiRoot\home\.antigravity-ide" }
    @{ c = "$U\.antigravity_cockpit";                                      d = "$AiRoot\home\.antigravity_cockpit" }
    @{ c = "$U\.gemini\antigravity-browser-profile\OptGuideOnDeviceModel"; d = "$AiRoot\home\.gemini-OptGuideOnDeviceModel" }
    @{ c = "$U\AppData\Local\Android";                                     d = "$AiRoot\LocalAppData\Android" }
    @{ c = "$U\AppData\Local\ms-playwright";                               d = "$AiRoot\LocalAppData\ms-playwright" }
    # SessionSensitive: MSIX 인접 AppData 경로. 앱의 per-user 가상화 때문에 예약작업 등
    # 다른 로그온 세션 토큰에서는 정션이 일반 폴더로 보인다(fsutil 4390). 대화형에서는 정상.
    # 그래서 이 둘은 관측 불가 시 FAIL 이 아니라 WARN 으로 강등한다(거짓 경보 방지).
    @{ c = "$U\AppData\Local\OpenAI";                                      d = "$AiRoot\LocalAppData\OpenAI"; SessionSensitive = $true }
    @{ c = "$U\AppData\Roaming\Antigravity IDE";                           d = "$AiRoot\RoamingAppData\Antigravity IDE"; SessionSensitive = $true }
    # .codex 자체는 rename 이 ACCESS_DENIED 로 막혀 정션을 못 건다. 전체의 90%인 sessions 하위만 옮겼다.
    @{ c = "$U\.codex\sessions";                                           d = "$AiRoot\home\.codex\sessions" }
)

$SettingContract = @(
    @{ name = 'npm cache(실효)'; actual = { (npm config get cache 2>$null) }; expect = "$AiRoot\npm-cache" }
)

# 환경변수 계약: 이 변수들이 D 를 가리켜야 새로 설치되는 도구도 C 를 안 채운다.
$EnvContract = [ordered]@{
    'AI_HOME'               = "$AiRoot"
    'HF_HOME'               = "$AiRoot\HuggingFace"
    'HUGGINGFACE_HUB_CACHE' = "$AiRoot\HuggingFace\hub"
    'TRANSFORMERS_CACHE'    = "$AiRoot\HuggingFace\transformers"
    'TORCH_HOME'            = "$AiRoot\PyTorch"
    'PIP_CACHE_DIR'         = "$AiRoot\pip-cache"
    'NPM_CONFIG_CACHE'      = "$AiRoot\npm-cache"
    'OLLAMA_MODELS'         = "$AiRoot\Ollama"
    'UV_CACHE_DIR'          = "$AiRoot\uv\cache"
    'UV_PYTHON_INSTALL_DIR' = "$AiRoot\uv\python"
    'UV_TOOL_DIR'           = "$AiRoot\uv\tools"
    'UV_INSTALL_DIR'        = "$AiRoot\bin"
}

# 설정하면 안 되는 변수: 설정 시 CLI 와 MSIX 앱이 서로 다른 홈을 써서 분기가 생긴다.
$EnvForbidden = @('CODEX_HOME')

Write-Host "AI 환경 건강검진  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

Section '1. 정션 계약 (ReparsePoint / Target정확 / 대상존재 / 통과열거)'
foreach ($e in $Contract) {
    $leaf = Split-Path $e.c -Leaf
    $j = Get-JunctionInfo -Path $e.c
    if (-not $j.Exists)     { Bad "$leaf : C 경로 없음"; continue }
    if (-not $j.IsJunction) {
        if ($e.SessionSensitive) {
            Note "$leaf : 이 세션에서 정션 미관측(MSIX 인접 경로) — 대화형 검진에서 확인 필요"
        }
        else { Bad "$leaf : Junction 아님 — 일반 폴더로 되돌아갔을 수 있음" }
        continue
    }
    if ([string]::IsNullOrWhiteSpace($j.Target)) {
        Note "$leaf : 정션 확인됨(ReparsePoint)이나 Target 조회 실패 — 앱 실행 중일 수 있음"
    }
    elseif ($j.Target.TrimEnd('\') -ne $e.d.TrimEnd('\')) {
        Bad "$leaf : Target 불일치 (실제=$($j.Target) / 계약=$($e.d))"; continue
    }
    if (-not (Test-Path $e.d)) { Bad "$leaf : D 대상 없음 -> $($e.d)"; continue }
    $probeErr = @()
    $top = @(Get-ChildItem -LiteralPath $e.c -Force -ErrorAction SilentlyContinue -ErrorVariable +probeErr)
    if ($probeErr.Count -gt 0) { Bad "$leaf : 정션 통과 열거 실패 — $($probeErr[0].Exception.Message)"; continue }
    if ($top.Count -eq 0)      { Note "$leaf : 정션은 정상이나 내용이 비어 있음" }
    $cf = @(Get-ChildItem -LiteralPath $e.c -Recurse -Force -File -ErrorAction SilentlyContinue).Count
    Ok "$leaf  ($cf 파일$(if($j.Source -eq 'fsutil'){' · target=fsutil'}))"
}

Section '2. 열거 오류 (ACL 접근거부 = 검증 신뢰 불가)'
$enumBad = 0
foreach ($e in $Contract) {
    $err = @()
    Get-ChildItem $e.d -Recurse -Force -Directory -ErrorAction SilentlyContinue -ErrorVariable +err | Out-Null
    if ($err.Count -gt 0) { $enumBad++; Bad "$(Split-Path $e.d -Leaf) : 열거 불가 $($err.Count)건 — 파일수 비교를 신뢰하지 마라" }
}
if ($enumBad -eq 0) { Ok '전 대상 열거 오류 0건' }

Section '3. 중첩·순환 정션'
foreach ($r in "$AiRoot", "$AiRoot\home", "$AiRoot\LocalAppData", "$AiRoot\RoamingAppData") {
    $it = Get-Item $r -Force -ErrorAction SilentlyContinue
    if (-not $it)         { Bad "이관 루트 없음: $r" }
    elseif ($it.LinkType) { Bad "이관 루트가 정션임 ($r) — 연쇄 붕괴 위험" }
}
$dead = @(Get-ChildItem "$AiRoot" -Recurse -Force -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Attributes -match 'ReparsePoint' -and -not (Test-Path $_.Target) })
if ($dead.Count) { $dead | ForEach-Object { Bad "끊어진 정션: $($_.FullName) -> $($_.Target)" } }
else             { Ok '이관 루트 정상 · 끊어진 정션 0건' }

Section '4. 설정 실효값 (환경변수가 설정파일을 이기는 함정)'
foreach ($s in $SettingContract) {
    $a = (& $s.actual); if ($a -is [array]) { $a = $a -join '' }; $a = "$a".Trim()
    if ($a -eq $s.expect) { Ok "$($s.name) = $a" } else { Bad "$($s.name) 불일치  실효='$a'  계약='$($s.expect)'" }
}

Section '4-B. AI 기본경로 환경변수 (신규 도구가 C 를 채우지 않게 하는 방어선)'
$envBad = 0
foreach ($k in $EnvContract.Keys) {
    $v = [Environment]::GetEnvironmentVariable($k, 'User')
    if ([string]::IsNullOrWhiteSpace($v)) { $envBad++; Bad "$k 미설정 — 이 도구는 C 에 캐시를 쌓는다" }
    elseif ($v.TrimEnd('\') -ne $EnvContract[$k].TrimEnd('\')) { $envBad++; Bad "$k 불일치  실효='$v'  계약='$($EnvContract[$k])'" }
}
if ($envBad -eq 0) { Ok "$($EnvContract.Count)개 전부 D 를 가리킴" }
foreach ($k in $EnvForbidden) {
    $reg = Get-ItemProperty 'HKCU:\Environment' -ErrorAction SilentlyContinue
    if ($reg -and $reg.PSObject.Properties[$k]) { Bad "$k 가 설정돼 있음(값='$($reg.$k)') — CLI/MSIX 분기 유발. 제거할 것" }
}
if ($envBad -eq 0) { Ok "금지 변수 $($EnvForbidden -join ', ') 미설정 확인" }

Section '5. PATH 위생'
$pth  = ([Environment]::GetEnvironmentVariable('Path','User') -split ';') | Where-Object { $_ }
$gone = @($pth | Where-Object { -not (Test-Path $_) })
$dup  = @($pth | ForEach-Object { $_.TrimEnd('\').ToLower() } | Group-Object | Where-Object { $_.Count -gt 1 })
if ($gone.Count) { $gone | ForEach-Object { Note "죽은 경로: $_" } }
if ($dup.Count)  { $dup  | ForEach-Object { Note "중복 경로: $($_.Name) x$($_.Count)" } }
if (-not $gone.Count -and -not $dup.Count) { Ok "$($pth.Count)건 전부 유효 · 중복 없음" }

Section '6. 고아 폴더 · .bak 잔여물'
$baks = @(Get-ChildItem $U, "$U\AppData\Local", "$U\AppData\Roaming" -Force -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -like '*.bak' })
if ($baks.Count) { $baks | ForEach-Object { Note ".bak 잔존: $($_.FullName)" } } else { Ok '.bak 잔여물 0건' }
# 주의: 실제 고아를 여기에 추가해 경고를 숨기지 마라. 경고는 정리 대상 신호다.
$known = $Contract.d + @("$AiRoot\npm-cache", "$AiRoot\Ollama", "$AiRoot\home\.codex")
$orphan = @(Get-ChildItem "$AiRoot\home", "$AiRoot\LocalAppData", "$AiRoot\RoamingAppData" -Force -Directory -ErrorAction SilentlyContinue |
            Where-Object { $known -notcontains $_.FullName })
if ($orphan.Count) { $orphan | ForEach-Object { Note "계약에 없는 D 폴더: $($_.FullName)" } } else { Ok '고아 폴더 0건' }

Section '7. 용량 임계치 (C 경보선 35% / 목표 40%)'
foreach ($dl in 'C', 'D') {
    $v = Get-Volume -DriveLetter $dl
    $pct = [math]::Round($v.SizeRemaining / $v.Size * 100, 2)
    $gb  = [math]::Round($v.SizeRemaining / 1GB, 2)
    if     ($dl -eq 'C' -and $pct -lt 35) { Bad  "C: $pct% ($gb GB) — 경보선 미만" }
    elseif ($dl -eq 'C' -and $pct -lt 40) { Note "C: $pct% ($gb GB) — 목표 40% 미달" }
    else                                  { Ok   "${dl}: $pct% ($gb GB)" }
}

Write-Host ''
if ($script:Fail -gt 0) { Write-Host "종합: FAIL $script:Fail 건 / WARN $script:Warn 건" -ForegroundColor Red; exit 1 }
elseif ($script:Warn -gt 0) { Write-Host "종합: 정상 (WARN $script:Warn 건 — 조치 권장)" -ForegroundColor Yellow; exit 0 }
else { Write-Host '종합: 전 항목 정상' -ForegroundColor Green; exit 0 }
