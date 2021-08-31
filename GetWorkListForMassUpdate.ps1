[CmdletBinding()]
param (
    [string] $PSDBConnectionString
    , [string] $PSBIDBConnectionString
    , [string] $AALogFilePath
)

if ($AALogFilePath.Trim() -eq [string]$null) {
    Write-Output "The AA Logfile path is missing"
    Exit 100
}
elseif (!(Test-Path -Path $AALogFilePath -PathType Leaf)) {
    Write-Output "The AA Logfile path does not exist."
    Exit 100
}

if ($PSDBConnectionString.Trim() -eq [string]$null) {
    Write-Output "DB Connection String is missing"
    Exit 101
}

if ($PSBIDBConnectionString.Trim() -eq [string]$null) {
    Write-Output "BINextGen DB Connection String is missing"
    Exit 102
}


function Write-Log {
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
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath; "AccountNumber" = ""; Message = $Message }
    If ($logfile) {
        try {
            $Content | Export-Csv -Path $logfile -NoTypeInformation -Append
        }
        catch {
            Write-Output $_.Exception.Message;
        }
    }
    Else {
        Write-Output $Message
    }
}

function Test-SQLConnection {    
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


function Invoke-UdfSQLQuery {
    param(
        [string] $connectionString,
        [string] $sqlCommand
    )
    $sqlDataAdapterError = $null
    
    try {
        $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
        $command = new-object system.data.sqlclient.sqlcommand($sqlCommand, $connection)
        $command.CommandTimeout = 0
        $connection.Open()
    
        $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null
    }
    catch {
        $sqlDataAdapterError = $_
        $dataset = $null        
    }
    finally {
        $connection.Close()
    }

    [PSCustomObject] @{
        DataSet = $dataSet
        Errors  = $sqlDataAdapterError
        Success = if ($null -eq $sqlDataAdapterError) { $true } else { $false }
    }
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
        # Setup bulk copy options
        [int]$bulkCopyOptions = ([System.Data.SqlClient.SqlBulkCopyOptions]::Default)
        $options = "TableLock", "CheckConstraints", "FireTriggers", "KeepIdentity", "KeepNulls"
        foreach ($option in $options) {
            $bulkCopyOptions = $bulkCopyOptions -bor (Invoke-Expression "[System.Data.SqlClient.SqlBulkCopyOptions]::$option")                    
        }
        $SqlBulkCopy = New-Object -TypeName System.Data.SqlClient.SqlBulkCopy($ConnString, $bulkCopyOptions)
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



Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for Data Ingestion Inititiated";
$isErrorExit = $false;

$DBTestConnection = Test-SQLConnection $PSDBConnectionString;
if ($DBTestConnection.Success -eq $false) {        
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $DBTestConnection.Errors.Exception.Message;
    $isErrorExit = $true
}

$BIDBTestConnection = Test-SQLConnection $PSBIDBConnectionString;
if ($BIDBTestConnection.Success -eq $false) {        
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $BIDBTestConnection.Errors.Exception.Message;
    $isErrorExit = $true
}


if ($isErrorExit) {
    Write-Host "Errors reported in AA LogFilePath."
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for Data Ingestion completed with errors";
    Exit 110
}

$MaxIDQuery = "SELECT TOP(1) tbSHOV01DID 
FROM dbo.SHOV_MU_WorkList 
WHERE tbSHOV01DID > 0 
ORDER BY tbSHOV01DID DESC;"

$MaxIDData = Invoke-UdfSQLQuery -connectionString $PSDBConnectionString -sqlCommand $MaxIDQuery;

if ($MaxIDData.Success -eq $true) {

    Write-Log -Level INFO -logfile $AALogFilePath -Message "Query to get maxID executed successfully.";
}
else {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $MaxIDData.Errors;
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for DB Ingestion completed with errors";
    EXIT 125
}

$MaxID = $MaxIDData.DataSet.Tables[0].tbSHOV01DID | Select-Object -First 1;

$Query = "SELECT ID
,[TransmissionControlNo]
,LEFT([ClaimNumber], 30) AS [ClaimNumber]
,LEFT([TargetAttnLine], 50) AS [TargetAttnLine]
,LEFT([TargetName], 50) AS [TargetName]
,LEFT([TargetAddress1], 70) AS [TargetAddress1]
,LEFT([TargetAddress2], 50) AS [TargetAddress2]
,LEFT([TargetCity], 30) AS [TargetCity]
,[TargetState]
,[TargetZipCode]
,[TargetPhoneNo]
,LEFT([PDFName], 90) AS [PDFName]
,[CustomerTransmissionCreationDateTime]
,[CustomerProcessDateTime]
,[PagePrinted]
,[PagePDF]
,LEFT([Carrier], 30) AS [Carrier]
,LEFT([TrackingNumber], 30) AS [TrackingNumber]
,[ShipmentDateTime]
,LEFT([CID], 10) AS [CID]
,[FacilityCode]
,[AccountNumber]
,LEFT([BillerID], 30) AS [BillerID]
,CAST([IsRejected] AS TINYINT) AS [IsRejected]
,[RejectCode]
,CAST([IsUpdated] AS TINYINT) AS [IsUpdated]
,LEFT([UpdatedAddress1], 50) AS [UpdatedAddress1]
,LEFT([UpdatedAddress2], 50) AS [UpdatedAddress2]
,[UpdatedCity]
,[UpdatedState]
,[UpdatedZipCode]
,LEFT([UDF1], 10) AS [UDF1]
,LEFT([UDF2], 40) AS [UDF2]
,[SnapshotDate]
,CAST(0 AS TINYINT) AS LockFlag
,CAST(0 AS TINYINT) AS RetryCount
FROM [dbo].[tbSHOV01D]
WHERE ID > $MaxID
and BillerID not in ('awilson1'
,'ncobaugh'
,'pmulshine'
,'kstanley'
,'tbrown17'
,'eamyot'
,'corton'
,'ldaniels11'
,'ikaur7'
,'rmishra08'
,'kgupta1'
,'pnegi6'
,'hlnu69'
,'ebhardwaj16'
,'krai11')" ;


$BIData = Invoke-UdfSQLQuery -connectionString $PSBIDBConnectionString -sqlCommand $Query;

if ($BIData.Success -eq $true) {

    Write-Log -Level INFO -logfile $AALogFilePath -Message "BINextGen query executed successfully.";
}
else {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $BIData.Errors;
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for DB Ingestion completed with errors";
    EXIT 125
}

$BIDataTable = $BIData.DataSet.Tables[0]

if ($BIDataTable.Rows.Count -eq 0) {
    Write-Log -Level INFO -logfile $AALogFilePath -Message "No Data to ingest.";   
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingestion completed successfully.";
    Exit 1000
}


$Columns = @{
    ID                                   = 'tbSHOV01DID'
    ClaimNumber                          = 'ClaimNumber'
    TargetName                           = 'TargetName'
    TargetAttnLine                       = 'TargetAttnLine'
    TargetAddress1                       = 'TargetAddress1'
    TargetAddress2                       = 'TargetAddress2'
    TargetCity                           = 'TargetCity'
    TargetState                          = 'TargetState'
    TargetZipCode                        = 'TargetZipCode'
    TargetPhoneNo                        = 'TargetPhoneNo'
    PDFName                              = 'PDFName'
    CustomerTransmissionCreationDateTime = 'CustomerTransmissionCreationDate'
    CustomerProcessDateTime              = 'CustomerProcessDate'
    PagePrinted                          = 'PagesPrinted'
    PagePDF                              = 'PagesPDF'
    Carrier                              = 'Carrier'
    TrackingNumber                       = 'TrackingNumber'
    ShipmentDateTime                     = 'ShipmentDateTime'
    CID                                  = 'CID'
    FacilityCode                         = 'FacilityCode'
    AccountNumber                        = 'AccountNumber'
    BillerID                             = 'BillerID'
    IsRejected                           = 'IsRejected'
    RejectCode                           = 'RejectCode'
    IsUpdated                            = 'IsUpdated'
    UpdatedAddress1                      = 'UpdatedAddress1'
    UpdatedAddress2                      = 'UpdatedAddress2'
    UpdatedCity                          = 'UpdatedCity'
    UpdatedState                         = 'UpdatedState'
    UpdatedZipCode                       = 'UpdatedZipCode'
    UDF1                                 = 'UDF1'
    UDF2                                 = 'UDF2'
    TransmissionControlNo                = 'TransmissionCtrlNo'
    LockFlag                             = 'LockFlag'
    RetryCount                           = 'RetryCount'        

}


$CopyDatatoSQLParams = @{
    ConnString = $PSDBConnectionString
    TableName  = "SHOV_MU_WorkList"
    ColumnMap  = $Columns
    DataTable  = $BIDataTable
}

$CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;

if ($CopyDataToSQLResponse.Success -eq $true) {
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingested in worklist table successfully.";

}
else {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $CopyDataToSQLResponse.Errors;
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingestion completed with errors.";
    Exit 125
}

Exit 1000