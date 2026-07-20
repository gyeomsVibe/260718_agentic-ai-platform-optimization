# Fix-WindowsNotifications.ps1
# Windows 알림 설정을 복구하고 활성화하는 스크립트입니다.
# 관리자 권한으로 실행할 것을 권장하며, `-ResetDB` 스위치를 통해 알림 DB 리셋도 가능합니다.

[CmdletBinding()]
param (
    [switch]$ResetDB
)

# 1. 알림 전역 설정 레지스트리 복구 (HKCU)
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
$name = "NOC_GLOBAL_SETTING_TOASTS_ENABLED"
$value = 1 # 1 = 활성화, 0 = 비활성화

Write-Host "[*] 알림 전역 레지스트리 설정을 검사합니다..." -ForegroundColor Cyan

if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    Write-Host "[+] 알림 설정 경로가 없어 새로 생성했습니다." -ForegroundColor Green
}

$currentValue = Get-ItemProperty -Path $registryPath -Name $name -ErrorAction SilentlyContinue

if ($null -eq $currentValue -or $currentValue.$name -ne $value) {
    Set-ItemProperty -Path $registryPath -Name $name -Value $value -Type DWord -Force
    Write-Host "[+] 알림 전역 활성화 레지스트리 값을 설정했습니다 (Enabled = 1)." -ForegroundColor Green
} else {
    Write-Host "[+] 알림 설정 레지스트리가 이미 활성화(1) 상태입니다." -ForegroundColor Green
}

# NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK 도 활성화 (잠금 화면 알림 표시)
$lockName = "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK"
$lockValue = Get-ItemProperty -Path $registryPath -Name $lockName -ErrorAction SilentlyContinue
if ($null -eq $lockValue -or $lockValue.$lockName -ne 1) {
    Set-ItemProperty -Path $registryPath -Name $lockName -Value 1 -Type DWord -Force
    Write-Host "[+] 잠금 화면 알림 허용 설정을 활성화했습니다." -ForegroundColor Green
}

# 2. Windows Push Notification Database (WPN DB) 리셋 처리
if ($ResetDB) {
    Write-Host "[*] Windows Push Notification 데이터베이스 초기화를 진행합니다..." -ForegroundColor Yellow

    # WPN 서비스 중지
    Write-Host "[-] 알림 관련 서비스를 중지합니다..." -ForegroundColor Cyan
    Stop-Service -Name "WpnService" -Force -ErrorAction SilentlyContinue
    
    # WpnUserService는 사용자 세션별로 호스트되므로 패턴으로 중지
    $userServices = Get-Service -Name "WpnUserService_*" -ErrorAction SilentlyContinue
    foreach ($service in $userServices) {
        Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
    }
    
    Start-Sleep -Seconds 2

    # DB 파일 경로 설정
    $dbFolder = "$env:LocalAppData\Microsoft\Windows\Notifications"
    $dbFile = Join-Path $dbFolder "wpndatabase.db"
    
    if (Test-Path $dbFile) {
        Write-Host "[-] 기존 wpndatabase.db 파일 백업 및 초기화를 수행합니다..." -ForegroundColor Cyan
        
        # 안전한 백업명 생성
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = Join-Path $dbFolder "wpndatabase.db.bak_$timestamp"
        
        try {
            # 백업 후 원본 삭제
            Rename-Item -Path $dbFile -NewName (Split-Path $backupFile -Leaf) -Force -ErrorAction Stop
            Write-Host "[+] 성공적으로 데이터베이스를 백업하고 리셋했습니다: $backupFile" -ForegroundColor Green
        } catch {
            Write-Warning "[-] 데이터베이스 파일 리네임에 실패했습니다. WPN 프로세스가 여전히 리소스를 잠그고 있을 수 있습니다."
            Write-Warning "[-] 에러 메시지: $_"
            Write-Warning "[-] 이 작업은 시스템 재부팅 직후 또는 Explorer 재시작 후 다시 시도해 주십시오."
        }
    } else {
        Write-Host "[+] 기존 WPN 데이터베이스 파일이 존재하지 않아 초기화 단계를 건너뜁니다." -ForegroundColor Green
    }

    # 서비스 재시작
    Write-Host "[*] 서비스를 재시작합니다..." -ForegroundColor Cyan
    Start-Service -Name "WpnService" -ErrorAction SilentlyContinue
    Write-Host "[+] 알림 서비스가 정상적으로 재기동되었습니다." -ForegroundColor Green
}

Write-Host "[*] 알림 설정 조치가 완료되었습니다." -ForegroundColor Green
