$Output = Get-Process
New-Item -Path "C:\" -Name "1.txt" -Force
Write-Output "asd" | Set-Content "c:\1.txt"
$Output
return $Output