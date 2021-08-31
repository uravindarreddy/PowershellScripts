[CmdletBinding()]
param (
    [string] $PSDBConnectionString
    , [string] $HCFAcsvFilePath
    , [string] $SupplyInvoicecsvFilePath
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
    Write-Output "Connection String is missing"
    Exit 101
}

if ($HCFAcsvFilePath.Trim() -eq [string]$null) {
    Write-Output "The csv file path for HCFA is missing"
    Exit 102
}

if ($SupplyInvoicecsvFilePath.Trim() -eq [string]$null) {
    Write-Output "The csv file path for Supply Invoice is missing"
    Exit 103
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
            Write-Output $_.Exception.Message;
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

Function New-HCFAWorkListTable {
    ###Creating a new DataTable###
    $tempTable = New-Object System.Data.DataTable
   
    ##Creating Columns for DataTable##
    
    $tempTable.Columns.Add("CombinedFileName", "string") | Out-Null
    $tempTable.Columns.Add("IndividualFileName", "string") | Out-Null
    $tempTable.Columns.Add("InvoiceNumber", "string") | Out-Null
    $tempTable.Columns.Add("PatientName", "string") | Out-Null
    $tempTable.Columns.Add("Address", "string") | Out-Null
    $tempTable.Columns.Add("CPT1", "string") | Out-Null
    $tempTable.Columns.Add("CPT2", "string") | Out-Null
    $tempTable.Columns.Add("CPT3", "string") | Out-Null
    $tempTable.Columns.Add("CPT4", "string") | Out-Null
    $tempTable.Columns.Add("CPT5", "string") | Out-Null
    $tempTable.Columns.Add("CPT6", "string") | Out-Null
    $tempTable.Columns.Add("PageNo", "int32") | Out-Null
    $tempTable.Columns.Add("BadAddressFlag", "byte?") | Out-Null
    $tempTable.Columns.Add("InsertedOn", "datetime") | Out-Null
    $tempTable.Columns.Add("StartProcessTime", "datetime") | Out-Null
    $tempTable.Columns.Add("EndProcessTime", "datetime") | Out-Null
    $tempTable.Columns.Add("LockFlag", "byte") | Out-Null
    $tempTable.Columns.Add("RetryCount", "byte") | Out-Null
           
       
    return , $tempTable
}

Function New-SupplyInvWorkListTable {
    ###Creating a new DataTable###
    $tempTable = New-Object System.Data.DataTable
   
    ##Creating Columns for DataTable##
    $tempTable.Columns.Add("CombinedFileName", "string") | Out-Null
    $tempTable.Columns.Add("IndividualFileName", "string") | Out-Null
    $tempTable.Columns.Add("InvoiceNumber", "string") | Out-Null
    $tempTable.Columns.Add("PatientName", "string") | Out-Null
    $tempTable.Columns.Add("PageNo", "int32") | Out-Null
    $tempTable.Columns.Add("ClaimNumber", "string") | Out-Null
    $tempTable.Columns.Add("DateOfService", "datetime") | Out-Null
    $tempTable.Columns.Add("LockFlag", "byte") | Out-Null
    $tempTable.Columns.Add("RetryCount", "byte") | Out-Null
    $tempTable.Columns.Add("InsertedOn", "datetime") | Out-Null
           
       
    return , $tempTable
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


Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for csv file import Inititiated";
$isErrorExit = $false;

$DBTestConnection = Test-SQLConnection $PSDBConnectionString
if ($DBTestConnection.Success -eq $false) {        
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $DBTestConnection.Errors.Exception.Message;
    $isErrorExit = $true
}
if (!(Test-Path -Path $HCFAcsvFilePath -PathType Leaf)) {
    $isErrorExit = $true
    Write-Log -Level FATAL -logfile $AALogFilePath -Message "The file path for HCFA does not exist.";
}
elseif ([System.IO.Path]::GetExtension($HCFAcsvFilePath) -ne ".csv") {
    $isErrorExit = $true
    Write-Log -Level FATAL -logfile $AALogFilePath -Message "The HCFA file provided is not csv.";
}

if (!(Test-Path -Path $SupplyInvoicecsvFilePath -PathType Leaf)) {
    $isErrorExit = $true
    Write-Log -Level FATAL -logfile $AALogFilePath -Message "The file path for Supply Invoice does not exist.";
}
elseif ([System.IO.Path]::GetExtension($SupplyInvoicecsvFilePath) -ne ".csv") {
    $isErrorExit = $true
    Write-Log -Level FATAL -logfile $AALogFilePath -Message "The Supply Invoice file provided is not csv.";
}


if ($isErrorExit) {
    Write-Host "Errors reported in AA LogFilePath."
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for csv file import completed";
    Exit 1000
}

try {
    $HCFAcsvData = Import-Csv -Path $HCFAcsvFilePath;
}
catch {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $_.Exception.Message;
    Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for csv file import completed with errors";
    Exit 1
}

[System.Data.DataTable]$HCFAClaimTable = New-HCFAWorkListTable;
$hcfaloopcounter = 1
foreach ($hcfacsvrow in $HCFAcsvData) {

    try {
        $HCFAClaimTablerow = $HCFAClaimTable.NewRow()

        #set the properties of each row from the data
        $HCFAClaimTablerow.CombinedFileName = $hcfacsvrow.CombinedFileName
        $HCFAClaimTablerow.IndividualFileName = $hcfacsvrow.IndividualFileName
        $HCFAClaimTablerow.InvoiceNumber = $hcfacsvrow.InvoiceNumber
        $HCFAClaimTablerow.PatientName = $hcfacsvrow.PatientName
        $HCFAClaimTablerow.PageNo = $hcfacsvrow.PageNO

        $HCFAClaimTablerow.Address = $hcfacsvrow.Address
        if ($hcfacsvrow.CPT1.Trim().Length -gt 0) {
            $HCFAClaimTablerow.CPT1 = $hcfacsvrow.CPT1
        }
        if ($hcfacsvrow.CPT2.Trim().Length -gt 0) {
            $HCFAClaimTablerow.CPT2 = $hcfacsvrow.CPT2
        }
        if ($hcfacsvrow.CPT3.Trim().Length -gt 0) {
            $HCFAClaimTablerow.CPT3 = $hcfacsvrow.CPT3
        }
        if ($hcfacsvrow.CPT4.Trim().Length -gt 0) {
            $HCFAClaimTablerow.CPT4 = $hcfacsvrow.CPT4
        }
        if ($hcfacsvrow.CPT5.Trim().Length -gt 0) {
            $HCFAClaimTablerow.CPT5 = $hcfacsvrow.CPT5
        }
        if ($hcfacsvrow.CPT6.Trim().Length -gt 0) {
            $HCFAClaimTablerow.CPT6 = $hcfacsvrow.CPT6
        }
        
        if ($hcfacsvrow.BadAddress.Trim().Length -gt 0) {
            $HCFAClaimTablerow.BadAddressFlag = $hcfacsvrow.BadAddress
        }

        $HCFAClaimTablerow.LockFlag = 0
        $HCFAClaimTablerow.RetryCount = 0
        $HCFAClaimTablerow.InsertedOn = [datetime](Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")
   

        $HCFAClaimTable.Rows.Add($HCFAClaimTablerow);

    }
    catch {
        Write-Log -Level ERROR -logfile $AALogFilePath -Message "Error occurred at csv row $hcfaloopcounter";        
        Write-Log -Level ERROR -logfile $AALogFilePath -Message $_.Exception.Message;
        continue;
    }

    $hcfaloopcounter = $hcfaloopcounter + 1;
}

$HCFAColumns = @{
    CombinedFileName   =	'CombinedFileName'
    IndividualFileName	=	'IndividualFileName'
    InvoiceNumber      =	'InvoiceNumber'
    PatientName        =	'PatientName'
    Address            =	'Address'
    CPT1               =	'CPT1'
    CPT2               =	'CPT2'
    CPT3               =	'CPT3'
    CPT4               =	'CPT4'
    CPT5               =	'CPT5'
    CPT6               =	'CPT6'
    PageNo             =	'PageNo'
    BadAddressFlag     =	'BadAddressFlag'
    InsertedOn         =	'InsertedOn'
    StartProcessTime   =	'StartProcessTime'
    EndProcessTime     =	'EndProcessTime'
    LockFlag           =	'LockFlag'
    RetryCount         =	'RetryCount'

}
$CopyDatatoSQLParams = @{
    ConnString = $PSDBConnectionString
    TableName  = "SHOV_IMGWM_HCFA_DataTesting"
    ColumnMap  = $HCFAColumns
    DataTable  = $HCFAClaimTable
}

$CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;

if ($CopyDataToSQLResponse.Success -eq $true) {


    Write-Log -Level INFO -logfile $AALogFilePath -Message "HCFA csv file data imported successfully.";
}
else {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $CopyDataToSQLResponse.Errors;
}

try {
    $SupplyInvcsvData = Import-Csv -Path $SupplyInvoicecsvFilePath;
}
catch {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $_.Exception.Message;
}

[System.Data.DataTable]$SupplyInvoiceTable = New-SupplyInvWorkListTable;
[int]$SupplyLoopCounter = 1
foreach ($SupplyInvcsvrow in $SupplyInvcsvData) {

    try {
        $SupplyInvoiceTablerow = $SupplyInvoiceTable.NewRow()

        #set the properties of each row from the data
    
        $SupplyInvoiceTablerow.CombinedFileName = $SupplyInvcsvrow.CombinedFileName
        $SupplyInvoiceTablerow.IndividualFileName = $SupplyInvcsvrow.SplitFileName
        $SupplyInvoiceTablerow.InvoiceNumber = $SupplyInvcsvrow.InvoiceNumber
        $SupplyInvoiceTablerow.PatientName = $SupplyInvcsvrow.PatientName
        $SupplyInvoiceTablerow.PageNo = $SupplyInvcsvrow.PageNo
        if ($SupplyInvcsvrow.ClaimNumber.Length -gt 0) {
            $SupplyInvoiceTablerow.ClaimNumber = $SupplyInvcsvrow.ClaimNumber
        }
        $SupplyInvoiceTablerow.DateOfService = $SupplyInvcsvrow.DateOfService
        $SupplyInvoiceTablerow.LockFlag = 0
        $SupplyInvoiceTablerow.RetryCount = 0
        $SupplyInvoiceTablerow.InsertedOn = [datetime](Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")

        $SupplyInvoiceTable.Rows.Add($SupplyInvoiceTablerow);
    }
    catch {
        Write-Log -Level ERROR -logfile $AALogFilePath -Message "Error occurred at csv row $SupplyLoopCounter";        
        Write-Log -Level ERROR -logfile $AALogFilePath -Message $_.Exception.Message;
        continue;
    }

    $SupplyLoopCounter = $SupplyLoopCounter + 1;
}

$SupplyInvoiceColumns = @{
    CombinedFileName   = 'CombinedFileName'
    IndividualFileName = 'IndividualFileName'
    InvoiceNumber      = 'InvoiceNumber'
    PatientName        = 'PatientName'
    PageNo             = 'PageNo'
    ClaimNumber        = 'ClaimNumber'
    DateOfService      = 'DateOfService'
    LockFlag           = 'LockFlag'
    RetryCount         = 'RetryCount'
    InsertedOn         = 'InsertedOn'

}
$CopyDatatoSQLParams = @{
    ConnString = $PSDBConnectionString
    TableName  = "SHOV_IMGWM_SupplyInvoice_DataTesting"
    ColumnMap  = $SupplyInvoiceColumns
    DataTable  = $SupplyInvoiceTable
}

$CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;

if ($CopyDataToSQLResponse.Success -eq $true) {

    Write-Log -Level INFO -logfile $AALogFilePath -Message "Supply Invoice csv file data imported successfully.";
}
else {
    Write-Log -Level FATAL -logfile $AALogFilePath -Message $CopyDataToSQLResponse.Errors;
}
Write-Log -Level INFO -logfile $AALogFilePath -Message "Powershell Execution for csv file import completed";
Exit 0