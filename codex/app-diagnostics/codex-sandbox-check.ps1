[CmdletBinding()]
param(
    [switch]$Interactive
)

$ErrorActionPreference = 'Continue'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🔍 Codex 샌드박스 및 미리보기 환경 자가진단 시작" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$hasErrors = $false

# 1. app.asar 순정 무결성 검사
Write-Host "`n[1/4] app.asar 무결성 검증 중..." -ForegroundColor Yellow
$asarPath = "C:\Program Files\WindowsApps\OpenAI.Codex_26.715.4045.0_x64__2p2nqsd0c76g0\app\resources\app.asar"
$expectedOriginalHash = "4F81FE8CFADD0ECD1D55A46F4B101B1DB70ABBB372B63A0120218B1D868008A3"

if (Test-Path -LiteralPath $asarPath) {
    $actualHash = (Get-FileHash -Path $asarPath -Algorithm SHA256).Hash
    if ($actualHash -eq $expectedOriginalHash) {
        Write-Host "✅ app.asar가 패치되지 않은 정상적인 순정 서명 상태입니다." -ForegroundColor Green
    } else {
        Write-Host "⚠️ 경고: app.asar 파일 해시가 원래의 순정 상태와 다릅니다!" -ForegroundColor Yellow
        Write-Host "   - 현재 해시: $actualHash"
        Write-Host "   - 기대 해시: $expectedOriginalHash"
        Write-Host "   - 만약 임의 패치로 인해 스토어 서명이 깨졌다면 앱 실행이 불가하거나 강제 복구될 수 있습니다." -ForegroundColor Yellow
        $hasErrors = $true
    }
} else {
    Write-Host "ℹ️ 정보: OpenAI.Codex 앱 경로가 발견되지 않았습니다. 이 기기에 Codex가 설치되어 있지 않다면 정상입니다. (app.asar 무결성 검사 건너뜀)" -ForegroundColor Gray
}


# 2. GitHub CLI (gh) 샌드박스 인증 상태 검사
Write-Host "`n[2/4] GitHub CLI 샌드박스 토큰 저장 방식 검증 중..." -ForegroundColor Yellow
$hostsYmlPath = Join-Path $env:APPDATA "GitHub CLI\hosts.yml"
$envGithubToken = $env:GITHUB_TOKEN

