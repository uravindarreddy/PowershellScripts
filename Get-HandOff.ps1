<#     
.SYNOPSIS       
   Powershell script for Data ingestion for the SourceHOV Charity & IS  Process
.DESCRIPTION
   Data ingestion for getting workitems via APIs for the SourceHOV  Charity & IS  Process

.PARAMETER ConfigFilePath
   File Path Location to the configuration file in which all the parameters required for the execution of this script are configured

.EXAMPLE       
   Powershell.exe "D:\PowershellScripts\scr_SHOV_DB_Ingestion.ps1" -ConfigFilePath "D:\PowershellScripts\SourceHOVISConfig_Powershell.csv" 
   .\scr_SHOV_DB_Ingestion.ps1 -ConfigFilePath "D:\PowershellScripts\SourceHOVISConfig_Powershell.csv" 
#>

[CmdletBinding()]
param (
    [Parameter (Mandatory = $true, Position = 0)] [string] $ConfigFilePath,
    [Parameter (Mandatory = $false, Position = 1)] [string] $AALogFile

)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12;

#region Function definitions
Function Get-UdfConfiguration { 
    [CmdletBinding()]
    param (
        [string] $configpath   
    )
    $configvals = Import-CSV -Path $configpath -Header name, value;

    $configlist = @{ };

    foreach ($item in $configvals) {
        $configlist.Add($item.name, $item.value)
    }   
    Return $configlist    
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

        [Parameter(Mandatory = $False)]
        [string]
        $logfile
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath; Message = $Message }
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

Function Test-SQLConnection {    
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $ConnectionString
    )
    $ErrorMessage = $null
    try {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        $sqlConnection.Open();        
    }
    catch {
        $ErrorMessage = $_ 

    }
    finally {
        $sqlConnection.Close();       
    }

    [PSCustomObject] @{
        Errors  = $ErrorMessage
        Success = if ($null -eq $ErrorMessage) { $true } else { $false }
    }
}

Function Invoke-UdfStoredProcedure { 
    [CmdletBinding()]
    param (
        [string] $sqlconnstring          , # Connection string
        [string] $sqlspname              , # SQL Query
        $parameterset                        # Parameter properties
    )
         
    $sqlDataAdapterError = $null
    try {
        $conn = new-object System.Data.SqlClient.SqlConnection($sqlconnstring);  

  
        $command = new-object system.data.sqlclient.Sqlcommand($sqlspname, $conn)

        $command.CommandType = [System.Data.CommandType]'StoredProcedure'; 

        foreach ($parm in $parameterset) {
            if ($parm.Direction -eq 'Input') {
                [void]$command.Parameters.AddWithValue($parm.Name, $parm.Value); 
            }
        }

        [void] $conn.Open()
  
        $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
  
        [void] $adapter.Fill($dataset)
 
    }
    catch {
        $sqlDataAdapterError = $_
        $dataset = $null
        
    }
    finally {
        $conn.Close()  
    }

    [PSCustomObject] @{
        DataSet = $dataSet
        Errors  = $sqlDataAdapterError
        Success = if ($null -eq $sqlDataAdapterError) { $true } else { $false }
    }
 
}

Function Add-UdfParameter { 
    [CmdletBinding()]
    param (
        [string] $name                    , # Parameter name from stored procedure, i.e. @myparm
        [string] $direction               , # Input or Output or InputOutput
        [string] $value                   , # parameter value
        [string] $datatype                , # db data type, i.e. string, int64, etc.
        [int]    $size                        # length
    )

    $parm = New-Object System.Object
    $parm | Add-Member -MemberType NoteProperty -Name "Name" -Value "$name"
    $parm | Add-Member -MemberType NoteProperty -Name "Direction" -Value "$direction"
    $parm | Add-Member -MemberType NoteProperty -Name "Value" -Value "$value"
    $parm | Add-Member -MemberType NoteProperty -Name "Datatype" -Value "$datatype"
    $parm | Add-Member -MemberType NoteProperty -Name "Size" -Value "$size"

    Write-Output $parm
    
}
Function Get-udfToken {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $clientID,
        [string] $clientSecret,
        [int] $RetryCount = 3,
        [int] $TimeoutInSecs = 10
    )
    ####### Token Generation ########
    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = $EndPoint
        Method      = $Method
        ContentType = $ContentType
        Headers     = @{ 
            'clientId'     = "$clientID"  
            'clientSecret' = "$clientSecret" 
        }
    }

    $Attempt = 1;
    $Flag = $true;
    Do {
        try {
            $rToken = Invoke-RestMethod @params
            $Flag = $false
        }
        catch {
            if ($Attempt -gt $RetryCount) {
                $ApiError = $_;
                $rToken = $null;
                $Flag = $false
            }
            else {
                Start-Sleep -Seconds $TimeoutInSecs;
                $Attempt = $Attempt + 1;
            }
        }
    }
    while ($Flag)

    #return $rToken
    [PSCustomObject] @{
        TokenDet = $rToken
        Errors   = $ApiError
        Success  = if ($null -eq $ApiError) { $true } else { $false }
    }

}

