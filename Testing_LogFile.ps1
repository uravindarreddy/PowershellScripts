$PSPath = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\Automation Anywhere Files\Automation Anywhere\My Docs\Source HOV\Charity\Logs\09.09.2020\Testing.csv"



Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG","EXECUTION")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$True)]
    [string]
    $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSPath; "Message" = $Message}
    If($logfile) {
        try
        {
            $Content | Export-Csv -Path $logfile -NoTypeInformation -Append           
        }
        catch
        {
            Write-Host $_.Exception.Message            
        }
    }
    Else {
        Write-Host $Message
    }
}
$LogFilePath = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\Automation Anywhere Files\Automation Anywhere\My Docs\Source HOV\Charity\Logs\09.09.2020\Testing.csv"

Write-Log -Level EXECUTION -Message "PowerShell script execution initiated" -logfile $LogFilePath


