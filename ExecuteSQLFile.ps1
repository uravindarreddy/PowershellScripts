$DBConnString = "Data Source=AUTOMATE02;Integrated Security=SSPI;Initial Catalog=DTO_DB"
$SqlQuery = "BEGIN TRY
	BEGIN TRAN

	DELETE
	FROM dbo.SHOV_Charity_Map

	INSERT INTO dbo.SHOV_Charity_Map (
		[FacilityCode]
		,[HospitalName]
		,[ApplicationName]
		,[NumOfPages]
		)
	VALUES (
		'ABIL'
		,'AMITA Health Adventist Medical Center Bolingbrook'
		,'Amita Health-9'
		,'9'
		)
		,(
		'AGIL'
		,'AMITA Health Adventist Medical Center Glen Oaks'
		,'Amita Health-9'
		,'9'
		)
		,(
		'AHIL'
		,'AMITA Health Adventist Medical Center Hinsdale'
		,'Amita Health-9'
		,'9'
		)
		,(
		'ALIL'
		,'AMITA Health Alexian Brothers Medical Center Elk Grove Village'
		,'Amita Health-9'
		,'9'
		)
		,(
		'AMIL'
		,'AMITA Health Adventist Medical Center LaGrange'
		,'Amita Health-9'
		,'9'
		)
		,(
		'ASIN'
		,'Carmel Ambulatory Surgery Center'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'BACC'
		,'Borgess Woodbridge Center LLC'
		,'Borgess Charity-7'
		,'7'
		)
		,(
		'BAOK'
		,'Ascension St. John Broken Arrow'
		,'St John OK Charity-5'
		,'5'
		)
		,(
		'BHTN'
		,'St. Thomas Midtown Hospital'
		,'St Thomas Health Charity-9'
		,'9'
		)
		,(
		'BMAL'
		,'St. Vincent''s Health System'
		,'St Vincent''s AL Charity-5'
		,'5'
		)
		,(
		'BOAH'
		,'Ascension Borgess Allegan'
		,'Ascension Borgess Allegan-8'
		,'8'
		)
		,(
		'BOGI'
		,'Borgess Ambulatory'
		,'Borgess Charity-7'
		,'7'
		)
		,(
		'BOLE'
		,'Ascension Borgess-Lee Hospital'
		,'Borgess Charity-7'
		,'7'
		)
		,(
		'BOMC'
		,'Ascension Borgess Hospital'
		,'Borgess Charity-7'
		,'7'
		)
		,(
		'BOSU'
		,'Borgess Ambulatory Surgery'
		,'Borgess Charity-7'
		,'7'
		)
		,(
		'BPHC'
		,'Ascension Borgess-Pipp Hospital'
		,'Borgess Charity-7'
		,'7'
		)
		,(
		'BSTX'
		,'Ascension Seton Bastrop'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'BTAL'
		,'St. Vincent''s Health System'
		,'St Vincent''s AL Charity-5'
		,'5'
		)
		,(
		'CAWI'
		,'Ascension Calumet Medical Center'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'CCWI'
		,'Columbia St. Marys Womens Hospital'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'CHAL'
		,'St. Vincent''s Chilton'
		,'St Vincent''s AL Charity-5'
		,'5'
		)
		,(
		'CHMI'
		,'Ascension Providence Rochester Hospital'
		,'Crittenton Charity-7'
		,'7'
		)
		,(
		'CHTX'
		,'Seton Shoal Creek Hospital'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'CLIN'
		,'St Vincent Clay Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'CPTX'
		,'Cedar Park Regional Medical Center'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'DCTX'
		,'Dell Children''s Medical Center of Central Texas'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'DPTX'
		,'Ascension Providence DePaul Center'
		,'Providence TX Charity-9'
		,'9'
		)
		,(
		'DSTX'
		,'Dell Seton Medical Center'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'ECIN'
		,'Endoscopy Center'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'EDTX'
		,'Ascension Seton Edgar B. Davis Hospital'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'EMFL'
		,'Ascension Sacred Heart Emerald Coast'
		,'Sacred Heart FL Charity-5'
		,'5'
		)
		,(
		'ERWI'
		,'Ascension Eagle River Memorial Hospital'
		,'Ministry Aspirus Charity-9'
		,'9'
		)
		,(
		'ESAL'
		,'St. Vincent''s Health System'
		,'St Vincent''s AL Charity-5'
		,'5'
		)
		,(
		'GRMC'
		,'Ascension Genesys Hospital'
		,'Ascension St Mary''s Charity-9'
		,'9'
		)
		,(
		'HEIL'
		,'AMITA Health Alexian Brothers Behavioral Health Hospital Hoffman Estates'
		,'Amita Health-9'
		,'9'
		)
		,(
		'HLTX'
		,'Ascension Seton Highland Lakes Hospital'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'HMTX'
		,'Ascension Seton Hays'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'HOWI'
		,'Ascension Howard Young Medical Center'
		,'Ministry Aspirus Charity-9'
		,'9'
		)
		,(
		'JAKS'
		,'Ascension Via Christi St. Joseph'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'JBKS'
		,'Ascension Via Christi St. Joseph'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'JCIL'
		,'AMITA Health Saint Joseph Hospital Chicago'
		,'Amita English-9'
		,'9'
		)
		,(
		'JEIL'
		,'AMITA Health Saint Joseph Hospital Elgin'
		,'Amita English-9'
		,'9'
		)
		,(
		'JPOK'
		,'Ascension St. John Jane Phillips'
		,'St John OK Charity-5'
		,'5'
		)
		,(
		'LHFL'
		,'Lakeland Regional Health Medical Center'
		,'Lakeland Charity-3'
		,'3'
		)
		,(
		'MCOK'
		,'Ascension St. John Medical Center'
		,'St John OK Charity-5'
		,'5'
		)
		,(
		'MCTX'
		,'Ascension Seton Medical Center Austin'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'MCWI'
		,'Ascension Columbia St. Mary''s Milwaukee'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'MEWI'
		,'Ascension NE Wisconsin Mercy Hospital'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'MGWI'
		,'Ascension Ministry Good Samaritan Health Center'
		,'Ministry Aspirus Charity-9'
		,'9'
		)
		,(
		'MHKS'
		,'Ascension Via Christi Hospital in Manhattan'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'MIWI'
		,'Ascension Saint Michaels Hospital'
		,'Ministry Aspirus Charity-9'
		,'9'
		)
		,(
		'MPWI'
		,'Ministry Medical Group'
		,'Ministry Charity-9'
		,'9'
		)
		,(
		'MSWI'
		,'Ascension Sacred Heart Hospital'
		,'Ministry Aspirus Charity-9'
		,'9'
		)
		,(
		'MTTN'
		,'St. Thomas Rutherford Hospital'
		,'St Thomas Health Charity-9'
		,'9'
		)
		,(
		'NHOK'
		,'Ascension St. John Nowata'
		,'St John OK Charity-5'
		,'5'
		)
		,(
		'NRIN'
		,'Naab Road Surgery Center'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'OCWI'
		,'Ascension Columbia St. Mary''s Ozaukee'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'OHOK'
		,'Ascension St. John Owasso Hospital'
		,'St John OK Charity-5'
		,'5'
		)
		,(
		'OLWI'
		,'Ascension Our Lady of Victory Hospital'
		,'Ministry Aspirus Charity-9'
		,'9'
		)
		,(
		'PFIL'
		,'AMITA Health Saint Francis Hospital Evanston'
		,'Amita English-9'
		,'9'
		)
		,(
		'PHAL'
		,'Providence Hospital'
		,'Providence AL Charity-9'
		,'9'
		)
		,(
		'PHDC'
		,'Providence Hospital'
		,'Providence DC Charity-7'
		,'7'
		)
		,(
		'PHIL'
		,'AMITA Health Holy Family Medical Center Des Plaines'
		,'Amita English-9'
		,'9'
		)
		,(
		'PJIL'
		,'AMITA Health Saint Joseph Medical Center Joliet'
		,'Amita English-9'
		,'9'
		)
		,(
		'PKIL'
		,'AMITA Health St. Marys Hospital Kankakee'
		,'Amita English-9'
		,'9'
		)
		,(
		'PMIL'
		,'AMITA Health Mercy Medical Center Aurora'
		,'Amita English-9'
		,'9'
		)
		,(
		'PNTX'
		,'Ascension Providence'
		,'Providence TX Charity-9'
		,'9'
		)
		,(
		'PRIL'
		,'AMITA Health Resurrection Medical Center Chicago'
		,'Amita English-9'
		,'9'
		)
		,(
		'PSIL'
		,'AMITA Health Saints Mary and Elizabeth Medical Center Chicago'
		,'Amita English-9'
		,'9'
		)
		,(
		'RHKS'
		,'Ascension Via Christi Rehabilitation Hospital'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'RHTN'
		,'St. Thomas Stones River'
		,'St Thomas Health Charity-9'
		,'9'
		)
		,(
		'RHTX'
		,'Ascension Seton Smithville'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'RPTN'
		,'St. Thomas River Park Hospital'
		,'St Thomas Health Charity-9'
		,'9'
		)
		,(
		'SAMD'
		,'St. Agnes Hospital'
		,'St Agnes Charity-3'
		,'3'
		)
		,(
		'SAWI'
		,'Ascension Saint Marys Hospital'
		,'Ministry Aspirus Charity-9'
		,'9'
		)
		,(
		'SCAL'
		,'St. Vincent''s Health System'
		,'St Vincent''s AL Charity-5'
		,'5'
		)
		,(
		'SCFL'
		,'Ascension St. Vincent''s Clay County'
		,'St Vincents HOPE Charity-25'
		,'25'
		)
		,(
		'SCWI'
		,'Ascension Saint Clares Hospital'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'SDTN'
		,'St. Thomas DeKalb'
		,'St Thomas Health Charity-9'
		,'9'
		)
		,(
		'SEIN'
		,'St Vincent Evansville'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'SEWI'
		,'Ascension NE Wisconsin St. Elizabeth Hospital'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'SHWI'
		,'Sacred Heart Rehabilitation Institute'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'SJMA'
		,'Ascension Macomb-Oakland Hospital, Warren Campus'
		,'Ascension Southeast Michigan Charity-7'
		,'7'
		)
		,(
		'SJMC'
		,'Ascension St. John Hospital'
		,'Ascension Southeast Michigan Charity-7'
		,'7'
		)
		,(
		'SJOK'
		,'Ascension Macomb-Oakland Hospital, Madison-Heights Campus'
		,'Ascension Southeast Michigan Charity-7'
		,'7'
		)
		,(
		'SJPK'
		,'Ascension Providence Hospital, Novi Campus'
		,'Ascension Southeast Michigan Charity-7'
		,'7'
		)
		,(
		'SJPR'
		,'Ascension Providence Hospital, Southfield Campus'
		,'Ascension Southeast Michigan Charity-7'
		,'7'
		)
		,(
		'SJRD'
		,'Ascension River District Hospital'
		,'Ascension Southeast Michigan Charity-7'
		,'7'
		)
		,(
		'SLFL'
		,'Ascension St. Vincents Southside'
		,'St Vincents HOPE Charity-25'
		,'25'
		)
		,(
		'SMMC'
		,'Ascension St. Mary''s Hospital'
		,'Ascension St Mary''s Charity-9'
		,'9'
		)
		,(
		'SMSH'
		,'Ascension Standish Hospital'
		,'Ascension St Mary''s Charity-9'
		,'9'
		)
		,(
		'SMWI'
		,'Columbia St. Marys Community Physicians'
		,'Ascension WI Charity-11'
		,'11'
		)
		,(
		'SNTX'
		,'Ascension Seton Northwest'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'SPOK'
		,'Ascension St. John Sapulpa'
		,'St John OK Charity-5'
		,'5'
		)
		,(
		'SSIN'
		,'St Vincent Seton Specialty Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'SSTX'
		,'Ascension Seton Southwest'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'STIL'
		,'AMITA Health St. Alexius Medical Center Hoffman Estates'
		,'Amita Health-9'
		,'9'
		)
		,(
		'STIN'
		,'St Vincent Stress Center'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'STKS'
		,'Ascension Via Christi St. Teresa'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'STTN'
		,'St. Thomas West Hospital'
		,'St Thomas Health Charity-9'
		,'9'
		)
		,(
		'SVFL'
		,'Ascension St. Vincents Riverside'
		,'St Vincents HOPE Charity-25'
		,'25'
		)
		,(
		'SVIN'
		,'St Vincent Hospital and Health Care'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'SWIN'
		,'St Vincent Warrick'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'TAWA'
		,'Ascension St. Joseph Hospital'
		,'Ascension St Mary''s Charity-9'
		,'9'
		)
		,(
		'THTN'
		,'St. Thomas Highlands'
		,'St Thomas Health Charity-9'
		,'9'
		)
		,(
		'UBTX'
		,'University Medical Center at Brackenridge'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'VAIN'
		,'St Vincent Anderson Regional Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VCIN'
		,'St Vincent Carmel Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VDIN'
		,'St Vincent Dunn Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VEIN'
		,'St Vincent Evansville Sorian'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VFIN'
		,'St Vincent Fishers Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VFKS'
		,'Ascension Via Christi St. Francis'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'VHIN'
		,'St Vincent Heart Center'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VJIN'
		,'St Vincent Jennings Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VJKS'
		,'Ascension Via Christi St. Joseph'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'VKIN'
		,'St. Vincent Kokomo'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VMIN'
		,'St Vincent Mercy Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VOIN'
		,'Ascension St. Vincent Evansville Orthopedic Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VPKS'
		,'Ascension Via Christi Hospital in Pittsburg'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'VRIN'
		,'St Vincent Randolph Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VSIN'
		,'St Vincent Salem Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VWIN'
		,'St Vincent Williamsport Hospital'
		,'St Vincent''s IN Charity-9'
		,'9'
		)
		,(
		'VWKS'
		,'Ascension Via Christi Behavioral Health Center'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'WHKS'
		,'Wamego Health Center'
		,'Via Christi Charity-9'
		,'9'
		)
		,(
		'WMTX'
		,'Ascension Seton Williamson'
		,'Seton Hospital Charity-5'
		,'5'
		)
		,(
		'WPWI'
		,'Ascension Medical Group'
		,'Ascension WI Charity-11'
		,'11'
		);

	COMMIT TRAN
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN;
	END;

	THROW;