if ($envGithubToken -and ($envGithubToken -like "*dummy*" -or $envGithubToken -like "*pat_antigravity*")) {
    Write-Host "ℹ️ 정보: 환경 변수 GITHUB_TOKEN에 더미 토큰($envGithubToken)이 설정되어 있어 gh 명령이 오작동할 수 있습니다." -ForegroundColor Gray
    Write-Host "   - 실제 검증을 위해 임시로 환경 변수를 제거하고 점검합니다." -ForegroundColor Gray
    Remove-Item Env:\GITHUB_TOKEN -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath $hostsYmlPath) {
    $hostsContent = Get-Content -LiteralPath $hostsYmlPath -Raw
    if ($hostsContent -like "*oauth_token:*") {
        Write-Host "✅ hosts.yml 파일 내에 평문 토큰이 저장되어 있습니다." -ForegroundColor Green
        
        # 실제 gh 실행 테스트 (파워셸의 stderr 리다이렉션 쿼크 방지를 위해 임시 파일 사용)
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            gh auth status > $tempFile 2>&1
            $ghStatus = Get-Content -Path $tempFile -Raw
        } finally {
            if (Test-Path -LiteralPath $tempFile) {
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        if ($ghStatus -like "*Logged in to github.com account*") {
            Write-Host "✅ GitHub CLI 로그인 상태 확인 완료: 정상적으로 인증되었습니다." -ForegroundColor Green
        } else {
            Write-Host "⚠️ 경고: hosts.yml은 있으나 실제 gh 실행 시 로그인 인증이 거부되었습니다." -ForegroundColor Yellow
            $hasErrors = $true
        }
    } else {
        Write-Host "⚠️ 경고: hosts.yml 파일이 존재하지만 평문 토큰(oauth_token)이 발견되지 않았습니다." -ForegroundColor Yellow
        Write-Host "   - 샌드박스 내부에서 gh 명령어 실행 시 로그인 안 됨 오류가 발생할 수 있습니다." -ForegroundColor Yellow
        Write-Host "   - 조치 가이드: 일반 터미널에서 다음 명령을 실행하여 샌드박스용 토큰을 동기화하십시오:" -ForegroundColor Yellow
        Write-Host "     gh auth token | gh auth login --with-token --insecure-storage --hostname github.com" -ForegroundColor Cyan
        $hasErrors = $true
    }
} else {
    Write-Host "⚠️ 경고: GitHub CLI 설정 파일(hosts.yml)이 발견되지 않았습니다." -ForegroundColor Yellow
    Write-Host "   - 경로: $hostsYmlPath"
    Write-Host "   - 조치 가이드: 'gh auth login' 명령을 사용해 로그인하거나 `--insecure-storage` 옵션으로 토큰을 파일로 내보내십시오." -ForegroundColor Yellow
    $hasErrors = $true
}

# 환경 변수 원복
if ($envGithubToken) {
    $env:GITHUB_TOKEN = $envGithubToken
}



# 3. 샌드박스 쓰기 경로 ACL(Modify ACE) 권한 검사
#    이 스크립트는 codex/app-diagnostics/ 안에 있으므로 워크스페이스 루트는 두 단계 위다.
Write-Host "`n[3/4] 샌드박스 쓰기 대상 디렉터리 권한 검증 중..." -ForegroundColor Yellow
$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$codexDir      = Join-Path $workspaceRoot "codex"
$repoSyncPath  = Join-Path $workspaceRoot "shared\repository-sync"
$targetPaths = @("C:\tmp", $codexDir, $repoSyncPath)
$aclCheckPassed = $true

foreach ($path in $targetPaths) {
    if (Test-Path -LiteralPath $path) {
        $acl = Get-Acl -LiteralPath $path
        $aclText = $acl.AccessToString
        
        if ($aclText -like "*CodexSandboxUsers*") {
            Write-Host "✅ $($path): CodexSandboxUsers 그룹에 대한 보안 규칙(ACL)이 정상 할당되어 있습니다." -ForegroundColor Green
        } else {
            Write-Host "⚠️ 경고: $($path) 디렉터리에 'CodexSandboxUsers' ACL 권한이 존재하지 않습니다!" -ForegroundColor Yellow
            Write-Host "   - 이로 인해 샌드박스에서 해당 폴더로 쓰기가 거부(Access Denied)될 수 있습니다." -ForegroundColor Yellow
            Write-Host "   - 조치 가이드: 관리자 권한 터미널에서 아래 명령을 실행하십시오:" -ForegroundColor Yellow
            Write-Host "     icacls `"$($path)`" /grant `"CodexSandboxUsers:(OI)(CI)M`"" -ForegroundColor Cyan
            $hasErrors = $true
            $aclCheckPassed = $false
        }
    } else {
        Write-Host "ℹ️ 정보: $path 폴더가 존재하지 않아 권한 점검을 건너뜁니다." -ForegroundColor Gray
    }
}


# 4. 최근 샌드박스 로그 에러 스캔 (최신 setup refresh 시점 기준 판정)
#    핵심 개선: "ACL이 지금 OK"만으로 과거 에러를 넘기지 않는다.
#    로그의 setup refresh 줄을 시간순으로 파싱해, '마지막 에러' 이후 '무오류 setup'이
#    실제로 실행됐는지를 근거로 판정한다 → 오탐(복구됨을 실패로)·미탐(재발을 합격으로) 동시 방지.
Write-Host "`n[4/4] 최근 샌드박스 실행 로그 에러 스캔 중..." -ForegroundColor Yellow
$sandboxLogDir = Join-Path $env:USERPROFILE ".codex\.sandbox"
if (Test-Path -LiteralPath $sandboxLogDir) {
    $recentLog = Get-ChildItem -Path $sandboxLogDir -Filter "sandbox.*.log" |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1

    if ($recentLog) {
        Write-Host "   - 최신 로그 파일 검사 중: $($recentLog.Name)" -ForegroundColor Gray

        # setup refresh 줄만 뽑아 [타임스탬프 + 에러 여부]로 파싱하고 시간순 정렬
        $refreshEvents = Select-String -Path $recentLog.FullName -Pattern 'setup refresh' | ForEach-Object {
            $line = $_.Line
            $ts = $null
            if ($line -match '^\[([^\]]+)\]') {
                try { $ts = [datetimeoffset]::Parse($matches[1]) } catch { $ts = $null }
            }
            [pscustomobject]@{
                Time     = $ts
                HasError = ($line -match 'errors=\["')
                Line     = $line
            }
        } | Where-Object { $_.Time -ne $null } | Sort-Object Time

        if (-not $refreshEvents) {
            Write-Host "ℹ️ 정보: 최신 로그에 setup refresh 기록이 없어 로그 기반 판정을 건너뜁니다." -ForegroundColor Gray
        } else {
            $lastRefresh = $refreshEvents[-1]
            $lastError   = ($refreshEvents | Where-Object {      $_.HasError } | Select-Object -Last 1)
            $lastSuccess = ($refreshEvents | Where-Object { -not $_.HasError } | Select-Object -Last 1)

            if (-not $lastError) {
                Write-Host "✅ 최근 샌드박스 로그에 쓰기 권한(SetNamedSecurityInfoW) 관련 차단 에러가 없습니다." -ForegroundColor Green
            }
            elseif (-not $lastRefresh.HasError -and $lastSuccess -and ($lastSuccess.Time -gt $lastError.Time)) {
                # 에러가 있었지만 '그 이후' 무오류 setup이 실행됨 → 근본 원인 복구 확인
                Write-Host "✅ 과거 쓰기 에러가 있었으나, 그 이후 정상 setup(무오류)이 실행되어 해결이 확인되었습니다." -ForegroundColor Green
                Write-Host "   - 마지막 에러 시각 : $($lastError.Time.ToString('u'))" -ForegroundColor Gray
                Write-Host "   - 이후 정상 setup  : $($lastSuccess.Time.ToString('u')) (무오류) ← 복구 이후 재발 없음" -ForegroundColor Gray
            }
            else {
                # 가장 최근 setup refresh가 여전히 에러 → 현재 진행형 실패 (미탐 방지)
                Write-Host "❌ 오류: 가장 최근 샌드박스 setup에서도 쓰기 에러가 발생 중입니다 (현재 진행형)." -ForegroundColor Red
                Write-Host "   - 최근 에러: $($lastError.Line)" -ForegroundColor Yellow
                if ($lastSuccess) {
                    Write-Host "   - 마지막 정상 setup: $($lastSuccess.Time.ToString('u')) → 그 이후 다시 실패함" -ForegroundColor Yellow
                } else {
                    Write-Host "   - 이 로그에는 아직 무오류 setup 기록이 없습니다." -ForegroundColor Yellow
                }
                if (-not $aclCheckPassed) {
                    Write-Host "   -> [3/4] 권한 검사도 실패 → fix-sandbox-acl.bat로 권한을 복구하세요." -ForegroundColor Red
                } else {
                    Write-Host "   -> [3/4] ACL은 지금 정상이나 setup 재적용 전입니다. Codex 재시작 후 재진단하세요." -ForegroundColor Yellow
                }
                $hasErrors = $true
            }
        }
    } else {
        Write-Host "ℹ️ 정보: 샌드박스 로그 파일이 존재하지 않습니다." -ForegroundColor Gray
    }
} else {
    Write-Host "ℹ️ 정보: Codex 샌드박스 로그 디렉터리를 찾을 수 없습니다." -ForegroundColor Gray
}

Write-Host "`n=============================================" -ForegroundColor Cyan
if ($hasErrors) {
    Write-Host "❌ 진단 완료: 일부 환경에 경고/오류가 발견되었습니다. 위의 조치 가이드를 따라주세요." -ForegroundColor Red
    
    # 대화식 세션이고 배치 파일이 존재할 경우 자동 복구 권장
    $batchPath = Join-Path $PSScriptRoot "fix-sandbox-acl.bat"
    if (Test-Path -LiteralPath $batchPath) {
        Write-Host "`n💡 꼬인 권한과 소유권을 한 번에 복구할 수 있는 배치 스크립트가 준비되어 있습니다." -ForegroundColor Yellow
        Write-Host "   스크립트 경로: $batchPath" -ForegroundColor Cyan
        Write-Host "   (관리자 권한 요청 UAC 팝업이 나타날 수 있습니다.)" -ForegroundColor Yellow
        
        # 대화형 프롬프트 제공
        if ($Interactive -and [Environment]::UserInteractive) {
            $response = Read-Host "`n관리자 권한으로 'fix-sandbox-acl.bat'를 실행하여 권한을 즉시 복구하시겠습니까? (Y/N)"
            if ($response -eq 'Y' -or $response -eq 'y') {
                Write-Host "`n[*] 관리자 권한으로 복구 배치를 실행합니다..." -ForegroundColor Cyan
                Start-Process cmd.exe -ArgumentList "/c `"$batchPath`"" -Verb RunAs -Wait
                Write-Host "✅ 복구 배치가 종료되었습니다. 자가진단을 재실행합니다...`n" -ForegroundColor Green
                & $MyInvocation.MyCommand.Path -Interactive
                exit
            }
        } else {
            Write-Host "   - 터미널에서 다음 명령을 실행하여 권한을 복구하십시오:" -ForegroundColor Yellow
            Write-Host "     Start-Process cmd.exe -ArgumentList `"/c `\`"$batchPath`\`"`" -Verb RunAs" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "✅ 진단 완료: 샌드박스 실행 환경이 모두 양호합니다!" -ForegroundColor Green
}
Write-Host "=============================================" -ForegroundColor Cyan

