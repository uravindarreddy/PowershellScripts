﻿& ([scriptblock]::Create((iwr -uri http://tinyurl.com/Install-GitHubHostedModule).Content)) -GitHubUserName Positronic-IO -ModuleName PSImaging -Branch 'master' -Scope CurrentUser

Export-ImageText -Path "C:\TestIn\XLP41737-1.xps"


dir "C:\TestIn\Sample Image.png" | ? {Export-ImageText $_.FullName}


function Test-Image {

    [CmdletBinding()]

    [OutputType([System.Boolean])]

    param(

        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]

        [ValidateNotNullOrEmpty()]

        [Alias('PSPath')]

        [string] $Path

    )

    PROCESS {

        $knownHeaders = @{

            jpg = @( "FF", "D8" );

            bmp = @( "42", "4D" );

            gif = @( "47", "49", "46" );

            tif = @( "49", "49", "2A" );

            png = @( "89", "50", "4E", "47", "0D", "0A", "1A", "0A" );

            pdf = @( "25", "50", "44", "46" );

        }

        # coerce relative paths from the pipeline into full paths

        if($_ -ne $null) {

            $Path = $_.FullName

        }

         # read in the first 8 bits

        $bytes = Get-Content -LiteralPath $Path -Encoding Byte -ReadCount 1 -TotalCount 8 -ErrorAction Ignore

         $retval = $false

        foreach($key in $knownHeaders.Keys) {

             # make the file header data the same length and format as the known header

            $fileHeader = $bytes |

                Select-Object -First $knownHeaders[$key].Length |

                ForEach-Object { $_.ToString("X2") }

            if($fileHeader.Length -eq 0) {

                continue

            }

             # compare the two headers

            $diff = Compare-Object -ReferenceObject $knownHeaders[$key] -DifferenceObject $fileHeader

            if(($diff | Measure-Object).Count -eq 0) {

                $retval = $true

            }

        }

        return $retval

    }

}

Test-Image "C:\TestIn\Sample Image.png"

Test-Image "C:\TestIn\XLP41737-1.xps"


Test-Image "\\R1-UEM-1\UEM_Profiles\US35107\profile\Downloads\text-pdf.pdf"

Test-Image "\\R1-UEM-1\UEM_Profiles\US35107\profile\Downloads\XLP36303-1.pdf"

Test-Image "C:\Testout\XLP41737-1.pdf"

Start-Process "C:\TestIn\XLP41737-1.xps" -Verb Print