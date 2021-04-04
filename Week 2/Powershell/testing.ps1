<#
https://poshcode.gitbook.io/powershell-practice-and-style/style-guide/documentation-and-comments
.SYNOPSIS
Prints Name and Age
.DESCRIPTION
Prints Name and Age, Age times
.PARAMETER Name
Name to print
.PARAMETER Age 
Age to print

.EXAMPLE
./testing.ps1 -name "asd" -age 3
#>
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true) ]
    [string]$Name,
    [Parameter(Mandatory=$true, ValueFromPipeline=$true) ]
    [int]$Age

)

for ($i = 0; $i -lt $Age; $i++) {
        Write-Output "$Name is $Age old"
}