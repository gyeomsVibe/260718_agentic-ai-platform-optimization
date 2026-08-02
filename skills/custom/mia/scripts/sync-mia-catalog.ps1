[CmdletBinding()]
param(
    [ValidateSet('Check', 'Apply')]
    [string]$Mode = 'Check'
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$catalogRoot = Split-Path -Parent $PSScriptRoot
$repositoryRoot = (Resolve-Path (Join-Path $catalogRoot '..\..\..')).Path
$stageRoot = Join-Path ([IO.Path]::GetTempPath()) "mia-catalog-sync-stage-$PID"

$definitions = @(
    [PSCustomObject]@{
        Name = 'mia-skill-compiler'
        Source = Join-Path $catalogRoot '1_mia-skill-compiler\candidates\mia-skill-compiler'
        Entries = @('SKILL.md', 'agents', 'references', 'scripts')
    },
    [PSCustomObject]@{
        Name = 'mia-vaccine-test'
        Source = Join-Path $catalogRoot '2_mia-vaccine-test'
        Entries = @('SKILL.md', 'agents', 'references')
    },
    [PSCustomObject]@{
        Name = 'mia-strategic'
        Source = Join-Path $catalogRoot '3_mia-strategic'
        Entries = @('SKILL.md', 'agents')
    }
)

function New-StagedPackage {
    param([Parameter(Mandatory)]$Definition)

    $destination = Join-Path $stageRoot $Definition.Name
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    foreach ($entry in $Definition.Entries) {
        $source = Join-Path $Definition.Source $entry
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Required MIA source is missing: $source"
        }
        Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
    }
    return $destination
}

