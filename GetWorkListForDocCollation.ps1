$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source=AUTOMATE02;Integrated Security=SSPI;Initial Catalog=DTO_DB"
$sqlBulkCopy = New-Object ("Data.SqlClient.SqlBulkCopy") -ArgumentList $SqlConnection
$sqlBulkCopy.DestinationTableName = "dbo.SHOV_DC_WorkList"

$CSVDataTable = Invoke-Sqlcmd -ServerInstance "AHS-A2RSAS01" -Database "BINEXTGEN" -Query "Select RV.EncounterID,
	   D1.RegistrationID,	
       D1.FacilityCode,
       D1.FacilityGroupName,
	   c.CID,
	   D1.note,
	   tc.ContractPayer,
	   rf.CurrentPlanCode,
	   pc.PayorName,
	   pc.PayorPlanName,
	   D1.[name] as 'Hand off Type',
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
	   cl.claimno as 'Patient Control Number'
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
	ua.createddatekey=(select max(createddatekey) from tbUserActivities WITH (NOLOCK) where facilitycode=ua.facilitycode and RegistrationID=ua.RegistrationID)    
       )D1
Inner join tbregistrationvisit rv WITH (NOLOCK) on D1.FacilityCode=rv.facilitycode and rv.RegistrationID=D1.registrationID
Inner Join tbRegistrationFinancial rf with (nolock) on D1.FacilityCode=rf.facilitycode and rf.RegistrationID=D1.registrationID
left join tbContractDetail tc with (nolock) on rf.FacilityCode=TC.FacilityCode and rf.CurrentPlanCode=TC.FacilityPlanCode
Join tbPerson P with (Nolock) on RV.FacilityCode=P.FacilityCode and rv.PersonID=P.PersonID
join tbplancode pc with (nolock) on rf.FacilityCode=pc.FacilityCode and rf.CurrentPlanCode=pc.FacilityPlanCode
left join CID c with (nolock) on D1.FacilityCode=c.facility
left join tbclaims cl with (nolock) on D1.FacilityCode=cl.facilitycode and D1.RegistrationID=cl.registrationID
WHERE D1.DispositionID='167971'" -OutputAs DataTables


$Lockflag = New-Object system.Data.DataColumn LockFlag,([int])
$RetryCount = New-Object system.Data.DataColumn RetryCount,([int])

$Lockflag.DefaultValue = 0
$RetryCount.DefaultValue = 0

$CSVDataTable.Columns.Add($Lockflag) 
$CSVDataTable.Columns.Add($RetryCount) 


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
$ColumnMap22 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("Patient Control Number", "PatientControlNo")
$ColumnMap23 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("Lockflag", "LockFlag")
$ColumnMap24 = New-Object System.Data.SqlClient.SqlBulkCopyColumnMapping("RetryCount", "RetryCount")


$sqlBulkCopy.ColumnMappings.Add($ColumnMap1)
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap2)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap3)
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap4)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap5)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap6)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap7)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap8)
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap9)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap10)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap11)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap12)
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap13)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap14)
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap15)
#$sqlBulkCopy.ColumnMappings.Add($ColumnMap16)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap17)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap18)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap19)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap20)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap21)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap22)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap23)
$sqlBulkCopy.ColumnMappings.Add($ColumnMap24)


$SqlConnection.Open()
$sqlBulkCopy.WriteToServer($CSVDataTable)
$SqlConnection.Close()


