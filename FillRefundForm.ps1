Param (
	[string]$Ministry,
	[string]$PatientClaimNumber,
    [string]$LogFilePath,
    [string]$OutputFilePath,
    [string]$InputFilePath,
    [string]$DllFilePath,
    [string]$DateOfReq,
    [string]$TableSpace,
    [string]$PatientName,
    [string]$OurClaimNumber,
    [string]$InsurancePolicyNumber,
    [string]$InsuranceCompanyName,
    [string]$InsuranceCompanyAdd1,
    [string]$InsuranceCompanyAdd2,
    [string]$DateOfService,
    [string]$ClaimNumber,
    [string]$CPT1,
    [string]$CPT2,
    [string]$CPT3,
    [string]$CPT4,
    [string]$RefundAmount1,
    [string]$RefundAmount2,
    [string]$RefundAmount3,
    [string]$RefundAmount4,
    [string]$TotalRefundAmount,
    [string]$ReasonForRefund,
    [string]$NameOfRequester,
    [string]$PreparedBy,
    [string]$PhoneNumberRequester,
    [string]$RefundedBy
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

#region arguments validation
Write-Log -Level INFO -Message "Arguments validation initiated" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber

if ($OutputFilePath -eq [string]$null)
{
    Write-Log -Level ERROR -Message "OutputFilePath is empty" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Exit
}

if ($InputFilePath -eq [string]$null)
{
    Write-Log -Level ERROR -Message "InputFilePath parameter is empty" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Exit
}

if ($DllFilePath -eq [string]$null)
{
    Write-Log -Level ERROR -Message "DllFilePath parameter is empty" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Exit
}

if ($PatientClaimNumber -eq [string]$null)
{
    Write-Log -Level ERROR -Message "PatientClaimNumber parameter is empty" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Write-Log -Level EXECUTION -Message "PowerShell script execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber
    Exit
}

#endregion


## Path to the PDF form you'd like to fill in 
#$change_form = '\\R1-UEM-1\UEM_Profiles\US28042\profile\Desktop\Packet-Prep\Andrius_POC\New_Blank_Document.pdf' 
  
#region Create the unique control number 
#$Patient_Name 
#$Claim_Number 
#$Policy_Number 
#$Company_Name 
#$CPT1 
#$CPT2 
#$CPT3
#$Refund_Amount 
#$PSCommandPath
#endregion

## Concatinating Patient first and last name
#$Patient_Name = "$First_Name"+" "+"$Last_Name"
  
## Path to the output PDF form where you'd like to save
#$output_file = "\\R1-UEM-1\UEM_Profiles\US28042\profile\Desktop\Packet-Prep\Andrius_POC\MyForm1.pdf" 
  
## Load the iTextSharp DLL to do all the heavy-lifting 
#[System.Reflection.Assembly]::LoadFrom('\\R1-UEM-1\UEM_Profiles\US28042\profile\Documents\Automation Anywhere Files\Automation Anywhere\My Scripts\PacketPrep\itextsharp.dll') | Out-Null 
[System.Reflection.Assembly]::LoadFrom($DllFilePath) | Out-Null 

  
## Instantiate the PdfReader object to open the PDF 
$reader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $InputFilePath 
  
## Instantiate the PdfStamper object to insert the form fields to 
$stamper = New-Object iTextSharp.text.pdf.PdfStamper($reader,[System.IO.File]::Create($OutputFilePath)) 
  
## Create a hash table with all field names and properties 
$pdf_fields =@{ 
    'untitled1'  =  $DateOfReq 
    'untitled2'  =  $TableSpace
    'untitled3'  =  $PatientName
    'untitled4'  =  $OurClaimNumber
    'untitled5'  =  $InsurancePolicyNumber
    'untitled6'  =  $InsuranceCompanyName
    'untitled9'  =  $DateOfService
    'untitled10' =  $ClaimNumber
    'untitled11' =  $InsuranceCompanyAdd1
    'untitled12' =  $InsuranceCompanyAdd2
    'untitled13' =  $CPT1
    'untitled17' =  $RefundAmount1
    'untitled18' =  $RefundAmount2
    'untitled19' =  $RefundAmount3
    'untitled20' =  $RefundAmount4
    'untitled21' =  $TotalRefundAmount
    'untitled22' =  $ReasonForRefund
    'untitled23' =  $NameOfRequester
    'untitled24' =  $PreparedBy
    'untitled25' =  $PhoneNumberRequester
    'untitled26' =  $RefundedBy
    'untitled27' =  $CPT2
    'untitled28' =  $CPT3
    'untitled29' =  $CPT4
} 

## Apply all hash table elements into the PDF form 
foreach ($field in $pdf_fields.GetEnumerator()) { 
    $stamper.AcroFields.SetField($field.Key, $field.Value) | Out-Null 
} 

## Making filled pdf form non-editable while saving 
$stamper.FormFlattening=$true
  
## Close  
$stamper.Close()

Write-Log -Level EXECUTION -Message "Execution completed" -logfile $LogFilePath -Min $Ministry -PCN $PatientClaimNumber 
exit 1
#$reader.AcroFields.Fields 
