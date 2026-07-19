$ErrorActionPreference = 'Stop'

$target = 'C:\Program Files\WindowsApps\OpenAI.Codex_26.715.4045.0_x64__2p2nqsd0c76g0\app\resources\app.asar'
$projectRoot = $PSScriptRoot
$backup = Join-Path $projectRoot 'backup\app.asar.original'
$patched = Join-Path $projectRoot 'staging\app.asar.patched'
$aclBackup = Join-Path $projectRoot 'backup\app.asar.acl.xml'
$verifyScript = Join-Path $projectRoot 'verify-asar.js'
$installLog = Join-Path $projectRoot 'install-patch.log'

$expectedOriginalHash = '4F81FE8CFADD0ECD1D55A46F4B101B1DB70ABBB372B63A0120218B1D868008A3'
$expectedPatchedHash = 'C3B963038A803E2DBC3D9DA7FB2B70B1069D7731B168F2C3A6DB0E302651A789'
$originalAcl = $null
$writeGranted = $false
$installed = $false

Start-Transcript -LiteralPath $installLog -Force | Out-Null

function Get-Sha256([string] $Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}

function Assert-Hash([string] $Path, [string] $Expected) {
    $actual = Get-Sha256 $Path
    if ($actual -ne $Expected) {
        throw "Hash mismatch: $Path expected=$Expected actual=$actual"
    }
}

function Write-ExactFile([string] $Source, [string] $Destination) {
    $bytes = [System.IO.File]::ReadAllBytes($Source)
    $stream = [System.IO.File]::Open(
        $Destination,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::Read
    )
    try {
        if ($stream.Length -ne $bytes.Length) {
            throw "Size mismatch: source=$($bytes.Length) destination=$($stream.Length)"
        }
        $stream.Position = 0
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }
}

Assert-Hash $target $expectedOriginalHash
Assert-Hash $backup $expectedOriginalHash
Assert-Hash $patched $expectedPatchedHash

$originalAcl = Get-Acl -LiteralPath $target
$originalAcl | Export-Clixml -LiteralPath $aclBackup

try {
    & takeown.exe /F $target /A | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "takeown failed with exit code $LASTEXITCODE"
    }

    & icacls.exe $target /grant '*S-1-5-32-544:F' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "icacls grant failed with exit code $LASTEXITCODE"
    }
    $writeGranted = $true

    Write-ExactFile -Source $patched -Destination $target
    Assert-Hash $target $expectedPatchedHash

    & node $verifyScript $target
    if ($LASTEXITCODE -ne 0) {
        throw "ASAR verification failed with exit code $LASTEXITCODE"
    }

    $installed = $true
    Write-Output 'PATCH_INSTALL=PASS'
}
catch {
    Write-Error $_
    if ($writeGranted) {
        Write-ExactFile -Source $backup -Destination $target
        Assert-Hash $target $expectedOriginalHash
        Write-Output 'PATCH_ROLLBACK=PASS'
    }
    throw
}
finally {
    if ($writeGranted -and $originalAcl -ne $null) {
        Set-Acl -LiteralPath $target -AclObject $originalAcl
        Write-Output 'ACL_RESTORE=PASS'
    }
}

if (-not $installed) {
    Stop-Transcript | Out-Null
    exit 1
}

Stop-Transcript | Out-Null

