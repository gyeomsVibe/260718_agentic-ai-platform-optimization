[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Model = 'qwen3.5:4b',

    [Parameter()]
    [ValidateSet('false', 'true', 'low', 'medium', 'high')]
    [string]$Think = 'false',

    [Parameter()]
    [ValidatePattern('^\d+(s|m|h)$')]
    [string]$KeepAlive = '10m'
)

$ErrorActionPreference = 'Stop'

$ollamaExecutable = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
if (-not (Test-Path -LiteralPath $ollamaExecutable -PathType Leaf)) {
    throw "Ollama 실행 파일을 찾을 수 없습니다: $ollamaExecutable"
}

try {
    $null = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 2
}
catch {
    Start-Process -FilePath $ollamaExecutable -ArgumentList 'serve' -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

$installedModels = & $ollamaExecutable list
if ($LASTEXITCODE -ne 0) {
    throw "ollama list가 종료 코드 $LASTEXITCODE`(으`)로 실패했습니다."
}

if (-not ($installedModels | Select-String -SimpleMatch $Model)) {
    throw "설치된 모델 목록에서 '$Model'을 찾지 못했습니다. 먼저 'ollama pull $Model'을 실행하세요."
}

Write-Host "모델: $Model / 추론: $Think / 종료: /bye" -ForegroundColor Cyan
& $ollamaExecutable run $Model "--think=$Think" --keepalive $KeepAlive
if ($LASTEXITCODE -ne 0) {
    throw "ollama run이 종료 코드 $LASTEXITCODE`(으`)로 실패했습니다."
}