END CATCH;"


function Invoke-UdfSQLQuery {
    param(
        [string] $connectionString,
        [string] $sqlCommand
    )
    $sqlDataAdapterError = $null
    
    try {
        $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
        $command = new-object system.data.sqlclient.sqlcommand($sqlCommand, $connection)
        $command.CommandTimeout = 0
        $connection.Open()
    
        $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null
    }
    catch {
        $sqlDataAdapterError = $_
        $dataset = $null        
    }
    finally {
        $connection.Close()
    }

    [PSCustomObject] @{
        DataSet = $dataSet
        Errors  = $sqlDataAdapterError
        Success = if ($null -eq $sqlDataAdapterError) { $true } else { $false }
    }
}

$SqlOutput = Invoke-UdfSQLQuery -connectionString $DBConnString -sqlCommand $SqlQuery;

if ( $SqlOutput.Success -eq $true) {

    Write-Output "Query Executed successfully"
    $TableCount = $SqlOutput.DataSet.Tables.Count 

    if ($TableCount -gt 0) {
        for (($i = 0); $i -lt $TableCount; $i++) {
            $SqlOutput.DataSet.Tables[$i].Rows | Out-GridView
        }

    }
}
else {
    Write-Host $SqlOutput.Errors -BackgroundColor DarkMagenta;
}
