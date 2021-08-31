$confighandoffnote = "Ciox/HealthSource process. Manual review is required,Medical records sent,Paper claim mailed to payer,Please provide the addresss in R1D,MR pages not found with Health Source"
$configvalues = $confighandoffnote.Split(",") 
$handoffnote = "The bot automation failed to complete the SourceHOV Medical Record Acquisition from Ciox/HealthSource process. Manual review is required. Failure reason: There are 0 pages to download"
$null -ne ($configvalues | Where-Object { ​​​​​​​ $handoffnote -match $_ }​​​​​​​)  # Returns $true


$configvalues | Where-Object { ​​​​​​​ $handoffnote -match $PSItem }​​​​​​​

$configvalues | Where-Object { ​​​​​​​ $PSItem -like "*process*" }​​​​​​​

$configvalues | Select-Object @{N = "Name"; E = { $_ } } | Where-Object { ​​​​​​​$handoffnote -match $_.Name }​​​​​​​

# $s = "something else entirely"
# $null -ne ($configvalues | where { ​​​​​​​ $handoffnote -match $_ }​​​​​​​)  # Returns $false



