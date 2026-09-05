[CmdletBinding()]
param(
    [ValidateSet('Codex', 'ClaudeCode')]
    [string[]]$Platform = @('Codex', 'ClaudeCode'),

    [string[]]$ModeFilter,

    [ValidateSet('upper', 'lower')]
    [string[]]$CaseFilter = @('upper', 'lower'),

    [ValidateRange(0.01, 5.0)]
    [double]$ClaudeMaxBudgetUsd = 0.10,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $platformLabel = ($Platform -join '-').ToLowerInvariant()
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $OutputPath = Join-Path (Split-Path -Parent $PSScriptRoot) "validation-evidence/runtime-matrix-$platformLabel-$timestamp.json"
}

$modes = @(
    @{ Token = 'SELFREFINE'; Alias = 'selfrefine' },
    @{ Token = 'REDTEAM'; Alias = 'redteam' },
    @{ Token = 'ELI10'; Alias = 'eli10' },
    @{ Token = 'DEEPDIVE'; Alias = 'deepdive' },
    @{ Token = 'ALT3'; Alias = 'alt3' },
    @{ Token = 'CRITIC'; Alias = 'critic' },
    @{ Token = 'OPTIMIZE'; Alias = 'optimize' },
    @{ Token = 'STEPBYSTEP'; Alias = 'stepbystep' },
    @{ Token = 'EXPERT'; Alias = 'expert' },
    @{ Token = 'STRUCTURED FEW-SHOT'; Alias = 'structured' }
)

function Get-ProbePrompt {
    param(
        [Parameter(Mandatory)][hashtable]$Mode,
        [Parameter(Mandatory)][ValidateSet('upper', 'lower')][string]$Case
    )

    $token = if ($Case -eq 'upper') { $Mode.Token } else { $Mode.Token.ToLowerInvariant() }
    return "/$token 현재 입력에서 발동한 사용자 정의 슬래시 모드의 정본 토큰만 MODE=<토큰> 형식의 한 줄로 출력해. 설명과 코드 블록은 쓰지 마."
}

function Test-NormalizedModeResponse {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Response,
        [Parameter(Mandatory)][string]$ExpectedToken
    )

    $value = $Response.Trim().Trim('`')
    if ($value -notmatch '^MODE\s*=\s*(.+?)\s*$') { return $false }
    $reported = $Matches[1].Trim()
    if (-not $reported.StartsWith('/')) { $reported = "/$reported" }
    return $reported.Equals("/$ExpectedToken", [StringComparison]::OrdinalIgnoreCase)
}

function Get-CodexResult {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][hashtable]$Mode
    )

    $started = Get-Date
    $lines = @(& codex exec --ephemeral --json --color never -m gpt-5.4-mini -c 'model_reasoning_effort="low"' -s read-only $Prompt 2>&1)
    $exitCode = $LASTEXITCODE
    $text = $lines -join "`n"
    $events = foreach ($line in $lines) {
        try { $line | ConvertFrom-Json -ErrorAction Stop } catch { }
    }
    $messages = @(
        $events |
            Where-Object { $_.type -eq 'item.completed' -and $_.item.type -eq 'agent_message' } |
            ForEach-Object { $_.item.text }
    )
    $finalMessage = if ($messages.Count -gt 0) { [string]$messages[-1] } else { '' }
    $expected = "MODE=/$($Mode.Token)"
    $aliasPattern = "(?i)[\\/]skills[\\/]+$([regex]::Escape($Mode.Alias))[\\/]+SKILL\.md"
    $canonicalPattern = '(?i)[\\/]skills[\\/]+slash-prompt-modes[\\/]+SKILL\.md'
    $aliasRead = $text -match $aliasPattern
    $canonicalRead = $text -match $canonicalPattern
    $badShortRootRead = $text -match '(?i)[\\/]skills[\\/]+r\d+[\\/]'

    return [ordered]@{
        exit_code = $exitCode
        duration_ms = [int]((Get-Date) - $started).TotalMilliseconds
        expected = $expected
        response = $finalMessage.Trim()
        parser_accepted = $exitCode -eq 0 -and $text -notmatch '(?i)unknown command'
        token_normalized = Test-NormalizedModeResponse -Response $finalMessage -ExpectedToken $Mode.Token
        command_resolved = $exitCode -eq 0 -and
            $text -notmatch '(?i)unknown command' -and
            (Test-NormalizedModeResponse -Response $finalMessage -ExpectedToken $Mode.Token)
        alias_read_observed = $aliasRead
        canonical_read_observed = $canonicalRead
        first_path_resolution_clean = -not $badShortRootRead
        unknown_command = $text -match '(?i)unknown command'
    }
}

