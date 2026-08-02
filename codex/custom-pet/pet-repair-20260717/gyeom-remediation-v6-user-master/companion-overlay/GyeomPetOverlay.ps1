[CmdletBinding()]
param(
    [double]$Scale = 1.15,
    [switch]$Demo,
    [int]$AutoCloseAfterSeconds = 0,
    [string]$DiagnosticsOut
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    throw 'Run this overlay through Start-GyeomPetOverlay.cmd or PowerShell with the -STA option.'
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$cellWidth = 192
$cellHeight = 208
$motionTempo = 1.60
$root = $PSScriptRoot
$normalizedSpritePath = Join-Path $root 'assets\\spritesheet-normalized.png'
$spritePath = if (Test-Path -LiteralPath $normalizedSpritePath) { $normalizedSpritePath } else { Join-Path $root 'assets\\spritesheet.png' }
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
$script:personalityEnabled = $true
$script:personalityIndex = 0
$script:nextPersonalityAt = [DateTime]::UtcNow.AddSeconds(8)
$script:personalityExpiresAt = $null
$script:personalityPlan = @(
    [pscustomobject]@{ State = 'waiting'; HoldMs = 4400; NextDelaySeconds = 22; Label = 'waiting' },
    [pscustomobject]@{ State = 'review';  HoldMs = 4800; NextDelaySeconds = 40; Label = 'reviewing' },
    [pscustomobject]@{ State = 'waving';  HoldMs = 4000; NextDelaySeconds = 68; Label = 'waving' }
)
$script:personalityEvents = [System.Collections.Generic.List[object]]::new()

function Add-PersonalityEvent {
    param([string]$Kind, [string]$State)

    $script:personalityEvents.Add([ordered]@{
            atUtc = [DateTime]::UtcNow.ToString('o')
            kind = $Kind
            state = $State
        })
}

function Write-Diagnostics {
    if ([string]::IsNullOrWhiteSpace($DiagnosticsOut)) {
        return
    }

    $directory = Split-Path -Parent $DiagnosticsOut
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        [IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    $payload = [ordered]@{
        finishedAtUtc = [DateTime]::UtcNow.ToString('o')
        personalityEnabled = $script:personalityEnabled
        currentState = $script:currentState
        eventCount = $script:personalityEvents.Count
        events = @($script:personalityEvents)
    }
    [IO.File]::WriteAllText($DiagnosticsOut, ($payload | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
}

function Show-Frame {
    $spec = $states[$script:currentState]
    $column = $spec.Frames[$script:frameIndex]
    $rect = New-Object Windows.Int32Rect -ArgumentList ($column * $cellWidth), ($spec.Row * $cellHeight), $cellWidth, $cellHeight
    $crop = New-Object Windows.Media.Imaging.CroppedBitmap -ArgumentList $bitmap, $rect
    $image.Source = $crop
    $window.Title = "Gyeom Pet Overlay — $($script:currentState)"
}

function Get-FrameDurationMs {
    param(
        [Parameter(Mandatory)][string]$State,
        [Parameter(Mandatory)][int]$Index
    )

    return [Math]::Round($states[$State].DurationMs[$Index] * $motionTempo)
}

function Set-OverlayState {
    param([ValidateSet('idle', 'running-right', 'running-left', 'waving', 'jumping', 'failed', 'waiting', 'running', 'review')][string]$Name)

    $script:currentState = $Name
    $script:frameIndex = 0
    $script:nextFrameAt = [DateTime]::UtcNow.AddMilliseconds((Get-FrameDurationMs -State $Name -Index 0))
    Show-Frame
}

function Schedule-PersonalityAction {
    param([DateTime]$Now)

    if (-not $script:personalityEnabled -or $null -ne $script:externalExpiresAt -or $Demo) {
        return
    }

    if ($null -ne $script:personalityExpiresAt -and $Now -ge $script:personalityExpiresAt) {
        $script:personalityExpiresAt = $null
        Set-OverlayState 'idle'
        Add-PersonalityEvent 'return-to-idle' 'idle'
        return
    }

    if ($script:currentState -eq 'idle' -and $Now -ge $script:nextPersonalityAt) {
        $step = $script:personalityPlan[$script:personalityIndex]
        $script:personalityIndex = ($script:personalityIndex + 1) % $script:personalityPlan.Count
        Set-OverlayState $step.State
        $script:personalityExpiresAt = $Now.AddMilliseconds($step.HoldMs)
        $script:nextPersonalityAt = $Now.AddSeconds($step.NextDelaySeconds)
        Add-PersonalityEvent 'personality-action' $step.State
    }
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
                $personalityProperty = $request.PSObject.Properties['personalityEnabled']
                if ($null -ne $personalityProperty) {
                    $script:personalityEnabled = [bool]$personalityProperty.Value
                    if (-not $script:personalityEnabled) {
                        $script:personalityExpiresAt = $null
                    }
                }
                Add-PersonalityEvent 'external-state' $requestedState
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
$personalityItem = New-Object Windows.Controls.MenuItem
$personalityItem.Header = 'Toggle personality loop'
$personalityItem.Add_Click({
        $script:personalityEnabled = -not $script:personalityEnabled
        $script:personalityExpiresAt = $null
        if ($script:currentState -ne 'idle' -and $null -eq $script:externalExpiresAt) {
            Set-OverlayState 'idle'
        }
        Add-PersonalityEvent 'personality-toggle' (if ($script:personalityEnabled) { 'enabled' } else { 'disabled' })
    })
[void]$menu.Items.Add($personalityItem)
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
            $script:nextFrameAt = $now.AddMilliseconds((Get-FrameDurationMs -State $script:currentState -Index $script:frameIndex))
            Show-Frame
        }
        if ($Demo -and $now -ge $script:nextDemoAt) {
            $script:demoIndex = ($script:demoIndex + 1) % $demoOrder.Count
            Set-OverlayState $demoOrder[$script:demoIndex]
            $script:nextDemoAt = $now.AddSeconds(1.5)
        }
        Schedule-PersonalityAction $now
    })
$ticker.Start()

if ($AutoCloseAfterSeconds -gt 0) {
    $closer = New-Object Windows.Threading.DispatcherTimer
    $closer.Interval = [TimeSpan]::FromSeconds($AutoCloseAfterSeconds)
    $closer.Add_Tick({ $closer.Stop(); Write-Diagnostics; $window.Close() })
    $closer.Start()
}

Set-OverlayState 'idle'
if ($Demo) {
    $script:nextDemoAt = [DateTime]::UtcNow.AddSeconds(1)
}
[void]$window.ShowDialog()
Write-Diagnostics
