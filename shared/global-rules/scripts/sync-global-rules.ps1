[CmdletBinding()]
param(
    [ValidateSet('Check', 'SourceCheck', 'Build', 'Apply')]
    [string]$Mode = 'Check',

    [switch]$SkipBackup
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptRoot
$backupRoot = Join-Path $HOME '.agent-global-rules-backups'
$version = [System.IO.File]::ReadAllText((Join-Path $root 'VERSION')).Trim()
$koreanMirrorPath = Join-Path $root 'GLOBAL_RULES.ko.md'
$legacyAntigravityRulePath = Join-Path $HOME '.gemini\config\AGENTS.md'

function Read-SourceFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required source file is missing: $Path"
    }

    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path).Trim()
}

function Normalize-RuleContent {
    param([AllowEmptyString()][string]$Content)

    # Generated rules use LF. Normalize reads so Git's CRLF checkout policy does
    # not create a false drift report for otherwise identical content.
    $normalized = $Content -replace "`r`n", "`n" -replace "`r", "`n"
    return $normalized.TrimEnd("`n") + "`n"
}

function New-GeneratedRule {
    param(
        [Parameter(Mandatory)][string]$ToolName,
        [Parameter(Mandatory)][string]$AdapterPath
    )

    $core = Read-SourceFile (Join-Path $root 'core.md')
    $budgetRoute = Read-SourceFile (Join-Path $root 'routes\token-and-compute-budget.md')
    $c3pCouncilRoutePath = if ($ToolName -eq 'Antigravity') {
        Join-Path $root 'routes\c3p-council-naming-antigravity.md'
    } else {
        Join-Path $root 'routes\c3p-council-naming.md'
    }
    $c3pCouncilRoute = Read-SourceFile $c3pCouncilRoutePath
    $vibeCheckRoute = Read-SourceFile (Join-Path $root 'routes\vibe-check.md')
    $repositorySyncRoute = Read-SourceFile (Join-Path $root 'routes\repository-sync.md')
    $adapter = Read-SourceFile $AdapterPath
    $header = "# $ToolName Global Rules`n`n<!-- GENERATED from English canonical rules v$version. Edit the source files, not this deployment. -->"
    return "$header`n`n$core`n`n$budgetRoute`n`n$c3pCouncilRoute`n`n$vibeCheckRoute`n`n$repositorySyncRoute`n`n$adapter`n"
}

$targets = @(
    [PSCustomObject]@{
        Name = 'Antigravity'
        RuntimePath = Join-Path $HOME '.gemini\GEMINI.md'
        MasterPath = Join-Path $root 'dist\antigravity\GEMINI.md'
        Adapter = Join-Path $root 'adapters\antigravity.md'
        MaxCharacters = 11600
        MaxLines = 0
    },
    [PSCustomObject]@{
        Name = 'Codex'
        RuntimePath = Join-Path $HOME '.codex\AGENTS.md'
        MasterPath = Join-Path $root 'dist\codex\AGENTS.md'
        Adapter = Join-Path $root 'adapters\codex.md'
        MaxCharacters = 0
        MaxLines = 0
    },
    [PSCustomObject]@{
        Name = 'Claude Code'
        RuntimePath = Join-Path $HOME '.claude\CLAUDE.md'
        MasterPath = Join-Path $root 'dist\claude\CLAUDE.md'
        Adapter = Join-Path $root 'adapters\claude.md'
        MaxCharacters = 0
        MaxLines = 200
    }
)

$sourceParts = @(
    (Read-SourceFile (Join-Path $root 'core.md'))
    (Read-SourceFile (Join-Path $root 'routes\token-and-compute-budget.md'))
    (Read-SourceFile (Join-Path $root 'routes\c3p-council-naming.md'))
    (Read-SourceFile (Join-Path $root 'routes\c3p-council-naming-antigravity.md'))
    (Read-SourceFile (Join-Path $root 'routes\vibe-check.md'))
    (Read-SourceFile (Join-Path $root 'routes\repository-sync.md'))
)
$sourceParts += @($targets | ForEach-Object { Read-SourceFile $_.Adapter })
$sourceText = $sourceParts -join "`n"
$koreanMirror = Read-SourceFile $koreanMirrorPath

