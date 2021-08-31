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
        [string] $pFacilityCode       ,
        [string] $pEpremisCID         ,
        [string] $pClientName                 
    )
    $parmset = @()   # Create a collection object.
   
    # Add the parameters we need to use...
    $parmset += (Add-UdfParameter "@vGetWorklistResponse" "Input" "$pWorkListjson" "string" -1)
    $parmset += (Add-UdfParameter "@vFacilityCode" "Input" "$pFacilityCode" "string" -1)
    $parmset += (Add-UdfParameter "@vEpremisCID" "Input" "$pEpremisCID" "string" -1)
    $parmset += (Add-UdfParameter "@vClientName" "Input" "$pClientName" "string" -1)

   
    $spExecParams = @{
        sqlconnstring = $connstring
        sqlspname     = $spname
        parameterset  = $parmset
    }
    Invoke-UdfStoredProcedure @spExecParams;
}

Function Invoke-udfGetWorkListSP {
    [CmdletBinding()]
    param (
        [string] $connstring          , # Connection string
        [string] $spName              , # SQL Query
        [int] $pLockTimeout       , # SP Parameter
        [int] $pRetryTimeout       ,
        [int] $pRetryCount         ,
        [datetime] $pStartTimeStamp                 
    )
    $parmset = @()   # Create a collection object.
   
    # Add the parameters we need to use...
    $parmset += (Add-UdfParameter "@vLockTimeout" "Input" "$pLockTimeout" "string" -1)
    $parmset += (Add-UdfParameter "@vRetryTimeout" "Input" "$pRetryTimeout" "string" -1)
    $parmset += (Add-UdfParameter "@vRetryCount" "Input" "$pRetryCount" "string" -1)
    $parmset += (Add-UdfParameter "@vStartTimeStamp" "Input" "$pStartTimeStamp" "datetime" -1)

   
    $spExecParams = @{
        sqlconnstring = $connstring
        sqlspname     = $spname
        parameterset  = $parmset
    }
    Invoke-UdfStoredProcedure @spExecParams;
}

Function Invoke-udfDTOReportingSP {
    [CmdletBinding()]
    param (
        [string] $connstring          , # Connection string
        [string] $spName               # SQL Query
        ,[string]$pUserID
        ,[string]$pAccountNumber
        ,[string]$pFacilityCode
        ,[string]$pStatusCheck
        ,[string]$pStatusDescription
        ,[string]$pBotName
        ,[string]$pProcessName
        ,[datetime]$pStartTimeStamp
        ,[datetime]$pEndTimeStamp
        ,[string]$pFinalMergePDF
        ,[string]$pDocCollationLogFilePath             
    )
    $parmset = @()   # Create a collection object.
   
    # Add the parameters we need to use...
    $parmset += (Add-UdfParameter "@vUserID" "Input" "$pUserID" "string" -1)
    $parmset += (Add-UdfParameter "@vAccountNumber" "Input" "$pAccountNumber" "string" -1)
    $parmset += (Add-UdfParameter "@vFacilityCode" "Input" "$pFacilityCode" "string" -1)
    $parmset += (Add-UdfParameter "@vStatusCheck" "Input" "$pStatusCheck" "string" -1)
    $parmset += (Add-UdfParameter "@vStatusDescription" "Input" "$pStatusDescription" "datetime" -1)
    $parmset += (Add-UdfParameter "@vBotName" "Input" "$pBotName" "string" -1)
    $parmset += (Add-UdfParameter "@vProcessName" "Input" "$pProcessName" "string" -1)
    $parmset += (Add-UdfParameter "@vStartTimeStamp" "Input" "$pStartTimeStamp" "string" -1)
    $parmset += (Add-UdfParameter "@vEndTimeStamp" "Input" "$pEndTimeStamp" "datetime" -1)
    $parmset += (Add-UdfParameter "@vFinalMergePDF" "Input" "$pFinalMergePDF" "string" -1)
    $parmset += (Add-UdfParameter "@vDocCollationLogFilePath" "Input" "$pDocCollationLogFilePath" "datetime" -1)
   
    $spExecParams = @{
        sqlconnstring = $connstring
        sqlspname     = $spname
        parameterset  = $parmset
    }
    Invoke-UdfStoredProcedure @spExecParams;
}

$WorkListjson = Get-Content "\\R1-UEM-1\UEM_Profiles\US35107\profile\Downloads\API 1\API 1\WHKS_171220034027.json" | Out-String
    $worklistspParams = @{
                connstring    = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
                spname        = "usp_SHOV_DC_InsertWorkList"
                pWorkListjson = $WorkListjson
                pFacilityCode = "BMAL"
                pEpremisCID   = "7892"
                pClientName   = "ASC"
            }                            
            $InsertWorkListData = Invoke-udfExecInsertWorkListSP @worklistspParams;

    $GetworklistspParams = @{
                connstring    = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
                spname        = "usp_SHOV_DC_GetWorkList"
                pLockTimeout = 10
                pRetryTimeout = 0
                pRetryCount   = 0
                pStartTimeStamp   = (Get-date)
            }                            
            $GetWorkListData = Invoke-udfGetWorkListSP @GetworklistspParams;

    $DTOReportingspParams = @{
                connstring    = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
                spname        = "udfGetWorkListSP"
                pUserID = "US35107"
                pAccountNumber = "5648778978"
                pFacilityCode = 'BMAL'
                pStatusCheck = 'Pass'
                pStatusDescription = ""
                pBotName = "HZC-RPA-165"
                pProcessName = "SHOV_DC"
                pStartTimeStamp = (Get-date)
                pEndTimeStamp = (Get-date)
                pFinalMergePDF = "CombinedFilename_5648778978.pdf"
                pDocCollationLogFilePath  = "HZC-RPA-165_SHOV_DC_5648778978.csv"
            }                            
            $DTOReportingData = Invoke-udfDTOReportingSP @DTOReportingspParams;

            