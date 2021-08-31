
[CmdletBinding()]
param (
    [string] $ConfigFilePath
    , [string] $LogFilePath
)

if ($ConfigFilePath -eq [string]$null) {
    Exit 100
}

if ($LogFilePath -eq [string]$null) {
    Exit 101
}

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

Function New-WorkListTable {
    ###Creating a new DataTable###
    $tempTable = New-Object System.Data.DataTable
   
    ##Creating Columns for DataTable##


    $tempTable.Columns.Add("WorklistID","int32") | Out-Null
    $tempTable.Columns.Add("AccountNumber","string") | Out-Null
    $tempTable.Columns.Add("DispositionWhy","string") | Out-Null
    $tempTable.Columns.Add("DispositionWhat","string") | Out-Null
    $tempTable.Columns.add("Note","string") | Out-Null
    $tempTable.Columns.Add("FacilityCode","string") | Out-Null
    $tempTable.Columns.Add("StartProcessTime","datetime") | Out-Null
    $tempTable.Columns.Add("EndProcessTime","datetime") | Out-Null
    $tempTable.Columns.Add("LockFlag","byte") | Out-Null
    $tempTable.Columns.add("RetryCount","byte") | Out-Null
    $tempTable.Columns.Add("ErequestID","string") | Out-Null
    $tempTable.Columns.Add("Status","string") | Out-Null
    $tempTable.Columns.add("HandOffType","string") | Out-Null           
       
    return ,$tempTable
}

Function Write-udfDataTableToSQLTable {
    [CmdletBinding()]
    param (
        [string] $ConnString,
        [string] $TableName,
        [hashtable[]] $ColumnMap,
        [System.Data.DataTable] $DataTable
    )
    $WriteError = $null
    try {
        $SqlBulkCopy = New-Object -TypeName System.Data.SqlClient.SqlBulkCopy($ConnString, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity)
        $SqlBulkCopy.EnableStreaming = $true
        $SqlBulkCopy.DestinationTableName = $TableName
        $SqlBulkCopy.BatchSize = 1000000; 
        $SqlBulkCopy.BulkCopyTimeout = 0 # seconds, 0 (zero) = no timeout limit
        if ($ColumnMap) {
            foreach ($columnname in $ColumnMap) {
                foreach ($key in $columnname.Keys) {
                    $null = $SqlBulkCopy.ColumnMappings.Add($key, $columnname[$key])
                }
            }
        }

        $SqlBulkCopy.WriteToServer($DataTable)


    }
    catch [System.Exception] {
        $WriteError = $_.Exception 
    }
    finally {
        $SqlBulkCopy.Close()
    }


    [PSCustomObject] @{

        Errors  = $WriteError
        Success = if ($null -eq $WriteError) { $true } else { $false }
    }

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


    ####### Token Generation ########
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
        [string] $pageSize,
        [int] $RetryCount = 3,
        [int] $TimeoutInSecs = 10
    )


    $apiQueryParams = [ordered] @{
        HandoffType = $handOffType
        Action      = $action
        Disposition = $disposition
        Notes       = $notes
        Status      = $status
        Pagenumber  = $pageNumber
        Pagesize    = $pageSize
    }

        
    [string]$query = ""
    [int]$i = 0

    foreach ( $item in $apiQueryParams.GetEnumerator()) {
        if ($i -eq 0) {
            $symbol = "?"
        }
        else {
            $symbol = "&"
        }
        if ([string]$null -ne $item.value ) {
            $query = -join ($query, $symbol, $item.Key.ToString(), "=", $item.Value.ToString());
            $i++
        }
    }

    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = -join ($EndPoint, $query)
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
Write-Log -Level INFO -logfile $LogFilePath -Message "Powershell Execution for Get Hand off Inititiated";

#region Reading Config file
try {
    $config = Get-UdfConfiguration -configpath $ConfigFilePath -ErrorAction Stop;
    Write-Output "Reading config file completed"
}
catch {
    Write-Output "Error while reading the config file"
    Write-Output $_.Exception.Message
    Write-Output "Bot Execution is stopped."
    Write-Log -Level INFO -logfile $LogFilePath -Message "Powershell Execution for Get Hand off completed";
    Exit
}
#endregion Reading Config file


#region Calling Token Generation API
$token = $null
Write-Host "Calling Token generation API" 
Write-Log -Level INFO -logfile $LogFilePath -Message "Calling Token API";