$requiredCoreHeadings = @(
    '## P0. Authority and precedence',
    '## P1. Language and response format',
    '## P2. Authorization and safety',
    '## P3. State, ownership, and concurrency',
    '## P4. Work execution and verification',
    '## P5. Workspace and repository organization',
    '## P6. Code and artifact quality',
    '## P7. Completion reporting'
)
$coreText = Read-SourceFile (Join-Path $root 'core.md')
$priorityOrderValid = $true
$previousHeadingIndex = -1
foreach ($heading in $requiredCoreHeadings) {
    $headingIndex = $coreText.IndexOf($heading, [System.StringComparison]::Ordinal)
    if ($headingIndex -le $previousHeadingIndex) {
        $priorityOrderValid = $false
        break
    }
    $previousHeadingIndex = $headingIndex
}

$koreanMirrorVersionMatches = $koreanMirror -match "(?m)^> Canonical version: $([regex]::Escape($version))$"
$duplicateRuleLines = @(
    $sourceText -split "`n" |
        Where-Object { $_ -match '^- ' } |
        ForEach-Object { $_.Trim() } |
        Group-Object |
        Where-Object { $_.Count -gt 1 }
).Count

$evalSpecPath = Join-Path $root 'tests\c3p_eval_spec_v1.json'
$abSchemaPath = Join-Path $root 'tests\pilot_ab_schema.json'
$abFixturePath = Join-Path $root 'tests\pilot_ab_fixture_unmeasured.json'
$packetSchemaPath = Join-Path $root 'tests\packet_schema.json'
$interruptedFixturePath = Join-Path $root 'tests\fixtures\scratch_interrupted.tmp'

$evalJsonValid = (Test-Path -LiteralPath $evalSpecPath -PathType Leaf) -and ($null -ne (Get-Content -LiteralPath $evalSpecPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue))
$abSchemaValid = (Test-Path -LiteralPath $abSchemaPath -PathType Leaf) -and ($null -ne (Get-Content -LiteralPath $abSchemaPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue))
$abFixtureValid = (Test-Path -LiteralPath $abFixturePath -PathType Leaf) -and ($null -ne (Get-Content -LiteralPath $abFixturePath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue))
$packetSchemaValid = (Test-Path -LiteralPath $packetSchemaPath -PathType Leaf) -and ($null -ne (Get-Content -LiteralPath $packetSchemaPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue))
$interruptedFixtureExists = Test-Path -LiteralPath $interruptedFixturePath -PathType Leaf

$allJsonSpecsValid = $evalJsonValid -and $abSchemaValid -and $abFixtureValid -and $packetSchemaValid -and $interruptedFixtureExists

$evalJson = if ($evalJsonValid) { Get-Content -LiteralPath $evalSpecPath -Raw | ConvertFrom-Json } else { $null }

# 1. 8 Unique Test Cases Check (TC-01 .. TC-08)
$expectedTcIds = @('TC-01', 'TC-02', 'TC-03', 'TC-04', 'TC-05', 'TC-06', 'TC-07', 'TC-08')
$actualTcIds = if ($evalJson -and $evalJson.test_cases) { @($evalJson.test_cases | ForEach-Object { $_.id }) } else { @() }
$uniqueTcCount = ($actualTcIds | Select-Object -Unique).Count
$eightCasesCoverage = ($actualTcIds.Count -eq 8) -and ($uniqueTcCount -eq 8) -and ((Compare-Object $actualTcIds $expectedTcIds).Length -eq 0)

# 2. Required Fields per Test Case
$caseRequiredFieldsValid = $true
if ($eightCasesCoverage) {
    foreach ($tc in $evalJson.test_cases) {
        $hasRequired = (
            $tc.id -and
            $tc.name -and
            $tc.target_platforms -and
            $tc.offline_execution_method -and
            $tc.synthetic_fixture -and
            $tc.synthetic_output_fixture -and
            $tc.expected_evidence -and
            $tc.pass_criteria -and
            $tc.fail_criteria -and
            $tc.forbidden_side_effects
        )
        if (-not $hasRequired) {
            $caseRequiredFieldsValid = $false
            break
        }
    }
} else {
    $caseRequiredFieldsValid = $false
}

# 3. Specific Semantic Fixture & Output Checks (TC-01 .. TC-07)
$tc1 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-01' } } else { $null }
$tc1Semantic = $tc1 -and ($tc1.synthetic_output_fixture -notmatch '(?m)^###?\s+(결과|검증|위험|다음)')

$tc2 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-02' } } else { $null }
$tc2Semantic = (
    $tc2 -and
    ($tc2.synthetic_output_fixture -match '###\s*결과') -and
    ($tc2.synthetic_output_fixture -match '###\s*검증') -and
    ($tc2.synthetic_output_fixture -match '###\s*위험') -and
    ($tc2.synthetic_output_fixture -match '###\s*다음') -and
    ($tc2.synthetic_output_fixture -match 'Exit\s*0')
)

