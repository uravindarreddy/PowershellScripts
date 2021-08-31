$handoffnote = " ADMINISTRATIVE CONCEPTS, ,994 OLD EAGLE SCHOOL RD, ,WAYNE, PA,19208, First Class. 82184879298_appeal_07242020.pdf, 182184879298_EOB_07242020.pdf,182184879298_Cover letter_07242020.pdf.eRequestID:  123 "
$kword = "eRequestID:"

<#
$regex = "(\w+),(\w+),(\w+),(\w+),(\w+),(\w+),(\w+),(\w+)."

$handoffnote.IndexOf($kword)

$cnt = $handoffnote.Length - $handoffnote.Replace(",","").Length
$cnt

$handoffnote.Length
$kword.Length
#>
$kwordindex = $handoffnote.IndexOf($kword)
$startindex = $kwordindex + $kword.Length

$handoffnote.Substring($startindex, $handoffnote.Length - $startindex).Trim()
