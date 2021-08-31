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
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath; Message = $Message }
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
    Exit 1000
}

$Query = "SELECT DISTINCT RV.EncounterID
,D1.RegistrationID
,D1.FacilityCode
,D1.FacilitySystem
,c.CID
,D1.note
,LEFT(tc.ContractPayer, 30) AS ContractPayer
,LEFT(rf.CurrentPlanCode, 50) AS CurrentPlanCode
,pc.PayorName
,LEFT(pc.PayorPlanName, 50) AS PayorPlanName
,LEFT(D1.[name], 50) AS HandoffType
,LEFT(D1.Disposition, 50) AS Disposition
,Datediff(D, ActivityDate, Getdate()) AS AgeFromLastActivity
,ActivityDate
,ActivityCode
,TC.PayerTeam ContractPayerTeam
,rf.BalanceInsuranceAmount
,rf.BalancePatientAmount
,LEFT(P.PatientPhone, 50) AS PatientPhone
,LEFT(P.PatientFirstName, 50) AS PatientFirstName
,LEFT(P.PatientLastName, 50) AS PatientLastName
, 0 AS LockFlag
, 0 AS RetryCount
FROM (
SELECT F.FacilityCode
    ,F.FacilitySystem
    ,UA.RegistrationID
    ,isnull(AC.Name, UAC.Code) AS ActivityCode
    ,D.DATE AS ActivityDate
    ,dp.Disposition
    ,dp.DispositionID
    ,UA.note
    ,ac.[name]

FROM tbUserActivities ua WITH (NOLOCK)
JOIN tbDATE d WITH (NOLOCK) ON UA.createddatekey = D.datekey
JOIN tbfacility F WITH (NOLOCK) ON UA.FacilityCode = F.FacilityCode
LEFT JOIN tbUserActivityCodes UAC WITH (NOLOCK) ON UA.FacilityCode = UAC.FacilityCode
    AND UAC.UserActivityCodeKey = UA.UserActivityCodeKey
LEFT JOIN accretive.dbo.actions ac WITH (NOLOCK) ON ua.actionid = ac.id
LEFT JOIN tbDisposition dp WITH (NOLOCK) ON ua.DispositionID = dp.DispositionID
WHERE
    -- Pull last activity code per account
    ua.createddatekey = (
        SELECT max(createddatekey)
        FROM tbUserActivities ua1 WITH (NOLOCK)
        LEFT JOIN tbDisposition dp1 WITH (NOLOCK) ON ua1.DispositionID = dp1.DispositionID
        WHERE ua1.facilitycode = ua.facilitycode
            AND ua1.RegistrationID = ua.RegistrationID
            AND dp1.Disposition IS NOT NULL
        )
) D1
INNER JOIN tbregistrationvisit rv WITH (NOLOCK) ON D1.FacilityCode = rv.facilitycode
AND rv.RegistrationID = D1.registrationID
INNER JOIN tbRegistrationFinancial rf WITH (NOLOCK) ON D1.FacilityCode = rf.facilitycode
AND rf.RegistrationID = D1.registrationID
LEFT JOIN tbContractDetail tc WITH (NOLOCK) ON rf.FacilityCode = TC.FacilityCode
AND rf.CurrentPlanCode = TC.FacilityPlanCode
JOIN tbPerson P WITH (NOLOCK) ON RV.FacilityCode = P.FacilityCode
AND rv.PersonID = P.PersonID
JOIN tbplancode pc WITH (NOLOCK) ON rf.FacilityCode = pc.FacilityCode
AND rf.CurrentPlanCode = pc.FacilityPlanCode
LEFT JOIN CID c WITH (NOLOCK) ON D1.FacilityCode = c.facility
LEFT JOIN tbclaims cl WITH (NOLOCK) ON D1.FacilityCode = cl.facilitycode
AND D1.RegistrationID = cl.registrationID
WHERE D1.DispositionID IN (167971, 169162)
" ;


$BIData = Invoke-UdfSQLQuery -connectionString $PSBIDBConnectionString -sqlCommand $Query;

if ($BIData.Success -eq $true) {

    Write-Log -Level INFO -logfile $AALogFilePath -Message "BINextGen query executed successfully.";
}
else {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $BIData.Errors;
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for DB Ingestion completed with errors";
    EXIT 25
}

$BIDataTable = $BIData.DataSet.Tables[0]

if ($BIDataTable.Rows.Count -gt 0) {

    #$BIDataTable | ForEach-Object { $_.note = ($_.note.Split([IO.Path]::GetInvalidFileNameChars()) -join "") };


    $Columns = @{
        EncounterID            = 'AccountNumber'
        FacilityCode           = 'FacilityCode'
        CID                    = 'ePremisCID'
        note                   = 'Note'
        ContractPayer          = 'PayorType'
        CurrentPlanCode        = 'PayerPlanType'
        PayorPlanName          = 'PayerPlanName'
        HandoffType            = 'DispositionWhy'
        Disposition            = 'DispositionWhat'
        AgeFromLastActivity    = 'AgeFromLastActivity'
        ActivityDate           = 'ActivityDueDate'
        ActivityCode           = 'ActivityCode'
        BalanceInsuranceAmount = 'PayerBalance'
        BalancePatientAmount   = 'PatientBalance'
        PatientPhone           = 'PatientPhoneNo'
        PatientFirstName       = 'PatientFirstName'
        PatientLastName        = 'PatientLastName'
        #'Patient Control Number' = 'PatientControlNo'
        LockFlag               = 'LockFlag'
        RetryCount             = 'RetryCount'
        FacilitySystem         = 'ClientName'

    }


    $CopyDatatoSQLParams = @{
        ConnString = $PSDBConnectionString
        TableName  = "SHOV_DC_WorkListTesting"
        ColumnMap  = $Columns
        DataTable  = $BIDataTable
    }

    $CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;



    if ($CopyDataToSQLResponse.Success -eq $true) {


        Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingested in worklist table successfully.";

        $DuplicatesUpdateQuery = "UPDATE W
        SET W.LockFlag = 5
        FROM dbo.SHOV_DC_WorkList AS W
        WHERE W.LockFlag = 0
        AND EXISTS ( SELECT 1
        FROM dbo.SHOV_DC_WorkList AS W1
        WHERE W1.AccountNumber = W.AccountNumber
        AND W1.Note = W.Note
        AND W1.ActivityDueDate = W.ActivityDueDate
        AND W1.LockFlag = 2
        );
        
        WITH CTE AS
        (
        SELECT rn = ROW_NUMBER() OVER(PARTITION BY AccountNumber, ActivityDueDate ORDER BY WorklistID DESC)
        ,LockFlag 
        FROM dbo.SHOV_DC_WorkList
        WHERE LockFlag = 0
        )
        UPDATE CTE
        SET LockFlag = 3
        WHERE rn > 1;
        "
        
        $DupeData = Invoke-UdfSQLQuery -connectionString $PSDBConnectionString -sqlCommand $DuplicatesUpdateQuery;
        
        if ($DupeData.Success -eq $true) {
        
        
            Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingestion completed successfully.";
        }
        else {
            Write-Log -Level FATAL -logfile $AALogFilePath -Message $DupeData.Errors;
            Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingestion completed with errors.";
            Exit 25
        }        
    }
    else {
        Write-Log -Level FATAL -logfile $AALogFilePath -Message $CopyDataToSQLResponse.Errors;
        Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingestion completed with errors.";
        Exit 25
    }

}
else {
    Write-Log -Level INFO -logfile $AALogFilePath -Message "No Data to ingest.";   
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingestion completed successfully.";   
}

Exit 0