$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("facilityCode", "DEMO")
$headers.Add("securityToken", "pZe3lr5kyTrYtmcxojGpwIsQ6aN1MSXzRpwbCTSatJALOEjIK0t01KigOOZfHl7fYanwnKLkQ1emzf26K9b7rsAHYg4n0eMVn0TPhQV0ppjc8JPiz7ZxMF71Q6_FSC5mGTitkUuJzwFgLJsHbf6vcX7YfmwBmM8lJhcRtLNu9akO7YdM-gWccR_MK7ypPIDOC8OBQb8y3IxbXtKhqAmlMXhwYD7vxHbvxLIT54sxHoTkoeYCJpu7ot0lhR76LM1P4dr6t06Yi8OXiuw2uwaX4RomVAxyvAM9EFFXubq6gEZEGSFhkpoRYmXMoiBhKYsq2jJXLPrFnZtZl7G5DfM3tkXOl8LDExvndgiWMw")

$multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
$multipartFile = '/path/to/file'
$FileStream = [System.IO.FileStream]::new($multipartFile, [System.IO.FileMode]::Open)
$fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
$fileHeader.Name = ""
$fileHeader.FileName = "/path/to/file"
$fileContent = [System.Net.Http.StreamContent]::new($FileStream)
$fileContent.Headers.ContentDisposition = $fileHeader
$multipartContent.Add($fileContent)

$body = $multipartContent

$response = Invoke-RestMethod 'https://pasfileservice.r1rcm.com/api/storage/uploaddoc/?id=3104&accountNumber=testaccount.test&serviceLine=LOC&description=Document_Uploaded&contentType=application^msword' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json