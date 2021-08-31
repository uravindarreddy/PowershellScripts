$Processname = "powershell"
$ProcessesToKill = Get-Process | where {$_.ProcessName -eq $Processname}; 

if($ProcessesToKill){
    $ProcessesToKill.Kill();
}
else
{
    Write-Host "No processes to kill"
}