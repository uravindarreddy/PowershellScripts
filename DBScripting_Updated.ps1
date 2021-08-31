[CmdletBinding()]
param (
     [string] $DBServerName = "PRDAMATWSQL01\RPA_DEV"
    ,[string] $dbname = "DTO_PayerPortalUpload_DB"
    ,[string] $configfile = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\WindowsPowerShell\Scripts\DBScripting\GenerateDBScripts.csv"
)


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $DBServerName
$db = $SMOserver.databases[$dbname]
$date_ = (Get-Date -f yyyyMMddhhmmss)
$ScriptSavePath = [Environment]::GetFolderPath('MyDocuments')+ "\"+"$date_"



$SavePath = $ScriptSavePath + "\" + $($dbname)

$DBObjects = Import-Csv $configfile

if ( $DBObjects.Count -eq 0){
Write-Host "No objects to be scripted"
return
}


$StoredProcedures =  $DBObjects |  Where-Object {$_.Object_Type -eq "StoredProcedure"} 
$Tables =  $DBObjects |  Where-Object {$_.Object_Type -eq "Table"} 


$scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
$scriptr.Options.AppendToFile = $False
$scriptr.Options.AllowSystemObjects = $False
$scriptr.Options.DriAll = $True
$scriptr.Options.ScriptDrops = $false
$scriptr.Options.IncludeHeaders = $False
$scriptr.Options.IncludeIfNotExists = $True
$scriptr.Options.Indexes = $True
$scriptr.Options.ToFileOnly = $True
$scriptr.Options.NoCollation = $True

$scriptr.Options.Permissions = $True
$scriptr.Options.WithDependencies = $False

$TextFile = "$SavePath\TextFile_$date_.txt";
       
        if ($Tables)
        {
        $TypeFolder = "Tables"
            if ( !(Test-Path "$SavePath\$TypeFolder"))
                   {$null=new-item -type directory -path "$SavePath\$TypeFolder"}
                foreach ($TbName in $Tables.Object_Name)
                {

                        #$Tb = $db.Tables[$TbName]
                        $Tb = $db.Tables| where {$_.Name -eq $TbName}
                        $ScriptFile = $Tb.Name
                        $scriptr.Options.FileName = "$SavePath\$TypeFolder\$ScriptFile.sql"
                        $scriptr.Script($Tb)
                        "CARE|DTO_DB|ALL|..\..\DB_Projects\ACH_DB_NonTran\DTO_DB\dbo\Tables\$ScriptFile.sql" | out-file -FilePath $TextFile -Append -Encoding ascii
                    
                }
        }

 
        if ($StoredProcedures)
        {
        $TypeFolder = "StoredProcedures"
            if ( !(Test-Path "$SavePath\$TypeFolder"))
                   {$null=new-item -type directory -path "$SavePath\$TypeFolder"}
                foreach ($spname in $StoredProcedures.Object_Name)
                {

                    $spname
                        #$sp = $db.StoredProcedures[$spname]
                        $sp =  $db.StoredProcedures | where {$_.Name -eq $spname}
                        $ScriptFile = $sp.Name
                        $scriptr.Options.FileName = "$SavePath\$TypeFolder\$ScriptFile.sql"
                        $scriptr.Script($sp);

                         "CARE|DTO_DB|ALL|..\..\DB_Projects\ACH_DB_NonTran\DTO_DB\dbo\Stored Procedures\$ScriptFile.sql"| out-file -FilePath $TextFile -Append -Encoding ascii;
                        
                }
        }

Invoke-Item -Path $SavePath

