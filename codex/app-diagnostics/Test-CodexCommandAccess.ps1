[CmdletBinding()]
param(
    [ValidateSet('OsRegistry', 'OsCim')]
    [string]$Probe = 'OsRegistry'
)

# Fixed read-only probes: no arbitrary command execution, credentials, or ACL edits.
# Run in the failing context first. Any outside-sandbox comparison requires the
# normal tool approval flow; this script never elevates itself.
$ErrorActionPreference = 'Stop'
try {
    if ($Probe -eq 'OsRegistry') {
        $os = Get-ItemProperty -LiteralPath 'HKLM:/SOFTWARE/Microsoft/Windows NT/CurrentVersion'
        $detail = [ordered]@{
            Edition = $os.EditionID
            Release = $os.DisplayVersion
            Build = ('{0}.{1}' -f $os.CurrentBuild, $os.UBR)
        }
    } else {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $detail = [ordered]@{
            Edition = $os.Caption
            Version = $os.Version
            Build = $os.BuildNumber
        }
    }
    [ordered]@{
        Probe = $Probe
        Status = 'Passed'
        Scope = 'This probe in the current execution context only'
        Detail = $detail
    } | ConvertTo-Json -Depth 4
    exit 0
} catch {
    # Error category is language independent; avoid outputting raw diagnostic
    # messages that may contain unrelated paths or data.
    [ordered]@{
        Probe = $Probe
        Status = 'Failed'
        Category = [string]$_.CategoryInfo.Category
        ExceptionType = $_.Exception.GetType().FullName
        HResult = $_.Exception.HResult
        NextStep = 'Compare the same probe through an approved execution context. Do not infer an LTSC defect from access denial alone.'
    } | ConvertTo-Json -Depth 4
    exit 1
}
