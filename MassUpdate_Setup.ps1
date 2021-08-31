
try 
{
    $AAAplicationPath = (Get-ItemProperty -Path "HKCU:\Software\Automation Anywhere\"  -ErrorAction Stop  ).'AAE.ApplicationPath'
}
catch
{
    [string]$AAAplicationPath = $null
    #"Nothing happened"
}




New-Item -Path "$AAAplicationPath\Automation Anywhere\My Docs\Source HOV\Configuration\"  -ItemType Directory

New-Item -Path "$AAAplicationPath\Automation Anywhere\My Docs\Source HOV\Logs\"  -ItemType Directory

New-Item -Path "$AAAplicationPath\Automation Anywhere\My Docs\Source HOV\Logs\Shared\"  -ItemType Directory

New-Item -Path "$AAAplicationPath\Automation Anywhere\My Docs\Source HOV\Input\"  -ItemType Directory


New-Item -Path "$AAAplicationPath\Automation Anywhere\My Scripts\Source HOV\Mass Update\"  -ItemType Directory
