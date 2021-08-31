 $h = import-csv -LiteralPath "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\HCFA\csvextracts\IMG_HCFA_ExtractedData.csv"




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
           
       
    return ,$tempTable
}

[System.Data.DataTable]$HCFAClaimTable = New-HCFAWorkListTable;

 foreach ($j in $h){


            $row = $HCFAClaimTable.NewRow()

            #set the properties of each row from the data
            $row.CombinedFileName = $j.CombinedFileName
            $row.IndividualFileName = $null
            $row.InvoiceNumber = $j.InvoiceNumber
            $row.PatientName = $j.PatientName
            $row.PageNo  = $j.PageNO

            $row.Address = $j.Address
            $row.CPT1  = $j.'CTP 1'
            $row.CPT2 = $j.'CTP 2'
            $row.CPT3  = $j.'CTP 3'
            $row.CPT4 = $j.'CTP 4'
            $row.CPT5 = $j.'CTP 5'
            $row.CPT6 = $j.'CTP  6'
            if ($j.'Missing/Bad Address'.Trim().Length -eq 0){

            }
            else {
            $row.BadAddressFlag = $j.'Missing/Bad Address'
            }

            $row.LockFlag = 0
            $row.RetryCount = 0
            $row.InsertedOn = [datetime](Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")

            $HCFAClaimTable.Rows.Add($row);
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
$Columns = @{
CombinedFileName	=	'CombinedFileName'
IndividualFileName	=	'IndividualFileName'
InvoiceNumber	=	'InvoiceNumber'
PatientName	=	'PatientName'
Address	=	'Address'
CPT1	=	'CPT1'
CPT2	=	'CPT2'
CPT3	=	'CPT3'
CPT4	=	'CPT4'
CPT5	=	'CPT5'
CPT6	=	'CPT6'
PageNo	=	'PageNo'
BadAddressFlag	=	'BadAddressFlag'
InsertedOn	=	'InsertedOn'
StartProcessTime	=	'StartProcessTime'
EndProcessTime	=	'EndProcessTime'
LockFlag	=	'LockFlag'
RetryCount	=	'RetryCount'

         }

$CopyDatatoSQLParams = @{
        ConnString = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
        TableName = "SHOV_IMGWM_HCFA_DataTesting"
        ColumnMap = $Columns
        DataTable = $HCFAClaimTable
    }

$CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;

$CopyDataToSQLResponse.Errors

