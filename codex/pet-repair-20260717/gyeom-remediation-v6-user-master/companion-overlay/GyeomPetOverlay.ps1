[CmdletBinding()]
param(
    [double]$Scale = 1.15,
    [switch]$Demo,
    [int]$AutoCloseAfterSeconds = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    throw 'Run this overlay through Start-GyeomPetOverlay.cmd or PowerShell with the -STA option.'
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$cellWidth = 192
$cellHeight = 208
$root = $PSScriptRoot
$spritePath = Join-Path $root 'assets\\spritesheet.png'
$stateFile = Join-Path $root 'state.json'

if (-not (Test-Path -LiteralPath $spritePath)) {
    throw "Missing sprite sheet: $spritePath"
}
if ($Scale -lt 0.5 -or $Scale -gt 3) {
    throw 'Scale must be between 0.5 and 3.'
}

$states = @{
    'idle'          = [pscustomobject]@{ Row = 0; Frames = @(0..5); DurationMs = @(280, 110, 110, 140, 140, 320) }
    'running-right' = [pscustomobject]@{ Row = 1; Frames = @(0..7); DurationMs = @(120, 120, 120, 120, 120, 120, 120, 220) }
    'running-left'  = [pscustomobject]@{ Row = 2; Frames = @(0..7); DurationMs = @(120, 120, 120, 120, 120, 120, 120, 220) }
    'waving'        = [pscustomobject]@{ Row = 3; Frames = @(0..3); DurationMs = @(140, 140, 140, 280) }
    'jumping'       = [pscustomobject]@{ Row = 4; Frames = @(0..4); DurationMs = @(140, 140, 140, 140, 280) }
    'failed'        = [pscustomobject]@{ Row = 5; Frames = @(0..7); DurationMs = @(140, 140, 140, 140, 140, 140, 140, 240) }
    'waiting'       = [pscustomobject]@{ Row = 6; Frames = @(0..5); DurationMs = @(150, 150, 150, 150, 150, 260) }
    'running'       = [pscustomobject]@{ Row = 7; Frames = @(0..5); DurationMs = @(120, 120, 120, 120, 120, 220) }
    'review'        = [pscustomobject]@{ Row = 8; Frames = @(0..5); DurationMs = @(150, 150, 150, 150, 150, 280) }
}
$stateOrder = @('idle', 'running', 'waiting', 'review', 'waving', 'jumping', 'failed', 'running-right', 'running-left')
$demoOrder = @('idle', 'waving', 'jumping', 'running', 'review', 'waiting', 'failed', 'running-right', 'running-left')

$bitmap = New-Object Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.UriSource = [Uri]$spritePath
$bitmap.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$bitmap.EndInit()
$bitmap.Freeze()

$window = New-Object Windows.Window
$window.Title = 'Gyeom Pet Overlay'
$window.Width = [Math]::Round($cellWidth * $Scale)
$window.Height = [Math]::Round($cellHeight * $Scale)
$window.WindowStyle = [Windows.WindowStyle]::None
$window.ResizeMode = [Windows.ResizeMode]::NoResize
$window.AllowsTransparency = $true
$window.Background = [Windows.Media.Brushes]::Transparent
$window.Topmost = $true
$window.ShowInTaskbar = $false
$window.Focusable = $true

$workArea = [Windows.SystemParameters]::WorkArea
$window.Left = $workArea.Right - $window.Width - 24
$window.Top = $workArea.Bottom - $window.Height - 36

$image = New-Object Windows.Controls.Image
$image.Width = $window.Width
$image.Height = $window.Height
$image.Stretch = [Windows.Media.Stretch]::Fill
$image.SnapsToDevicePixels = $true
$image.UseLayoutRounding = $true
$image.ToolTip = '왼쪽 드래그: 이동 · 오른쪽 클릭: 행동 선택 · Esc: 종료'
$window.Content = $image

$script:currentState = 'idle'
$script:frameIndex = 0
$script:nextFrameAt = [DateTime]::UtcNow
$script:stateFileStamp = [DateTime]::MinValue
$script:externalExpiresAt = $null
$script:demoIndex = 0
$script:nextDemoAt = [DateTime]::UtcNow.AddSeconds(2)

function Show-Frame {
    $spec = $states[$script:currentState]
    $column = $spec.Frames[$script:frameIndex]
    $rect = New-Object Windows.Int32Rect -ArgumentList ($column * $cellWidth), ($spec.Row * $cellHeight), $cellWidth, $cellHeight
    $crop = New-Object Windows.Media.Imaging.CroppedBitmap -ArgumentList $bitmap, $rect
    $image.Source = $crop
    $window.Title = "Gyeom Pet Overlay — $($script:currentState)"
}

function Set-OverlayState {
    param([ValidateSet('idle', 'running-right', 'running-left', 'waving', 'jumping', 'failed', 'waiting', 'running', 'review')][string]$Name)

    $script:currentState = $Name
    $script:frameIndex = 0
    $script:nextFrameAt = [DateTime]::UtcNow.AddMilliseconds($states[$Name].DurationMs[0])
    Show-Frame
}

function Read-RequestedState {
    if (-not (Test-Path -LiteralPath $stateFile)) {
        return
    }

    try {
        $stamp = (Get-Item -LiteralPath $stateFile).LastWriteTimeUtc
        if ($stamp -gt $script:stateFileStamp) {
            $request = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
            $requestedState = [string]$request.state
            if ($states.ContainsKey($requestedState)) {
                Set-OverlayState $requestedState
                $script:stateFileStamp = $stamp
                $ttl = 0
                if ($null -ne $request.ttlMs) {
                    $ttl = [int]$request.ttlMs
                }
                $script:externalExpiresAt = if ($ttl -gt 0) { [DateTime]::UtcNow.AddMilliseconds($ttl) } else { $null }
            }
        }
    }
    catch {
        # A partially written state file is ignored; the next complete update is read normally.
    }

    if ($null -ne $script:externalExpiresAt -and [DateTime]::UtcNow -ge $script:externalExpiresAt) {
        $script:externalExpiresAt = $null
        Set-OverlayState 'idle'
    }
}

$menu = New-Object Windows.Controls.ContextMenu
foreach ($name in $stateOrder) {
    $item = New-Object Windows.Controls.MenuItem
    $item.Header = $name
    $item.Tag = $name
    $item.Add_Click({ param($sender, $eventArgs) Set-OverlayState ([string]$sender.Tag) })
    [void]$menu.Items.Add($item)
}
[void]$menu.Items.Add((New-Object Windows.Controls.Separator))
$demoItem = New-Object Windows.Controls.MenuItem
$demoItem.Header = '9개 동작 데모 시작'
$demoItem.Add_Click({
        $script:demoIndex = 0
        $script:nextDemoAt = [DateTime]::UtcNow
        Set-OverlayState $demoOrder[$script:demoIndex]
    })
[void]$menu.Items.Add($demoItem)
$closeItem = New-Object Windows.Controls.MenuItem
$closeItem.Header = '오버레이 닫기'
$closeItem.Add_Click({ $window.Close() })
[void]$menu.Items.Add($closeItem)
$image.ContextMenu = $menu

$window.Add_MouseLeftButtonDown({ param($sender, $eventArgs) $sender.DragMove() })
$window.Add_KeyDown({
        param($sender, $eventArgs)
        if ($eventArgs.Key -eq [Windows.Input.Key]::Escape) {
            $sender.Close()
        }
    })

$ticker = New-Object Windows.Threading.DispatcherTimer
$ticker.Interval = [TimeSpan]::FromMilliseconds(60)
$ticker.Add_Tick({
        Read-RequestedState
        $now = [DateTime]::UtcNow
        $spec = $states[$script:currentState]
        if ($now -ge $script:nextFrameAt) {
            $script:frameIndex = ($script:frameIndex + 1) % $spec.Frames.Count
            $script:nextFrameAt = $now.AddMilliseconds($spec.DurationMs[$script:frameIndex])
            Show-Frame
        }
        if ($Demo -and $now -ge $script:nextDemoAt) {
            $script:demoIndex = ($script:demoIndex + 1) % $demoOrder.Count
            Set-OverlayState $demoOrder[$script:demoIndex]
            $script:nextDemoAt = $now.AddSeconds(1.5)
        }
    })
$ticker.Start()

if ($AutoCloseAfterSeconds -gt 0) {
    $closer = New-Object Windows.Threading.DispatcherTimer
    $closer.Interval = [TimeSpan]::FromSeconds($AutoCloseAfterSeconds)
    $closer.Add_Tick({ $closer.Stop(); $window.Close() })
    $closer.Start()
}

Set-OverlayState 'idle'
if ($Demo) {
    $script:nextDemoAt = [DateTime]::UtcNow.AddSeconds(1)
}
[void]$window.ShowDialog()
