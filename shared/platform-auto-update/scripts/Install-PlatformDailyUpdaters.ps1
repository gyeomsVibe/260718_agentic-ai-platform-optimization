[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Remove
)

$scripts = @(
    @{
        TaskName = "Codex CLI Daily Update"
        Time = "15:00"
        Script = "Update-CodexCliAtLogon.vbs"
        Desc = "Daily automatic update for Codex CLI via npm."
    },
    @{
        TaskName = "Antigravity Daily Update"
        Time = "15:10"
        Script = "Update-AntigravityAtLogon.vbs"
        Desc = "Daily sequential automatic update for Antigravity IDE, 2.0, and CLI via winget."
    },
    @{
        TaskName = "GitHub CLI Daily Update"
        Time = "15:20"
        Script = "Update-GitHubCliDaily.vbs"
        Desc = "Daily automatic update for GitHub CLI via winget."
    }
)

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# 기존 시작프로그램 레지스트리 키 제거
$runKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$cleanupValues = @("Codex CLI Logon Updater", "Antigravity Sequential Logon Updater", "Claude Code GitHub CLI Update Monitor")

foreach ($value in $cleanupValues) {
    if (Get-ItemProperty -Path $runKeyPath -Name $value -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($runKeyPath, "Remove registry value $value")) {
            Remove-ItemProperty -Path $runKeyPath -Name $value -Force
            Write-Host "- Removed legacy logon startup registry: $value"
        }
    }
}

# 태스크 제거/등록 처리
foreach ($item in $scripts) {
    $taskName = $item.TaskName
    $scriptPath = Join-Path $PSScriptRoot $item.Script

    # 1. 기존 태스크 언등록
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($taskName, 'Remove scheduled task')) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "- Removed existing scheduled task: $taskName"
        }
    }

    if ($Remove) {
        continue
    }

    # 2. 파일 존재 검증
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Warning "VBS Script not found: $scriptPath. Skipping registration."
        continue
    }

    # 3. 신규 일일 태스크 등록
    # //B = 배치(무음) 모드. 스크립트 오류·경로 문제 시에도 대화상자를 띄우지 않는다.
    $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\wscript.exe" -Argument ('//B "{0}"' -f $scriptPath)
    
    # 15:00 / 15:10 / 15:20 매일 실행 트리거 정의
    $trigger = New-ScheduledTaskTrigger -Daily -At $item.Time
    
    $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    if ($PSCmdlet.ShouldProcess($taskName, 'Register scheduled task')) {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $item.Desc -Force | Out-Null
        Write-Host "- Registered daily scheduled task: $taskName at $($item.Time)"
    }
}
