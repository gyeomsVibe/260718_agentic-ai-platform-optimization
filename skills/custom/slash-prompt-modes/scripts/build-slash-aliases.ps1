param(
    [Parameter(Mandatory = $true)]
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'

$aliases = @(
    @{ Name = 'selfrefine'; Token = '/SELFREFINE'; Guard = '사용자가 /SELFREFINE을 정확히 명시할 때만 사용한다.' },
    @{ Name = 'redteam'; Token = '/REDTEAM'; Guard = '사용자가 /REDTEAM을 정확히 명시할 때만 사용한다.' },
    @{ Name = 'eli10'; Token = '/ELI10'; Guard = '사용자가 /ELI10을 정확히 명시할 때만 사용한다.' },
    @{ Name = 'deepdive'; Token = '/DEEPDIVE'; Guard = '사용자가 /DEEPDIVE를 정확히 명시할 때만 사용한다.' },
    @{ Name = 'alt3'; Token = '/ALT3'; Guard = '사용자가 /ALT3를 정확히 명시할 때만 사용한다.' },
    @{ Name = 'critic'; Token = '/CRITIC'; Guard = '사용자가 /CRITIC을 정확히 명시할 때만 사용한다.' },
    @{ Name = 'optimize'; Token = '/OPTIMIZE'; Guard = '사용자가 /OPTIMIZE를 정확히 명시할 때만 사용한다.' },
    @{ Name = 'stepbystep'; Token = '/STEPBYSTEP'; Guard = '사용자가 /STEPBYSTEP을 정확히 명시할 때만 사용한다.' },
    @{ Name = 'expert'; Token = '/EXPERT'; Guard = '사용자가 /EXPERT를 정확히 명시할 때만 사용한다.' },
    @{ Name = 'structured'; Token = '/STRUCTURED FEW-SHOT'; Guard = '사용자가 /STRUCTURED 바로 뒤에 FEW-SHOT을 첫 인수로 명시할 때만 사용한다.' }
)

$resolvedRoot = [IO.Path]::GetFullPath($OutputRoot)
$licenseSource = Join-Path (Split-Path -Parent $PSScriptRoot) 'LICENSE.md'
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

# $($alias.Token) 별칭

이 Skill은 독립 정본 ``slash-prompt-modes``의 ``$($alias.Token)`` 모드를 호출하는 얇은 어댑터다.

1. [공통 실행 계약](../slash-prompt-modes/SKILL.md)을 읽는다.
2. [모드별 계약](../slash-prompt-modes/references/mode-contracts.md)에서 ``$($alias.Token)`` 절을 적용한다.
3. 입력에 다른 지원 슬래시 토큰이 있으면 공통 실행 계약의 조합 규칙으로 한 번에 합성한다.
4. 명령 뒤의 나머지 입력을 작업 대상으로 사용하며, 별칭 자체는 권한을 확대하지 않는다.
"@

    [IO.File]::WriteAllText(
        (Join-Path $aliasDirectory 'SKILL.md'),
        $content,
        [Text.UTF8Encoding]::new($false)
    )
    Copy-Item -LiteralPath $licenseSource -Destination (Join-Path $aliasDirectory 'LICENSE.md')

    if ($content.Contains('System.Collections.Hashtable.Token') -or $content.Contains('$(')) {
        throw "Alias token interpolation failed: $($alias.Name)"
    }
}

Write-Output "Generated $($aliases.Count) slash aliases at $resolvedRoot"
