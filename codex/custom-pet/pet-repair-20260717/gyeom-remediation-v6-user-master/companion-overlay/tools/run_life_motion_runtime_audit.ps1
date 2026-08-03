param(
    [Parameter(Mandatory = $true)][string]$OverlayRoot,
    [int]$DurationSeconds = 60,
    [int]$CaptureIntervalMs = 500
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class GyeomLifeWindow {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr extraData);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    public static IntPtr FindForProcess(uint targetPid) {
        IntPtr found = IntPtr.Zero;
        EnumWindows(delegate(IntPtr hWnd, IntPtr extraData) {
            uint pid;
            GetWindowThreadProcessId(hWnd, out pid);
            if (pid == targetPid && IsWindowVisible(hWnd)) { found = hWnd; return false; }
            return true;
        }, IntPtr.Zero);
        return found;
    }
    public static string Title(IntPtr hWnd) {
        StringBuilder text = new StringBuilder(256);
        GetWindowText(hWnd, text, text.Capacity);
        return text.ToString();
    }
}
"@

$overlay = Join-Path $OverlayRoot 'GyeomPetOverlay.ps1'
$setter = Join-Path $OverlayRoot 'Set-GyeomPetState.ps1'
$statePath = Join-Path $OverlayRoot 'state.json'
$qaRoot = Join-Path $OverlayRoot 'qa'
$diagnosticsPath = Join-Path $qaRoot 'life-motion-runtime-diagnostics.json'
$observationPath = Join-Path $qaRoot 'life-motion-runtime-observation.json'
$contactSheetPath = Join-Path $qaRoot 'life-motion-runtime-contact-sheet.png'
$captureRoot = Join-Path ([IO.Path]::GetTempPath()) ('gyeom-life-audit-' + [Guid]::NewGuid().ToString('N'))

New-Item -ItemType Directory -Path $captureRoot -Force | Out-Null
$stateBackup = [IO.File]::ReadAllBytes($statePath)
$records = [Collections.Generic.List[object]]::new()
$process = $null
$startedAt = [DateTime]::UtcNow

