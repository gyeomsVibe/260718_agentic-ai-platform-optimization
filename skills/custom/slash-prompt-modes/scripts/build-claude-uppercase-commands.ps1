param(
    [Parameter(Mandatory = $true)]
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $skillRoot 'references\mode-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Missing mode manifest: $manifestPath"
}
$commands = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8) | ConvertFrom-Json

$resolvedRoot = [IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Path $resolvedRoot -Force | Out-Null

foreach ($command in $commands) {
    $commandName = $command.name.ToUpperInvariant()
    $target = Join-Path $resolvedRoot ($commandName + '.md')
    if (Test-Path -LiteralPath $target) {
        throw "Refusing to overwrite existing Claude command: $target"
    }

    $content = @"
---
description: $($command.token) 대문자 호환 어댑터. 소문자 Skill과 같은 계약을 적용한다.
---

$($command.token)를 ASCII 대소문자 비구분 정본 모드로 적용한다. 정본 토큰을 줄이거나 일부 인수를 명령 이름에서 탈락시키지 않는다.

- 계약: $($command.contract)
- 입력에 다른 지원 슬래시 토큰이 있으면 대소문자를 정규화하고 중복 없이 합성한다.
- 모드는 방법과 출력만 바꾸며 사용자 권한과 작업 범위를 확대하지 않는다.

사용자 작업:

`$ARGUMENTS
"@

    [IO.File]::WriteAllText($target, $content, [Text.UTF8Encoding]::new($false))
}

Write-Output "Generated $($commands.Count) uppercase Claude commands at $resolvedRoot"
