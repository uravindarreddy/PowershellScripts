$filepath = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\WindowsPowerShell\Scripts\DBScripting"



dir -Path $filepath -recurse | Where-Object { $_.PSIsContainer }| Select FullName | convertto-csv -NoTypeInformation | out-file "C:\Filetest.csv"


get-childitem $filepath -recurse | select-object DirectoryName,Name, FullName | where { $_.DirectoryName -ne $NULL } | Export-CSV C:\Filelist.csv -NoTypeInformation