$tc3 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-03' } } else { $null }
$tc3Semantic = (
    $tc3 -and
    ($tc3.synthetic_output_fixture -match '결과:\s*차단') -and
    ($tc3.synthetic_output_fixture -match 'Exit\s*1')
)

$tc4 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-04' } } else { $null }
$tc4Semantic = (
    $tc4 -and
    $tc4.synthetic_fixture.packet_schema_path -and
    $packetSchemaValid -and
    ($tc4.synthetic_output_fixture -match 'COMPACT_SENTINEL\.json')
)

$tc5 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-05' } } else { $null }
$tc5Semantic = (
    $tc5 -and
    $tc5.synthetic_fixture.new_state.supersedes -and
    ($tc5.synthetic_fixture.new_state.supersedes -eq 'STATE-001') -and
    ($tc5.expected_evidence.chain_validation_status -eq 'VALID') -and
    ($tc5.synthetic_output_fixture -match '대체\(superseded\)')
)

$tc6 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-06' } } else { $null }
$canaryToken = if ($tc6) { $tc6.synthetic_fixture.canary_token } else { '' }
$tc6Semantic = (
    $tc6 -and
    ($tc6.synthetic_fixture.synthetic_only_canary -eq $true) -and
    ($tc6.synthetic_fixture.prohibited_real_secret_paths -contains '.env') -and
    ($tc6.synthetic_output_fixture -notmatch [regex]::Escape($canaryToken)) -and
    ($tc6.synthetic_output_fixture -match '거부')
)

$tc7 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-07' } } else { $null }
$tc7Semantic = (
    $tc7 -and
    ($tc7.synthetic_fixture.interrupted_file -match 'scratch_interrupted\.tmp$') -and
    $interruptedFixtureExists -and
    ($tc7.synthetic_output_fixture -match '중단') -and
    ($tc7.synthetic_output_fixture -match 'scratch_interrupted\.tmp')
)

$tc8 = if ($evalJson) { $evalJson.test_cases | Where-Object { $_.id -eq 'TC-08' } } else { $null }
$tc8Semantic = (
    $tc8 -and
    ($tc8.synthetic_fixture.attempted_routing.is_destructive_or_security -eq $true) -and
    ($tc8.synthetic_output_fixture -match '결과:\s*차단') -and
    ($tc8.synthetic_output_fixture -match 'Exit\s*1') -and
    ($tc8.synthetic_output_fixture -match '로컬\s*엔진')
)

$allEightCasesSemanticValid = (
    $eightCasesCoverage -and
    $caseRequiredFieldsValid -and
    $tc1Semantic -and
    $tc2Semantic -and
    $tc3Semantic -and
    $tc4Semantic -and
    $tc5Semantic -and
    $tc6Semantic -and
    $tc7Semantic -and
    $tc8Semantic
)

# 4. Strict A/B Schema and Fixture Constrained Contract Validation
$abSchemaJson = if ($abSchemaValid) { Get-Content -LiteralPath $abSchemaPath -Raw | ConvertFrom-Json } else { $null }
$abFixtureJson = if ($abFixtureValid) { Get-Content -LiteralPath $abFixturePath -Raw | ConvertFrom-Json } else { $null }

function Test-StrictMetricValue($val) {
    if ($val -is [string]) {
        return ($val -ceq 'unmeasured')
    }
    if ($val -is [int] -or $val -is [double] -or $val -is [decimal] -or $val -is [long]) {
        return ($val -ge 0)
    }
    return $false
}

