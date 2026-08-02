[CmdletBinding()]
param(
    [ValidateSet('Check', 'Apply')]
    [string]$Mode = 'Check',
    [switch]$MigrateAntigravity
)

$ErrorActionPreference = 'Stop'
$catalogScript = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\scripts\sync-mia-catalog.ps1')).Path

if ($MigrateAntigravity) {
    Write-Output 'Legacy migration is included in the catalog Apply workflow.'
}

& $catalogScript -Mode $Mode
exit $LASTEXITCODE
