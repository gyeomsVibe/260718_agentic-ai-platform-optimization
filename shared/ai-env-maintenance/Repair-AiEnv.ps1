<#
    Repair-AiEnv.ps1 — 되돌아간 정션을 안전하게 재연결 (쓰기 작업)
    ────────────────────────────────────────────────────────────────
    C3P 합의체(Claude Code·Codex·Antigravity, /CRITIC /REDTEAM /OPTIMIZE)의 반론을 반영한 안전판.
    기본은 미리보기(DRYRUN). 실제 변경은 -Apply 필요.

    안전 게이트:
      G1 프로세스 뮤텍스: 대상 앱이 하나라도 실행 중이면 전체 중단.
      G2 거짓 부분집합 차단: C·D 양쪽 열거 오류 0건이 아니면 SKIP.
      G3 내용 검증: C에만 있거나 C가 더 최신인 파일이 하나라도 있으면 '병합위험' SKIP.
      G4 2회 연속 확인으로만 '정션 풀림' 판정.
      G5 삭제 금지: C원본은 .bak 격리 후에만 재연결. 실패 시 자동 재시도 안 함.

    경로: $U=$env:USERPROFILE, $AiRoot=$env:AI_HOME(폴백 D:\AI-Models). 머신값 하드코딩 없음.
    이 스크립트는 어떤 경우에도 파일을 '삭제'하지 않는다. rename(.bak)만 한다.
#>
[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$LogDir
)

$ErrorActionPreference = 'Continue'
$U = $env:USERPROFILE
$AiRoot = if ($env:AI_HOME) { $env:AI_HOME } else { 'D:\AI-Models' }
if (-not $LogDir) { $LogDir = Join-Path $AiRoot '_maintenance-logs' }
$mode = if ($Apply) { 'APPLY' } else { 'DRYRUN' }

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
    @{ c = "$U\AppData\Local\OpenAI";                                      d = "$AiRoot\LocalAppData\OpenAI" }
    @{ c = "$U\AppData\Roaming\Antigravity IDE";                           d = "$AiRoot\RoamingAppData\Antigravity IDE" }
    @{ c = "$U\.codex\sessions";                                           d = "$AiRoot\home\.codex\sessions" }
)

# G1: 이 프로세스들이 하나라도 살아 있으면 정션 조작을 하지 않는다.
$GuardProcesses = @('claude', 'codex', 'codex-*', 'antigravity*', 'node', 'ollama*', 'Code')

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$log = Join-Path $LogDir ("repair-{0}-{1}.log" -f $mode, (Get-Date -Format 'yyyyMMdd-HHmmss'))
function W($m) { $l = "$(Get-Date -Format 'HH:mm:ss')  $m"; Write-Host $l; Add-Content -LiteralPath $log -Value $l -Encoding UTF8 }

W "Repair-AiEnv 시작 ($mode)  AiRoot=$AiRoot"

$alive = @()
foreach ($pat in $GuardProcesses) { $alive += @(Get-Process -Name $pat -ErrorAction SilentlyContinue) }
$alive = $alive | Sort-Object Id -Unique
if ($alive.Count -gt 0) {
    $names = ($alive | Select-Object -Expand Name -Unique) -join ', '
    W "ABORT (G1): 대상 프로세스 실행 중 — $names. 정션 조작을 하지 않는다."
    return
}
W "G1 통과: 대상 프로세스 0건"

function Test-IsReparse($path) {
    $it = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if (-not $it) { return $null }
    [bool]($it.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

$repaired = 0; $skipped = 0; $okc = 0
foreach ($e in $Contract) {
    $leaf = Split-Path $e.c -Leaf
    if (-not (Test-Path $e.c)) { W "SKIP $leaf : C 경로 없음"; $skipped++; continue }

    $r1 = Test-IsReparse $e.c; Start-Sleep -Milliseconds 300; $r2 = Test-IsReparse $e.c
    if ($r1 -and $r2) { $okc++; continue }
    if ($r1 -ne $r2)  { W "SKIP $leaf : 정션 상태 불안정($r1/$r2) — 재조회 필요"; $skipped++; continue }

    W "감지 $leaf : 정션이 일반 폴더로 되돌아감"
    if (-not (Test-Path $e.d)) { W "  SKIP: D 대상 없음($($e.d)) — 수동 확인 필요"; $skipped++; continue }

    $ec = @(); $ed = @()
    $cf = Get-ChildItem $e.c -Recurse -Force -File -ErrorAction SilentlyContinue -ErrorVariable +ec
    $df = Get-ChildItem $e.d -Recurse -Force -File -ErrorAction SilentlyContinue -ErrorVariable +ed
    if ($ec.Count -or $ed.Count) { W "  SKIP (G2): 열거 오류 C=$($ec.Count) D=$($ed.Count) — 판정 신뢰불가"; $skipped++; continue }

    $dmap = @{}
    foreach ($f in $df) { $dmap[$f.FullName.Substring($e.d.Length)] = $f }
    $risk = 0; $risklist = @()
    foreach ($f in $cf) {
        $rel = $f.FullName.Substring($e.c.Length)
        if (-not $dmap.ContainsKey($rel)) { $risk++; $risklist += "C-only:$rel"; continue }
        if ($f.LastWriteTimeUtc -gt $dmap[$rel].LastWriteTimeUtc.AddSeconds(2)) { $risk++; $risklist += "C-newer:$rel" }
    }
    if ($risk -gt 0) {
        W "  SKIP (G3): 병합 위험 $risk 건 — 자동 덮어쓰기 금지, 사용자 판단 필요"
        $risklist | Select-Object -First 5 | ForEach-Object { W "     $_" }
        $skipped++; continue
    }
    W "  안전 판정: C는 D의 진부분집합이며 더 최신인 파일 없음"

    if (-not $Apply) { W "  [DRYRUN] 재연결 예정 (실제 변경 안 함)"; $skipped++; continue }

    $bak = "$($e.c).bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
    try { Rename-Item -LiteralPath $e.c -NewName (Split-Path $bak -Leaf) -ErrorAction Stop; W "  .bak 격리: $(Split-Path $bak -Leaf)" }
    catch { W "  SKIP: rename 실패(잠금 가능성) — $($_.Exception.Message)"; $skipped++; continue }

    $null = cmd /c mklink /J "`"$($e.c)`"" "`"$($e.d)`""
    if ((Test-IsReparse $e.c) -eq $true) {
        $via = @(Get-ChildItem $e.c -Recurse -Force -File -ErrorAction SilentlyContinue).Count
        W "  OK: 재연결 완료 ($via 파일). .bak 은 사용자 승인 전까지 보존."
        $repaired++
    }
    else {
        cmd /c rmdir "`"$($e.c)`"" | Out-Null
        Rename-Item -LiteralPath $bak -NewName $leaf
        W "  ROLLBACK: 정션 생성 실패 → 원복 완료. 자동 재시도 안 함."
        $skipped++
    }
}

W "완료: 복구 $repaired · 정상 $okc · 건너뜀 $skipped ($mode)"
if (-not $Apply) { W "실제 적용하려면 -Apply 를 붙여 다시 실행하라." }
