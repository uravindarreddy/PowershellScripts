$fileName = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\SQL Server Management Studio\TestScriptForBulkCopy.sql"
$fileContent = get-content  $fileName -Raw
$fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
#$fileContentEncoded 


#$file = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\Base64string.txt"
#$data = Get-Content $file
#[System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($fileContentEncoded)) | Out-File -Encoding "ASCII" "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\out.sql"


[System.Text.Encoding]::utf8.GetString([System.Convert]::FromBase64String($fileContentEncoded)) | Out-File -Encoding utf8 "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\outandout.sql"


