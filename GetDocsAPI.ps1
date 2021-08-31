Function Get-udfToken {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $clientID,
        [string] $clientSecret
    )
    ####### Token Generation ########
    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = $EndPoint
        Method      = $Method
        ContentType = $ContentType
        Headers     = @{ 
            'clientId'     = "$clientID"  
            'clientSecret' = "$clientSecret" 
        }
    }
    try {
        $rToken = Invoke-RestMethod @params         
    }
    catch {
        $ApiError = $_;
        $rToken = $null;
    }

    #return $rToken
    [PSCustomObject] @{
        TokenDet = $rToken
        Errors   = $ApiError
        Success  = if ($null -eq $ApiError) { $true } else { $false }
    }


    ####### Token Generation ########
}


Function Invoke-udfGetDocs {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $token,
        [string] $FacilityCode,
        [string] $visitnumber
    )

    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $EndPoint = $EndPoint + "?visitnumber=$visitnumber"
    $params = @{
        Uri         = $EndPoint
        Method      = $Method
        ContentType = $ContentType
        Headers     = @{ 
            'facilityCode'  = "$FacilityCode"                   
            'Authorization' = "Bearer $token"
        }        
    }
    try {
        $response = Invoke-RestMethod @params         
    }
    catch {
        $ApiError = $_;
        $response = $null;
    }

    #return $rToken
    [PSCustomObject] @{
        AccountDet = $response
        Errors     = $ApiError
        Success    = if ($null -eq $ApiError) { $true } else { $false }
    }
    
}


#region Calling Token Generation API
$token = $null
Write-Host "Calling Token generation API" 
<# PROD Values
$clientID = "PFSS3566PR";
$clientSecret = "+X5ZSGJKBKHJXI0AJ7CH4BEGHKDEMEAIILJIVV3X/WW=";    
$Tokenurl = "https://api.hub.r1rcm.local/auth/v1/token";
$HandOffurl = "https://api.hub.r1rcm.local/v1/activities/documents";
#>
$clientID = "SOUR6337IQ";
$clientSecret = "VWPIKJXKL9VAQFD8+5X+UGFRZHCVFLTLW56CBWYLYJA=";    
$Tokenurl = "http://iqaapi.hub.r1rcm.local/auth/v1/token";
$HandOffurl = "http://iqaapi.hub.r1rcm.local/v1/activities/documents";
$FacilityCode = "SJPK"
$VisitNo = "00000561688"
$tokenresponse = Get-udfToken -EndPoint $Tokenurl -clientID $clientID -clientSecret $clientSecret -ErrorAction Stop;
if ($tokenresponse.Success -eq $true) {
    $token = $tokenresponse.TokenDet.token;
    Write-Host "Token generated successfully" ;
}
else {
    Write-Host  "Error during Token Generation API call." 
    Write-Host $tokenresponse.Errors.Exception.Message 
    if ($tokenresponse.Errors.ErrorDetails.Message) {
        Write-Host  $tokenresponse.Errors.ErrorDetails.Message 
    }    
}
#endregion 

$HandOffResponejsonfile = -join ( ([System.Io.Path]::GetTempPath()) , "DownloadDocs.txt")

 $HandOffResponse = $null
            $HandOffAPIParams = @{
                EndPoint        = $HandOffurl
                token           = $token
                FacilityCode	= $FacilityCode
                visitnumber     = $VisitNo
                
            }
            $HandOffResponse = Invoke-udfGetDocs @HandOffAPIParams;
        
            if ($HandOffResponse.Success -eq $true) {

                $HandOffResponsejson = $HandOffResponse.AccountDet | ConvertTo-Json -Depth 10;
                   if ($HandOffResponsejson) {
                            Write-Host  "Response received from Get Docs API successfully " 
                             $HandOffResponsejson | out-file -FilePath $HandOffResponejsonfile
                             invoke-item $HandOffResponejsonfile
                }
                }
        else {
                
                Write-Host  "Error during Get Docs API Call"
                Write-Host $HandOffResponse.Errors.Exception.Message 
                if ($HandOffResponse.Errors.ErrorDetails.Message) {
                    Write-Host  $HandOffResponse.Errors.ErrorDetails.Message 
                }

                }