function Get-RelativeFileMap {
    param([Parameter(Mandatory)][string]$Root)

    $map = @{}
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return $map
    }
    $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
    foreach ($file in Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File) {
        $relative = $file.FullName.Substring($resolvedRoot.Length).TrimStart('\').Replace('\', '/')
        $map[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    return $map
}

function Test-DirectoryMatch {
    param(
        [Parameter(Mandatory)][string]$Expected,
        [Parameter(Mandatory)][string]$Actual
    )

    $expectedMap = Get-RelativeFileMap $Expected
    $actualMap = Get-RelativeFileMap $Actual
    if ($expectedMap.Count -ne $actualMap.Count) {
        return $false
    }
    foreach ($key in $expectedMap.Keys) {
        if (-not $actualMap.ContainsKey($key) -or $actualMap[$key] -ne $expectedMap[$key]) {
            return $false
        }
    }
    return $true
}

function Assert-SafeTarget {
    param([Parameter(Mandatory)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $allowedParents = @(
        (Join-Path $repositoryRoot '.agents\skills'),
        (Join-Path $HOME '.agents\skills'),
        (Join-Path $HOME '.codex\skills'),
        (Join-Path $HOME '.claude\skills'),
        (Join-Path $HOME '.gemini\config\skills'),
        (Join-Path $HOME '.gemini\config\plugins')
    ) | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') }
    $parent = [IO.Path]::GetDirectoryName($fullPath).TrimEnd('\')
    if ($parent -notin $allowedParents) {
        throw "Refusing to replace an unexpected target: $fullPath"
    }
}

function Backup-And-ReplaceDirectory {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$BackupPath
    )

    Assert-SafeTarget $Destination
    if (Test-Path -LiteralPath $Destination) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $BackupPath) | Out-Null
        Copy-Item -LiteralPath $Destination -Destination $BackupPath -Recurse -Force
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

# 배포 전 엄격 검증 게이트.
# 3대 도구 중 Codex 의 YAML 파서가 가장 엄격해, 위반 시 스킬 로딩 자체를 거부한다.
# Claude Code 는 관대해 결함을 은폐하므로 반드시 엄격 파서로 먼저 막는다.
$validator = Join-Path $PSScriptRoot 'validate-skill-manifests.py'
if (Test-Path -LiteralPath $validator) {
    $validatorOutput = & python $validator 2>&1
    $validatorExit = $LASTEXITCODE
    $validatorOutput | ForEach-Object { Write-Output $_ }
    if ($validatorExit -ne 0) {
        throw "매니페스트 검증 실패 (exit $validatorExit). 배포를 중단합니다."
    }
}
else {
    throw "매니페스트 검증기를 찾을 수 없습니다: $validator"
}

New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
$staged = @{}
foreach ($definition in $definitions) {
    $staged[$definition.Name] = New-StagedPackage $definition
}

$strategicCanonical = [IO.File]::ReadAllText((Join-Path $staged['mia-strategic'] 'SKILL.md'))
$strategicBody = [regex]::Replace($strategicCanonical, '(?s)\A---\s*.*?\s*---\s*', '')
$claudeStrategic = @"
---
name: mia-strategic
description: Activate the MIA strategic hypothesis-verification workflow when the user says "MIA모드 발동", "MIA 전략스킬 발동", "MIA 전략절차 발동", "MIA 전략스킬 해줘", "MIA 전략절차 해줘", or invokes `$mia-strategic for planning, review, execution, or validation.
argument-hint: "MIA모드 발동: [기획|검토|실행|검증] <목표>"
user-invocable: true
---

$strategicBody
"@
$claudeStage = Join-Path $stageRoot 'mia-strategic-claude'
if (Test-Path -LiteralPath $claudeStage) {
    Remove-Item -LiteralPath $claudeStage -Recurse -Force
}
Copy-Item -LiteralPath $staged['mia-strategic'] -Destination $claudeStage -Recurse -Force
[IO.File]::WriteAllText((Join-Path $claudeStage 'SKILL.md'), $claudeStrategic, $utf8)

$pluginStage = Join-Path $stageRoot 'mia-modular-intelligence-architect'
if (Test-Path -LiteralPath $pluginStage) {
    Remove-Item -LiteralPath $pluginStage -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Join-Path $pluginStage 'skills\mia-strategic') | Out-Null
Copy-Item -LiteralPath (Join-Path $catalogRoot '3_mia-strategic\plugin\plugin.json') -Destination $pluginStage
Copy-Item -LiteralPath (Join-Path $catalogRoot '3_mia-strategic\plugin\VERSION') -Destination $pluginStage
[IO.File]::WriteAllText((Join-Path $pluginStage 'skills\mia-strategic\SKILL.md'), $strategicCanonical, $utf8)

$targets = [System.Collections.Generic.List[object]]::new()
$standardRoots = @(
    [PSCustomObject]@{ Label = 'workspace'; Root = Join-Path $repositoryRoot '.agents\skills' },
    [PSCustomObject]@{ Label = 'shared-user'; Root = Join-Path $HOME '.agents\skills' },
    [PSCustomObject]@{ Label = 'codex'; Root = Join-Path $HOME '.codex\skills' },
    [PSCustomObject]@{ Label = 'claude'; Root = Join-Path $HOME '.claude\skills' }
)
foreach ($root in $standardRoots) {
    foreach ($definition in $definitions) {
        $source = $staged[$definition.Name]
        if ($root.Label -eq 'claude' -and $definition.Name -eq 'mia-strategic') {
            $source = $claudeStage
        }
        $targets.Add([PSCustomObject]@{
                Label = "$($root.Label)/$($definition.Name)"
                Source = $source
                Destination = Join-Path $root.Root $definition.Name
            })
    }
}
foreach ($name in @('mia-skill-compiler', 'mia-vaccine-test')) {
    $targets.Add([PSCustomObject]@{
            Label = "antigravity/$name"
            Source = $staged[$name]
            Destination = Join-Path $HOME ".gemini\config\skills\$name"
        })
}
$targets.Add([PSCustomObject]@{
        Label = 'antigravity/plugin'
        Source = $pluginStage
        Destination = Join-Path $HOME '.gemini\config\plugins\mia-modular-intelligence-architect'
    })

$legacyTargets = @(
    (Join-Path $repositoryRoot '.agents\skills\plan-review-execute'),
    (Join-Path $HOME '.agents\skills\plan-review-execute'),
    (Join-Path $HOME '.codex\skills\plan-review-execute'),
    (Join-Path $HOME '.claude\skills\plan-review-execute'),
    (Join-Path $HOME '.gemini\config\skills\plan-review-execute'),
    (Join-Path $HOME '.gemini\config\skills\mia-strategic')
)

$backupRoot = $null
if ($Mode -eq 'Apply') {
    $backupRoot = Join-Path $HOME ('.mia-skill-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    foreach ($target in $targets) {
        $backupPath = Join-Path $backupRoot ($target.Label.Replace('/', '\'))
        Backup-And-ReplaceDirectory -Source $target.Source -Destination $target.Destination -BackupPath $backupPath
    }
    foreach ($legacy in $legacyTargets) {
        if (Test-Path -LiteralPath $legacy) {
            Assert-SafeTarget $legacy
            $safeName = ($legacy -replace '[:\\/]', '_').Trim('_')
            $backupPath = Join-Path $backupRoot "legacy\$safeName"
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backupPath) | Out-Null
            Copy-Item -LiteralPath $legacy -Destination $backupPath -Recurse -Force
            Remove-Item -LiteralPath $legacy -Recurse -Force
        }
    }
    [IO.File]::WriteAllText((Join-Path $catalogRoot '3_mia-strategic\CLAUDE-SKILL.md'), $claudeStrategic, $utf8)
    New-Item -ItemType Directory -Force -Path (Join-Path $catalogRoot '3_mia-strategic\plugin\skills\mia-strategic') | Out-Null
    [IO.File]::WriteAllText((Join-Path $catalogRoot '3_mia-strategic\plugin\skills\mia-strategic\SKILL.md'), $strategicCanonical, $utf8)
    Write-Output "Backup: $backupRoot"
}

$results = foreach ($target in $targets) {
    [PSCustomObject]@{
        Target = $target.Label
        Exists = Test-Path -LiteralPath $target.Destination -PathType Container
        MatchesCanonical = Test-DirectoryMatch -Expected $target.Source -Actual $target.Destination
    }
}
$results | Format-Table -AutoSize
$legacyResults = foreach ($legacy in $legacyTargets) {
    [PSCustomObject]@{ Legacy = $legacy; Exists = Test-Path -LiteralPath $legacy }
}
$legacyResults | Format-Table -AutoSize

$repositoryGeneratedMatches =
    (Test-Path -LiteralPath (Join-Path $catalogRoot '3_mia-strategic\CLAUDE-SKILL.md')) -and
    ([IO.File]::ReadAllText((Join-Path $catalogRoot '3_mia-strategic\CLAUDE-SKILL.md')) -eq $claudeStrategic) -and
    (Test-Path -LiteralPath (Join-Path $catalogRoot '3_mia-strategic\plugin\skills\mia-strategic\SKILL.md')) -and
    ([IO.File]::ReadAllText((Join-Path $catalogRoot '3_mia-strategic\plugin\skills\mia-strategic\SKILL.md')) -eq $strategicCanonical)
Write-Output "RepositoryGeneratedMatches=$repositoryGeneratedMatches"

$hasMismatch =
    @($results | Where-Object { -not $_.MatchesCanonical }).Count -gt 0 -or
    @($legacyResults | Where-Object { $_.Exists }).Count -gt 0 -or
    -not $repositoryGeneratedMatches
if (Test-Path -LiteralPath $stageRoot) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
if ($hasMismatch) { exit 1 }
exit 0
