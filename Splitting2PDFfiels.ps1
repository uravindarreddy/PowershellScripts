$xpsfiles = Get-ChildItem  "C:\OCRTesting\xps"
$i = 0
foreach ($xps in $xpsfiles){

$x = New-Item -Path "C:\OCRTesting\SplitFiles" -Name $xps.BaseName -ItemType Directory


2Pdf.exe -src $xps.FullName -dst $x.FullName -options alerts:no scansf:no keepsf:yes overwrite:yes silent:yes -pdf multipage:split 


$FileList = Get-ChildItem $x.FullName

foreach ($file in $FileList)
{

$filename = $file.Name

$filename = $filename -replace $file.Extension, "";



if ( $filename.Split("-")[2]%2 -eq 0){
Remove-Item -Path $file.FullName -Force -Confirm:$false;
}    
}

2Pdf.exe -src "$($x.FullName)\*.pdf" -dst "C:\OCRTesting\SplitFiles" -options silent:yes alerts:no scansf:no keepsf:yes overwrite:yes fast_combine:1000 -pdf multipage:append combine:"$($xps.BaseName).pdf"

$i = $i + 1

Write-Host $i
}

-options alerts:no silent:yes