try {
    $process = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', $overlay,
        '-AutoCloseAfterSeconds', [string]$DurationSeconds,
        '-DiagnosticsOut', $diagnosticsPath,
        '-OffsetX', '320'
    ) -WindowStyle Hidden -PassThru

    $handle = [IntPtr]::Zero
    $deadline = [DateTime]::UtcNow.AddSeconds(8)
    while ($handle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 100
        $handle = [GyeomLifeWindow]::FindForProcess([uint32]$process.Id)
    }
    if ($handle -eq [IntPtr]::Zero) {
        throw "Overlay window was not found for process $($process.Id)."
    }

    & $setter -State idle -PersonalityEnabled $true | Out-Null
    $sample = 0
    while (-not $process.HasExited) {
        Start-Sleep -Milliseconds $CaptureIntervalMs
        if ($process.HasExited) { break }
        $rect = New-Object GyeomLifeWindow+RECT
        if (-not [GyeomLifeWindow]::GetWindowRect($handle, [ref]$rect)) {
            $process.Refresh()
            $elapsedSeconds = ([DateTime]::UtcNow - $startedAt).TotalSeconds
            if ($process.HasExited -or $elapsedSeconds -ge ($DurationSeconds - 2)) { break }
            Start-Sleep -Milliseconds 100
            if (-not [GyeomLifeWindow]::GetWindowRect($handle, [ref]$rect)) {
                throw 'GetWindowRect failed while the overlay process was still running.'
            }
        }
        $width = $rect.Right - $rect.Left
        $height = $rect.Bottom - $rect.Top
        if ($width -le 0 -or $height -le 0) {
            throw "Invalid overlay size: ${width}x${height}"
        }
        $title = [GyeomLifeWindow]::Title($handle)
        $state = if ($title.StartsWith('Gyeom Pet Overlay')) { ($title -split ' ')[-1] } else { 'unknown' }
        $bitmap = New-Object Drawing.Bitmap($width, $height)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
            $name = 'capture-{0:D3}.png' -f $sample
            $path = Join-Path $captureRoot $name
            $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
            $records.Add([pscustomobject]@{
                sample = $sample
                elapsedMs = [math]::Round(([DateTime]::UtcNow - $startedAt).TotalMilliseconds)
                state = $state
                file = $path
                width = $width
                height = $height
            })
        }
        finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
        $sample += 1
    }

    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        throw "Overlay exited with code $($process.ExitCode)."
    }

    $grouped = @($records | Group-Object state)
    $selected = [Collections.Generic.List[object]]::new()
    foreach ($group in $grouped) {
        $items = @($group.Group)
        $indexes = @(0, [math]::Floor(($items.Count - 1) / 2), ($items.Count - 1)) | Select-Object -Unique
        foreach ($index in $indexes) { $selected.Add($items[[int]$index]) }
    }
    $selected = @($selected | Sort-Object elapsedMs)
    $tileWidth = [int](($records | Measure-Object width -Maximum).Maximum)
    $tileHeight = [int](($records | Measure-Object height -Maximum).Maximum)
    $columns = 4
    $labelHeight = 24
    $rows = [math]::Ceiling($selected.Count / $columns)
    $sheet = New-Object Drawing.Bitmap($tileWidth * $columns, ($tileHeight + $labelHeight) * $rows)
    $sheetGraphics = [Drawing.Graphics]::FromImage($sheet)
    try {
        $sheetGraphics.Clear([Drawing.Color]::FromArgb(34, 34, 34))
        $font = New-Object Drawing.Font('Segoe UI', 9)
        $brush = [Drawing.Brushes]::White
        for ($index = 0; $index -lt $selected.Count; $index += 1) {
            $item = $selected[$index]
            $column = $index % $columns
            $row = [math]::Floor($index / $columns)
            $x = $column * $tileWidth
            $y = $row * ($tileHeight + $labelHeight)
            $source = [Drawing.Image]::FromFile($item.file)
            try {
                $sheetGraphics.DrawString("$($item.state)  $([math]::Round($item.elapsedMs / 1000, 1))s", $font, $brush, $x + 4, $y + 3)
                $sheetGraphics.DrawImage($source, $x, $y + $labelHeight, $source.Width, $source.Height)
            }
            finally { $source.Dispose() }
        }
        $sheet.Save($contactSheetPath, [Drawing.Imaging.ImageFormat]::Png)
        $font.Dispose()
    }
    finally {
        $sheetGraphics.Dispose()
        $sheet.Dispose()
    }

    $diagnostics = Get-Content -LiteralPath $diagnosticsPath -Raw | ConvertFrom-Json
    $stateCounts = [ordered]@{}
    foreach ($group in $grouped) { $stateCounts[$group.Name] = $group.Count }
    $required = @('idle-breathe', 'idle-look', 'idle-stretch', 'idle-yawn', 'waving', 'review')
    $missing = @($required | Where-Object { -not $stateCounts.Contains($_) })
    $result = [ordered]@{
        ok = ($missing.Count -eq 0 -and $process.ExitCode -eq 0)
        durationSeconds = $DurationSeconds
        captureIntervalMs = $CaptureIntervalMs
        captureCount = $records.Count
        distinctStateCount = $stateCounts.Count
        stateCounts = $stateCounts
        requiredStates = $required
        missingRequiredStates = $missing
        diagnostics = $diagnostics
        contactSheet = $contactSheetPath
    }
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $observationPath -Encoding utf8
    $result | ConvertTo-Json -Depth 8
    if (-not $result.ok) { exit 1 }
}
finally {
    [IO.File]::WriteAllBytes($statePath, $stateBackup)
    if ($null -ne $process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
}
