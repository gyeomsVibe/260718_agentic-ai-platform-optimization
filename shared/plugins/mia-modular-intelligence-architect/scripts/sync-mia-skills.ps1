[CmdletBinding()]
param(
    [ValidateSet('Check', 'Apply')]
    [string]$Mode = 'Check',
    [switch]$MigrateAntigravity
)

$utf8 = [System.Text.UTF8Encoding]::new($false)
$pluginRoot = Split-Path -Parent $PSScriptRoot
$canonicalPath = Join-Path $pluginRoot 'skills\plan-review-execute\SKILL.md'
$pluginManifestPath = Join-Path $pluginRoot 'plugin.json'
$versionPath = Join-Path $pluginRoot 'VERSION'
foreach ($requiredPath in @($canonicalPath, $pluginManifestPath, $versionPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "MIA plugin source is incomplete: $requiredPath"
    }
}

$canonical = [System.IO.File]::ReadAllText($canonicalPath)
$body = [regex]::Replace($canonical, '(?s)\A---\s*.*?\s*---\s*', '')
if ([string]::IsNullOrWhiteSpace($body)) {
    throw 'Canonical MIA skill has no instruction body.'
}
$claudeFrontmatter = @"
---
name: plan-review-execute
description: Activate only when the user explicitly says "MIA모드 발동" to start the 기획·검토·실행 모드 for an evidence-backed product, business, or meaningful technical decision. Do not activate for similar natural-language requests.
argument-hint: "MIA모드 발동: [기획|검토|실행|검증] <목표>"
user-invocable: false
---

"@
$claudeSkill = $claudeFrontmatter + $body

$agentRoot = Split-Path -Parent (Split-Path -Parent $pluginRoot)
$antigravityPluginRoot = Join-Path $env:USERPROFILE '.gemini\config\plugins\mia-modular-intelligence-architect'
$legacyAntigravitySkill = Join-Path $env:USERPROFILE '.gemini\config\skills\plan-review-execute'
$targets = @(
    @{ Name = 'Workspace mirror'; Path = (Join-Path $agentRoot 'skills\plan-review-execute\SKILL.md'); Content = $canonical },
    @{ Name = 'Codex'; Path = (Join-Path $env:USERPROFILE '.codex\skills\plan-review-execute\SKILL.md'); Content = $canonical },
    @{ Name = 'Claude source mirror'; Path = (Join-Path $agentRoot 'skills\plan-review-execute\CLAUDE-SKILL.md'); Content = $claudeSkill },
    @{ Name = 'Claude'; Path = (Join-Path $env:USERPROFILE '.claude\skills\plan-review-execute\SKILL.md'); Content = $claudeSkill },
    @{ Name = 'Antigravity plugin skill'; Path = (Join-Path $antigravityPluginRoot 'skills\plan-review-execute\SKILL.md'); Content = $canonical },
    @{ Name = 'Antigravity plugin manifest'; Path = (Join-Path $antigravityPluginRoot 'plugin.json'); Content = [System.IO.File]::ReadAllText($pluginManifestPath) },
    @{ Name = 'Antigravity plugin version'; Path = (Join-Path $antigravityPluginRoot 'VERSION'); Content = [System.IO.File]::ReadAllText($versionPath) }
)

if ($Mode -eq 'Apply') {
    foreach ($target in $targets) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target.Path) | Out-Null
        [System.IO.File]::WriteAllText($target.Path, $target.Content, $utf8)
    }
    if ($MigrateAntigravity -and (Test-Path -LiteralPath $legacyAntigravitySkill)) {
        Remove-Item -LiteralPath $legacyAntigravitySkill -Recurse -Force
    }
}

$results = foreach ($target in $targets) {
    $exists = Test-Path -LiteralPath $target.Path
    $matches = $exists -and ([System.IO.File]::ReadAllText($target.Path) -eq $target.Content)
    [PSCustomObject]@{ Target = $target.Name; Exists = $exists; MatchesCanonical = $matches }
}
$results | Format-Table -AutoSize
[PSCustomObject]@{ LegacyAntigravityStandaloneExists = Test-Path -LiteralPath $legacyAntigravitySkill } | Format-List
if (@($results | Where-Object { -not $_.MatchesCanonical }).Count -gt 0) { exit 1 }
if ($MigrateAntigravity -and (Test-Path -LiteralPath $legacyAntigravitySkill)) { exit 1 }