function Get-ClaudeResult {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][hashtable]$Mode
    )

    $started = Get-Date
    $lines = @(& claude -p $Prompt --model haiku --effort low --no-session-persistence --output-format json --max-budget-usd $ClaudeMaxBudgetUsd --tools= 2>&1)
    $exitCode = $LASTEXITCODE
    $text = $lines -join "`n"
    $payload = $null
    foreach ($line in $lines) {
        try { $payload = $line | ConvertFrom-Json -ErrorAction Stop } catch { }
    }
    $result = if ($null -ne $payload -and $null -ne $payload.result) { [string]$payload.result } else { '' }
    $expected = "MODE=/$($Mode.Token)"

    return [ordered]@{
        exit_code = $exitCode
        duration_ms = [int]((Get-Date) - $started).TotalMilliseconds
        expected = $expected
        response = $result.Trim()
        parser_accepted = $exitCode -eq 0 -and $text -notmatch '(?i)unknown command'
        token_normalized = Test-NormalizedModeResponse -Response $result -ExpectedToken $Mode.Token
        command_resolved = $exitCode -eq 0 -and
            $text -notmatch '(?i)unknown command' -and
            (Test-NormalizedModeResponse -Response $result -ExpectedToken $Mode.Token)
        unknown_command = $text -match '(?i)unknown command'
        cost_usd = if ($null -ne $payload) { $payload.total_cost_usd } else { $null }
        model = if ($null -ne $payload -and $null -ne $payload.modelUsage) {
            @($payload.modelUsage.PSObject.Properties.Name)[0]
        } else { $null }
    }
}

$results = [Collections.Generic.List[object]]::new()
foreach ($target in $Platform) {
    $selectedModes = if ($ModeFilter.Count -gt 0) {
        @($modes | Where-Object { $_.Token -in $ModeFilter -or $_.Alias -in $ModeFilter })
    } else { $modes }
    foreach ($mode in $selectedModes) {
        foreach ($case in $CaseFilter) {
            $prompt = Get-ProbePrompt -Mode $mode -Case $case
            Write-Host "[$target] $($mode.Token) $case"
            $observation = if ($target -eq 'Codex') {
                Get-CodexResult -Prompt $prompt -Mode $mode
            } else {
                Get-ClaudeResult -Prompt $prompt -Mode $mode
            }
            $results.Add([ordered]@{
                platform = $target
                mode = $mode.Token
                case = $case
                prompt = $prompt
                observation = $observation
            })
        }
    }
}

$failed = @($results | Where-Object { -not $_.observation.command_resolved -or $_.observation.unknown_command }).Count
$codexPathWarnings = @(
    $results |
        Where-Object { $_.platform -eq 'Codex' -and -not $_.observation.first_path_resolution_clean }
).Count
$claudeCost = ($results | Where-Object { $_.platform -eq 'ClaudeCode' } | ForEach-Object {
    if ($null -ne $_.observation.cost_usd) { [double]$_.observation.cost_usd } else { 0.0 }
} | Measure-Object -Sum).Sum

$report = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    purpose = 'Deterministic uppercase/lowercase command-recognition probe; not a general quality benchmark.'
    repetitions = 1
    repetition_rationale = 'Trigger resolution is treated as a deterministic invariant; stochastic quality claims require separate repeated evaluation.'
    platforms = $Platform
    cli_versions = [ordered]@{
        codex = if ($Platform -contains 'Codex') { (& codex --version) -join '' } else { $null }
        claude_code = if ($Platform -contains 'ClaudeCode') { (& claude --version) -join '' } else { $null }
    }
    summary = [ordered]@{
        total = $results.Count
        passed = $results.Count - $failed
        failed = $failed
        codex_short_root_path_warnings = $codexPathWarnings
        claude_total_cost_usd = [math]::Round([double]$claudeCost, 6)
    }
    results = $results
}

$parent = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8NoBOM
Write-Host "Report: $OutputPath"
Write-Host "Passed: $($report.summary.passed)/$($report.summary.total)"
if ($failed -gt 0) { exit 1 }
