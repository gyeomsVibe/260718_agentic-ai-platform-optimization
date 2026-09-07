<#
    Invoke-AiEnvMaintenance.ps1 — 주기 유지보수 오케스트레이터
    ────────────────────────────────────────────────────────────────
    C3P 합의 반영판. 두 모드로 실행한다.

      -Mode Watch   (일간, 경량): 건강검진 + C/D 여유율 감시 + 신규유입 감시 + 경보. 변경 없음.
      -Mode Weekly  (주간, 정리): Watch + 안전 Temp 정리 + 정션 복구(기본 DRYRUN).

    합의 반영:
      - D 여유율도 감시 (이관 후 데이터는 D 에 쌓이므로).
      - 감시(일)와 정리(주) 분리.
      - 목적함수 = '여유율 유지'. 유지 불가면 자동조작이 아니라 경보.
      - 정션 복구는 기본 DRYRUN. 실제 변경은 -RepairApply 명시해야만.
      - 삭제는 Temp 24h 경과 파일에 한정. 휴지통·활성폴더·사용자데이터·시스템영역 무접촉.

    경로: 형제 스크립트는 $PSScriptRoot 기준. 로그는 $AiRoot\_maintenance-logs (repo 밖).
    사용자 레벨로 완결(관리자 불요).
#>
[CmdletBinding()]
param(
    [ValidateSet('Watch', 'Weekly')][string]$Mode = 'Watch',
    [switch]$RepairApply,
    [int]$CFreeWarn = 40,
    [int]$CFreeCrit = 35,
    [int]$DFreeWarn = 15,
    [int]$DFreeCrit = 8
)

$ErrorActionPreference = 'Continue'
$Here = $PSScriptRoot
$AiRoot = if ($env:AI_HOME) { $env:AI_HOME } else { 'D:\AI-Models' }
$LogDir = Join-Path $AiRoot '_maintenance-logs'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$log = Join-Path $LogDir ("maintenance-{0}-{1}.log" -f $Mode, (Get-Date -Format 'yyyyMMdd-HHmmss'))
function W($m) { $l = "$(Get-Date -Format 'HH:mm:ss')  $m"; Write-Host $l; Add-Content -LiteralPath $log -Value $l -Encoding UTF8 }
$alerts = @()

W "=== AI 환경 유지보수 시작  Mode=$Mode  AiRoot=$AiRoot ==="

# ── 1. 건강검진 (읽기 전용) ──────────────────────────────────────────
$health = Join-Path $Here 'Test-AiEnvHealth.ps1'
if (Test-Path $health) {
    W "[1] 건강검진 실행"
    $h = & pwsh -NoProfile -File $health 2>&1
    $rc = $LASTEXITCODE
    ($h | Where-Object { $_ -match 'FAIL|WARN' }) | ForEach-Object { W "   $_" }
    W "   건강검진 종료코드 = $rc"
    if ($rc -ne 0) { $alerts += "건강검진 실패(exit $rc) — 로그 확인 필요" }
}
else { W "[1] 건강검진 스크립트 없음: $health"; $alerts += "Test-AiEnvHealth.ps1 없음" }

# ── 2. 용량 임계 감시 (C 와 D 둘 다) ────────────────────────────────
W "[2] 용량 임계 감시"
foreach ($dl in 'C', 'D') {
    $v = Get-Volume -DriveLetter $dl
    $pct = [math]::Round($v.SizeRemaining / $v.Size * 100, 1)
    $gb = [math]::Round($v.SizeRemaining / 1GB, 1)
    $warn = if ($dl -eq 'C') { $CFreeWarn } else { $DFreeWarn }
    $crit = if ($dl -eq 'C') { $CFreeCrit } else { $DFreeCrit }
    $tag = if ($pct -lt $crit) { 'CRIT' } elseif ($pct -lt $warn) { 'WARN' } else { 'OK' }
    W "   ${dl}: $pct% 여유 ($gb GB) [$tag]"
    if ($tag -ne 'OK') { $alerts += "${dl}드라이브 여유 $pct% ($tag, 경고선 ${warn}%)" }
}

# ── 3. 주간 모드 전용: 안전 Temp 정리 ───────────────────────────────
if ($Mode -eq 'Weekly') {
    W "[3] 안전 Temp 정리 (24h 경과분, 활성폴더 제외)"
    $t = "$env:LOCALAPPDATA\Temp"
    $keepPatterns = @('codex-ollama-sync-*', 'node-compile-cache', 'WinGet')   # 활성/최신 보존
    $cut = (Get-Date).AddDays(-1)
    $before = (Get-Volume -DriveLetter C).SizeRemaining
    $del = 0; $freed = 0
    foreach ($item in Get-ChildItem $t -Force -ErrorAction SilentlyContinue) {
        if ($item.LastWriteTime -ge $cut) { continue }                     # 24h 이내는 보존
        $isKeep = $false
        foreach ($p in $keepPatterns) { if ($item.Name -like $p) { $isKeep = $true; break } }
        if ($isKeep) { continue }
        try {
            $sz = if ($item.PSIsContainer) { (Get-ChildItem $item.FullName -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } else { $item.Length }
            Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
            $del++; $freed += [long]$sz
        }
        catch { }   # 잠긴 항목은 조용히 건너뜀 (다음 주기 재시도)
    }
    W "   삭제 $del 항목 / 약 $([math]::Round($freed/1GB,2)) GB"
}
else { W "[3] (Watch 모드 — Temp 정리 생략)" }

# ── 4. 정션 복구 (기본 DRYRUN) ──────────────────────────────────────
if ($Mode -eq 'Weekly') {
    $repair = Join-Path $Here 'Repair-AiEnv.ps1'
    if (Test-Path $repair) {
        $rmode = if ($RepairApply) { 'APPLY' } else { 'DRYRUN' }
        W "[4] 정션 복구 점검 ($rmode)"
        if ($RepairApply) { & pwsh -NoProfile -File $repair -Apply 2>&1 | ForEach-Object { W "   $_" } }
        else { & pwsh -NoProfile -File $repair 2>&1 | ForEach-Object { W "   $_" } }
    }
    else { W "[4] Repair-AiEnv.ps1 없음" }
}

# ── 5. 신규 유입 감시 ───────────────────────────────────────────────
W "[5] 신규 유입 감시"
$knownLeaf = @('.sonarlint', '.cache', '.gradle', '.vscode', '.codex', '.gemini', '.antigravity-ide',
    '.antigravity_cockpit', '.local', '.claude', 'codex-oversized-rollouts-20260726')
$suspects = Get-ChildItem "$env:USERPROFILE" -Force -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '.*' -and $knownLeaf -notcontains $_.Name -and $_.Attributes -notmatch 'ReparsePoint' } |
    ForEach-Object {
        $s = (Get-ChildItem $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($s -gt 200MB) { [PSCustomObject]@{ Name = $_.Name; GB = [math]::Round($s / 1GB, 2) } }
    }
if ($suspects) { $suspects | ForEach-Object { W "   신규 후보: $($_.Name) ($($_.GB) GB) — 이관 검토 제안"; $alerts += "신규 AI 폴더 $($_.Name) $($_.GB)GB" } }
else { W "   신규 대형 폴더 없음" }

# ── 6. 경보 요약 (로그가 정본) ──────────────────────────────────────
W "=== 요약: 경보 $($alerts.Count)건 ==="
$alerts | ForEach-Object { W "   ! $_" }
W "로그: $log"
exit ([int]($alerts.Count -gt 0))
