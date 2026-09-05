[CmdletBinding()]
param(
    [ValidateSet('Check', 'Apply')]
    [string]$Mode = 'Check'
)

$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$stageRoot = Join-Path ([IO.Path]::GetTempPath()) "slash-prompt-modes-sync-$PID"
$backupRoot = Join-Path $HOME ('.agent-skill-backups\slash-prompt-modes-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$skillNames = @(
    'slash-prompt-modes', 'selfrefine', 'redteam', 'eli10', 'deepdive',
    'alt3', 'critic', 'optimize', 'stepbystep', 'expert', 'structured'
)

function Get-RelativeFileMap {
    param([Parameter(Mandatory)][string]$Root)

    $map = @{}
    if (-not (Test-Path -LiteralPath $Root)) { return $map }
    $item = Get-Item -LiteralPath $Root
    if (-not $item.PSIsContainer) {
        $sha = [Security.Cryptography.SHA256]::Create()
        $map[$item.Name] = [BitConverter]::ToString(
            $sha.ComputeHash([IO.File]::ReadAllBytes($item.FullName))
        ).Replace('-', '')
        return $map
    }

    $resolved = $item.FullName.TrimEnd('\')
    $sha = [Security.Cryptography.SHA256]::Create()
    foreach ($file in Get-ChildItem -LiteralPath $resolved -Recurse -File) {
        $relative = $file.FullName.Substring($resolved.Length).TrimStart('\').Replace('\', '/')
        $map[$relative] = [BitConverter]::ToString(
            $sha.ComputeHash([IO.File]::ReadAllBytes($file.FullName))
        ).Replace('-', '')
    }
    return $map
}

function Test-PathMatch {
    param(
        [Parameter(Mandatory)][string]$Expected,
        [Parameter(Mandatory)][string]$Actual
    )

    $expectedMap = Get-RelativeFileMap $Expected
    $actualMap = Get-RelativeFileMap $Actual
    if ($expectedMap.Count -ne $actualMap.Count) { return $false }
    foreach ($key in $expectedMap.Keys) {
        if (-not $actualMap.ContainsKey($key) -or $actualMap[$key] -ne $expectedMap[$key]) {
            return $false
        }
    }
    return $true
}

function Assert-SafeDestination {
    param([Parameter(Mandatory)][string]$Path)

    $full = [IO.Path]::GetFullPath($Path)
    $allowedParents = @(
        (Join-Path $HOME '.codex\skills'),
        (Join-Path $HOME '.claude\skills'),
        (Join-Path $HOME '.gemini\config\skills'),
        (Join-Path $HOME '.claude\commands')
    ) | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') }
    $parent = [IO.Path]::GetDirectoryName($full).TrimEnd('\')
    if ($parent -notin $allowedParents) {
        throw "Refusing unexpected destination: $full"
    }
}

function Backup-And-Replace {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$BackupPath
    )

    Assert-SafeDestination $Destination
    if (Test-Path -LiteralPath $Destination) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $BackupPath) | Out-Null
        Copy-Item -LiteralPath $Destination -Destination $BackupPath -Recurse -Force
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

try {
    New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
    $skillStage = Join-Path $stageRoot 'skills'
    $commandStage = Join-Path $stageRoot 'commands'
    $mainStage = Join-Path $skillStage 'slash-prompt-modes'
    New-Item -ItemType Directory -Force -Path $mainStage | Out-Null

    foreach ($entry in @('SKILL.md', 'agents', 'references', 'LICENSE.md')) {
        $source = Join-Path $skillRoot $entry
        if (-not (Test-Path -LiteralPath $source)) { throw "Missing canonical entry: $source" }
        Copy-Item -LiteralPath $source -Destination $mainStage -Recurse
    }

    & (Join-Path $PSScriptRoot 'build-slash-aliases.ps1') -OutputRoot $skillStage | Out-Null
    & (Join-Path $PSScriptRoot 'build-claude-uppercase-commands.ps1') -OutputRoot $commandStage | Out-Null

    $targets = [Collections.Generic.List[object]]::new()
    foreach ($platform in @(
        @{ Name = 'Codex'; Root = Join-Path $HOME '.codex\skills' },
        @{ Name = 'Claude Code'; Root = Join-Path $HOME '.claude\skills' },
        @{ Name = 'Antigravity'; Root = Join-Path $HOME '.gemini\config\skills' }
    )) {
        foreach ($name in $skillNames) {
            $targets.Add([pscustomobject]@{
                Label = "$($platform.Name)/$name"
                Source = Join-Path $skillStage $name
                Destination = Join-Path $platform.Root $name
                Backup = Join-Path $backupRoot "$($platform.Name)/skills/$name"
            })
        }
    }

    foreach ($command in Get-ChildItem -LiteralPath $commandStage -File) {
        $targets.Add([pscustomobject]@{
            Label = "Claude Code command/$($command.Name)"
            Source = $command.FullName
            Destination = Join-Path $HOME ".claude\commands\$($command.Name)"
            Backup = Join-Path $backupRoot "Claude Code/commands/$($command.Name)"
        })
    }

    if ($Mode -eq 'Apply') {
        foreach ($target in $targets) {
            Backup-And-Replace -Source $target.Source -Destination $target.Destination -BackupPath $target.Backup
        }
    }

    $results = foreach ($target in $targets) {
        [pscustomobject]@{
            Target = $target.Label
            MatchesCanonical = Test-PathMatch -Expected $target.Source -Actual $target.Destination
        }
    }
    $results | Format-Table -AutoSize
    $mismatchCount = @($results | Where-Object { -not $_.MatchesCanonical }).Count
    if ($mismatchCount -gt 0) {
        throw "$mismatchCount cross-platform slash-prompt target(s) differ from the canonical package."
    }
    if ($Mode -eq 'Apply') { Write-Output "Backup: $backupRoot" }
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}
