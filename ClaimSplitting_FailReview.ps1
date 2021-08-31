
$QueryParams = @{
    ServerInstance = "AUTOMATE02"
    Database       = "DTO_DB"
    Query          = "
    SELECT PCN
    FROM (
    SELECT IIF(C1 > 0, SUBSTRING(t1.StatusDescription, C1+c3+1, C2-C1-c3-1), 'PCN') as PCN
    FROM tbSourceHOV_ClaimSplit_DTO AS T1
    CROSS APPLY
    (SELECT CHARINDEX('the file ', t1.StatusDescription)
    , CHARINDEX('_', t1.StatusDescription), LEN('the file ')) d(c1, c2,c3)
    WHERE ProcessName = 'ClaimSplittingASC_UB04_Attempt2'
    AND ProcessStatus = 'Fail'
    AND EndProcess >= CONVERT( DATE, GETDATE() -1 )
    ) as PCNList
    where PCN <> 'PCN'
    "
}
    
$PCNList = Invoke-Sqlcmd @QueryParams;
    
$BIOutputFile = -join ( ([System.Io.Path]::GetTempPath()) , ("BINextGen_QueryOutput_" + (Get-Date -Format "ddMMyyhhmmss") + ".csv"))
    
foreach ($PCN IN $PCNList) {
    
    $BiQuery = "
    SELECT TOP (1) [Claim Number],[Account Number], Facility 
    FROM dbo.ClaimEditMaster with(NOLOCK)
    WHERE [Claim Number] = '$($PCN.PCN)'
    "
    
    $QueryParams = @{
        ServerInstance = "AHS-A2RSAS01"
        Database       = "BINextGen"
        Query          = $BiQuery
    }
    
    $BIOutput = Invoke-Sqlcmd @QueryParams 
    
    $content = [PSCustomObject]@{
        "Input PCN"         = $PCN.PCN; 
        "BI Claim Number"   = $BIOutput.'Claim Number'; 
        "BI Account Number" = $BIOutput.'Account Number'; 
        "Facility Code"     = $BIOutput.'Facility'
    };
    
    $content | Export-Csv -Path $BIOutputFile -NoTypeInformation -Append;
}
    
if ( Test-Path $BIOutputFile) {
    invoke-item $BIOutputFile;
}