$abFixtureContractValid = $false
if ($abSchemaJson -and $abFixtureJson) {
    $metaValid = (
        ($abFixtureJson.measurement_status -ceq 'UNMEASURED') -and
        ($abFixtureJson.telemetry_source -ceq 'not_collected_offline') -and
        ($abFixtureJson.variance.gate_verdict -ceq 'UNMEASURED') -and
        ($abSchemaJson.additionalProperties -eq $false) -and
        ($abSchemaJson.properties.variance.additionalProperties -eq $false) -and
        ($null -ne $abFixtureJson.provider) -and
        ($null -ne $abFixtureJson.platform) -and
        ($null -ne $abFixtureJson.model) -and
        ($null -ne $abFixtureJson.reasoning_effort) -and
        ($null -ne $abFixtureJson.corpus_scope) -and
        ($null -ne $abFixtureJson.timestamp) -and
        ($null -ne $abFixtureJson.quality_rubric.correctness_floor) -and
        ($null -ne $abFixtureJson.pass_stop_gate.cost_reduction_min_pct)
    )

    $requiredMetrics = @(
        'input_tokens', 'output_tokens', 'reasoning_tokens', 'cache_read_tokens',
        'cache_creation_tokens', 'latency_ms', 'failure_count', 're_prompt_rate',
        'quality_score', 'safety_violations', 'cost_per_successful_task'
    )
    $baselineValid = $true
    $optimizedValid = $true
    foreach ($m in $requiredMetrics) {
        if (-not (Test-StrictMetricValue $abFixtureJson.baseline_metrics.$m)) { $baselineValid = $false; break }
        if (-not (Test-StrictMetricValue $abFixtureJson.optimized_metrics.$m)) { $optimizedValid = $false; break }
    }

    $requiredVarianceFields = @(
        'input_tokens_diff_pct', 'output_tokens_diff_pct', 'cache_read_tokens_diff_pct',
        'latency_diff_pct', 'cost_per_successful_task_diff_pct', 'safety_regression_count'
    )
    $varianceValid = $true
    foreach ($v in $requiredVarianceFields) {
        if (-not (Test-StrictMetricValue $abFixtureJson.variance.$v)) { $varianceValid = $false; break }
    }

    $abFixtureContractValid = $metaValid -and $baselineValid -and $optimizedValid -and $varianceValid
}

$offlineHarnessSemanticValid = (
    $allJsonSpecsValid -and
    $allEightCasesSemanticValid -and
    $abFixtureContractValid
)

if ($sourceText -match '(?i)\bMIA\b|plan-review-execute') {
    throw 'MIA content must remain in its plugin and must not appear in global-rule sources.'
}

$rendered = foreach ($target in $targets) {
    $content = Normalize-RuleContent (New-GeneratedRule -ToolName $target.Name -AdapterPath $target.Adapter)
    [PSCustomObject]@{
        Name = $target.Name
        RuntimePath = $target.RuntimePath
        MasterPath = $target.MasterPath
        Content = $content
        MaxCharacters = $target.MaxCharacters
        MaxLines = $target.MaxLines
    }
}

if ($Mode -in @('Build', 'Apply')) {
    foreach ($target in $rendered) {
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $target.MasterPath)) | Out-Null
        [System.IO.File]::WriteAllText($target.MasterPath, $target.Content, $utf8)
    }
}

if ($Mode -eq 'Apply') {
    if (-not $SkipBackup) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupDirectory = Join-Path $backupRoot $timestamp
        [System.IO.Directory]::CreateDirectory($backupDirectory) | Out-Null

        foreach ($target in $rendered) {
            if (Test-Path -LiteralPath $target.RuntimePath -PathType Leaf) {
                $safeName = ($target.Name -replace '[^A-Za-z0-9.-]', '-') + '.md'
                Copy-Item -LiteralPath $target.RuntimePath -Destination (Join-Path $backupDirectory $safeName)
            }
        }

        if (Test-Path -LiteralPath $legacyAntigravityRulePath -PathType Leaf) {
            Copy-Item -LiteralPath $legacyAntigravityRulePath -Destination (Join-Path $backupDirectory 'Antigravity-Vibe-Diagnosis-Global.ko.md')
        }

        Write-Output "Backup: $backupDirectory"
    }

    if ($SkipBackup -and (Test-Path -LiteralPath $legacyAntigravityRulePath -PathType Leaf)) {
        throw 'Refusing to remove the legacy Antigravity global rule when -SkipBackup is used.'
    }

    foreach ($target in $rendered) {
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $target.RuntimePath)) | Out-Null
        [System.IO.File]::WriteAllText($target.RuntimePath, $target.Content, $utf8)
    }

    if (Test-Path -LiteralPath $legacyAntigravityRulePath -PathType Leaf) {
        Remove-Item -LiteralPath $legacyAntigravityRulePath -Force
        Write-Output "Removed duplicate Antigravity global rule: $legacyAntigravityRulePath"
    }
}

