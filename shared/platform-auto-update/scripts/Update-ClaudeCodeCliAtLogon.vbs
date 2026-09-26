Option Explicit

' Claude Code CLI daily updater. 2026-09-27 신규.
'
' 왜 필요한가: Claude Code는 제품 내장 자동업데이트가 있지만, 그 동작은
' %USERPROFILE%\.claude.json 의 "autoUpdates" 값에 달려 있다. 이 값은 설치 방식 변경,
' 설정 마이그레이션, 사용자의 /config 조작으로 false 가 될 수 있고, 실제로 2026-09-27
' 확인 시 false 였다(2.1.281 → 2.1.283 두 판 뒤처져 있었다).
' 그래서 설정값에 의존하지 않는 바깥쪽 경로를 둔다: 예약 작업이 매일 `claude update` 를
' 직접 실행한다. 이 명령은 autoUpdates 값과 무관하게 최신판을 설치한다.
' 설정이 다시 false 로 바뀌어도 갱신은 멈추지 않으며, 알림에 그 사실을 함께 표시한다.

Const ForAppending = 8
Const MaxLogBytes = 1048576
Const StaleBinaryDays = 7

Dim shell, fileSystem, scriptDirectory, logDirectory, logPath
Dim claudeCommand, versionBefore, versionAfter, exitCode, autoUpdateFlag, summary
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
logDirectory = fileSystem.BuildPath(scriptDirectory, "logs")
logPath = fileSystem.BuildPath(logDirectory, "claude-code-cli-daily-updater.log")

If WScript.Arguments.Named.Exists("test") Then
    claudeCommand = ResolveClaude()
    WScript.Echo "claude resolved: " & claudeCommand
    WScript.Echo "claude version: " & ReadClaudeVersion(claudeCommand)
    WScript.Echo "in-app autoUpdates: " & ReadAutoUpdateFlag()
    WScript.Echo "stale .old binaries: " & CStr(CountStaleBinaries())
    If WScript.Arguments.Named.Exists("notify") Then
        Notify "Claude Code CLI auto-update", "Windows notification test sent."
    End If
    WScript.Quit 0
End If

RotateLog
WriteLog "Daily update check started."

claudeCommand = ResolveClaude()
If claudeCommand = "" Then
    WriteLog "Skipped: claude.exe was not found in .local\bin, PATH, or APPDATA\npm."
    Notify "Claude Code CLI auto-update", "Skipped: claude.exe was not found."
    WScript.Quit 0
End If

autoUpdateFlag = ReadAutoUpdateFlag()
versionBefore = ReadClaudeVersion(claudeCommand)
exitCode = shell.Run("cmd.exe /c " & Chr(34) & Chr(34) & claudeCommand & Chr(34) & " update" & Chr(34), 0, True)
versionAfter = ReadClaudeVersion(claudeCommand)

If exitCode <> 0 Then
    summary = "failed (" & CStr(exitCode) & "), still " & versionBefore
ElseIf versionBefore = versionAfter Then
    summary = "latest (" & versionAfter & ")"
Else
    summary = "updated " & versionBefore & " -> " & versionAfter
End If

' 내장 자동업데이트가 꺼져 있었는데 버전이 올라갔다면, 이 예약 작업이 공백을 메운 것이다.
If autoUpdateFlag = "false" Then
    summary = summary & "; in-app autoUpdates=false, covered by schedule"
End If

WriteLog "autoUpdates=" & autoUpdateFlag & ", exit=" & CStr(exitCode) & ", " & versionBefore & " -> " & versionAfter
WriteLog "Stale .old binaries left by the installer: " & CStr(CountStaleBinaries()) & " (older than " & CStr(StaleBinaryDays) & " days; run with /prune to delete)."

If WScript.Arguments.Named.Exists("prune") Then
    WriteLog "Pruned stale binaries: " & CStr(PruneStaleBinaries())
End If

Notify "Claude Code CLI auto-update", summary
WriteLog "Daily update check finished."

Function ResolveClaude()
    Dim candidate

    candidate = shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\.local\bin\claude.exe"
    If fileSystem.FileExists(candidate) Then
        ResolveClaude = candidate
        Exit Function
    End If

    candidate = Trim(CaptureOutput("where claude"))
    If candidate <> "" Then
        candidate = Trim(Split(Replace(candidate, vbCr, vbLf), vbLf)(0))
        If fileSystem.FileExists(candidate) Then
            ResolveClaude = candidate
            Exit Function
        End If
    End If

    candidate = shell.ExpandEnvironmentStrings("%APPDATA%") & "\npm\claude.cmd"
    If fileSystem.FileExists(candidate) Then
        ResolveClaude = candidate
        Exit Function
    End If

    ResolveClaude = ""
End Function

