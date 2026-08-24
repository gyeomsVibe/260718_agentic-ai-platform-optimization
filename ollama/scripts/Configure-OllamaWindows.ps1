[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ModelsPath = 'D:\AI-Models\Ollama',

    [Parameter()]
    [ValidateRange(2048, 131072)]
    [int]$ContextLength = 8192,

    [Parameter()]
    [ValidateRange(1, 16)]
    [int]$NumParallel = 1,

    [Parameter()]
    [ValidateRange(1, 16)]
    [int]$MaxLoadedModels = 1
)

$ErrorActionPreference = 'Stop'

$ollamaInstallDirectory = Join-Path $env:LOCALAPPDATA 'Programs\Ollama'
$ollamaExecutable = Join-Path $ollamaInstallDirectory 'ollama.exe'

if (-not (Test-Path -LiteralPath $ollamaExecutable -PathType Leaf)) {
    throw "Ollama 실행 파일을 찾을 수 없습니다: $ollamaExecutable"
}

if (-not (Test-Path -LiteralPath $ModelsPath -PathType Container)) {
    New-Item -ItemType Directory -Path $ModelsPath -Force | Out-Null
}

$resolvedModelsPath = (Resolve-Path -LiteralPath $ModelsPath).Path
$settings = [ordered]@{
    OLLAMA_MODELS            = $resolvedModelsPath
    OLLAMA_CONTEXT_LENGTH    = [string]$ContextLength
    OLLAMA_NUM_PARALLEL      = [string]$NumParallel
    OLLAMA_MAX_LOADED_MODELS = [string]$MaxLoadedModels
}

foreach ($entry in $settings.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'User')
    Set-Item -Path "Env:$($entry.Key)" -Value $entry.Value
}

Get-Process -Name 'ollama', 'ollama app' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path.StartsWith($ollamaInstallDirectory, [StringComparison]::OrdinalIgnoreCase) } |
    Stop-Process -Force

Start-Sleep -Seconds 2
Start-Process -FilePath $ollamaExecutable -ArgumentList 'serve' -WindowStyle Hidden

$serverReady = $false
foreach ($attempt in 1..20) {
    Start-Sleep -Seconds 1
    try {
        $null = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 2
        $serverReady = $true
        break
    }
    catch {
        if ($attempt -eq 20) {
            throw 'Ollama 서버가 20초 안에 시작되지 않았습니다.'
        }
    }
}

if (-not $serverReady) {
    throw 'Ollama 서버 준비 상태를 확인하지 못했습니다.'
}

Write-Host ''
Write-Host '[완료] Ollama 사용자 설정이 저장됐습니다.' -ForegroundColor Green
Write-Host "모델 저장소: $resolvedModelsPath"
Write-Host "컨텍스트: $ContextLength / 병렬 요청: $NumParallel / 동시 모델: $MaxLoadedModels"
Write-Host ''
& $ollamaExecutable list
if ($LASTEXITCODE -ne 0) {
    throw "ollama list가 종료 코드 $LASTEXITCODE`(으`)로 실패했습니다."
}
