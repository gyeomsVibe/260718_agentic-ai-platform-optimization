[CmdletBinding()]
param(
    [switch]$Interactive,
    [string]$LogPath,
    [switch]$ProbeWorkspaceWrite,
    [ValidateRange(1, 1440)][int]$MaxAgeMinutes = 10
)
# No credentials, ACL changes, subprocesses, or automatic elevation.
# Exit 0: requested observations passed; 1: observed failure; 2: incomplete.
$ErrorActionPreference = 'Stop'
$checks = [System.Collections.Generic.List[object]]::new()
$exitCode = 0
if ($Interactive) { Write-Warning 'Interactive repair is retired. This command never changes ACLs.' }
try {
    if (-not $LogPath) {
        $logDir = Join-Path $env:USERPROFILE '.codex/.sandbox'
        $latest = Get-ChildItem -LiteralPath $logDir -Filter 'sandbox.*.log' -File |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $latest) { throw 'No log available' }
        $LogPath = $latest.FullName
    }
    # Only completed records count; spawn messages are not successful setup.
    $events = @()
    $malformed = $false
    foreach ($line in Get-Content -LiteralPath $LogPath) {
        if ($line -match '^\[([^\]]+)\] setup refresh: processed \d+ write roots.*; errors=(.*)$') {
            try {
                $stamp = [datetimeoffset]::Parse($matches[1])
                $rawErrors = $matches[2].Trim()
                if (-not ($rawErrors.StartsWith('[') -and $rawErrors.EndsWith(']'))) { throw 'Invalid errors array' }
                $errors = @($rawErrors | ConvertFrom-Json)
                $events += [pscustomobject]@{Time=$stamp; Failed=($errors.Count -gt 0)}
            } catch { $malformed = $true }
        }
    }
    if ($malformed -or $events.Count -eq 0) {
        $checks.Add(@{Check='Setup'; Status='Unknown'; Reason='Missing or malformed completion evidence'})
        $exitCode = 2
    } else {
        $last = $events | Sort-Object Time | Select-Object -Last 1
        $age = ([datetimeoffset]::UtcNow - $last.Time).TotalMinutes
        if ($age -lt -1 -or $age -gt $MaxAgeMinutes) {
            $checks.Add(@{Check='Setup'; Status='Unknown'; Reason='Stale or future timestamp'})
            $exitCode = 2
        } elseif ($last.Failed) {
            $checks.Add(@{Check='Setup'; Status='Failed'; Reason='Latest completion has errors; inspect the reported target through the approved diagnostic flow'})
            $exitCode = 1
        } else {
            $checks.Add(@{Check='Setup'; Status='Passed'; Reason='Latest observed setup only; not proof for every task or path'})
        }
    }
} catch {
    $checks.Add(@{Check='Setup'; Status='Unknown'; Reason='Log unavailable'; Category=[string]$_.CategoryInfo.Category})
    $exitCode = 2
}
if ($ProbeWorkspaceWrite) {
    $stream = $null
    try {
        # Only a unique new file beside this script, never protected metadata.
        $probePath = Join-Path $PSScriptRoot ('.sandbox-probe-' + [guid]::NewGuid().ToString('N'))
        $stream = [System.IO.FileStream]::new($probePath, [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None, 4096,
            [System.IO.FileOptions]::DeleteOnClose)
        $stream.WriteByte(83)
        $stream.Flush()
        $stream.Position = 0
        if ($stream.ReadByte() -ne 83) { throw 'Round-trip mismatch' }
        $checks.Add(@{Check='WorkspaceWrite'; Status='Passed'; Reason='Create/write/read at script directory only'})
    } catch {
        $checks.Add(@{Check='WorkspaceWrite'; Status='Failed'; Category=[string]$_.CategoryInfo.Category})
        $exitCode = 1
    } finally { if ($null -ne $stream) { $stream.Dispose() } }
}
[ordered]@{
    Scope='Requested checks in this process only; no global sandbox health claim'
    Checks=@($checks.ToArray())
    ExitCode=$exitCode
    GitWrites='Use the platform approval flow for protected Git metadata; do not remove DENY ACLs'
} | ConvertTo-Json -Depth 5
exit $exitCode
