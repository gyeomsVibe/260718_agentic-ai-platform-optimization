Option Explicit

Const ForAppending = 8
' winget APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE (0x8A15002B).
' WScript.Shell.Run and Task Scheduler can expose the same HRESULT with
' different signs, so accept both numeric representations.
Const NoApplicableUpdateExitCodeUnsigned = 2316632107
Const NoApplicableUpdateExitCodeSigned = -1978335189

Dim shell, fileSystem, scriptDirectory, logDirectory, logPath
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
logDirectory = fileSystem.BuildPath(scriptDirectory, "logs")
logPath = fileSystem.BuildPath(logDirectory, "github-cli-daily-updater.log")

If WScript.Arguments.Named.Exists("test") Then
    WScript.Echo "winget.exe found: " & CStr(IsWingetAvailable())
    If WScript.Arguments.Named.Exists("notify") Then
        Notify "GitHub CLI auto-update", "Windows notification test sent."
    End If
    WScript.Quit 0
End If

WriteLog "Daily update check started."
Dim updateResult
updateResult = UpdateGitHubCli()
WriteLog "Daily update check finished."
Notify "GitHub CLI auto-update", updateResult

Function IsWingetAvailable()
    Dim checkCommand, exitCode

    checkCommand = "powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -Command " & Chr(34) & _
        "if(Get-Command winget.exe -ErrorAction SilentlyContinue){exit 0}else{exit 1}" & Chr(34)
    exitCode = shell.Run(checkCommand, 0, True)
    IsWingetAvailable = (exitCode = 0)
End Function

Function UpdateGitHubCli()
    Dim command, exitCode

    If Not IsWingetAvailable() Then
        WriteLog "Skipped: winget.exe was not found."
        UpdateGitHubCli = "Skipped (winget not found)."
        Exit Function
    End If

    WriteLog "Checking GitHub CLI for updates."
    command = "winget.exe upgrade --id GitHub.cli --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements"
    exitCode = shell.Run(command, 0, True)

    If exitCode = 0 Then
        WriteLog "GitHub CLI update completed."
        UpdateGitHubCli = "Update completed successfully."
    ElseIf IsNoApplicableUpdate(exitCode) Then
        WriteLog "GitHub CLI is already up to date."
        UpdateGitHubCli = "GitHub CLI is already up to date (latest)."
    Else
        WriteLog "GitHub CLI update check failed with exit code " & CStr(exitCode) & "."
        UpdateGitHubCli = "Update check failed (code " & CStr(exitCode) & ")."
    End If
End Function

Function IsNoApplicableUpdate(exitCode)
    IsNoApplicableUpdate = (exitCode = NoApplicableUpdateExitCodeUnsigned Or _
        exitCode = NoApplicableUpdateExitCodeSigned)
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
