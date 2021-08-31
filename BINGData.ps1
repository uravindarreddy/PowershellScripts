$NPICrossWalkPath = "C:\NPICrosswalk.csv" #### NPI Crosswalk file path
$PCN = "1841298999" #### PCN/PAN
$NPI = "1841298999" #### NPI

If (Test-path -Path $NPICrossWalkPath)
{


$NPIData = Import-Csv -Path $NPICrossWalkPath


$f = $NPIData | where {$_.NPI -eq "1841298999"} | Select-Object facilitycode | ConvertTo-Csv -NoTypeInformation  | select -skip 1

$d = [string]::Join(",",$f).replace("""","'")

    
$SQLQuery = "SELECT DISTINCT [Claim Number],[Account Number],Facility FROM ClaimEditMaster WITH(NOLOCK)
WHERE [Claim Number] = '$PCN' And Facility IN ($d)"


$BINGData = Invoke-Sqlcmd -ServerInstance "AHS-A2RSAS01" -Database "BINEXTGEN" -Query $SQLQuery

IF ($BINGData)
{
$BINGData | Out-GridView
}
else
{
    Write-Host "NO Data Found" -ForegroundColor Magenta
}
}
else
{
    Write-Host "NO File Found" -ForegroundColor Magenta
}