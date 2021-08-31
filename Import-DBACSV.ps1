Import-DbaCsv -Path "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\Charity_List.csv" -SqlInstance "HZC-RPA-D01-165" -Database "AdventureWorksLT2017" -AutoCreateTable

Import-DbaCsv -Path "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\HCFA\csvextracts\IMG_HCFA_ExtractedData.csv" -SqlInstance "PRDAMATWSQL01\RPA_DEV" -Database "DTO_DB" -AutoCreateTable
Import-DbaCsv -Path "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\HCFA\csvextracts\IMG_SupplyInvoice_ExtractedData.csv" -SqlInstance "PRDAMATWSQL01\RPA_DEV" -Database "DTO_DB" -AutoCreateTable

Import-DbaCsv -Path "C:\xps\Pdf - Copy\PDFABBY2.CSV " -SqlInstance "HZC-RPA-D01-165" -Database "AdventureWorksLT2017" -AutoCreateTable

