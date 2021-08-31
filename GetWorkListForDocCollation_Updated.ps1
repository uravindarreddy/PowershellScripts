$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source=AUTOMATE02;Integrated Security=SSPI;Initial Catalog=DTO_DB"
$sqlBulkCopy = New-Object ("Data.SqlClient.SqlBulkCopy") -ArgumentList $SqlConnection
$sqlBulkCopy.DestinationTableName = "dbo.SHOV_DC_WorkList"

$CSVDataTable = Invoke-Sqlcmd -ServerInstance "AHS-A2RSAS01" -Database "BINEXTGEN" -Query "SELECT DISTINCT RV.EncounterID
	,D1.RegistrationID
	,D1.FacilityCode
	,D1.FacilityGroupName
	,c.CID
	,D1.note
	,tc.ContractPayer
	,rf.CurrentPlanCode
	,pc.PayorName
	,pc.PayorPlanName
	,D1.[name] AS 'Hand off Type'
	,D1.Disposition
	,Datediff(D, ActivityDate, Getdate()) AS AgeFromLastActivity
	,ActivityDate
	,ActivityCode
	,TC.PayerTeam ContractPayerTeam
	,rf.BalanceInsuranceAmount
	,rf.BalancePatientAmount
	,P.PatientPhone
	,P.PatientFirstName
	,P.PatientLastName
--	   cl.claimno as 'Patient Control Number'  Remove per Kendall 10/28/20
FROM (
	SELECT F.FacilityCode
		,F.FacilityGroupName
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
			FROM tbUserActivities WITH (NOLOCK)
			WHERE facilitycode = ua.facilitycode
				AND RegistrationID = ua.RegistrationID
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
-- Only provide records where SHOV Ready for Bot is the disposition on the last activity code
WHERE D1.DispositionID IN ('167971', '169162')" -OutputAs DataTables


$Lockflag = New-Object system.Data.DataColumn LockFlag,([int])
$RetryCount = New-Object system.Data.DataColumn RetryCount,([int])

$Lockflag.DefaultValue = 0
$RetryCount.DefaultValue = 0

$CSVDataTable.Columns.Add($Lockflag) 
$CSVDataTable.Columns.Add($RetryCount)



if ($CSVDataTable.Rows.Count -gt 0) {

$DCDataTable = Invoke-Sqlcmd -ServerInstance "AUTOMATE02" -Database "DTO_DB" -Query "SELECT * FROM dbo.SHOV_DC_WorkList" -OutputAs DataTables

$CSVDataTable = $CSVDataTable | Where-Object { ($DCDataTable.AccountNumber -notcontains $_.EncounterID) -or  ($DCDataTable.note -notcontains $_.note)} | Where-Object note -Like "*.pdf*"

#### Replacing special characters in the note field 
### Used system function [IO.Path]::GetInvalidFileNameChars() to identify the special characters
$CSVDataTable | foreach {$_.note = ($_.note.Split([IO.Path]::GetInvalidFileNameChars()) -join "")}

Invoke-Sqlcmd -ServerInstance "AUTOMATE02" -Database "DTO_DB" -Query ";WITH CTE AS
(
SELECT rn = ROW_NUMBER() OVER(PARTITION BY AccountNumber order by WorklistID DESC)
,* 
FROM SHOV_DC_WorkList
WHERE LockFlag = 0
)
UPDATE CTE
SET LockFlag = 3
WHERE rn > 1;" | Out-Null;

<#
$RowsWithInvalidNote = $CSVDataTable | Where-Object { ($_.note.Split([IO.Path]::GetInvalidFileNameChars()).Count -gt 1 -or $_.note.Split(",")[0].Split([IO.Path]::GetInvalidFileNameChars()).Count -gt 1 ) }

$CSVDataTable = $CSVDataTable | Where-Object { ($RowsWithInvalidNote.EncounterID -notcontains $_.EncounterID) -or  ($RowsWithInvalidNote.note -notcontains $_.note)}

$noteErrorFile = -join ( ([System.Io.Path]::GetTempPath()) , "NoteErrorfile.txt")

$RowsWithInvalidNote | Out-File $noteErrorFile

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

if ($CSVDataTable.Rows.Count -gt 0){
$SqlConnection.Open()
$sqlBulkCopy.WriteToServer($CSVDataTable)
$SqlConnection.Close()
$SqlConnection.Dispose()
}
else {
Write-Host "No Data to insert" -BackgroundColor Magenta;
}
}
else {
Write-Host "No Data to insert" -BackgroundColor Magenta;
}


$null = $sqlBulkCopy.Close()
$null = $sqlBulkCopy.Dispose()
$null = $DCDataTable.Clear()
$null = $DCDataTable.Dispose()
