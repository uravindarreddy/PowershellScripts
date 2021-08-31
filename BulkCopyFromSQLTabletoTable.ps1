$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
$sqlBulkCopy = New-Object (“Data.SqlClient.SqlBulkCopy”) -ArgumentList $SqlConnection
$sqlBulkCopy.DestinationTableName = “dbo.PersonDet”

$CSVDataTable = Invoke-Sqlcmd -ServerInstance "PRDAMATWSQL01\RPA_DEV" -Database "DTO_DB" -Query "SELECT FullName
, AddressLine1
, AddressLine2
, City
, PostalCode
, StateProvinceCode
FROM dbo.TestPersonDet" -as DataTables 


$Lockflag = New-Object system.Data.DataColumn LockFlag,([tinyint])
$RetryCount = New-Object system.Data.DataColumn RetryCount,([tinyint])

$Lockflag.DefaultValue = 0
$RetryCount.DefaultValue = 0

$CSVDataTable.Columns.Add($Lockflag) 
$CSVDataTable.Columns.Add($RetryCount) 
 



 $CSVDataTable | Out-GridView

 $CSVDataTable | FOREACH-OBJECT {
  write-host "Lockflag: " $_.Lockflag
    write-host "RetryCount: " $_.RetryCount
}

$ColumnMap1 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("FullName", "FullName")
$ColumnMap2 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("AddressLine1", "Line1")
$ColumnMap3 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("AddressLine2", "Line2")
$ColumnMap4 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("City", "City")
$ColumnMap5 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("PostalCode", "ZipCode")
$ColumnMap6 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("StateProvinceCode", "StateCode")

$sqlBulkCopy.ColumnMappings.Add($ColumnMap1)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap2)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap3)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap4)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap5)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap6)

$SqlConnection.Open()
$sqlBulkCopy.WriteToServer($CSVDataTable)
$SqlConnection.Close()