[CmdletBinding()]
param(
    [ValidateSet('idle', 'running-right', 'running-left', 'waving', 'jumping', 'failed', 'waiting', 'running', 'review')]
    [string]$State,
    [int]$DurationMs = 0,
    [switch]$Clear
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Clear) {
    $State = 'idle'
    $DurationMs = 0
}
if ([string]::IsNullOrWhiteSpace($State)) {
    throw 'Provide -State or use -Clear.'
}
if ($DurationMs -lt 0) {
    throw 'DurationMs cannot be negative.'
}

$statePath = Join-Path $PSScriptRoot 'state.json'
$temporaryPath = "$statePath.tmp"
$payload = [ordered]@{
    state = $State
    ttlMs = $DurationMs
    updatedAt = [DateTime]::UtcNow.ToString('o')
}
$json = $payload | ConvertTo-Json
[IO.File]::WriteAllText($temporaryPath, $json, (New-Object Text.UTF8Encoding($false)))
Move-Item -LiteralPath $temporaryPath -Destination $statePath -Force
Write-Output "Gyeom overlay state: $State"
