# Register-NotificationStartupTask.ps1
# 로그인 시 Windows 알림 활성화 스크립트를 자동으로 실행하도록 등록합니다.
# 1. 관리자 권한이 있으면 -> 작업 스케줄러(Task Scheduler)에 등록
# 2. 관리자 권한이 없으면 -> 현재 사용자 시작프로그램(Startup) 폴더에 무창 VBScript 등록

$scriptName = "Fix-WindowsNotifications.ps1"
$sourcePath = Join-Path $PSScriptRoot $scriptName

# 소스 파일 체크
if (-not (Test-Path $sourcePath)) {
    Write-Error "[-] 원본 스크립트를 찾을 수 없습니다: $sourcePath"
    exit 1
}

# 관리자 권한 검사
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    # ==========================================
    # 방법 A: 관리자 권한용 - 작업 스케줄러 등록
    # ==========================================
    Write-Host "[*] 관리자 권한이 감지되었습니다. 작업 스케줄러 방식으로 등록을 시도합니다..." -ForegroundColor Cyan

    $targetDir = "C:\ProgramData\PC-Maintenance"
    $targetPath = Join-Path $targetDir $scriptName

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $sourcePath -Destination $targetPath -Force
    Write-Host "[+] 실행 스크립트를 로컬에 배치했습니다: $targetPath" -ForegroundColor Green

    $taskName = "AutoEnableNotifications"
    $description = "사용자 로그인 시 Windows 전역 알림 설정을 자동으로 검사하고 강제 활성화합니다."

    # 기존 작업 제거
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($null -ne $existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
    }

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -Role Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description $description -ErrorAction Stop | Out-Null
        Write-Host "[+] 작업 스케줄러 등록 완료 (Task: $taskName)" -ForegroundColor Green
    } catch {
        Write-Warning "[-] 작업 스케줄러 등록 중 오류가 발생했습니다: $_"
        Write-Warning "[-] 대안 방식인 시작프로그램(Startup) 폴더 등록으로 전환합니다."
        $isAdmin = $false
    }
}

if (-not $isAdmin) {
    # ==========================================
    # 방법 B: 일반 사용자 권한용 - 시작프로그램 VBScript 등록
    # ==========================================
    Write-Host "[*] 일반 사용자 권한으로 실행 중입니다. 시작프로그램(Startup) 폴더 방식으로 등록합니다..." -ForegroundColor Cyan

    # 사용자 AppData 로컬 경로에 스크립트 복사
    $targetDir = Join-Path $env:APPDATA "PC-Maintenance"
    $targetPath = Join-Path $targetDir $scriptName

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $sourcePath -Destination $targetPath -Force
    Write-Host "[+] 실행 스크립트를 복사했습니다: $targetPath" -ForegroundColor Green

    # 시작프로그램 경로 및 VBS 파일 정의
    $startupFolder = [System.Environment]::GetFolderPath('Startup')
    $vbsPath = Join-Path $startupFolder "Fix-Notifications-Startup.vbs"

    # 콘솔 창 없이 백그라운드로 실행하기 위한 VBScript 내용 생성
    $vbsContent = @"
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetPath`"", 0, False
"@

    try {
        [System.IO.File]::WriteAllText($vbsPath, $vbsContent, [System.Text.Encoding]::ASCII)
        Write-Host "[+] 시작프로그램에 무창 실행 스크립트가 성공적으로 등록되었습니다." -ForegroundColor Green
        Write-Host "[+] 경로: $vbsPath" -ForegroundColor Green
    } catch {
        Write-Error "[-] 시작프로그램 스크립트 생성에 실패했습니다: $_"
        exit 1
    }
}

Write-Host "[*] 자동 등록 절차가 완료되었습니다. 다음 로그인부터 알림 자동 보정이 실행됩니다." -ForegroundColor Green
