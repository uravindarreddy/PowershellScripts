Param (
	[string]$DocumentPath,
	[string]$FacilityCode,
    [string]$GetTokenURL,
    [string]$UploadDocumentURL,
    [string]$ServerClientSecret,
    [string]$ServerClientId,
    [string]$PayloadTemplatePath,
    [string]$LogFilePath,
    [string]$PSCommandPath,
    [string]$AccountNumber
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12;

Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG","EXECUTION")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$True)]
    [string]
    $logfile,

    [Parameter(Mandatory=$True)]
    [string]
    $AccountNumber
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath;"Account" = $AccountNumber;"Message" = $Message}
    If($logfile) {
        try
        {
            $Content | Export-Csv -Path $logfile -NoTypeInformation -Append           
        }
        catch
        {
            Write-Host $_.Exception.Message            
        }
    }
    Else {
        Write-Host $Message
    }
}


if ($LogFilePath -eq [string]$null)
{
   Exit 100
}
Write-Log -Level EXECUTION -Message "PowerShell script execution initiated" -logfile $LogFilePath -AccountNumber $AccountNumber

"Arguments validation..."
#region arguments validation
Write-Log -Level INFO -Message "Arguments validation initiated" -logfile $LogFilePath -AccountNumber $AccountNumber

if ($DocumentPath -eq [string]$null)
{
    Write-Log -Level ERROR -Message "DocumentPath parameter is empty" -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
    Exit
}

if ($FacilityCode -eq [string]$null)
{ 
    Write-Log -Level ERROR -Message "FacilityCode parameter is empty" -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
    Exit
}

if ($ServerURL -eq [string]$null)
{
   Write-Log -Level ERROR -Message "ServerURL parameter is empty" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   Exit
}

if ($ServerClientSecret -eq [string]$null)
{
   Write-Log -Level ERROR -Message "ServerClientSecret parameter is empty" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   Exit
}

if ($ServerClientId -eq [string]$null)
{
   Write-Log -Level ERROR -Message "ServerClientId parameter is empty" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   Exit
}

if ($PayloadTemplatePath -eq [string]$null)
{
   Write-Log -Level ERROR -Message "PayloadTemplatePath parameter is empty" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   Exit
}

if ($PSCommandPath -eq [string]$null)
{
   Write-Log -Level ERROR -Message "PSCommandPath parameter is empty" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   Exit
}
#endregion
"All arguments are valid"
Write-Log -Level INFO -Message "All arguments are valid" -logfile $LogFilePath -AccountNumber $AccountNumber

"Converting document to base64..."
#region Converting document to base64
Write-Log -Level INFO -Message "Converting document to base64 is initiated" -logfile $LogFilePath -AccountNumber $AccountNumber

$base64string = ''
try
{
    $base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($DocumentPath))
}
catch
{
   Write-Log -Level ERROR -Message "Converting to base64: $_" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   Exit
}
#endregion
"Converting document to base64 complete"
Write-Log -Level INFO -Message "Converting document to base64 is completed" -logfile $LogFilePath -AccountNumber $AccountNumber


"Generating payload..."
#region Generating payload
Write-Log -Level INFO -Message "Payload generation initiated" -logfile $LogFilePath -AccountNumber $AccountNumber

$payload = ''
try
{
    $payload = ((Get-Content -path $PayloadTemplatePath -Raw) -replace "REPLACE_CONTENT_PLACEHOLDER", $base64string)
}
catch
{
   Write-Log -Level ERROR -Message "Error while generating payload: $_" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   Exit
}
#endregion
"Generating payload complete"
Write-Log -Level INFO -Message "Payload generation completed" -logfile $LogFilePath -AccountNumber $AccountNumber

"Token generation..."
#region Token generation
Write-Log -Level INFO -Message "Token generation initiated" -logfile $LogFilePath -AccountNumber $AccountNumber

$token = ''

try {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("ClientId", $ServerClientId)
    $headers.Add("ClientSecret", $ServerClientSecret)

    $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($GetTokenURL);

    $response = Invoke-RestMethod ($GetTokenURL) -Method 'GET' -Headers $headers

    $token = $response.token
    if ($token -eq [string]$null)
    {
       Write-Log -Level ERROR -Message "Could not receive token: $_" -logfile $LogFilePath -AccountNumber $AccountNumber
       Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
       $ServicePoint.CloseConnectionGroup("");
       Exit
    } 
}
catch 
{
   Write-Log -Level ERROR -Message "Error while retrieving token: $_" -logfile $LogFilePath -AccountNumber $AccountNumber
   Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
   $ServicePoint.CloseConnectionGroup("");
   Exit
}
#endregion
"Token generation complete"
Write-Log -Level INFO -Message "Token generation completed" -logfile $LogFilePath -AccountNumber $AccountNumber

"Uploading document..."
#region Uploading document
Write-Log -Level INFO -Message "Document uploading initiated" -logfile $LogFilePath -AccountNumber $AccountNumber

$documentNumber = ''

try {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("facilityCode", $FacilityCode)
    $headers.Add("Authorization", "Bearer " + $token)
    $headers.Add("Content-Type", "application/json")
    $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($UploadDocumentURL);
    $response = Invoke-RestMethod ($UploadDocumentURL) -Method 'POST' -Headers $headers -Body $payload
    $documentNumber = $response.documentNumber;
    if ( $documentNumber -eq $null)
    {
        Write-Log -Level ERROR -Message "Error while uploading document.Document number not found: $response" -logfile $LogFilePath -AccountNumber $AccountNumber
        Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
        $ServicePoint.CloseConnectionGroup("");
        Exit
    }
}
catch 
{
    Write-Log -Level ERROR -Message "Error while uploading document: $_" -logfile $LogFilePath -AccountNumber $AccountNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber
    $ServicePoint.CloseConnectionGroup("");
    Exit
}
#endregion
"Uploading document completed. Documnet Number is :"+$documentNumber
Write-Log -Level INFO -Message "Document uploading completed" -logfile $LogFilePath -AccountNumber $AccountNumber

Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -AccountNumber $AccountNumber

Exit $documentNumber