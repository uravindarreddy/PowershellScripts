
try 
{
    $AAAplicationPath = (Get-ItemProperty -Path "HKCU:\Software\Automation Anywhere\"  -ErrorAction Stop  ).'AAE.ApplicationPath'
}
catch
{
    [string]$AAAplicationPath = $null
    #"Nothing happened"
}
<#
$AAAplicationPath.GetType()


"$AAAplicationPath\Automation Anywhere\My Docs\Source HOV\Itemized Statement\Configuration"

Invoke-Item "$AAAplicationPath\Automation Anywhere\My Docs\Source HOV\Itemized Statement\Configuration"

#>

