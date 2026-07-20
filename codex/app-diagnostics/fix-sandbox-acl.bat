@echo off
chcp 65001 >nul
:: 관리자 권한 승격 검사
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 이 스크립트는 반드시 "관리자 권한으로 실행"해야 합니다.
    echo [!] 마우스 우클릭 -> '관리자 권한으로 실행'을 선택하여 다시 실행해주세요.
    echo.
    pause
    exit /b
)

echo ========================================================
echo [*] Codex 샌드박스 꼬인 디렉터리 소유권 및 NTFS 권한 복구 시작
echo ========================================================
set WORKSPACE_DIR=d:\D_Workspace_NB\-google-workspace\-antigravity-workspace\260718_agentic-ai-platform-optimization

:: 1. 꼬인 폴더들의 소유권을 Administrators 그룹으로 강제 변경
echo [*] 1. 소유권 회수 중 (takeown)...
takeown /F "%WORKSPACE_DIR%" /A /R /D Y

:: 2. 워크스페이스 루트 및 하위 전체에 대해 사용자 및 샌드박스 그룹 권한 부여
echo [*] 2. 호스트 사용자(Kimyoongyeom) Full Control 권한 상속 설정 중 (icacls)...
icacls "%WORKSPACE_DIR%" /grant "Kimyoongyeom:(OI)(CI)F" /T /C /Q

echo [*] 3. CodexSandboxUsers 그룹 Modify 권한 설정 중 (icacls)...
icacls "%WORKSPACE_DIR%" /grant "CodexSandboxUsers:(OI)(CI)M" /T /C /Q

:: 3. 개별 타겟 폴더 조치 (C:\tmp 등)
if exist "C:\tmp" (
    echo [*] 4. C:\tmp 폴더 소유권 및 권한 복구 중...
    takeown /F "C:\tmp" /A /R /D Y >nul 2>&1
    icacls "C:\tmp" /grant "Kimyoongyeom:(OI)(CI)F" /C /Q
    icacls "C:\tmp" /grant "CodexSandboxUsers:(OI)(CI)M" /C /Q
)

echo.
echo [+] 권한 복구 조치가 완료되었습니다!
echo [+] 자가진단 스크립트(codex-sandbox-check.ps1)를 다시 실행하여 검증해보세요.
echo ========================================================
pause
