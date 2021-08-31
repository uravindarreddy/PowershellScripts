$fOLDER = "\\R1-UEM-1\UEM_Profiles\US35107\profile\Downloads\API 2\API 2"
<#
$FLIST = Get-ChildItem -Path $fOLDER
foreach ( $f in $FLIST)
{
    $fcode = $f.Name.Substring(0,4)
}
#>


Function Invoke-UdfStoredProcedure { 
    [CmdletBinding()]
    param (
        [string] $sqlconnstring          , # Connection string
        [string] $sqlspname              , # SQL Query
        $parameterset                        # Parameter properties
    )
         
    $sqlDataAdapterError = $null
    try {
        $conn = new-object System.Data.SqlClient.SqlConnection($sqlconnstring);  

  
        $command = new-object system.data.sqlclient.Sqlcommand($sqlspname, $conn)

        $command.CommandType = [System.Data.CommandType]'StoredProcedure'; 

        foreach ($parm in $parameterset) {
            if ($parm.Direction -eq 'Input') {
                [void]$command.Parameters.AddWithValue($parm.Name, $parm.Value); 
            }
        }

        [void] $conn.Open()
  
        $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
  
        [void] $adapter.Fill($dataset)
 
    }
    catch {
        $sqlDataAdapterError = $_
        $dataset = $null
        
    }
    finally {
        $conn.Close()  
    }

    [PSCustomObject] @{
        DataSet = $dataSet
        Errors  = $sqlDataAdapterError
        Success = if ($null -eq $sqlDataAdapterError) { $true } else { $false }
    }
 
}

Function Add-UdfParameter { 
    [CmdletBinding()]
    param (
        [string] $name                    , # Parameter name from stored procedure, i.e. @myparm
        [string] $direction               , # Input or Output or InputOutput
        [string] $value                   , # parameter value
        [string] $datatype                , # db data type, i.e. string, int64, etc.
        [int]    $size                        # length
    )

    $parm = New-Object System.Object
    $parm | Add-Member -MemberType NoteProperty -Name "Name" -Value "$name"
    $parm | Add-Member -MemberType NoteProperty -Name "Direction" -Value "$direction"
    $parm | Add-Member -MemberType NoteProperty -Name "Value" -Value "$value"
    $parm | Add-Member -MemberType NoteProperty -Name "Datatype" -Value "$datatype"
    $parm | Add-Member -MemberType NoteProperty -Name "Size" -Value "$size"

    Write-Output $parm
    
}


Function Invoke-udfExecInsertWorkListSP {
    [CmdletBinding()]
    param (
        [string] $connstring          , # Connection string
        [string] $spName              , # SQL Query
        [string] $pWorkListjson       , # SP Parameter
        [string] $pFacilityCode       ,
        [string] $pEpremisCID         ,
        [string] $pClientName                 
    )
    $parmset = @()   # Create a collection object.
   
    # Add the parameters we need to use...
    $parmset += (Add-UdfParameter "@vGetWorklistResponse" "Input" "$pWorkListjson" "string" -1)
    $parmset += (Add-UdfParameter "@vFacilityCode" "Input" "$pFacilityCode" "string" -1)
    $parmset += (Add-UdfParameter "@vEpremisCID" "Input" "$pEpremisCID" "string" -1)
    $parmset += (Add-UdfParameter "@vClientName" "Input" "$pClientName" "string" -1)

   
    $spExecParams = @{
        sqlconnstring = $connstring
        sqlspname     = $spname
        parameterset  = $parmset
    }
    Invoke-UdfStoredProcedure @spExecParams;
}

$Fdata = Invoke-Sqlcmd -ServerInstance "PRDAMATWSQL01\RPA_DEV" -Database "DTO_DB" -Query "select c.FacilityCode, c.FacilitySystem as ClientName, cd.EpremisCID 
from dbo.ClientNameMappingTemp as c
left join dbo.SHOV_DC_FacilityCIDMap as cd
on c.FacilityCode = cd.FacilityID" -OutputAs DataTables

foreach ( $rowid in $Fdata.Rows){




$FLIST = Get-ChildItem -Path $fOLDER -Filter "*$($rowid.FacilityCode)*" 

if ($FLIST){

   $WorkListjson = Get-Content -Path $FLIST.FullName | Out-String

    $worklistspParams = @{
                connstring    = "Data Source=PRDAMATWSQL01\RPA_DEV;Integrated Security=SSPI;Initial Catalog=DTO_DB"
                spname        = "usp_SHOV_DC_InsertWorkList"
                pWorkListjson = $WorkListjson
                pFacilityCode = $rowid.FacilityCode
                pEpremisCID   = $rowid.EpremisCID
                pClientName   = $rowid.ClientName
            }                            
            $InsertWorkListData = Invoke-udfExecInsertWorkListSP @worklistspParams;

            if ($InsertWorkListData.Success -eq $true) {
                Write-Host "json parsing done successfully"
            }
            else {
                Write-Host "Error while parsing the json."
                Write-Host $InsertWorkListData.Errors.Exception.Message 
            }

 

}

}