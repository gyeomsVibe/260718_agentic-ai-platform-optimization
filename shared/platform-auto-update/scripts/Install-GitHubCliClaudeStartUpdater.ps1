[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Remove
)

$taskName = 'Claude Code GitHub CLI Update Monitor'
$scriptPath = Join-Path $PSScriptRoot 'Update-GitHubCliOnClaudeStart.vbs'

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Updater script was not found: $scriptPath"
}

if ($Remove) {
    if ($PSCmdlet.ShouldProcess($taskName, 'Remove scheduled task')) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    }
    return
}

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\wscript.exe" -Argument ('"{0}"' -f $scriptPath)
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

if ($PSCmdlet.ShouldProcess($taskName, 'Register scheduled task')) {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Monitors Claude Code starts and updates GitHub CLI through winget.' -Force | Out-Null
}
