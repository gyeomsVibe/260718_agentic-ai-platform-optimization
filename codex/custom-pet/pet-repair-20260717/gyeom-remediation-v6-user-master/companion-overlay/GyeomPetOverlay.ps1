[CmdletBinding()]
param(
    [double]$Scale = 1.15,
    [switch]$Demo,
    [int]$AutoCloseAfterSeconds = 0,
    [string]$DiagnosticsOut,
    [int]$OffsetX = 0,
    [int]$OffsetY = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    throw 'Run this overlay through Start-GyeomPetOverlay.cmd or PowerShell with the -STA option.'
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$cellWidth = 192
$cellHeight = 208
$lifeCellHeight = 256
$root = $PSScriptRoot
$normalizedSpritePath = Join-Path $root 'assets\\spritesheet-normalized.png'
$spritePath = if (Test-Path -LiteralPath $normalizedSpritePath) { $normalizedSpritePath } else { Join-Path $root 'assets\\spritesheet.png' }
$lifeSpritePath = Join-Path $root 'assets\\life-motions.png'
$stateFile = Join-Path $root 'state.json'

if (-not (Test-Path -LiteralPath $spritePath)) {
    throw "Missing sprite sheet: $spritePath"
}
if ($Scale -lt 0.5 -or $Scale -gt 3) {
    throw 'Scale must be between 0.5 and 3.'
}
if ($OffsetX -lt 0 -or $OffsetY -lt 0) {
    throw 'OffsetX and OffsetY cannot be negative.'
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
$states.Values | ForEach-Object {
    $_ | Add-Member -NotePropertyName Sheet -NotePropertyValue 'core'
    $_ | Add-Member -NotePropertyName CellWidth -NotePropertyValue $cellWidth
    $_ | Add-Member -NotePropertyName CellHeight -NotePropertyValue $cellHeight
    $_ | Add-Member -NotePropertyName Tempo -NotePropertyValue 1.60
    $_ | Add-Member -NotePropertyName OneShot -NotePropertyValue $false
}

$lifeEnabled = Test-Path -LiteralPath $lifeSpritePath
if ($lifeEnabled) {
    $states['idle-breathe'] = [pscustomobject]@{ Sheet = 'life'; Row = 0; CellWidth = $cellWidth; CellHeight = $lifeCellHeight; Frames = @(0..7); DurationMs = @(240, 240, 100, 120, 120, 240, 260, 320); Tempo = 1.0; OneShot = $false }
    $states['idle-yawn'] = [pscustomobject]@{ Sheet = 'life'; Row = 1; CellWidth = $cellWidth; CellHeight = $lifeCellHeight; Frames = @(0..5); DurationMs = @(220, 220, 260, 420, 260, 320); Tempo = 1.0; OneShot = $true }
    $states['idle-stretch'] = [pscustomobject]@{ Sheet = 'life'; Row = 2; CellWidth = $cellWidth; CellHeight = $lifeCellHeight; Frames = @(0..7); DurationMs = @(200, 190, 190, 240, 420, 240, 200, 300); Tempo = 1.0; OneShot = $true }
    $states['idle-look'] = [pscustomobject]@{ Sheet = 'life'; Row = 3; CellWidth = $cellWidth; CellHeight = $lifeCellHeight; Frames = @(0..7); DurationMs = @(220, 260, 320, 220, 260, 320, 220, 300); Tempo = 1.0; OneShot = $true }
}
$defaultIdleState = if ($lifeEnabled) { 'idle-breathe' } else { 'idle' }
$stateOrder = if ($lifeEnabled) { @('idle', 'idle-look', 'idle-stretch', 'idle-yawn', 'waving', 'running', 'waiting', 'review', 'jumping', 'failed', 'running-right', 'running-left') } else { @('idle', 'running', 'waiting', 'review', 'waving', 'jumping', 'failed', 'running-right', 'running-left') }
$demoOrder = if ($lifeEnabled) { @('idle', 'idle-look', 'idle-stretch', 'idle-yawn', 'waving', 'jumping', 'running', 'review', 'waiting', 'failed', 'running-right', 'running-left') } else { @('idle', 'waving', 'jumping', 'running', 'review', 'waiting', 'failed', 'running-right', 'running-left') }

function Import-SpriteBitmap {
    param([Parameter(Mandatory)][string]$Path)

    $loaded = New-Object Windows.Media.Imaging.BitmapImage
    $loaded.BeginInit()
    $loaded.UriSource = [Uri]$Path
    $loaded.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $loaded.EndInit()
    $loaded.Freeze()
    return $loaded
}

$bitmaps = @{ core = Import-SpriteBitmap -Path $spritePath }
if ($lifeEnabled) {
    $bitmaps['life'] = Import-SpriteBitmap -Path $lifeSpritePath
}

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
$windowBottom = $workArea.Bottom - 36 - $OffsetY
$window.Left = $workArea.Right - $window.Width - 24 - $OffsetX
$window.Top = $windowBottom - $window.Height

$image = New-Object Windows.Controls.Image
$image.Width = $window.Width
$image.Height = $window.Height
$image.Stretch = [Windows.Media.Stretch]::Fill
$image.SnapsToDevicePixels = $true
$image.UseLayoutRounding = $true
$image.ToolTip = '왼쪽 드래그: 이동 · 오른쪽 클릭: 행동 선택 · Esc: 종료'
$window.Content = $image

$script:currentState = $defaultIdleState
$script:frameIndex = 0
$script:nextFrameAt = [DateTime]::UtcNow
$script:stateFileStamp = [DateTime]::MinValue
$script:externalExpiresAt = $null
$script:demoIndex = 0
$script:nextDemoAt = [DateTime]::UtcNow.AddSeconds(2)
$script:personalityEnabled = $true
$script:personalityIndex = 0
$script:nextPersonalityAt = [DateTime]::UtcNow.AddSeconds(4)
$script:personalityExpiresAt = $null
$script:personalityPlan = if ($lifeEnabled) {
    @(
        [pscustomobject]@{ State = 'idle-look'; HoldMs = 0; NextDelaySeconds = 7; Label = 'looking-around' },
        [pscustomobject]@{ State = 'idle-stretch'; HoldMs = 0; NextDelaySeconds = 9; Label = 'stretching' },
        [pscustomobject]@{ State = 'idle-yawn'; HoldMs = 0; NextDelaySeconds = 12; Label = 'yawning' },
        [pscustomobject]@{ State = 'waving'; HoldMs = 2600; NextDelaySeconds = 14; Label = 'waving' },
        [pscustomobject]@{ State = 'review'; HoldMs = 3200; NextDelaySeconds = 16; Label = 'reviewing' },
        [pscustomobject]@{ State = 'waiting'; HoldMs = 3000; NextDelaySeconds = 18; Label = 'waiting' }
    )
}
else {
    @(
        [pscustomobject]@{ State = 'waiting'; HoldMs = 4400; NextDelaySeconds = 22; Label = 'waiting' },
        [pscustomobject]@{ State = 'review'; HoldMs = 4800; NextDelaySeconds = 40; Label = 'reviewing' },
        [pscustomobject]@{ State = 'waving'; HoldMs = 4000; NextDelaySeconds = 68; Label = 'waving' }
    )
}
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
        lifeMotionsEnabled = $lifeEnabled
        defaultIdleState = $defaultIdleState
        currentState = $script:currentState
        eventCount = $script:personalityEvents.Count
        events = @($script:personalityEvents)
    }
    [IO.File]::WriteAllText($DiagnosticsOut, ($payload | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
}

function Show-Frame {
    $spec = $states[$script:currentState]
    $column = $spec.Frames[$script:frameIndex]
    $frameWidth = [int]$spec.CellWidth
    $frameHeight = [int]$spec.CellHeight
    $targetWidth = [Math]::Round($frameWidth * $Scale)
    $targetHeight = [Math]::Round($frameHeight * $Scale)
    if ($window.Width -ne $targetWidth -or $window.Height -ne $targetHeight) {
        $window.Width = $targetWidth
        $window.Height = $targetHeight
        $image.Width = $targetWidth
        $image.Height = $targetHeight
        $window.Left = $workArea.Right - $window.Width - 24 - $OffsetX
        $window.Top = $windowBottom - $window.Height
    }
    $rect = New-Object Windows.Int32Rect -ArgumentList ($column * $frameWidth), ($spec.Row * $frameHeight), $frameWidth, $frameHeight
    $crop = New-Object Windows.Media.Imaging.CroppedBitmap -ArgumentList $bitmaps[$spec.Sheet], $rect
    $image.Source = $crop
    $window.Title = "Gyeom Pet Overlay — $($script:currentState)"
}

function Get-FrameDurationMs {
    param(
        [Parameter(Mandatory)][string]$State,
        [Parameter(Mandatory)][int]$Index
    )

    return [Math]::Round($states[$State].DurationMs[$Index] * $states[$State].Tempo)
}

function Set-OverlayState {
    param([Parameter(Mandatory)][string]$Name)

    $resolvedName = if ($Name -eq 'idle') { $defaultIdleState } else { $Name }
    if (-not $states.ContainsKey($resolvedName)) {
        throw "Unknown Companion state: $Name"
    }

    $script:currentState = $resolvedName
    $script:frameIndex = 0
    $script:nextFrameAt = [DateTime]::UtcNow.AddMilliseconds((Get-FrameDurationMs -State $resolvedName -Index 0))
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
        Add-PersonalityEvent 'return-to-idle' $defaultIdleState
        return
    }

    if ($script:currentState -eq $defaultIdleState -and $Now -ge $script:nextPersonalityAt) {
        $step = $script:personalityPlan[$script:personalityIndex]
        $script:personalityIndex = ($script:personalityIndex + 1) % $script:personalityPlan.Count
        Set-OverlayState $step.State
        $script:personalityExpiresAt = if ($step.HoldMs -gt 0) { $Now.AddMilliseconds($step.HoldMs) } else { $null }
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
            if ($requestedState -eq 'idle' -or $states.ContainsKey($requestedState)) {
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
$demoItem.Header = if ($lifeEnabled) { '전체 생활·업무 동작 데모 시작' } else { '9개 동작 데모 시작' }
$demoItem.Add_Click({
        $script:demoIndex = 0
        $script:nextDemoAt = [DateTime]::UtcNow
        Set-OverlayState $demoOrder[$script:demoIndex]
    })
[void]$menu.Items.Add($demoItem)
$personalityItem = New-Object Windows.Controls.MenuItem
$personalityItem.Header = '생활 동작 자동 재생 켜기/끄기'
$personalityItem.Add_Click({
        $script:personalityEnabled = -not $script:personalityEnabled
        $script:personalityExpiresAt = $null
        if ($script:currentState -ne $defaultIdleState -and $null -eq $script:externalExpiresAt) {
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
            if ($spec.OneShot -and $script:frameIndex -ge ($spec.Frames.Count - 1)) {
                $finishedState = $script:currentState
                Set-OverlayState 'idle'
                Add-PersonalityEvent 'clip-complete' $finishedState
            }
            else {
                $script:frameIndex = ($script:frameIndex + 1) % $spec.Frames.Count
                $script:nextFrameAt = $now.AddMilliseconds((Get-FrameDurationMs -State $script:currentState -Index $script:frameIndex))
                Show-Frame
            }
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
