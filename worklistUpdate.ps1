$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
$sqlBulkCopy = New-Object ("Data.SqlClient.SqlBulkCopy") -ArgumentList $SqlConnection
$sqlBulkCopy.DestinationTableName = "dbo.SHOV_DC_WorkList"

$CSVDataTable = Invoke-Sqlcmd -ServerInstance "PRDAMATWSQL01\RPA_DEV" -Database "DTO_DB" -Query "SELECT * FROM BI_Worklist" -OutputAs DataTables


$Lockflag = New-Object system.Data.DataColumn LockFlag,([int])
$RetryCount = New-Object system.Data.DataColumn RetryCount,([int])

$Lockflag.DefaultValue = 0
$RetryCount.DefaultValue = 0

#$CSVDataTable.Columns.Add($Lockflag) 
#$CSVDataTable.Columns.Add($RetryCount)



if ($CSVDataTable.Rows.Count -gt 0) {

$DCDataTable = Invoke-Sqlcmd -ServerInstance "PRDAMATWSQL01\RPA_DEV" -Database "DTO_DB" -Query "SELECT * FROM dbo.SHOV_DC_WorkList" -OutputAs DataTables

$CSVDataTable = $CSVDataTable | Where-Object { ($DCDataTable.AccountNumber -notcontains $_.EncounterID) -or  ($DCDataTable.note -notcontains $_.note)} | Where-Object note -Like "*.pdf*"
$CSVDataTable.Rows.Count
$CSVDataTable | foreach {$_.note = ($_.note.Split([IO.Path]::GetInvalidFileNameChars()) -join "")}

<#
$RowsWithInvalidNote = $CSVDataTable | Where-Object { ($_.note.Split([IO.Path]::GetInvalidFileNameChars()).Count -gt 1 -or $_.note.Split(",")[0].Split([IO.Path]::GetInvalidFileNameChars()).Count -gt 1 ) }

$CSVDataTable = $CSVDataTable | Where-Object { ($RowsWithInvalidNote.EncounterID -notcontains $_.EncounterID) -or  ($RowsWithInvalidNote.note -notcontains $_.note)}

$noteErrorFile = -join ( ([System.Io.Path]::GetTempPath()) , "NoteErrorfile.txt")

$RowsWithInvalidNote | Out-File $noteErrorFile;

if (Test-Path $noteErrorFile -PathType Leaf){
    Invoke-Item $noteErrorFile;
}
#>
$ColumnMap1 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("EncounterID", "AccountNumber")
#$ColumnMap2 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("RegistrationID", "")
$ColumnMap3 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("FacilityCode", "FacilityCode")
#$ColumnMap4 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("FacilityGroupName", "")
$ColumnMap5 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("CID", "ePremisCID")
$ColumnMap6 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("note", "Note")
$ColumnMap7 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("ContractPayer", "PayorType")
$ColumnMap8 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("CurrentPlanCode", "PayerPlanType")
#$ColumnMap9 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("PayorName", "")
$ColumnMap10 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("PayorPlanName", "PayerPlanName")
$ColumnMap11 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("Hand off Type", "DispositionWhy")
$ColumnMap12 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("Disposition", "DispositionWhat")
#$ColumnMap13 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("AgeFromLastActivity", "")
$ColumnMap14 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("ActivityDate", "ActivityDueDate")
#$ColumnMap15 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("ActivityCode", "")
#$ColumnMap16 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("ContractPayerTeam", "")
$ColumnMap17 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("BalanceInsuranceAmount", "PayerBalance")
$ColumnMap18 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("BalancePatientAmount", "PatientBalance")
$ColumnMap19 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("PatientPhone", "PatientPhoneNo")
$ColumnMap20 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("PatientFirstName", "PatientFirstName")
$ColumnMap21 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("PatientLastName", "PatientLastName")
#$ColumnMap22 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("Patient Control Number", "PatientControlNo")
$ColumnMap23 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("Lockflag", "LockFlag")
$ColumnMap24 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("RetryCount", "RetryCount")


$sqlBulkCopy.ColumnMappings.Add($ColumnMap1) | out-null
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap2) | OUt-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap3) | out-null
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap4) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap5) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap6) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap7) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap8) | out-null
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap9) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap10) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap11)| out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap12)| out-null
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap13) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap14) | out-null
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap15) | out-null
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap16) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap17) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap18) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap19) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap20) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap21) | out-null
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap22) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap23) | out-null
$sqlBulkCopy.ColumnMappings.Add($ColumnMap24) | out-null

$CSVDataTable.Rows.Count

if ($CSVDataTable.Rows.Count -gt 0){
$SqlConnection.Open()
$sqlBulkCopy.WriteToServer($CSVDataTable)
$SqlConnection.Close()
$SqlConnection.Dispose()
}
else {
Write-Host "No Data to insert after validation" -BackgroundColor Magenta;
}
}
else {
Write-Host "No Data to insert" -BackgroundColor Magenta;
}


$null = $sqlBulkCopy.Close()
$null = $sqlBulkCopy.Dispose()
$null = $DCDataTable.Clear()
$null = $DCDataTable.Dispose()
