#Document Download API Powershell Script
<#    
.SYNOPSIS       
   Powershell script to Download Documents for Document Collation  Process
.DESCRIPTION
   This Script  perform the Document Download using the API and Saves the Document into a configurable location

.PARAMETERS
   token: - Required for Auhorizaion in API
   DownloadDocumentEndpoint:- Api Endpoint for Downloading Documents
   facilityCode = the facility for which the API needs to be hit
   AccountNumber =  The Account Number required for which the doc should be download
   DocNumber = The DocNumber which should be download
   BaseDownloadFolderPath = The Folder Path where the Downloaded Document is Saved

.EXAMPLE       
   Powershell.exe "D:\PowershellScripts\scr_SHOV_DB_Ingestion.ps1" -token " " -DownloadDocumentEndpoint " " -facilityCode " " -AccountNumber " " -DocNumber " " -BaseDownloadFolderPath " "
#>

#region Parameters Mapping from VBScript
param (
    [Parameter (Mandatory = $true, Position = 0)] [string] $token,
    [Parameter (Mandatory = $true, Position = 1)] [string] $DownloadDocumentEndpoint,
    [Parameter (Mandatory = $true, Position = 2)] [string] $facilityCode,
    [Parameter (Mandatory = $true, Position = 3)] [string] $AccountNumber,
    [Parameter (Mandatory = $true, Position = 4)] [string] $DocNumber,
    [Parameter (Mandatory = $true, Position = 5)] [string] $BaseDownloadFolderPath     

)
#endregion

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12;

#region Variable Intialization
<#$AccountNumber = "00001903155"

$DocNumber = "13685"

$BaseDownloadFolderPath ="\\R1-UEM-1.accretivehealth.local\redirection$\US21793\Desktop\DownloadDoccumentPath\"

$token = ""

$facilityCode = "SJPK"

$DownloadDocumentEndpoint ="http://iqaapi.hub.r1rcm.local/v1/activities/documents/download"#>

$queryString =  "?visitNumber=$AccountNumber&documentNumber=$DocNumber"

$DownloadDocumentURL = $DownloadDocumentEndpoint+$queryString

#endregion


Function Invoke-udfAPIDownloadDocument {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $token,
        [string] $FacilityCode
    )
    



    $Method = "GET"
    $ApiError = $null
    $params = @{
        Uri         = $EndPoint
        Method      = $Method
       # ContentType = "application\pdf"
        Headers     = @{
            'facilitycode'  = "$facilityCode"                    
            #'Authorization' = "Bearer $token"
            'Authorization' = $token
        }
    }
    try {
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($EndPoint);
        $response = Invoke-WebRequest @params;
        #$response =Invoke-RestMethod @params
    }
    catch {
        $ApiError = $_;
        $response = $null;
    }
    finally
    {
        $ServicePoint.CloseConnectionGroup("");
    }

    #return $rToken
    [PSCustomObject] @{
        DocDet = $response
        Errors      = $ApiError
        Success     = if ($null -eq $ApiError) { $true } else { $false }
    }
    
}

#region  Download Document API Call
$Doc =  Invoke-udfAPIDownloadDocument -EndPoint $DownloadDocumentURL -token $token -FacilityCode $facilityCode
#endregion

#region File Writing Process
if ($Doc.Success -eq $true){
    $filename = $Doc.DocDet.Headers.'Content-Disposition'.Split(";")[1].Split("=")[1].Replace('"', '')

    [System.IO.File]::WriteAllBytes($BaseDownloadFolderPath + $filename,$Doc.DocDet.Content)

    Write-Host "Successfully Downloaded the File and Saved"
}
else{
    Write-Host $Doc.Errors
}
#endregion