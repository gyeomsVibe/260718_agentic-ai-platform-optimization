Option Explicit

Const ForAppending = 8

Dim shell, fileSystem, scriptDirectory, logDirectory, logPath, npmCacheDirectory, processEnvironment, updateResult
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
logDirectory = fileSystem.BuildPath(scriptDirectory, "logs")
logPath = fileSystem.BuildPath(logDirectory, "codex-cli-logon-updater.log")
npmCacheDirectory = fileSystem.BuildPath(scriptDirectory, "npm-cache")

If WScript.Arguments.Named.Exists("test") Then
    WScript.Echo "npm.cmd found: " & CStr(fileSystem.FileExists(shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\nodejs\npm.cmd"))
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

WriteLog "Logon update check started."
updateResult = UpdateCodexCli()
WriteLog "Logon update check finished."
Notify "Codex CLI auto-update", updateResult

Function UpdateCodexCli()
    Dim npmCommand, exitCode
    npmCommand = shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\nodejs\npm.cmd"

    If Not fileSystem.FileExists(npmCommand) Then
        WriteLog "Skipped: npm.cmd was not found in the Node.js installation directory."
        UpdateCodexCli = "Skipped: npm.cmd was not found."
        Exit Function
    End If

    exitCode = shell.Run(Chr(34) & npmCommand & Chr(34) & " install -g @openai/codex@latest --no-audit --no-fund", 0, True)

    If exitCode = 0 Then
        WriteLog "CLI update check completed successfully."
        UpdateCodexCli = "Update check completed successfully."
    Else
        WriteLog "CLI update check failed with exit code " & CStr(exitCode) & "."
        UpdateCodexCli = "Update check failed (code " & CStr(exitCode) & ")."
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
