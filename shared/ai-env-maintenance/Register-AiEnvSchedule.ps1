<#
    Register-AiEnvSchedule.ps1 — 유지보수 예약 작업 등록/해제 (사용자 레벨)
    ────────────────────────────────────────────────────────────────
    관리자 권한 불요. 현재 사용자 컨텍스트로 등록한다.
      MIA_AiEnv_Watch   : 매일 (기본 09:30) -Mode Watch  (읽기전용 순찰)
      MIA_AiEnv_Weekly  : 매주 일요일 (기본 10:00) -Mode Weekly (Temp정리 + 정션복구 DRYRUN)

    사용:
      pwsh -File Register-AiEnvSchedule.ps1            # 등록(또는 갱신)
      pwsh -File Register-AiEnvSchedule.ps1 -Remove    # 해제
      pwsh -File Register-AiEnvSchedule.ps1 -WhatIf    # 미리보기

    설계: 실제 복구(-RepairApply)는 예약에 넣지 않는다. 파괴 가능성이 있는 단계는
    사람이 앱을 끄고 수동 실행한다(C3P 합의: 앱 실행 중 자동 정션 조작 금지).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Remove,
    [string]$WatchTime = '09:30',
    [string]$WeeklyTime = '10:00',
    [string]$WeeklyDay = 'Sunday'
)

$ErrorActionPreference = 'Stop'
$Here = $PSScriptRoot
$orchestrator = Join-Path $Here 'Invoke-AiEnvMaintenance.ps1'
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwsh) { $pwsh = (Get-Command powershell).Source }

$tasks = @(
    @{ Name = 'MIA_AiEnv_Watch';  Args = '-Mode Watch';  Trigger = 'Daily' }
    @{ Name = 'MIA_AiEnv_Weekly'; Args = '-Mode Weekly'; Trigger = 'Weekly' }
)

if ($Remove) {
    foreach ($t in $tasks) {
        if (Get-ScheduledTask -TaskName $t.Name -ErrorAction SilentlyContinue) {
            if ($PSCmdlet.ShouldProcess($t.Name, 'Unregister')) {
                Unregister-ScheduledTask -TaskName $t.Name -Confirm:$false
                Write-Host "해제: $($t.Name)" -ForegroundColor Yellow
            }
        }
        else { Write-Host "없음: $($t.Name)" }
    }
    return
}

if (-not (Test-Path $orchestrator)) { throw "오케스트레이터 없음: $orchestrator" }

foreach ($t in $tasks) {
    $action = New-ScheduledTaskAction -Execute $pwsh `
        -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$orchestrator`" $($t.Args)"

    if ($t.Trigger -eq 'Daily') {
        $trigger = New-ScheduledTaskTrigger -Daily -At $WatchTime
    }
    else {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $WeeklyDay -At $WeeklyTime
    }

    # 사용자 레벨, 최고권한 아님, 배터리에서도 실행, 놓친 실행은 기동 후 보충
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -MultipleInstances IgnoreNew

    if ($PSCmdlet.ShouldProcess($t.Name, 'Register')) {
        Register-ScheduledTask -TaskName $t.Name -Action $action -Trigger $trigger `
            -Principal $principal -Settings $settings `
            -Description "AI 환경 유지보수 ($($t.Args)). shared/ai-env-maintenance. C3P 합의 설계." -Force | Out-Null
        Write-Host "등록: $($t.Name)  [$($t.Trigger)]  $($t.Args)" -ForegroundColor Green
    }
}

Write-Host ''
Write-Host '등록된 작업:' -ForegroundColor Cyan
Get-ScheduledTask -TaskName 'MIA_AiEnv_*' -ErrorAction SilentlyContinue |
    Select-Object TaskName, State | Format-Table -AutoSize
