<#     
.SYNOPSIS       
   Powershell script for checking Sharepoint upload time restrictions
.DESCRIPTION
   This script will check for upload sharepoint time restrictions. It takes timezone and timeslots as input parameters.
   As per TimeSlots mentioned this script will check current time as per timezone and wait till the end of slots.
   If the current time does not fall into mentioned Timeslots it will just complete execution.

.PARAMETER TimeZone
   TimeZone of the time restriction
    TimeZones accepted by this script
    
    UTC 		Coordinated Universal Time 
    GMT 		GMT Standard Time
    IST 		India Standard Time
    EST 		Eastern Standard Time
    CST 		Central Standard Time
    PST 		Pacific Standard Time
    MST 		Mountain Standard Time

.PARAMETER TimeSlots
   Timeslots in a delimited string format "hh:mm AM/PM - hh:mm AM/PM" with a PIPE "|" delimeter.

.EXAMPLE       
   Powershell.exe -File "D:\PowershellScripts\SharePointUploadTimeRestrictions.ps1" -TimeZone "CST" -TimeSlots "08:40AM-08:45AM|09:10PM-9:15PM"
#>

[CmdletBinding()]
param (
    [string] $TimeZone
    , [string] $TimeSlots
    , [string] $AccountNumber
    , [string] $LogFilePath
)

if ($LogFilePath -eq [string]$null) {
    Exit 100
}

Function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG", "EXECUTION")]
        [String]
        $Level = "INFO",

        [Parameter(Mandatory = $True)]
        [string]
        $Message,

        [Parameter(Mandatory = $True)]
        [string]
        $logfile,

        [Parameter(Mandatory = $True)]
        [string]
        $AccountNumber
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath; "Account" = $AccountNumber; "Message" = $Message }
    If ($logfile) {
        try {
            $Content | Export-Csv -Path $logfile -NoTypeInformation -Append           
        }
        catch {
            Write-Host $_.Exception.Message            
        }
    }
    Else {
        Write-Host $Message
    }
    Write-Host $Message
}

Write-Log -Level INFO -Message "PowerShell script execution initiated" -logfile $LogFilePath -AccountNumber $AccountNumber

if ($TimeZone -eq [string]$null) {
    Write-Log -Level ERROR -Message "TimeZone is blank" -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level INFO -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
    Exit 
}

Switch ($TimeZone) {
    "UTC" { $Val = "UTC" }
    "GMT" { $Val = "GMT Standard Time" }
    "IST" { $Val = "India Standard Time" }
    "EST" { $Val = "Eastern Standard Time" }
    "CST" { $Val = "Central Standard Time" }
    "PST" { $Val = "Pacific Standard Time" }
    "MST" { $Val = "Mountain Standard Time" }
    default { $Val = [string]$null }
}

if ($Val -eq [string]$null) {
    Write-Log -Level ERROR -Message "TimeZone mentioned is wrong. It should be EST, CST, PST or MST." -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level INFO -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
    Exit 
}

if ($TimeSlots -eq [string]$null) {
    Write-Log -Level ERROR -Message "TimeSlots not mentioned" -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level INFO -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
    Exit 
}

$regex = "\b((1[0-2]|0?[1-9]):([0-5][0-9])\s*([AaPp][Mm]))\s*-\s*\b((1[0-2]|0?[1-9]):([0-5][0-9])\s*([AaPp][Mm]))"

if (!($TimeSlots -match $regex)) {
    Write-Log -Level ERROR -Message "TimeSlots not mentioned in prescribed format hh:mm AM/PM-hh:mm AM/PM separated by pipe (|)" -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level INFO -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
    Exit 
}


try {

    $ArrayOfTimeSlots = $TimeSlots.Split("|").Trim()
    $TimeNow = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), $Val)


    foreach ($ts in $ArrayOfTimeSlots) {
        $StartTime = Get-Date $ts.Split("-")[0]
        $EndTime = Get-Date $ts.Split("-")[1]

        if ( $TimeNow.TimeOfDay -ge $StartTime.TimeOfDay -and $TimeNow.TimeOfDay -lt $EndTime.TimeOfDay) {
            $TimeDiff = New-TimeSpan $TimeNow $EndTime
            $DelayInSeconds = $TimeDiff.Minutes * 60 + $TimeDiff.Seconds
            Write-Host "It is going to wait for $DelayInSeconds seconds"
            Write-Log -Level INFO -Message "BOT is going to wait for $DelayInSeconds seconds" -logfile $LogFilePath -AccountNumber $AccountNumber
            Start-Sleep -Seconds $DelayInSeconds
        }

    }
}
catch {
    Write-Log -Level ERROR -Message "Error while waiting for SharePoint Upload: $_" -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level INFO -Message "PowerShell script execution completed with errors" -logfile $LogFilePath -AccountNumber $AccountNumber
    Exit 50
}
Write-Log -Level INFO -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
Exit 200