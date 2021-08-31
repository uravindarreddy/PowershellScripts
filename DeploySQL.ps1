<#
.SYNOPSIS 
    Deploy SQL files to a database.  Includes root level exception handling.
.DESCRIPTION 
    Deploy SQL files to a database.  Includes root level exception handling.
    User must have permission to perform the steps within the sql file.
    Requires PowerShell module SqlServer installed on the server running the PowerShell script.


.PARAMETER ServerInstance
    The SQL server instance where the SQL will be deployed.
.PARAMETER Database
    The database where the SQL will be deployed.
.PARAMETER SqlFolder
    The folder containing the .sql files that will be deployed.
.PARAMETER FileFilter
    The regext matching criteria to filter specific sql files. If kept blank it will consider all files in a folder specified.
.EXAMPLE
    .\DeploySql -ServerInstance SERVERINSTANCE1 -Database DATABASE1 -SqlFolder "C:\temp\sql\DATABASE1\"
    .\DeploySql -ServerInstance SERVERINSTANCE2  -Database DATABASE2 -SqlFolder "C:\temp\sql\DATABASE2\" -FileFilter "usp_SHOV"
Powershell.exe -File "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\WindowsPowerShell\Scripts\DeploySQL.ps1" -ServerInstance "PRDAMATWSQL01\RPA_DEV"  -Database "DTO_DB" -SqlFolder "C:\Users\US35107\SourceCode\r1-hub-database\ACH_DB_NonTran\DTO_DB\dbo\Stored Procedures" -FileFilter "usp_SHOV_IS"
#>
[Cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$ServerInstance,
    [Parameter(Mandatory=$true)]
    [String]$Database,    
    [Parameter(Mandatory=$true)]
    [String]$SqlFolder,
    [Parameter(Mandatory=$false)]
    [String]$FileFilter
)

function Invoke-DeploySql {
    <#
    .SYNOPSIS 
        Deploy SQL files to a database.
    .DESCRIPTION 
        Deploy SQL files to a database.
        User must have permission to perform the steps within the sql file.
        Requires PowerShell module SqlServer installed on the server running the PowerShell script.
    .PARAMETER ServerInstance
        The SQL server instance where the SQL will be deployed.
    .PARAMETER Database
        The database where the SQL will be deployed.
    .PARAMETER SqlFiles
        The SQL files that will be deployed.
    .EXAMPLE
        # Adjust directories to reflect where the module and sql files are located.
        Import-Module ".\COMPANYNAME.DevOps.Sql.psm1" -Force
        $sqlFolder = "..\sql\DATABASE1\"
        $sqlFiles = Get-ChildItem $sqlFolder -Filter *.sql | Sort-Object
        Invoke-DeploySql -ServerInstance SERVERINSTANCE1 -Database DATABASE1 -SqlFiles $sqlFiles
        Import-Module ".\COMPANYNAME.DevOps.Sql.psm1" -Force
        $sqlFolder = "..\sql\DATABASE2\"
        $sqlFiles = Get-ChildItem $sqlFolder -Filter *.sql | Sort-Object
        Invoke-DeploySql -ServerInstance SERVERINSTANCE2 -Database DATABASE2 -SqlFiles $sqlFiles
    #>
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [String]$Database,        
        [Parameter(Mandatory=$true)]
        [Array]$SqlFiles
    )
    Write-Output "$($MyInvocation.MyCommand) - Start"
    $totalSqlFiles = ($SqlFiles | Measure-Object).Count
    Write-Output "Total sql files: $totalSqlFiles"
    $SqlFiles | Foreach-Object {
        $sqlFile = $_.FullName
        Write-Output "Processing file: $sqlFile"
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -InputFile $sqlFile
        Write-Output "Completed file:  $sqlFile"
    }
    Write-Output "$($MyInvocation.MyCommand) - End"
}


$scriptFile = Get-Item $PSCommandPath;
Write-Output "$($scriptFile.Name) - Start"
Try {

    Write-Output "Applying scripts to server instance '$ServerInstance' on database '$Database'"
    $sqlFiles = Get-ChildItem $SqlFolder -Filter "*$FileFilter*.sql" | Sort-Object
    $totalSqlFilesFound = ($sqlFiles | Measure-Object).Count
    If ($totalSqlFilesFound -eq 0) {
        Write-Output "##vso[task.LogIssue type=warning;]Warning: no sql files found."
    }
    else {
        Invoke-DeploySql -ServerInstance $ServerInstance -Database $Database -SqlFiles $sqlFiles
    }
}
Catch {
    Write-Output "##vso[task.LogIssue type=error;] $($scriptFile.Name)"
    Write-Output "##vso[task.LogIssue type=error;] Script Path: $($scriptFile.FullName)"
    Write-Output "##vso[task.LogIssue type=error;] $_"
    Write-Output "##vso[task.LogIssue type=error;] $($_.ScriptStackTrace)"
    Exit 1
}
Write-Output "$($scriptFile.Name) - End"