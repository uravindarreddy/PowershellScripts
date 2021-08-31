$sFileNames = Import-csv "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\DOc Collation Sorting Merging\FileTypeKeywords.csv"



$cFileNames = Get-ChildItem "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\DOc Collation Sorting Merging\2\"




foreach  ($cfname in $cFileNames){

    foreach ($sKeyword in $sFileNames) {

        if ( $cfname -match $sKeyword.KeyWordtoInclude )
        {

            if ($cfname -match ( $sKeyword.KeyWordtoInclude + "(\d+)")){
            
            #$sKeyword.SortingOrder.PadLeft(2,"0")  
            [string]$s = $Matches[1]

            $NewName = $sKeyword.SortingOrder.PadLeft(2,"0") + $s.PadLeft(2,"0")+ "_" + $cfname.Name
            $folder = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Documents\DOc Collation Sorting Merging\sorting"

            $NewName = Join-Path -Path $folder -ChildPath $NewName
            
                  Copy-Item -Path $cfname.FullName -Destination $NewName
            }
            
            
           #$sKeyword.SortingOrder
            
        }

    }

}