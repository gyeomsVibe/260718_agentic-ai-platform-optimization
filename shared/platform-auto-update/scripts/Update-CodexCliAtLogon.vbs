Option Explicit

' Codex CLI daily updater.
' 2026-09-27 개선: npm 경로 탐색 3단계, 업데이트 전후 버전 비교, 로그 회전(1MB).
' 이전 판은 npm.cmd가 %ProgramFiles%\nodejs 에 없으면 조용히 건너뛰고,
' 버전이 바뀌었는지와 무관하게 "completed successfully"만 알렸다.

Const ForAppending = 8
Const ForReading = 1
Const MaxLogBytes = 1048576

Dim shell, fileSystem, scriptDirectory, logDirectory, logPath, npmCacheDirectory, processEnvironment
Dim npmCommand, versionBefore, versionAfter, updateResult
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
logDirectory = fileSystem.BuildPath(scriptDirectory, "logs")
logPath = fileSystem.BuildPath(logDirectory, "codex-cli-logon-updater.log")
npmCacheDirectory = fileSystem.BuildPath(scriptDirectory, "npm-cache")

If WScript.Arguments.Named.Exists("test") Then
    npmCommand = ResolveNpm()
    WScript.Echo "npm.cmd resolved: " & npmCommand
    WScript.Echo "codex version: " & ReadCodexVersion(npmCommand)
    If WScript.Arguments.Named.Exists("notify") Then
        Notify "Codex CLI auto-update", "Windows notification test sent."
    End If
    WScript.Quit 0
End If

If Not fileSystem.FolderExists(npmCacheDirectory) Then
    fileSystem.CreateFolder(npmCacheDirectory)
End If

Set processEnvironment = shell.Environment("Process")
processEnvironment("npm_config_cache") = npmCacheDirectory

RotateLog
WriteLog "Daily update check started."

npmCommand = ResolveNpm()
If npmCommand = "" Then
    WriteLog "Skipped: npm.cmd was not found in Program Files, PATH, or APPDATA."
    Notify "Codex CLI auto-update", "Skipped: npm.cmd was not found."
    WScript.Quit 0
End If

versionBefore = ReadCodexVersion(npmCommand)
updateResult = RunUpdate(npmCommand)

If updateResult = 0 Then
    versionAfter = ReadCodexVersion(npmCommand)
    If versionBefore = versionAfter Then
        WriteLog "Latest already installed: " & versionAfter
        Notify "Codex CLI auto-update", "latest (" & versionAfter & ")"
    Else
        WriteLog "Updated: " & versionBefore & " -> " & versionAfter
        Notify "Codex CLI auto-update", "updated " & versionBefore & " -> " & versionAfter
    End If
Else
    WriteLog "Update failed with exit code " & CStr(updateResult) & ". Installed version stays " & versionBefore & "."
    Notify "Codex CLI auto-update", "failed (" & CStr(updateResult) & "), still " & versionBefore
End If

WriteLog "Daily update check finished."

' npm.cmd 를 세 곳에서 찾는다. 이전 판은 첫 번째만 보고 없으면 건너뛰었다.
Function ResolveNpm()
    Dim candidate

    candidate = shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\nodejs\npm.cmd"
    If fileSystem.FileExists(candidate) Then
        ResolveNpm = candidate
        Exit Function
    End If

    candidate = Trim(CaptureOutput("where npm.cmd"))
    If candidate <> "" Then
        candidate = Split(candidate, vbCrLf)(0)
        If fileSystem.FileExists(candidate) Then
            ResolveNpm = candidate
            Exit Function
        End If
    End If

    candidate = shell.ExpandEnvironmentStrings("%APPDATA%") & "\npm\npm.cmd"
    If fileSystem.FileExists(candidate) Then
        ResolveNpm = candidate
        Exit Function
    End If

    ResolveNpm = ""
End Function

Function RunUpdate(npmPath)
    RunUpdate = shell.Run(Chr(34) & npmPath & Chr(34) & " install -g @openai/codex@latest --no-audit --no-fund", 0, True)
End Function

' 설치된 버전을 읽는다. 실패하면 unknown 을 돌려주고 흐름은 멈추지 않는다.
Function ReadCodexVersion(npmPath)
    Dim output, marker, position, rest

    If npmPath = "" Then
        ReadCodexVersion = "unknown"
        Exit Function
    End If

    output = CaptureOutput(Chr(34) & npmPath & Chr(34) & " ls -g --depth=0 @openai/codex")
    marker = "@openai/codex@"
    position = InStr(output, marker)
    If position = 0 Then
        ReadCodexVersion = "not installed"
        Exit Function
    End If

    rest = Mid(output, position + Len(marker))
    rest = Split(Replace(Replace(rest, vbCr, vbLf), vbTab, vbLf), vbLf)(0)
    ReadCodexVersion = Trim(Split(rest & " ", " ")(0))
End Function

' 콘솔 창 없이 표준 출력을 읽는다.
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

' 로그가 1MB를 넘으면 .1 로 한 번만 밀어낸다. 무한 증가를 막는다.
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
