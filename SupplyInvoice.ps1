 $s = import-csv -LiteralPath "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\HCFA\csvextracts\IMG_SupplyInvoice_ExtractedData.csv"

 


 Function New-WorkListTable {
    ###Creating a new DataTable###
    $tempTable = New-Object System.Data.DataTable
   
    ##Creating Columns for DataTable##
    $tempTable.Columns.Add("CombinedFileName","string") | Out-Null
    $tempTable.Columns.Add("IndividualFileName","string") | Out-Null
    $tempTable.Columns.Add("InvoiceNumber","string") | Out-Null
    $tempTable.Columns.Add("PatientName","string") | Out-Null
    $tempTable.Columns.Add("PageNo","int32") | Out-Null
    $tempTable.Columns.Add("ClaimNumber","string") | Out-Null
    $tempTable.Columns.Add("DateOfService","datetime") | Out-Null
    $tempTable.Columns.Add("LockFlag","byte") | Out-Null
    $tempTable.Columns.Add("RetryCount","byte") | Out-Null
    $tempTable.Columns.Add("InsertedOn","datetime") | Out-Null
           
       
    return ,$tempTable
}

[System.Data.DataTable]$SupplyInvoiceTable = New-WorkListTable;

 foreach ($i in $s){


            $row = $SupplyInvoiceTable.NewRow()

            #set the properties of each row from the data
            $row.CombinedFileName = $i.CombinedFileName
            $row.IndividualFileName = $null
            $row.InvoiceNumber = $i.InvoiceNumber
            $row.PatientName = $i.PatientName
            $row.PageNo  = $i.PageNo
            if (($i.ClaimNumber -eq $null) -or ($i.ClaimNumber -eq "") -or ($i.ClaimNumber.Length -eq 0)){
            $row.ClaimNumber = $null
            }
            else{
            $row.ClaimNumber = $i.ClaimNumber
            }

            $row.DateOfService = $i.DateOfService
            $row.LockFlag = 0
            $row.RetryCount = 0
            $row.InsertedOn = [datetime](Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")

            $SupplyInvoiceTable.Rows.Add($row);
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
CombinedFileName = 'CombinedFileName'
IndividualFileName = 'IndividualFileName'
InvoiceNumber = 'InvoiceNumber'
PatientName = 'PatientName'
PageNo = 'PageNo'
ClaimNumber = 'ClaimNumber'
DateOfService = 'DateOfService'
LockFlag = 'LockFlag'
RetryCount = 'RetryCount'
InsertedOn = 'InsertedOn'
         }

$CopyDatatoSQLParams = @{
        ConnString = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
        TableName = "SHOV_IMGWM_SupplyInvoice_DataTesting"
        ColumnMap = $Columns
        DataTable = $SupplyInvoiceTable
    }

$CopyDataToSQLResponse = Write-udfDataTableToSQLTable @CopyDatatoSQLParams;

$CopyDataToSQLResponse.Errors

