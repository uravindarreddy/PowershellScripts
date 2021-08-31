$T1 = Get-Date
2Pdf.exe -src "C:\Testing\FileWatcher\*.*" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 
$T2 = Get-Date

$TDiff = New-TimeSpan $T1 $T2

Remove-Item -Path "C:\Testing\FilesCopied\*" -Force -Confirm:$false -ErrorAction Stop | Out-Null;


$T1 = Get-Date
2Pdf.exe -src "C:\Testing\FileWatcher\XLP46397-1.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 
2Pdf.exe -src "C:\Testing\FileWatcher\XLP46398-1.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 
2Pdf.exe -src "C:\Testing\FileWatcher\XLP46399-1.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 
2Pdf.exe -src "C:\Testing\FileWatcher\XLP46400-1.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 
2Pdf.exe -src "C:\Testing\FileWatcher\XLP46402-1.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 
2Pdf.exe -src "C:\Testing\FileWatcher\XLP46403-1.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 
2Pdf.exe -src "C:\Testing\FileWatcher\XLP46404-1.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes 

2Pdf.exe -src "C:\xps\IMHUB04\xps\XLP139420-1.xps" -dst "C:\xps\IMHUB04\pdf" -options alerts:no scansf:no keepsf:yes overwrite:yes 



$T2 = Get-Date

$TDiff2 = New-TimeSpan $T1 $T2


2Pdf.exe -src "C:\xps\1stSet\*.xps" -dst "C:\xps\Pdf" -options alerts:no scansf:no keepsf:yes overwrite:yes 


2Pdf.exe -src "C:\xps\3\*.xps" -dst "C:\Testing\FilesCopied" -options alerts:no scansf:no keepsf:yes overwrite:yes pages:all


2Pdf.exe -src "SourcePath" -dst "DestinationPath"




2Pdf.exe -src "C:\OCRTesting\xps\*.xps" -dst "C:\OCRTesting\pdf" -options alerts:no scansf:no keepsf:yes overwrite:yes 


2Pdf.exe -src "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF\xps\*.xps" -dst "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF\pdf" -options alerts:no scansf:no keepsf:yes overwrite:yes -pdf multipage:split 

2Pdf.exe -src "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF\pdf\*.pdf" -dst "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF" -options alerts:no scansf:no keepsf:yes overwrite:yes fast_combine:1000 -pdf multipage:append combine:"mergedfile.pdf"


2Pdf.exe -src "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\HCFA\Individual\*.pdf" -dst "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF" -options alerts:no scansf:no keepsf:yes overwrite:yes fast_combine:1000 -pdf multipage:append combine:"MergeIndividualSplit.pdf"


2Pdf.exe -src "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF\xps\*.xps" -dst "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF\pdf" -options alerts:no scansf:no keepsf:yes overwrite:yes -pdf multipage:split




2Pdf.exe -src "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\HCFA\Input\Salt Lake HCFA's 01.22.2021.pdf" -dst "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\2PDF\Split" -options alerts:no scansf:no keepsf:yes overwrite:yes -pdf multipage:split 