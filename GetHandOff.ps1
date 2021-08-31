<#



#>
    [CmdletBinding()]
    param (
    [Parameter (Mandatory = $true, Position = 0)] [string] $TokenURL ,
    [Parameter (Mandatory = $true, Position = 1)] [string] $clientID ,
    [Parameter (Mandatory = $true, Position = 2)] [string] $clientSecret ,
    [Parameter (Mandatory = $true, Position = 3)] [string] $GetHandOffURL,
    [Parameter (Mandatory = $true, Position = 4)] [string] $FacilityCode ,
    [Parameter (Mandatory = $true, Position = 4)] [string] $EpremisCID,
    [Parameter (Mandatory = $true, Position = 5)] [string] $handOffType,
    [Parameter (Mandatory = $true, Position = 6)] [string] $action,
    [Parameter (Mandatory = $true, Position = 7)] [string] $disposition,
    [Parameter (Mandatory = $true, Position = 8)] [string] $status,
    [Parameter (Mandatory = $true, Position = 9)] [string] $pageNumber,
    [Parameter (Mandatory = $true, Position = 10)] [string] $pageSize,
    [Parameter (Mandatory = $true, Position = 11)] [string] $PSDBConnectionString,
    [Parameter (Mandatory = $true, Position = 12)] [string] $LogFilename
    )

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

Function Get-udfToken {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $clientID,
        [string] $clientSecret
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
    try {
        $rToken = Invoke-RestMethod @params         
    }
    catch {
        $ApiError = $_;
        $rToken = $null;
    }

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

    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = -join($EndPoint, $query)
        Method      = $Method
        ContentType = $ContentType
        Headers     = @{ 
            'facilityCode'  = "$FacilityCode"                   
            'Authorization' = "Bearer $token"
        }
    }

    Write-host "$EndPoint$query"
    try {
        $response = Invoke-RestMethod @params         
    }
    catch {
        $ApiError = $_;
        $response = $null;
    }

    #return $rToken
    [PSCustomObject] @{
        AccountDet = $response
        Errors     = $ApiError
        Success    = if ($null -eq $ApiError) { $true } else { $false }
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


Function Invoke-udfExecInsertWorkListSP {
    [CmdletBinding()]
    param (
        [string] $connstring          , # Connection string
        [string] $spName              , # SQL Query
        [string] $pWorkListjson       , # SP Parameter
        [string] $pFacilityCode,
        [string] $pEpremisCID                 
    )
    $parmset = @()   # Create a collection object.
   
    # Add the parameters we need to use...
    $parmset += (Add-UdfParameter "@vGetWorklistResponse" "Input" "$pWorkListjson" "string" -1)
    $parmset += (Add-UdfParameter "@vFacilityCode" "Input" "$pFacilityCode" "string" -1)
    $parmset += (Add-UdfParameter "@vEpremisCID" "Input" "$pEpremisCID" "string" -1)
   
    $spExecParams = @{
        sqlconnstring = $connstring
        sqlspname     = $spname
        parameterset  = $parmset
    }
    Invoke-UdfStoredProcedure @spExecParams;
}

Write-Log -Level EXECUTION -logfile $LogFilename -Message "Get HandOff PS Execution Started" ;
#region Calling Token Generation API
$token = $null
Write-Host "Calling Token generation API" 
Write-Log -Level INFO -logfile $LogFilename -Message "Calling Token generation API" ; 



$tokenresponse = Get-udfToken -EndPoint $Tokenurl -clientID $clientID -clientSecret $clientSecret -ErrorAction Stop;
if ($tokenresponse.Success -eq $true) {
    $token = $tokenresponse.TokenDet.token;
    Write-Log -Level INFO -logfile $LogFilename -Message "Token generated successfully" ;
}
else {
    Write-Log -Level ERROR -logfile $LogFilename -Message  "Error during Token Generation API call." 
    Write-Log -Level ERROR -logfile $LogFilename -Message $tokenresponse.Errors.Exception.Message 
    if ($tokenresponse.Errors.ErrorDetails.Message) {
        Write-Log -Level ERROR -logfile $LogFilename -Message  $tokenresponse.Errors.ErrorDetails.Message 
    }
    Write-Log -Level EXECUTION -logfile $LogFilename -Message "Get HandOff PS Execution Completed" ;    
    Exit    
}
#endregion 


    $WorkListAPIparams = @{
        EndPoint = $GetHandOffURL
        token = $token
        FacilityCode = $FacilityCode
        handOffType = $handOffType
        action = $action
        disposition = $disposition # $null #"Ready for Bot" 
        notes = $null
        status = $status #"4"
        pageNumber = $pageNumber #"1"
        pageSize = $pageSize #"1000"
    }

    $WorklistResponse = Invoke-udfGetHandOffAPI @WorkListAPIparams;



if ($WorklistResponse.Success -eq $true) {
    $WorklistResponse.AccountDet

    $WorkListjson = $WorklistResponse.AccountDet | ConvertTo-Json -Depth 10;

    
    Write-Log -Level INFO -logfile $LogFilename "json response received successfully" ;

                $worklistspParams = @{
                connstring    = $PSDBConnectionString
                spname        = "usp_SHOV_DC_InsertWorkList"
                pWorkListjson = $WorkListjson
                pFacilityCode = $FacilityCode
                pEpremisCID = $EpremisCID #"7893"
            }                            
            $InsertWorkListData = Invoke-udfExecInsertWorkListSP @worklistspParams;

            if ($InsertWorkListData.Success -eq $true) {
                Write-Log -Level INFO -logfile $LogFilename "json parsing done successfully"
            }
            else {
                Write-Log -Level ERROR -logfile $LogFilename "Error while parsing the json."
                Write-Log -Level ERROR -logfile $LogFilename $InsertWorkListData.Errors.Exception.Message 
            }
}
else {
    Write-Log -Level ERROR -logfile $LogFilename  "Error during Get HandOff API call." 
    Write-Log -Level ERROR -logfile $LogFilename $WorklistResponse.Errors.Exception.Message 
    if ($WorklistResponse.Errors.ErrorDetails.Message) {
        Write-Log -Level ERROR -logfile $LogFilename  $WorklistResponse.Errors.ErrorDetails.Message 
    }    
}
Write-Log -Level EXECUTION -logfile $LogFilename -Message "Get HandOff PS Execution Completed" ;    