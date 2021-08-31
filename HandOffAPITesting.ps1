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


Function Invoke-udfHandOffAPI {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $token,
        [string] $FacilityCode,
        [string] $jsonbody
    )

    $Method = "POST"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = $EndPoint
        Method      = $Method
        ContentType = $ContentType
        Headers     = @{ 
            'facilityCode'  = "$FacilityCode"                   
            'Authorization' = "Bearer $token"
        }
        Body        = $jsonbody
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

$clientID = "PFSS3566PR";
$clientSecret = "+X5ZSGJKBKHJXI0AJ7CH4BEGHKDEMEAIILJIVV3X/WW=";    
$Tokenurl = "https://api.hub.r1rcm.local/auth/v1/token";
$HandOffurl = "https://api.hub.r1rcm.local/v1/activities/billedit";
$FacilityCode = "ASWI"

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

$HandOffJson = @"
{
"timestamp": "2020-10-20T06:45:45.194Z", 
"type": "ActivityUpdateRequest",
"body": {
"totalItems": 1,
"item": [
{
"code": "CBO/BSO-FollowUp",
"name": "HandOff",
"partOf": {
"type": "Process",
"identifier": {
"type": "workflow",
"value": "Source HOV Billing"
},
"supplement": {
"key": "Sub-Process",
"value": "Billing to Source HOV Billing"
}
},
"focus": {
"type": "Visit",
"identifier": {
"value": "40005027131",
"type": "VisitNumber"
}
},
"task": [
{
"name": "TaskName",
"status": "1",
"performer": {
"code": "56398",
"type": "User"
},
"result": [
{
"text": "Result Text",
"disposition": {
"why": "Source HOV Billing Request",
"what": "Ready for Bot",
"who": {
"type": "Department",
"code": ""
},
"note": {
"text": "Test API Response"
}
}
}
]
}
]
}
]
}
}
"@
$HandOffResponejsonfile = -join ( ([System.Io.Path]::GetTempPath()) , "HandOffJson.txt")

 $HandOffResponse = $null
            $HandOffAPIParams = @{
                EndPoint        = $HandOffurl
                token           = $token
                FacilityCode	= $FacilityCode
                jsonbody        = $HandOffJson
            }
            $HandOffResponse = Invoke-udfHandOffAPI @HandOffAPIParams;
        
            if ($HandOffResponse.Success -eq $true) {

                $HandOffResponsejson = $HandOffResponse.AccountDet | ConvertTo-Json -Depth 10;
                   if ($HandOffResponsejson) {
                            Write-Host  "Response received from Handoff API successfully " 
                             $HandOffResponsejson | out-file -FilePath $HandOffResponejsonfile
                             invoke-item $HandOffResponejsonfile
                }
                }
        else {
                
                Write-Host  "Error during HandOff API call for account number"
                Write-Host $HandOffResponse.Errors.Exception.Message 
                if ($HandOffResponse.Errors.ErrorDetails.Message) {
                    Write-Host  $HandOffResponse.Errors.ErrorDetails.Message 
                }

                }