' `claude --version` 은 "2.1.283 (Claude Code)" 형태로 답한다. 첫 토큰만 쓴다.
Function ReadClaudeVersion(claudePath)
    Dim output

    If claudePath = "" Then
        ReadClaudeVersion = "unknown"
        Exit Function
    End If

    output = Trim(CaptureOutput(Chr(34) & claudePath & Chr(34) & " --version"))
    If output = "" Then
        ReadClaudeVersion = "unknown"
        Exit Function
    End If

    output = Trim(Split(Replace(output, vbCr, vbLf), vbLf)(0))
    ReadClaudeVersion = Trim(Split(output & " ", " ")(0))
End Function

' .claude.json 은 100KB를 넘으므로 전체를 읽지 않고 findstr 로 해당 줄만 본다.
Function ReadAutoUpdateFlag()
    Dim configPath, output

    configPath = shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\.claude.json"
    If Not fileSystem.FileExists(configPath) Then
        ReadAutoUpdateFlag = "unknown"
        Exit Function
    End If

    output = CaptureOutput("findstr /C:" & Chr(34) & Chr(34) & Chr(34) & "autoUpdates" & Chr(34) & Chr(34) & Chr(34) & " " & Chr(34) & configPath & Chr(34))
    If InStr(output, "false") > 0 Then
        ReadAutoUpdateFlag = "false"
    ElseIf InStr(output, "true") > 0 Then
        ReadAutoUpdateFlag = "true"
    Else
        ReadAutoUpdateFlag = "unknown"
    End If
End Function

' 설치기가 남기는 claude.exe.old.* 는 한 개당 약 230MB다. 기본은 세지기만 한다.
Function CountStaleBinaries()
    Dim folderPath, folder, file, count

    count = 0
    folderPath = shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\.local\bin"
    If Not fileSystem.FolderExists(folderPath) Then
        CountStaleBinaries = 0
        Exit Function
    End If

    Set folder = fileSystem.GetFolder(folderPath)
    For Each file In folder.Files
        If InStr(file.Name, "claude.exe.old.") = 1 Then
            If DateDiff("d", file.DateLastModified, Now) >= StaleBinaryDays Then
                count = count + 1
            End If
        End If
    Next

    CountStaleBinaries = count
End Function

Function PruneStaleBinaries()
    Dim folderPath, folder, file, removed

    removed = 0
    folderPath = shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\.local\bin"
    If Not fileSystem.FolderExists(folderPath) Then
        PruneStaleBinaries = 0
        Exit Function
    End If

    Set folder = fileSystem.GetFolder(folderPath)
    For Each file In folder.Files
        If InStr(file.Name, "claude.exe.old.") = 1 Then
            If DateDiff("d", file.DateLastModified, Now) >= StaleBinaryDays Then
                On Error Resume Next
                file.Delete True
                If Err.Number = 0 Then
                    removed = removed + 1
                Else
                    Err.Clear
                End If
                On Error GoTo 0
            End If
        End If
    Next

    PruneStaleBinaries = removed
End Function

Function CaptureOutput(command)
    Dim exec, output

    On Error Resume Next
    Set exec = shell.Exec("cmd.exe /c " & command & " 2>&1")
    If Err.Number <> 0 Then
        CaptureOutput = ""
        Err.Clear
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0

    Do While exec.Status = 0
        WScript.Sleep 200
    Loop

    output = exec.StdOut.ReadAll()
    CaptureOutput = output
End Function

Sub Notify(title, message)
    Dim safeTitle, safeMessage, toastScript, command

    safeTitle = Replace(title, "'", "''")
    safeMessage = Replace(message, "'", "''")
    toastScript = "Add-Type -AssemblyName System.Runtime.WindowsRuntime; " & _
        "[Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime] | Out-Null; " & _
        "$xml=[Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02); " & _
        "$text=$xml.GetElementsByTagName('text'); " & _
        "[void]$text.Item(0).AppendChild($xml.CreateTextNode('" & safeTitle & "')); " & _
        "[void]$text.Item(1).AppendChild($xml.CreateTextNode('" & safeMessage & "')); " & _
        "$toast=[Windows.UI.Notifications.ToastNotification]::new($xml); " & _
        "[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('WindowsPowerShell').Show($toast)"
    command = "powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -Command " & Chr(34) & toastScript & Chr(34)
    shell.Run command, 0, False
End Sub

Sub RotateLog()
    Dim rotatedPath

    If Not fileSystem.FileExists(logPath) Then
        Exit Sub
    End If

    If fileSystem.GetFile(logPath).Size <= MaxLogBytes Then
        Exit Sub
    End If

    rotatedPath = logPath & ".1"
    If fileSystem.FileExists(rotatedPath) Then
        fileSystem.DeleteFile rotatedPath, True
    End If
    fileSystem.MoveFile logPath, rotatedPath
End Sub

Sub WriteLog(message)
    Dim logFile

    If Not fileSystem.FolderExists(logDirectory) Then
        fileSystem.CreateFolder(logDirectory)
    End If

    Set logFile = fileSystem.OpenTextFile(logPath, ForAppending, True)
    logFile.WriteLine "[" & Year(Now) & "-" & Right("0" & Month(Now), 2) & "-" & Right("0" & Day(Now), 2) & " " & Time & "] " & message
    logFile.Close
End Sub