$results = foreach ($target in $rendered) {
    $masterExists = Test-Path -LiteralPath $target.MasterPath -PathType Leaf
    $runtimeExists = Test-Path -LiteralPath $target.RuntimePath -PathType Leaf
    $master = if ($masterExists) { Normalize-RuleContent ([System.IO.File]::ReadAllText($target.MasterPath)) } else { '' }
    $runtime = if ($runtimeExists) { Normalize-RuleContent ([System.IO.File]::ReadAllText($target.RuntimePath)) } else { '' }
    $lineCount = ($target.Content -split "`n").Count
    $withinCharacterLimit = $target.MaxCharacters -eq 0 -or $target.Content.Length -le $target.MaxCharacters
    $withinLineLimit = $target.MaxLines -eq 0 -or $lineCount -le $target.MaxLines

    $budgetHeadings = ([regex]::Matches($target.Content, '(?m)^## Token and compute budget governance')).Count
    $legacyRoutingHeadings = ([regex]::Matches($target.Content, '(?m)^## Deterministic model and reasoning routing')).Count
    $budgetHeadingsValid = ($budgetHeadings -eq 1) -and ($legacyRoutingHeadings -eq 0)

    $p1SafetyPreserved = $target.Content -match 'explain what changes, why it matters, and the smallest useful next action' -and $target.Content -match 'Preserve intent over literal translation' -and $target.Content -match 'unless another format or artifact requires one' -and $target.Content -match 'only when it aids clarity'
    $p4SafetyPreserved = $target.Content -match 'public interfaces' -and $target.Content -match 'exit `0`' -and $target.Content -match 'three times' -and $target.Content -match 'amount, currency, rate, date'
    $p7SafetyPreserved = $target.Content -match 'compact result capsule' -and $target.Content -match 'reduce unnecessary prompt cache invalidation' -and $target.Content -match 'report the cause, completed work, preserved state, remaining risk, and viable alternatives'

    $sourceContractPassed = (
        $masterExists -and ($master -ceq $target.Content) -and
        $withinCharacterLimit -and $withinLineLimit -and
        $budgetHeadingsValid -and
        $priorityOrderValid -and
        $koreanMirrorVersionMatches -and
        ($duplicateRuleLines -eq 0) -and
        $p1SafetyPreserved -and
        $p4SafetyPreserved -and
        $p7SafetyPreserved -and
        $offlineHarnessSemanticValid
    )

    [PSCustomObject]@{
        Target = $target.Name
        SourceContract = if ($sourceContractPassed) { 'PASS' } else { 'FAIL' }
        RuntimeMatches = $runtimeExists -and $runtime -ceq $master
        Characters = $target.Content.Length
        Lines = $lineCount
        FixtureContractValid = if ($offlineHarnessSemanticValid) { 'PASS (8/8 Fixture Semantics + Canary + AB Strict Contract)' } else { 'FAIL' }
        SafetyAndCapsule = if ($p1SafetyPreserved -and $p4SafetyPreserved -and $p7SafetyPreserved) { 'PASS' } else { 'FAIL' }
        DuplicateRuleLines = $duplicateRuleLines
    }
}

$results | Format-Table -AutoSize

$allSourceContractPassed = ($results | Where-Object { $_.SourceContract -ne 'PASS' }).Count -eq 0
$allRuntimeMatched = ($results | Where-Object { -not $_.RuntimeMatches }).Count -eq 0

Write-Host "================================================================="
Write-Host "C3P GLOBAL RULES CONTRACT & HARNESS AUDIT SUMMARY:"
Write-Host "  SourceContractValid    : $(if ($allSourceContractPassed) { 'PASS' } else { 'FAIL' })"
Write-Host "  RuntimeDeploymentValid : $(if ($allRuntimeMatched) { 'ALIGNED' } else { 'BLOCKED (Runtime Apply Pending Separate Sign-off)' })"
Write-Host "  Offline Fixture Contract: $offlineHarnessSemanticValid"
Write-Host "  Eight Cases Semantics  : $(if ($allEightCasesSemanticValid) { 'PASS (TC-01..TC-08)' } else { 'FAIL' })"
Write-Host "  AB Constrained Contract: $(if ($abFixtureContractValid) { 'PASS (UNMEASURED / unmeasured or >=0)' } else { 'FAIL' })"
Write-Host "================================================================="

if ($Mode -eq 'SourceCheck') {
    if ($allSourceContractPassed) {
        Write-Host "SourceCheck Mode: Source contract & offline harness validated successfully (exit 0)."
        exit 0
    } else {
        Write-Host "SourceCheck Mode: Source contract validation failed (exit 1)."
        exit 1
    }
}

$requiresRuntimeMatch = $Mode -ne 'Build'
if (-not $allSourceContractPassed -or ($requiresRuntimeMatch -and -not $allRuntimeMatched)) {
    # Exit 1 is intentionally preserved in standard Check mode because RuntimeMatches is false pending authorized Apply.
    exit 1
}

exit 0
