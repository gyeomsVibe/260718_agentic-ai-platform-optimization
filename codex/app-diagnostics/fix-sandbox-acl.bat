@echo off
REM ============================================================
REM  Codex sandbox ACL recovery -- WORKSPACE folders only.
REM  ASCII-only + CRLF on purpose (Korean text / LF breaks cmd).
REM
REM  Do NOT grant ACL on C:\tmp. C:\tmp is owned by Administrators
REM  and the real fix is to EXCLUDE it from sandbox write-roots:
REM      config.toml -> [sandbox_workspace_write] exclude_slash_tmp = true
REM  See ROOT_CAUSE_c-tmp-write-root_2026-07-22.md in this folder.
REM ============================================================

REM --- Require administrator ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] This script must be run as Administrator.
    echo [!] Right-click the file and choose "Run as administrator".
    echo.
    pause
    exit /b 1
)

REM --- Resolve workspace root = two levels up from this script ---
REM     (script lives in codex\app-diagnostics\)
pushd "%~dp0..\.."
set "WORKSPACE_DIR=%CD%"
popd

echo ========================================================
echo  Codex sandbox ACL recovery
echo  Target: %WORKSPACE_DIR%
echo ========================================================

echo [*] 1/3 Reclaiming ownership (takeown)...
takeown /F "%WORKSPACE_DIR%" /A /R /D Y

echo [*] 2/3 Granting host user (%USERNAME%) Full Control...
icacls "%WORKSPACE_DIR%" /grant "%USERNAME%:(OI)(CI)F" /T /C /Q

echo [*] 3/3 Granting CodexSandboxUsers Modify...
icacls "%WORKSPACE_DIR%" /grant "CodexSandboxUsers:(OI)(CI)M" /T /C /Q

echo.
echo [+] Done. Re-run codex-sandbox-check.ps1 to verify.
echo [+] If C:\tmp errors persist, the fix is excludeSlashTmp=true in
echo [+] config.toml, NOT ACL on C:\tmp. See ROOT_CAUSE doc here.
echo ========================================================
pause
