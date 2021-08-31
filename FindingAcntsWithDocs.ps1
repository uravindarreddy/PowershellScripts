

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
#region Calling Token Generation API
$token = $null
Write-Host "Calling Token generation API" 

$clientID = "PFSS3566UA";
$clientSecret = "DMZREXX+K9K5QQTJH2HNYTFQNNWWX6XFDUTS2ULQ/TS=";    
$Tokenurl = "https://uatapi.hub.r1rcm.local/auth/v1/token";

$tokenresponse = Get-udfToken -EndPoint $Tokenurl -clientID $clientID -clientSecret $clientSecret -ErrorAction Stop;
if ($tokenresponse.Success -eq $true) {
    $token = $tokenresponse.TokenDet.token;
    Write-Host "Token generated successfully";
}
else {
    Write-Host  "Error during Token Generation API call." 
    Write-Host $tokenresponse.Errors.Exception.Message 
    if ($tokenresponse.Errors.ErrorDetails.Message) {
        Write-Host  $tokenresponse.Errors.ErrorDetails.Message 
    }    
}
#endregion 


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("FacilityCode", "SJPK")
$headers.Add("Authorization", "Bearer $token")
 
try{
$response = Invoke-RestMethod 'https://uatapi.hub.r1rcm.local/v1/activities/handoff?status=4&pageNumber=1&pageSize=1000' -Method 'GET' -Headers $headers -Body $body
}
catch{
Write-Host "Error while calling Get hand off API"
return
}
$AccountsWithDocs = New-Object System.Collections.ArrayList



foreach ($accnt in $response.item.account.accountNumber){
$endpoint = "https://uatapi.hub.r1rcm.local/v1/activities/documents?visitNumber=$accnt"
try{
    $accntresponse = Invoke-RestMethod $endpoint -Method 'GET' -Headers $headers -Body $body

    $AccountsWithDocs.Add("$accnt") | Out-Null;
}
catch{
Write-Host "Error"
}


}

$responejsonfile = -join ( ([System.Io.Path]::GetTempPath()) , ("AccntsWithDocs_" +(Get-Date -Format "ddMMyyhhmmss")+".txt"));

$AccountsWithDocs | Out-File $responejsonfile;

if (test-path $responejsonfile -PathType Leaf){
invoke-item $responejsonfile
}