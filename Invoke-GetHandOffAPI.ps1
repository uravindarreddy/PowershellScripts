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


Function Invoke-udfGetHandOffAPI {
    [CmdletBinding()]
    param (
        [string] $EndPoint,
        [string] $token,
        [string] $FacilityCode,
        [string] $handOffType,
        [string] $action,
        [string] $disposition, 
        [string] $notes,
        [string] $status,
        [string] $pageNumber,
        [string] $pageSize
    )


    $apiQueryParams = [ordered] @{
        HandoffType = $handOffType
        Action =  $action
        Disposition = $disposition
        Notes = $notes
        Status = $status
        Pagenumber = $pageNumber
        Pagesize = $pageSize
        }

        
        [string]$query = ""
        [int]$i = 0

        foreach ( $item in $apiQueryParams.GetEnumerator()) {
        if ($i -eq 0){
            $symbol = "?"
            }
            else {
            $symbol = "&"
            }
            if([string]$null -ne $item.value ){
               $query =  -join ($query, $symbol, $item.Key.ToString(),"=", $item.Value.ToString());
               $i++
                }
        }

    $Method = "GET"
    $ContentType = "application/json"
    $ApiError = $null
    $params = @{
        Uri         = -join($EndPoint, $query)
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

$clientID = "PFSS3566PR";
$clientSecret = "+X5ZSGJKBKHJXI0AJ7CH4BEGHKDEMEAIILJIVV3X/WW=";    
$Tokenurl = "https://api.hub.r1rcm.local/auth/v1/token";

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

$FacilityCodeList = import-csv -Path "C:\Facility_List.csv"

foreach ($Facility in $FacilityCodeList)
{
    

    $WorkListAPIparams = @{
        EndPoint = "https://api.hub.r1rcm.local/v1/activities/handoff"
        token = $token
        FacilityCode = $Facility.FacilityCode
        handOffType = "Source HOV Billing"
        action = "Source HOV Billing Request"
        disposition ="Ready for Bot" 
        notes = $null
        status = "Identified"
        pageNumber = "1"
        pageSize = "50000"
    }

    $WorklistResponse = Invoke-udfGetHandOffAPI @WorkListAPIparams;

    $responejsonfile = -join ( ([System.Io.Path]::GetTempPath()) , ("$($Facility.FacilityCode)_" +(Get-Date -Format "ddMMyyhhmmss")+".txt"))

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

}