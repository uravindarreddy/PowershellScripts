$SQLServer = "PRDAMATWSQL01\RPA_DEV"
$DBName = "DTO_DB"
$LogFilePath = "C:\DeadLockTesting\$PID.csv"

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

        [Parameter(Mandatory = $False)]
        [string]
        $logfile,

        [Parameter(Mandatory = $False)]
        [string]
        $wklistID
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath; Message = $Message; "ID" = $wklistID }
    If ($logfile) {
        try {
            $Content | Export-Csv -Path $logfile -NoTypeInformation -Append
        }
        catch {
            Write-Output $_.Exception.Message            
        }
    }
    Else {
        Write-Output $Message
    }
}

Write-Log -Level INFO -logfile $LogFilePath -Message "Powershell Execution  Initiated";
while (1 -eq 1) {

    $ProcessTimeOut = 210
    $ConnectorPayorSelectHealth = 'AVAILITY'
    $RequestUpdateDate = '2021-03-18 14:15:53.763'
    $MachineName = 'RaviTesting'

    $SPQuery = "[dbo].[usp_AuthEnhancement_GetEreferralRequestXML_v1_WithoutAppLock] @ProcessTimeOut = $ProcessTimeOut
    ,@ConnectorPayorSelectHealth = '$ConnectorPayorSelectHealth'
    ,@RequestUpdateDate = '$RequestUpdateDate'
    ,@MachineName = '$MachineName'"
    $WorklistIds = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -Query $SPQuery -OutputAs DataTables; 


    if ($WorklistIds) {
 

        foreach ($ID in $WorklistIds) {

            Write-Log -Level INFO -logfile $LogFilePath -Message "ID Fetched" -wklistID $ID.ID;
            $rnd = Get-Random -Minimum 1 -Maximum 10

            Start-Sleep -Seconds $rnd

            $UpdateLockQuery = "[dbo].[usp_AuthEnhancement_UpdateLockFlag_v2_WithoutAppLock] 
            @AuthResponse1 = 'AuthResponse1'
           ,@AuthResponse2 = 'AuthResponse2'
           ,@PostResponseStatus = '210'
           ,@ID = $($ID.ID)
           ,@RequestUpdateDate = '2021-02-05 00:03:28.910'"
            $UpdateLock = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -Query $UpdateLockQuery; 
        
        }    
    }
    else {
        Write-Log -Level INFO -logfile $LogFilePath -Message "NO Requests To be Processed";
        break 
    }

 

}
Write-Log -Level INFO -logfile $LogFilePath -Message "Powershell Execution completed";