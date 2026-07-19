Option Explicit

Const ForAppending = 8

Dim shell, fileSystem, scriptDirectory, logDirectory, logPath, ideResult, antigravityResult, cliResult
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
logDirectory = fileSystem.BuildPath(scriptDirectory, "logs")
logPath = fileSystem.BuildPath(logDirectory, "antigravity-logon-updater.log")

If WScript.Arguments.Named.Exists("test") Then
    WScript.Echo "Update order: Antigravity IDE -> Antigravity 2.0 -> Antigravity CLI"
    If WScript.Arguments.Named.Exists("notify") Then
        Notify "Antigravity auto-update", "Windows notification test sent."
    End If
    WScript.Quit 0
End If

' 로그온 직후 Windows 시작 프로세스와의 CPU·디스크 경합을 피한다 (10분 지연).
' Codex 업데이터(5분 지연)가 끝난 뒤에 시작되도록 시차를 둔다.
WScript.Sleep 600000

WriteLog "Logon update sequence started."
ideResult = UpdatePackage("Google.AntigravityIDE", "Antigravity IDE")
antigravityResult = UpdatePackage("Google.Antigravity", "Antigravity 2.0")
cliResult = UpdateCli()
WriteLog "Logon update sequence finished."
Notify "Antigravity auto-update", "IDE: " & ideResult & " | 2.0: " & antigravityResult & " | CLI: " & cliResult

Function UpdatePackage(packageId, displayName)
    Dim command, exitCode

    command = "winget.exe upgrade --id " & packageId & " --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements"
    WriteLog "Checking " & displayName & "."
    exitCode = shell.Run(command, 0, True)

    If exitCode = 0 Then
        WriteLog displayName & " update check completed successfully."
        UpdatePackage = "completed"
    ElseIf exitCode = -1978335189 Then
        WriteLog displayName & " is already up to date."
        UpdatePackage = "latest"
    Else
        WriteLog displayName & " update check failed with exit code " & CStr(exitCode) & "."
        UpdatePackage = "failed (" & CStr(exitCode) & ")"
    End If
End Function

Function UpdateCli()
    Dim cliCommand, exitCode
    cliCommand = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\agy\bin\agy.exe"

    If Not fileSystem.FileExists(cliCommand) Then
        WriteLog "Antigravity CLI was not found; skipped its update check."
        UpdateCli = "skipped"
        Exit Function
    End If

    WriteLog "Checking Antigravity CLI."
    exitCode = shell.Run(Chr(34) & cliCommand & Chr(34) & " update", 0, True)

    If exitCode = 0 Then
        WriteLog "Antigravity CLI update check completed successfully."
        UpdateCli = "completed"
    Else
        WriteLog "Antigravity CLI update check failed with exit code " & CStr(exitCode) & "."
        UpdateCli = "failed (" & CStr(exitCode) & ")"
    End If
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

Sub WriteLog(message)
    Dim logFile

    If Not fileSystem.FolderExists(logDirectory) Then
        fileSystem.CreateFolder(logDirectory)
    End If

    Set logFile = fileSystem.OpenTextFile(logPath, ForAppending, True)
    logFile.WriteLine "[" & Year(Now) & "-" & Right("0" & Month(Now), 2) & "-" & Right("0" & Day(Now), 2) & " " & Time & "] " & message
    logFile.Close
End Sub