Function Invoke-udfGetHandOffAPI {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $token,
        [string] $FacilityCode,
        [string] $handOffType,
        [string] $action,
        [string] $disposition, 
        [string] $notes,
        [string] $status,
        [string] $pageNumber,
        [string] $pageSize
    )


    $apiQueryParams = [ordered] @{
        HandoffType = $handOffType
        Action =  $action
        Disposition = $disposition
        Notes = $notes
        Status = $status
        Pagenumber = $pageNumber
        Pagesize = $pageSize
        }

        
        [string]$query = ""
        [int]$i = 0

        foreach ( $item in $apiQueryParams.GetEnumerator()) {
        if ($i -eq 0){
            $symbol = "?"
            }
            else {
            $symbol = "&"
            }
            if([string]$null -ne $item.value ){
               $query =  -join ($query, $symbol, $item.Key.ToString(),"=", $item.Value.ToString());
               $i++
                }
        }

    $EndPoint = -join($EndPoint, $query);

    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = $EndPoint
        Method      = $Method
        ContentType = $ContentType
        Headers     = @{ 
            'facilityCode'  = "$FacilityCode"                   
            'Authorization' = "Bearer $token"
        }
    }

    $Attempt = 1;
    $Flag = $true;
    Do {

        try {
            $response = Invoke-RestMethod @params;
            $Flag = $false;        
        }
        catch {

            if ($Attempt -gt $RetryCount) {
                    $ApiError = $_;
                    $response = $null;        
                    $Flag = $false
                }
                else {
                    Start-Sleep -Seconds $TimeoutInSecs;
                    $Attempt = $Attempt + 1;
                }
    }
        }
    while ($Flag)

    #return $rToken
    [PSCustomObject] @{
        AccountDet = $response
        Errors     = $ApiError
        Success    = if ($null -eq $ApiError) { $true } else { $false }
    }
    
}

#endregion Function definitions


#region Reading Config file
try {
    $config = Get-UdfConfiguration -configpath $ConfigFilePath -ErrorAction Stop
    Write-Output "Reading config file completed"
}
catch {
    Write-Output "Error while reading the config file"
    Write-Output $_.Exception.Message
    Write-Output "Bot Execution is stopped."
    Exit
}
#endregion Reading Config file

[bool]$isErrorExit = $false

#region Log file Initialization
if ([string]$null -ne $config.ProcessLogFilePath) {
    if ( -not ( Test-Path -Path $config.ProcessLogFilePath -PathType Container) ) {
        Write-Output "Log file folder location is not accessible or does not exists."
        Write-Output "Bot Execution is stopped."
        $isErrorExit = $true
    }
}
else {
    Write-Output "Log file folder location is blank."
    Write-Output "Bot Execution is stopped."    
    $isErrorExit = $true
}

$ProcessLogFilePath = Join-Path $config.ProcessLogFilePath (Get-Date).ToString('MM.dd.yyyy')
if ( -not (Test-Path -Path $ProcessLogFilePath -PathType Container) ) {
    New-Item -ItemType "directory" -Path $ProcessLogFilePath | Out-Null    
}

$LogFileName = $env:COMPUTERNAME + "_" + $Config.ProcessName + ".csv"
$LogFileName = Join-Path $ProcessLogFilePath $LogFileName;

#endregion

#region Config values validation
if ([string]$null -ne $config.PSDBConnectionString) {
    $DBTestConnection = Test-SQLConnection $config.PSDBConnectionString
    if ($DBTestConnection.Success -eq $false) {
        Write-Log -Level ERROR -Message $DBTestConnection.Errors.Exception.Message -logfile $LogFileName -ErrorAction Stop
        $isErrorExit = $true
    }
}
else {        
    Write-Log -Level ERROR -Message "Database connectionstring is not provided." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}

if ([string]$null -eq $config.InsertWorkListSP) {
    Write-Log -Level ERROR -Message "InsertWorkListSP is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.GetWorkListSP) {
    Write-Log -Level ERROR -Message "GetWorkListSP is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.CheckoutAccountSP) {
    Write-Log -Level ERROR -Message "CheckoutAccountSP is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.DTOReportingSP) {
    Write-Log -Level ERROR -Message "DTOReportingSP is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.SkipDTOReportingSP) {
    Write-Log -Level ERROR -Message "SkipDTOReportingSP is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}

if ([string]$null -eq $config.PurgeDataSP) {
    Write-Log -Level ERROR -Message "PurgeDataSP is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}

if ([string]$null -eq $config.APIBaseURL) {
    Write-Log -Level ERROR -Message "API Base URL is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}

if ([string]$null -eq $config.APITokenGeneration) {
    Write-Log -Level ERROR -Message "API Base URL is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.APIGetWorkList) {
    Write-Log -Level ERROR -Message "End point for Get Worklist API is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.APICheckoutAccount) {
    Write-Log -Level ERROR -Message "Endpoint for Checkout Account API is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.clientId) {
    Write-Log -Level ERROR -Message "clientId is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.clientSecret) {
    Write-Log -Level ERROR -Message "clientSecret is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}
if ([string]$null -eq $config.PerformerCode) {
    Write-Log -Level ERROR -Message "PerformerCode is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}

if ([string]$null -eq $config.RequestTypes) {
    Write-Log -Level ERROR -Message "Request Type is blank." -logfile $LogFileName -ErrorAction Stop
    $isErrorExit = $true
}

if ($isErrorExit) {
    Write-Output "Bot Execution is stopped."
    Exit    
}
#endregion Config values validation