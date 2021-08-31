$InputPathFolder="C:\xps\"
$OutputFolder="C:\pdf"

<#
[CmdletBinding()]
param (
    [Parameter (Mandatory = $true, Position = 0)] [string] $InputPathFolder,
    [Parameter (Mandatory = $true, Position = 1)] [string] $OutputFolder
)
#>
$Extension="*.xps"
$InputPath= Join-Path $InputPathFolder $Extension



 If(!(Test-Path -Path $InputPathFolder -PathType Container))
 {
 Write-Output "Error: Input folder does not exist"
 return
 }
 
 If(!(Test-Path -Path $OutputFolder -PathType Container))
 {

 Write-Output "Error: Ouput folder does not exist"
 return
  
 }
 else
 {
 
 $OutputFolder=Join-Path $OutputFolder (Get-Date -Format "MMddyyyyhhmmss")
 If(!(Test-Path -Path $OutputFolder -PathType Container)){
 New-Item -Path $OutputFolder -ItemType Directory
 }
 
 }
 
 try
 {
 
  \\Prdamatwfil01\2pdf\2Pdf.exe -src $InputPath -dst $OutputFolder -options alerts:no #-pdf ocr:yes ocr_lang:English

 }
 
 catch
 {
 write-Output "Error: Converting xps files to pdf : " + $_
 return
 }

 ## get File count of input (xps) and output (pdf) files and compare the count 
 $XpsFilesCount=(Get-ChildItem $InputPath -filter "*.xps").Count
 $PdfFilesCount=(Get-ChildItem $OutputFolder -filter "*.pdf").Count


 If($XpsFilesCount -eq $PdfFilesCount)
 {
 Write-Output "All files are converted to pdf succesfully. Xps filesCount =$XpsFilesCount and pdf files count= $PdfFilesCount"
 }
 else
 {
 Write-Output "Error: All files are NOT converted to pdf. Xps filesCount =$XpsFilesCount and pdf files count= $PdfFilesCount"
 
 }