$tokenresponse = Get-udfToken -EndPoint $config.TokenRequestURI -clientID $config.clientId -clientSecret $config.clientSecret -ErrorAction Stop;
if ($tokenresponse.Success -eq $true) {
    $token = $tokenresponse.TokenDet.token;
    Write-Host "Token generated successfully" ;
    Write-Log -Level INFO -logfile $LogFilePath -Message "Token generated";
    #Getting Tokeng Generation date time to check token expiry
    $TokenDt = Get-Date;
}
else {
    Write-Host  "Error during Token Generation API call" 
    Write-Log -Level ERROR -logfile $LogFilePath -Message "Error during Token API call" ;
    Write-Log -Level ERROR -logfile $LogFilePath -Message $tokenresponse.Errors.Exception.Message;
    if ($tokenresponse.Errors.ErrorDetails.Message) {
        Write-Log -Level ERROR -logfile $LogFilePath -Message $tokenresponse.Errors.ErrorDetails.Message;
    }
    Write-Log -Level INFO -logfile $LogFilePath -Message "Powershell Execution for Get Hand off completed";
    Exit
}
#endregion 

#region Ready Facility Code csv file
Write-Log -Level INFO -logfile $LogFilePath -Message "Reading Facility List Csv file initiated";
try {

    $FacilityCodeList = import-csv -Path $config.FacilityCodeList;

    Write-Log -Level INFO -logfile $LogFilePath -Message "Reading Facility List Csv file completed";
}
catch {
    Write-Log -Level ERROR -logfile $LogFilePath -Message "Error While Reading the Facility List csv file" ;
    Write-Log -Level ERROR -logfile $LogFilePath -Message $_ ;
}
#endregion
if ($FacilityCodeList.Count -eq 0){
        Write-Log -Level ERROR -logfile $LogFilePath -Message "The Facility List csv file does not have any Facility Code" ;
        Write-Log -Level INFO -logfile $LogFilePath -Message "Powershell Execution for Get Hand off completed";
        EXIT
}

### Creating a Datatable with structure similar to Worklist table in the Database
[System.Data.DataTable]$WorklistTable = New-WorkListTable;



