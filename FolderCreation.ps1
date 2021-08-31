$FolderList = @(
,"\Automation Anywhere\My Docs\Source HOV\Document Collation\Configuration\"
,"\Automation Anywhere\My Docs\Source HOV\Document Collation\Output\"
,"\Automation Anywhere\My Docs\Source HOV\Document Collation\Logs\"
,"\Automation Anywhere\My Docs\Source HOV\Document Collation\SharePointTemp\"
,"\Automation Anywhere\My Scripts\Source HOV\Document Collation\"
)

try 
{
    $AAAplicationPath = (Get-ItemProperty -Path "HKCU:\Software\Automation Anywhere\"  -ErrorAction Stop  ).'AAE.ApplicationPath'
}
catch
{
    [string]$AAAplicationPath = $null
    #"Nothing happened"
}

$FolderList | ForEach-Object {[system.io.directory]::CreateDirectory((Join-Path $AAAplicationPath $PSItem))}




Rename-item -Path  "C:\xps\XLP46259-1.pdf" -NewName "C:\xps\XLP46259-1.zip"

[System.io]::GetI

[System.IO.FileAttributes]::