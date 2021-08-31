$data = Get-Content "\\R1-UEM-1\UEM_Profiles\US35107\profile\Downloads\NoteErrorfile_9th november.txt"

$datatable = New-Object System.Data.DataTable;


$datatable.Columns.Add("EncounterID")
$datatable.Columns.Add("RegistrationID")
$datatable.Columns.Add("FacilityCode")
$datatable.Columns.Add("FacilityGroupName")
$datatable.Columns.Add("CID")
$datatable.Columns.Add("note")
$datatable.Columns.Add("ContractPayer")
$datatable.Columns.Add("CurrentPlanCode")
$datatable.Columns.Add("PayorName")
$datatable.Columns.Add("PayorPlanName")
$datatable.Columns.Add("Hand off Type")
$datatable.Columns.Add("Disposition")
$datatable.Columns.Add("AgeFromLastActivity")
$datatable.Columns.Add("ActivityDate")
$datatable.Columns.Add("ActivityCode")
$datatable.Columns.Add("ContractPayerTeam")
$datatable.Columns.Add("BalanceInsuranceAmount")
$datatable.Columns.Add("BalancePatientAmount")
$datatable.Columns.Add("PatientPhone")
$datatable.Columns.Add("PatientFirstName")
$datatable.Columns.Add("PatientLastName")
$datatable.Columns.Add("LockFlag")
$datatable.Columns.Add("RetryCount")



for($i = 0; $i -lt $data.Count ; $i = $i+23){

        $row = $datatable.NewRow()

        for($j=0;$j -le 22;$j++)
        {


        if ( $data[($i+$j)].Contains(":")) {
        
            if ( $data[($i+$j)].Split(":").Count -gt 1){
            

            $row[($data[($i+$j)].Split(":")[0].Trim())] = $data[($i+$j)].Split(":")[1].Trim()
            }

            }
            else
            {
                "Nothing"
            }
            
        }

        $datatable.Rows.Add($row) | Out-Null

}



$datatable | Out-GridView

$sqlconn = New-Object System.Data.SqlClient.SqlConnection
$sqlconn.ConnectionString = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
$bulkCopy = New-Object ("Data.SqlClient.SqlBulkCopy") -ArgumentList $sqlconn



        $bulkCopy.DestinationTableName = "BI_Worklist"
        $bulkCopy.BatchSize = 75000


        $sqlconn.Open()
$bulkCopy.WriteToServer($datatable)
$bulkCopy.Close()
$bulkCopy.Dispose()

$sqlconn.Close()
$sqlconn.Dispose()


$datatable.Clear()