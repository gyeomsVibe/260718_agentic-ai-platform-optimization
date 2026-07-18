[CmdletBinding()]
param(
    [ValidateSet('Check', 'Apply')]
    [string]$Mode = 'Check',

    [switch]$SkipBackup
)

$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptRoot
$backupRoot = Join-Path $HOME '.agent-global-rules-backups'
$version = [System.IO.File]::ReadAllText((Join-Path $root 'VERSION')).Trim()
$legacyAntigravityRulePath = Join-Path $HOME '.gemini\config\AGENTS.md'

function Read-SourceFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required source file is missing: $Path"
    }

    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path).Trim()
}

function New-GeneratedRule {
    param(
        [Parameter(Mandatory)][string]$ToolName,
        [Parameter(Mandatory)][string]$AdapterPath
    )

    $core = Read-SourceFile (Join-Path $root 'core.md')
    $route = Read-SourceFile (Join-Path $root 'routes\vibe-check.md')
    $adapter = Read-SourceFile $AdapterPath
    $header = "# $ToolName Global Rules`n`n<!-- GENERATED from English canonical rules v$version. Edit the source files, not this deployment. -->"
    return "$header`n`n$core`n`n$route`n`n$adapter`n"
}

$targets = @(
    [PSCustomObject]@{
        Name = 'Antigravity'
        RuntimePath = Join-Path $HOME '.gemini\GEMINI.md'
        MasterPath = Join-Path $root 'dist\antigravity\GEMINI.md'
        Adapter = Join-Path $root 'adapters\antigravity.md'
        MaxCharacters = 12000
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
    (Read-SourceFile (Join-Path $root 'routes\vibe-check.md'))
)
$sourceParts += @($targets | ForEach-Object { Read-SourceFile $_.Adapter })
$sourceText = $sourceParts -join "`n"

if ($sourceText -match '(?i)\bMIA\b|plan-review-execute') {
    throw 'MIA content must remain in its plugin and must not appear in global-rule sources.'
}

$rendered = foreach ($target in $targets) {
    $content = New-GeneratedRule -ToolName $target.Name -AdapterPath $target.Adapter
    [PSCustomObject]@{
        Name = $target.Name
        RuntimePath = $target.RuntimePath
        MasterPath = $target.MasterPath
        Content = $content
        MaxCharacters = $target.MaxCharacters
        MaxLines = $target.MaxLines
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
        foreach ($destination in @($target.MasterPath, $target.RuntimePath)) {
            [System.IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
            [System.IO.File]::WriteAllText($destination, $target.Content, $utf8)
        }
    }

    if (Test-Path -LiteralPath $legacyAntigravityRulePath -PathType Leaf) {
        Remove-Item -LiteralPath $legacyAntigravityRulePath -Force
        Write-Output "Removed duplicate Antigravity global rule: $legacyAntigravityRulePath"
    }
}

$results = foreach ($target in $rendered) {
    $masterExists = Test-Path -LiteralPath $target.MasterPath -PathType Leaf
    $runtimeExists = Test-Path -LiteralPath $target.RuntimePath -PathType Leaf
    $master = if ($masterExists) { [System.IO.File]::ReadAllText($target.MasterPath) } else { '' }
    $runtime = if ($runtimeExists) { [System.IO.File]::ReadAllText($target.RuntimePath) } else { '' }
    $lineCount = ($target.Content -split "`n").Count
    $withinCharacterLimit = $target.MaxCharacters -eq 0 -or $target.Content.Length -le $target.MaxCharacters
    $withinLineLimit = $target.MaxLines -eq 0 -or $lineCount -le $target.MaxLines

    [PSCustomObject]@{
        Target = $target.Name
        MasterMatches = $masterExists -and $master -ceq $target.Content
        RuntimeMatches = $runtimeExists -and $runtime -ceq $master
        Characters = $target.Content.Length
        Lines = $lineCount
        WithinLimit = $withinCharacterLimit -and $withinLineLimit
        MiaReference = $target.Content -match '(?i)\bMIA\b|plan-review-execute'
        DuplicateGlobalRule = $target.Name -eq 'Antigravity' -and (Test-Path -LiteralPath $legacyAntigravityRulePath -PathType Leaf)
    }
}

$results | Format-Table -AutoSize

if ($results | Where-Object { -not $_.MasterMatches -or -not $_.RuntimeMatches -or -not $_.WithinLimit -or $_.MiaReference -or $_.DuplicateGlobalRule }) {
    exit 1
}

exit 0
