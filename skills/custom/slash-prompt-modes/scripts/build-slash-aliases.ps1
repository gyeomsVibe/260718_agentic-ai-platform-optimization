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
$aliases = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8) | ConvertFrom-Json

$resolvedRoot = [IO.Path]::GetFullPath($OutputRoot)
$licenseSource = Join-Path $skillRoot 'LICENSE.md'
if (-not (Test-Path -LiteralPath $licenseSource -PathType Leaf)) {
    throw "Missing canonical license: $licenseSource"
}
New-Item -ItemType Directory -Path $resolvedRoot -Force | Out-Null

foreach ($alias in $aliases) {
    $aliasDirectory = Join-Path $resolvedRoot $alias.Name
    if (Test-Path -LiteralPath $aliasDirectory) {
        throw "Refusing to overwrite existing alias directory: $aliasDirectory"
    }
    New-Item -ItemType Directory -Path $aliasDirectory | Out-Null

    $content = @"
---
name: $($alias.Name)
description: $($alias.Token) 전용 교차 플랫폼 별칭 Skill. ASCII 대소문자를 구분하지 않는다. $($alias.Guard) 슬래시 없는 일반 자연어나 MIA 호출문에는 사용하지 않는다.
license: MIT
---

# $($alias.token) 별칭

이 Skill은 독립 정본 ``slash-prompt-modes``의 ``$($alias.token)`` 모드를 호출하는 얇은 어댑터다.

1. 입력 토큰을 정본 ``$($alias.token)``으로 정규화한다.
2. 즉시 적용할 최소 계약: $($alias.contract)
3. 복잡한 작업, 중단·금지 조건 또는 여러 모드 조합이 필요할 때만 [공통 실행 계약](../slash-prompt-modes/SKILL.md)과 [모드별 계약](../slash-prompt-modes/references/mode-contracts.md)의 ``$($alias.token)`` 절을 읽는다.
4. 다른 지원 슬래시 토큰이 있으면 공통 실행 계약의 조합 규칙으로 중복 없이 합성한다.
5. 명령 뒤의 나머지 입력을 작업 대상으로 사용하며, 별칭 자체는 권한을 확대하지 않는다.
"@

    [IO.File]::WriteAllText(
        (Join-Path $aliasDirectory 'SKILL.md'),
        $content,
        [Text.UTF8Encoding]::new($false)
    )
    Copy-Item -LiteralPath $licenseSource -Destination (Join-Path $aliasDirectory 'LICENSE.md')

    if ($content.Contains('System.Collections.Hashtable.Token') -or $content.Contains('$(')) {
        throw "Alias token interpolation failed: $($alias.name)"
    }
}

Write-Output "Generated $($aliases.Count) slash aliases at $resolvedRoot"
