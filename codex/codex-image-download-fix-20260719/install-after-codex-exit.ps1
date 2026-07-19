$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$installer = Join-Path $projectRoot 'install-patch.ps1'
$watcherLog = Join-Path $projectRoot 'install-after-exit.log'
$statusFile = Join-Path $projectRoot 'install-after-exit.status.json'
$deadline = [DateTimeOffset]::Now.AddMinutes(10)

Start-Transcript -LiteralPath $watcherLog -Force | Out-Null

try {
    Write-Output 'WAITING_FOR_CODEX_EXIT'
    while ([DateTimeOffset]::Now -lt $deadline) {
        $codexProcesses = @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue)
        if ($codexProcesses.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 750
    }

    if (@(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue).Count -ne 0) {
        throw 'Timed out waiting for all Codex ChatGPT processes to exit'
    }

    Start-Sleep -Seconds 2
    & 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -ExecutionPolicy Bypass -File $installer
    if ($LASTEXITCODE -ne 0) {
        throw "Installer failed with exit code $LASTEXITCODE"
    }

    [pscustomobject]@{
        status = 'PASS'
        completedAt = [DateTimeOffset]::Now.ToString('o')
    } | ConvertTo-Json | Set-Content -LiteralPath $statusFile -Encoding utf8
    Write-Output 'PATCH_AFTER_EXIT=PASS'
}
catch {
    [pscustomobject]@{
        status = 'FAIL'
        completedAt = [DateTimeOffset]::Now.ToString('o')
        error = $_.Exception.Message
    } | ConvertTo-Json | Set-Content -LiteralPath $statusFile -Encoding utf8
    Write-Error $_
}
finally {
    Stop-Transcript | Out-Null
    Start-Process -FilePath 'explorer.exe' -ArgumentList 'shell:AppsFolder\OpenAI.Codex_2p2nqsd0c76g0!App'
}

