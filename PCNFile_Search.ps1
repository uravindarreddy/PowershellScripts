[string] $PCNFilePath = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Downloads\PatientControlNumber.csv"
[string] $SearchFolder = "\\ahvsmiprt01\Eprem\SJHS\BILLING\Failed Claims\13th run\"
[string] $DesinationFolder = "C:\Testing"

if ($PCNFilePath -eq [string] $null) 
{
    Write-Host "Destination Folder can't be blank" -ForegroundColor Magenta
    return  
}

if ($PCNFilePath -eq [string] $null) 
{
    Write-Host "Destination Folder can't be blank" -ForegroundColor Magenta
    return  
}
if ( [System.IO.Path]::GetExtension($PCNFilePath) -ne ".csv")
{
    Write-Host "Input file is not a csv file. Please provide csv file." -ForegroundColor Magenta
    return  
}

if ( [System.IO.Path]::GetExtension($PCNFilePath) -ne ".csv")
{
    Write-Host "Input file is not a csv file. Please provide csv file." -ForegroundColor Magenta
    return  
}

if ($DesinationFolder -eq [string] $null) 
{
    Write-Host "Destination Folder can't be blank" -ForegroundColor Magenta
    return  
}


if ($SearchFolder -eq [string] $null) 
{
    Write-Host "SearchFolder can't be blank" -ForegroundColor Magenta
    return  
}

if (!(Test-Path -Path $PCNFilePath -PathType Leaf)) 
{
    Write-Host "The file path for PCn does not exists" -ForegroundColor Magenta
    return  
}

if (!(Test-Path -Path $DesinationFolder -PathType Container))
{
    Write-Host "Destination Folder mentioned does not exists." -ForegroundColor Magenta
    return
}

if (!(Test-Path -Path $SearchFolder -PathType Container))
{
    Write-Host "Folder path mentioned for searching files does not exists." -ForegroundColor Magenta
    return
}


<#
$PCNQuery = "SELECT PatientControlNumber 
FROM tbSourceHOV_ClaimSplit_DTO
WHERE ProcessName = 'Source HOV Claim Splitting UB04'
AND ProcessStatus = 'Fail'
AND ISNULL(PatientControlNumber, '') <> ''
AND ExecutionDate  = cast( GETDATE() AS DATE)
"

$PCNData = Invoke-Sqlcmd -ServerInstance "PRDAMATWSQL01\RPA_DEV" -Database "DTO_DB" -Query $PCNQuery
#>

$PCNData = import-csv -Path $PCNFilePath

$logfile = join-path ([io.fileinfo]$PCNFilePath).Directory.FullName ("FilesMovestatus_" + (Get-Date).toString("yyyyMMddHHmmss") + ".csv")



if ( $PCNData[0].psobject.Properties.Name -notcontains "PatientControlNumber")
{
    Write-Host "The csv file does not contain the header PatientControlNumber." -ForegroundColor Magenta
    return    
}


if ($PCNData) {
#$PCNData | Out-GridView 
foreach ($PCN in $PCNData)
{

   $SkippedFiles =  Get-ChildItem $SearchFolder -Filter "*$($PCN.PatientControlNumber.Trim())*.pdf"
   
   if ($SkippedFiles){
   try{
    Move-Item -Path $SkippedFiles.FullName -Destination $DesinationFolder -Force -Confirm:$false -ErrorAction Stop;
    
    $Content = [PSCustomObject]@{
        "PatientControlNumber" = $PCN.PatientControlNumber.Trim()
        MoveStatus   = "OK"
    }
    Export-Csv -InputObject $Content -Path $logfile -NoTypeInformation -Append;

   }
   catch{
    Write-Host $_ -ForegroundColor DarkRed
   }

   }
   else {
#    Write-Host "No files were found with the PCN $PCN" -ForegroundColor Magenta    

    $Content = [PSCustomObject]@{
        "PatientControlNumber" = $PCN.PatientControlNumber.Trim()
        MoveStatus   = "NOT OK"
    }
    Export-Csv -InputObject $Content -Path $logfile -NoTypeInformation -Append;
   }    

}
}
else
{
    Write-Host "No PCNs were found in the file $PCNFilePath" -ForegroundColor Magenta
    Invoke-Item $PCNFilePath
}


if( Test-Path -Path $logfile -PathType Leaf)
{
    invoke-item $logfile
}