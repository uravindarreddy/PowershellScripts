[CmdletBinding()]
    param (
        [Parameter (Mandatory = $true, Position = 0)] [string] $DotxPath
        , [Parameter (Mandatory = $true, Position = 1)] [string] $WordFilePath
        , [Parameter (Mandatory = $true, Position = 2)] [string] $PDFFilePath
		, [Parameter (Mandatory = $true, Position = 3)] [string] $PatientName
		, [Parameter (Mandatory = $true, Position = 4)] [string] $ClaimNumber
		, [Parameter (Mandatory = $true, Position = 5)] [string] $InsurancePolicy
		, [Parameter (Mandatory = $true, Position = 6)] [string] $InsuranceCompanyName
        , [Parameter (Mandatory = $true, Position = 7)] [string] $LogFilePath
	    , [Parameter (Mandatory = $true, Position = 8)] [string] $Ministry
	    , [Parameter (Mandatory = $true, Position = 9)] [string] $PatientClaimNumber
    )

if ($LogFilePath -eq [string]$null)
{
   Exit 100
}



Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG","EXECUTION")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$True)]
    [string]
    $logfile,

    
    [Parameter(Mandatory=$True)]
    [string]
    $Min,

    
    [Parameter(Mandatory=$True)]
    [string]
    $PCN
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss.fff")
    $Content = [PSCustomObject]@{"Log Level" = $Level ; "Timestamp" = $Stamp; "CurrentTask" = $PSCommandPath; "Ministry" = $Ministry; "PatientClaimNumber" = $PatientClaimNumber; "Message" = $Message}
    If($logfile) {
        try
        {
            $Content | Export-Csv -Path $logfile -NoTypeInformation -Append           
        }
        catch
        {
            Write-Host $_.Exception.Message            
        }
    }
    Else {
        Write-Host $Message
    }
}

Write-Log -Level EXECUTION -Message "PowerShell script execution initiated" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber 

Function Write-UdfEditWordDoc {
    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true, Position = 0)] [string] $fDotxPath
        , [Parameter (Mandatory = $true, Position = 1)] [string] $fWordFilePath
        , [Parameter (Mandatory = $true, Position = 2)] [string] $fPDFFilePath
		, [Parameter (Mandatory = $true, Position = 3)] [string] $fPatientName
		, [Parameter (Mandatory = $true, Position = 4)] [string] $fClaimNumber
		, [Parameter (Mandatory = $true, Position = 5)] [string] $fInsurancePolicy
		, [Parameter (Mandatory = $true, Position = 6)] [string] $fInsuranceCompanyName
    )
    $ErrorMessage = $null;

    try {
   
        $Word = New-Object -ComObject word.application;
        if (!$Word) {
            Write-Error -Message "Unable to open Word. Please check install.";
        }
        #Hide it
        $Word.Visible = $false;
        #Open the template
        #$DotxPath = "C:\Users\ravindarreddyu\Documents\Custom Office Templates\SampleWordFile1.dotx";
        $Doc = $Word.Documents.Add($fDotxPath);
    
        ForEach ($Control in $Doc.ContentControls) {
            Switch ($Control.Title) {
                "PatientName" { $Control.Range.Text = $fPatientName };
                "ClaimNumber" { $Control.Range.text = $fClaimNumber };
                "InsurancePolicy" { $Control.Range.text = $fInsurancePolicy };
                "InsuranceCompanyName" { $Control.Range.text = $fInsuranceCompanyName};
            }
        }

        #$c = $Doc.ContentControls

        $FullDocPath = $fWordFilePath
        $Doc.saveAs([ref] $FullDocPath);

        $FullDocPath = $fPDFFilePath
        $Doc.saveAs([ref] $FullDocPath, [ref] 17);


    }
    catch {
        $ErrorMessage = $_;
    }
    finally {
        $Doc.Close() | Out-Null;
        $Word.Quit() | Out-Null;
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Word) | Out-Null;
    }
    [PSCustomObject] @{
        Errors  = $ErrorMessage
        Success = if ($null -eq $ErrorMessage) { $true } else { $false }
    }

}


#region arguments validation
Write-Log -Level INFO -Message "Arguments validation initiated" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber


if ($PatientClaimNumber -eq [string]$null)
{
    Write-Log -Level ERROR -Message "PatientClaimNumber parameter is empty" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Exit
}

#endregion

$wordParams = @{
    fDotxPath = $DotxPath
    fWordFilePath =  $WordFilePath                 
    fPDFFilePath = $PDFFilePath
} 
$result = Write-UdfEditWordDoc @wordParams;

if ($result.Success -eq $true)
{
    Write-Host "Success"
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber;   
    Exit 1
}
else
{
    Write-Host "Failure"
    # Catch this error code 0 which indicates error in Powershell script
    # Log this error using $result.ErrorMessage 
    Write-Log -Level ERROR -Message $result.ErrorMessage  -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber;
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber;
    Exit 0 
}
