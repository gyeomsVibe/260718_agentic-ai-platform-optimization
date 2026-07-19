$ErrorActionPreference = 'Stop'

$target = 'C:\Program Files\WindowsApps\OpenAI.Codex_26.715.4045.0_x64__2p2nqsd0c76g0\app\resources\app.asar'
$projectRoot = $PSScriptRoot
$backup = Join-Path $projectRoot 'backup\app.asar.original'
$aclBackup = Join-Path $projectRoot 'backup\app.asar.acl.xml'
$expectedOriginalHash = '4F81FE8CFADD0ECD1D55A46F4B101B1DB70ABBB372B63A0120218B1D868008A3'

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $backup).Hash -ne $expectedOriginalHash) {
    throw 'Original backup hash mismatch'
}

$currentAcl = Get-Acl -LiteralPath $target
try {
    & takeown.exe /F $target /A | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "takeown failed: $LASTEXITCODE" }
    & icacls.exe $target /grant '*S-1-5-32-544:F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "icacls grant failed: $LASTEXITCODE" }

    $bytes = [System.IO.File]::ReadAllBytes($backup)
    $stream = [System.IO.File]::Open(
        $target,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::Read
    )
    try {
        if ($stream.Length -ne $bytes.Length) { throw 'Restore size mismatch' }
        $stream.Position = 0
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }

    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash -ne $expectedOriginalHash) {
        throw 'Restored file hash mismatch'
    }
    Write-Output 'ORIGINAL_RESTORE=PASS'
}
finally {
    if (Test-Path -LiteralPath $aclBackup) {
        Set-Acl -LiteralPath $target -AclObject (Import-Clixml -LiteralPath $aclBackup)
    }
    else {
        Set-Acl -LiteralPath $target -AclObject $currentAcl
    }
    Write-Output 'ACL_RESTORE=PASS'
}