foreach ($Facility in $FacilityCodeList) {

    Write-Log -Level INFO -logfile $LogFilePath -Message "Checking Token expiry" ;
    $TokenExpiryCheck = New-TimeSpan -Start $TokenDt -End (Get-Date);

    If ( $TokenExpiryCheck -gt 13){
    Write-Log -Level INFO -logfile $LogFilePath -Message "Token Expired" ;

        #region Calling Token Generation API
        $token = $null
        Write-Host "Calling Token generation API" 
        Write-Log -Level INFO -logfile $LogFilePath -Message "Calling Token API";

        $tokenresponse = Get-udfToken -EndPoint $config.TokenRequestURI -clientID $config.clientId -clientSecret $config.clientSecret -ErrorAction Stop;
        if ($tokenresponse.Success -eq $true) {
            $token = $tokenresponse.TokenDet.token;
            Write-Host "Token generated successfully" ;
            Write-Log -Level INFO -logfile $LogFilePath -Message "Token generated";
            #Getting Tokeng Generation date time to check token expiry
            $TokenDt = Get-Date;
        }
        else {
            Write-Host  "Error during Token Generation API call" 
            Write-Log -Level ERROR -logfile $LogFilePath -Message "Error during Token API call" ;
            Write-Log -Level ERROR -logfile $LogFilePath -Message $tokenresponse.Errors.Exception.Message;
            if ($tokenresponse.Errors.ErrorDetails.Message) {
                Write-Log -Level ERROR -logfile $LogFilePath -Message $tokenresponse.Errors.ErrorDetails.Message;
            }

            continue
        }
        #endregion 

    }

    $WorkListAPIparams = @(
        @{
            EndPoint     = $config.GetWorklist_URI
            token        = $token
            FacilityCode = $Facility.FacilityCode
            handOffType  = $config.GetWorklist_WorkFlowType1
            action       = $config.GetWorklist_Action1
            disposition  = $config.GetWorklist_Disposition1
            notes        = $null
            status       = $config.GetWorklist_Status1
            pageNumber   = $config.GetWorklist_DefaultPageNo
            pageSize     = $config.GetWorklist_Pagesize
        },
        @{
            EndPoint     = $config.GetWorklist_URI
            token        = $token
            FacilityCode = $Facility.FacilityCode
            handOffType  = $config.GetWorklist_WorkFlowType2
            action       = $config.GetWorklist_Action2
            disposition  = $config.GetWorklist_Disposition2
            notes        = $null
            status       = $config.GetWorklist_Status2
            pageNumber   = $config.GetWorklist_DefaultPageNo
            pageSize     = $config.GetWorklist_Pagesize
        }
    )

    foreach ($WorkListAPIparam IN $WorkListAPIparams) {

    #region Call Get Hand off API
    Write-Log -Level INFO -logfile $LogFilePath -Message "Calling Get Hand Off API for Facility Code: $($WorkListAPIparam.FacilityCode)" ;
    Write-Log -Level INFO -logfile $LogFilePath -Message "API Parameters $($WorkListAPIparam.GetWorklist_WorkFlowType1) |`
     $($WorkListAPIparam.GetWorklist_Action1) | $($WorkListAPIparam.GetWorklist_Disposition1) | $($WorkListAPIparam.GetWorklist_Status1) | $($WorkListAPIparam.GetWorklist_DefaultPageNo) | `
     $($WorkListAPIparam.GetWorklist_Pagesize)" ;

     $WorklistResponse = $null;

        $WorklistResponse = Invoke-udfGetHandOffAPI @WorkListAPIparam;


        if ($WorklistResponse.Success -eq $true) {
    
            $WorkListjson = $WorklistResponse.AccountDet | ConvertTo-Json -Depth 10;

            Write-Host "json response received successfully for Facility Code: $($Facility.FacilityCode)" ;
            Write-Log -Level INFO -logfile $LogFilePath -Message "json response received successfully for Facility Code: $($Facility.FacilityCode)"

        }
        else {
            Write-Host  "Error during Get HandOff API call." 
            Write-Log -Level ERROR -logfile $LogFilePath -Message "Error during Get HandOff API call." 
            Write-Log -Level ERROR -logfile $LogFilePath -Message $WorklistResponse.Errors.Exception.Message
            if ($WorklistResponse.Errors.ErrorDetails.Message) {        
                Write-Log -Level ERROR -logfile $LogFilePath -Message $WorklistResponse.Errors.ErrorDetails.Message 
            }
            continue
        }

    
        foreach( $item in $WorkListjson.item ){

            $row = $WorklistTable.NewRow()

            #set the properties of each row from the data
            $row.FacilityCode = $Facility.FacilityCode
            $row.AccountNumber = $item.account.accountNumber
            $row.HandOffType = $config.GetWorklist_WorkFlowType1
            $row.DispositionWhat = $item.activity.task.result.disposition.what
            $row.DispositionWhy = $item.activity.task.result.disposition.why
            $row.Note = $item.activity.task.result.disposition.note.text
            $row.Status = $item.activity.status
            $row.LockFlag = 0
            $row.RetryCount = 0
            $WorklistTable.Rows.Add($row);
        }
    #endregion 

    }

}

$Columns = @{
          AccountNumber = 'AccountNumber'
          DispositionWhy = 'DispositionWhy'
          DispositionWhat = 'DispositionWhat'
          Note = 'Note'
          FacilityCode = 'FacilityCode'
          LockFlag = 'LockFlag'
          RetryCount = 'RetryCount'
          Status = 'Status'
          HandOffType = 'HandOffType'
         }

$CopyDatatoSQLParams = @{
        ConnString = $config.PSDBConnectionString
        TableName = $config.WorkListTableName
        ColumnMap = $Columns
        DataTable = $WorklistTable
    }

$CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;

        if ($CopyDataToSQLResponse.Success -eq $true) {
            Write-Host "Get Hand off API Data is ingested successfully" ;
            Write-Log -Level INFO -logfile $LogFilePath -Message "Get Hand off API Data is ingested successfully"
        }
        else
        {
            Write-Host  "Error while ingesting the Get Hand off Data" 
            Write-Log -Level ERROR -logfile $LogFilePath -Message "Error while ingesting the Get Hand off Data" 
            Write-Log -Level ERROR -logfile $LogFilePath -Message $CopyDataToSQLResponse.Errors;            
        }


Write-Log -Level INFO -logfile $LogFilePath -Message "Powershell Execution for Get Hand off completed";
Exit 1000