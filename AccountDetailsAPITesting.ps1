$AccountNumber = "05796055"

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


Function Invoke-udfGetAccountDetails {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $token,
        [string] $FacilityCode,
        [string] $VisitNumber
            )
            
    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = $EndPoint + "?VisitNumber=" + $VisitNumber
        Method      = $Method
        ContentType = $ContentType
        Headers     = @{ 
            'facilityCode'  = "$FacilityCode"                   
            'Authorization' = "Bearer $token"
        }
    }

    Write-host "$EndPoint$query"
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
<# #IQA Environment
$clientID = "SOUR6337IQ";
$clientSecret = "VWPIKJXKL9VAQFD8+5X+UGFRZHCVFLTLW56CBWYLYJA=";
$Tokenurl = "http://iqaapi.hub.r1rcm.local/auth/v1/token";
$Accounturl = "http://iqaapi.hub.r1rcm.local/BillingAndFollowup/v1/activities/account-transactions"
#>
#PROD
$clientID = "PFSS3566PR";
$clientSecret = "+X5ZSGJKBKHJXI0AJ7CH4BEGHKDEMEAIILJIVV3X/WW=";    
$Tokenurl = "https://api.hub.r1rcm.local/auth/v1/token";
$Accounturl = "https://api.hub.r1rcm.local/BillingAndFollowup/v1/activities/account-transactions"

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


    $WorkListAPIparams = @{
        EndPoint = $Accounturl
        token = $token
        FacilityCode = "LPAZ"
        VisitNumber = $AccountNumber
    }

    $WorklistResponse = Invoke-udfGetAccountDetails @WorkListAPIparams;

    $responejsonfile = -join ( ([System.Io.Path]::GetTempPath()) , (Get-Date -Format "ddMMyyhhmmss")+".txt")

if ($WorklistResponse.Success -eq $true) {
    $WorklistResponse.AccountDet

    $WorkListjson = $WorklistResponse.AccountDet | ConvertTo-Json -Depth 10;

    $WorkListjson | out-file -FilePath $responejsonfile;
    invoke-item $responejsonfile
    Write-Host "json response received successfully" ;

}
else {
    Write-Host  "Error during Get HandOff API call." 
    Write-Host $WorklistResponse.Errors.Exception.Message 
    if ($WorklistResponse.Errors.ErrorDetails.Message) {
        Write-Host  $WorklistResponse.Errors.ErrorDetails.Message 
    }    
}

