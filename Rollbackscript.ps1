[CmdletBinding()]
param (
     [string] $DBServerName = "PRDAMATWSQL01\RPA_DEV"
    ,[string] $dbname = "DTO_DB"
    ,[string] $configfile = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\WindowsPowerShell\Scripts\DBScripting\GenerateDBScripts.csv"
)


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $DBServerName
$db = $SMOserver.databases[$dbname]
$date_ = (Get-Date -f yyyyMMddhhmmss)
$ScriptSavePath = [Environment]::GetFolderPath('MyDocuments')+ "\"+"$date_"



$SavePath = $ScriptSavePath + "\" + $($dbname)
$ScriptFile = $SavePath + "RollbackScript.sql"

            if ( !(Test-Path $ScriptSavePath))
                   {$null=new-item -type directory -path $ScriptSavePath}

$DBObjects = Import-Csv $configfile

if ( $DBObjects.Count -eq 0){
Write-Host "No objects to be scripted"
return
}


$StoredProcedures =  $DBObjects |  Where-Object {$_.Object_Type -eq "StoredProcedure"} 
$Tables =  $DBObjects |  Where-Object {$_.Object_Type -eq "Table"} 


$scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
$scriptr.Options.AppendToFile = $True
$scriptr.Options.AllowSystemObjects = $False
$scriptr.Options.DriAll = $True
$scriptr.Options.ScriptDrops = $True
$scriptr.Options.IncludeHeaders = $False
$scriptr.Options.IncludeIfNotExists = $True
$scriptr.Options.Indexes = $True
$scriptr.Options.ToFileOnly = $True


$scriptr.Options.Permissions = $True
$scriptr.Options.WithDependencies = $False

$TextFile = "$SavePath\TextFile_$date_.txt";
       
        if ($Tables)
        {

                foreach ($TbName in $Tables.Object_Name)
                {

                        #$Tb = $db.Tables[$TbName]
                        $Tb = $db.Tables| where {$_.Name -eq $TbName}
                        
                        $scriptr.Options.FileName = $ScriptFile
                        $scriptr.Script($Tb)

                    
                }
        }

 
        if ($StoredProcedures)
        {

                foreach ($spname in $StoredProcedures.Object_Name)
                {

                    $spname
                        #$sp = $db.StoredProcedures[$spname]
                        $sp =  $db.StoredProcedures | where {$_.Name -eq $spname}
                        $scriptr.Options.FileName = $ScriptFile
                        $scriptr.Script($sp);


                        
                }
        }

Invoke-Item -Path $ScriptSavePath

