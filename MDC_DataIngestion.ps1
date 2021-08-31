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

#region Functions
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
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath; "RequestID" = ""; Message = $Message }
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
#endregion Functions


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

$Query = "Select Distinct RV.EncounterID,
D1.RegistrationID,
D1.FacilityCode,
D1.FacilityGroupName,
c.CID as 'ClientID',
D1.note,
tc.ContractPayer,
rf.CurrentPlanCode,
pc.PayorName,
pc.PayorPlanName,
D1.[name] as 'HandoffType',
D1.Disposition,
Datediff(D,ActivityDate,Getdate()) as AgeFromLastActivity,
ActivityDate,
ActivityCode,
TC.PayerTeam ContractPayerTeam,
rf. BalanceInsuranceAmount,
rf. BalancePatientAmount,
P.PatientPhone,
P.PatientFirstName,
P.PatientLastName,
rv.AdmitDateKey,
rv.DischargeDateKey,
p.mrn,
p.DOB,
cl.claimno as 'ClaimNumber' 
From(
Select
F.FacilityCode,
F.FacilityGroupName,
UA.RegistrationID,
isnull(AC.Name,UAC.Code) as ActivityCode,
D.date as ActivityDate,
dp.Disposition,
dp.DispositionID,
UA.note,
ac.[name]
from tbUserActivities ua WITH (NOLOCK)
Join tbDATE d WITH (Nolock) on UA.createddatekey=D.datekey
Join tbfacility F with (Nolock) on UA.FacilityCode=F.FacilityCode
Left join tbUserActivityCodes UAC with (Nolock) on UA.FacilityCode=UAC.FacilityCode and UAC.UserActivityCodeKey=UA.UserActivityCodeKey
Left join accretive.dbo.actions ac with (Nolock) on ua.actionid=ac.id
Left join tbDisposition dp with (nolock) on ua.DispositionID=dp.DispositionID
where
-- Pull last activity code per account
ua.createddatekey=(select max(createddatekey) from tbUserActivities ua1 WITH (NOLOCK) left join tbDisposition dp1 with (nolock) on ua1.DispositionID=dp1.DispositionID where ua1.facilitycode=ua.facilitycode and ua1.RegistrationID=ua.RegistrationID and dp1.Disposition is not null)
)D1
Inner join tbregistrationvisit rv WITH (NOLOCK) on D1.FacilityCode=rv.facilitycode and rv.RegistrationID=D1.registrationID
Inner Join tbRegistrationFinancial rf with (nolock) on D1.FacilityCode=rf.facilitycode and rf.RegistrationID=D1.registrationID
left join tbContractDetail tc with (nolock) on rf.FacilityCode=TC.FacilityCode and rf.CurrentPlanCode=TC.FacilityPlanCode
Join tbPerson P with (Nolock) on RV.FacilityCode=P.FacilityCode and rv.PersonID=P.PersonID
join tbplancode pc with (nolock) on rf.FacilityCode=pc.FacilityCode and rf.CurrentPlanCode=pc.FacilityPlanCode
left join CID c with (nolock) on D1.FacilityCode=c.facility
left join tbclaims cl with (nolock) on D1.FacilityCode=cl.facilitycode and D1.RegistrationID=cl.registrationID
-- Only provide records where SHOV Ready for Bot is the disposition on the last activity code
where D1.DispositionID in ('182108','182109')
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
        LockFlag               = 'LockFlag'
        RetryCount             = 'RetryCount'
        FacilitySystem         = 'ClientName'
        ClaimNumber = 'ClaimNumber'

    }


    $CopyDatatoSQLParams = @{
        ConnString = $PSDBConnectionString
        TableName  = "SHOV_MultiDoc_WorkList"
        ColumnMap  = $Columns
        DataTable  = $BIDataTable
    }

    $CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;



    if ($CopyDataToSQLResponse.Success -eq $true) {


        Write-Log -Level INFO -logfile $AALogFilePath -Message "Data ingested in worklist table successfully.";

        $DuplicatesUpdateQuery = "UPDATE W
        SET W.LockFlag = 5
        FROM dbo.SHOV_MultiDoc_WorkList AS W
        WHERE W.LockFlag = 0
        AND EXISTS ( SELECT 1
        FROM dbo.SHOV_MultiDoc_WorkList AS W1
        WHERE W1.AccountNumber = W.AccountNumber
        AND W1.Note = W.Note
        AND W1.ActivityDueDate = W.ActivityDueDate
        AND W1.LockFlag IN (2,3,4)
        );
        
        WITH CTE AS
        (
        SELECT rn = ROW_NUMBER() OVER(PARTITION BY AccountNumber, ActivityDueDate ORDER BY WorklistID DESC)
        ,LockFlag 
        FROM dbo.SHOV_MultiDoc_WorkList
        WHERE LockFlag = 0
        )
        UPDATE CTE
        SET LockFlag = 3 --- Duplicate on single execution
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