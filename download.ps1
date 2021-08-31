$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("facilitycode", "sjpk")
$headers.Add("Authorization", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IlNPVVI2MzM3SVEiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9zeXN0ZW0iOiIxMC4yNDguNjguMzQiLCJuYmYiOjE2MDQ2NzUyMjksImV4cCI6MTYwNDY3NjEyOSwiaWF0IjoxNjA0Njc1MjI5LCJpc3MiOiJBUElHVy1EZXYiLCJhdWQiOiIxMC4yNDguNjguMzQifQ.gU0pgIc-Hcgkox8pdBjVK9s_AqqOMlzJpilqcRD0KlI")

$response = Invoke-WebRequest 'http://iqaapi.hub.r1rcm.local/v1/activities/documents/download?visitNumber=00001787562&documentNumber=31' -Method 'GET' -Headers $headers 
#$Doc = $response | ConvertTo-Json -Depth 10

$response | Get-Member

#$BaseDownloadFolderPath = Join-Path $env:TEMP "pdfile.png"
#[System.IO.File]::WriteAllBytes($BaseDownloadFolderPath ,$response)

$BaseDownloadFolderPath =  $env:TEMP 
$filename = $response.DocDet.Headers.'Content-Disposition'.Split(";")[1].Split("=")[1].Replace('"', '')
$BaseDownloadFolderPath = Join-Path $env:TEMP $filename;
    [System.IO.File]::WriteAllBytes($BaseDownloadFolderPath ,$response.Content)

Invoke-Item $BaseDownloadFolderPath






    $Method = "GET"
    $EndPoint = 'http://iqaapi.hub.r1rcm.local/v1/activities/documents/download?visitNumber=00001787562&documentNumber=31'

    $token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IlNPVVI2MzM3SVEiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9zeXN0ZW0iOiIxMC4yNDguNjguMzQiLCJhY3RvcnQiOiJTb3VyY2VIT1YgRFRPIFRlYW0iLCJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvY2xhaW1zL3VzZXJkYXRhIjoiIiwibmJmIjoxNjA0Njc2MDUxLCJleHAiOjE2MDQ2NzY5NTEsImlhdCI6MTYwNDY3NjA1MSwiaXNzIjoiQVBJR1ctRGV2IiwiYXVkIjoiMTAuMjQ4LjY4LjM0In0.5bptAsI95lPcMudcm3Fyv3i0Qwa7XZj45R0EB-QV6nA"
    $params = @{
        Uri         = $EndPoint
        Method      = $Method
        Headers     = @{
            'facilitycode'  = "sjpk"
            #'Authorization' = $token
            'Authorization' = "Bearer $token"
        }
    }

        $response = Invoke-WebRequest @params;

        $BaseDownloadFolderPath =  $env:TEMP 
$filename = $response.Headers.'Content-Disposition'.Split(";")[1].Split("=")[1].Replace('"', '')
$BaseDownloadFolderPath = Join-Path $env:TEMP $filename;
    [System.IO.File]::WriteAllBytes($BaseDownloadFolderPath ,$response.Content)

Invoke-Item $BaseDownloadFolderPath