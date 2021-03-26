#Request elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}


#Refresh env vars
$RefEnv = '$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")'


#Check if choco is installed
Write-Host "Checking if Chocolatey is installed" -ForegroundColor Cyan
$IsChocoInstaleld = Invoke-Expression -Command "choco -v" 2>$null
Write-Host
if(-Not($IsChocoInstaleld)){
    Write-Host "Chocolatley is missing, fatching installation files.." -ForegroundColor Red
    Write-Host
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    Invoke-Expression -Command $RefEnv
    $IsChocoInstaleld = Invoke-Expression -Command "choco -v"  2>$null
} 
Write-Host "Chocolatey is installed." -ForegroundColor Green;
Write-Host "Choco Version = $IsChocoInstaleld" -ForegroundColor Green;


#Install postgresql
Write-Host
Write-Host "Installing PostgreSQL" -ForegroundColor Cyan

$PostgresqlService = Get-Service -Name "postgresql*"
if(-Not($PostgresqlService)){
    Invoke-Expression -Command "choco install postgresql13 -yf --params '/Password:123123' --ia '--serverport 5432'"
    Invoke-Expression -Command $RefEnv
}
Write-Host "PosgreSQL is installed." -ForegroundColor Green;

#Configure postgresql to allow connection with password 
Write-host "Configuring postgresql" -ForegroundColor Cyan

#Listen to all
$PostgresqlConf = (Get-Childitem -Path "C:\Program Files\PostgreSQL" -Include "postgresql.conf" -File -Recurse -ErrorAction SilentlyContinue).FullName
if(-Not($PostgresqlConf)){
   $PostgresqlConf = Read-Host "Cant find 'postgresql.conf' please provide full path to file (Should be in <PostgreSQL installation folder>\Data)" -ForegroundColor Red
}
(Get-Content -Path $PostgresqlConf) | ForEach-Object {
    $_.Replace("#listen_addresses = 'localhost'","listen_addresses = '*'")
} | Set-Content -Path $PostgresqlConf

#allows access to all databases for all users with an encrypted password
$pg_hba = (Get-Childitem -Path "C:\Program Files\PostgreSQL" -Include "pg_hba.conf" -File -Recurse -ErrorAction SilentlyContinue).FullName
if(-Not($pg_hba)){
   $pg_hba = Read-Host "Cant find 'pg_hba.conf' please provide full path to file (Should be in <PostgreSQL installation folder>\Data)" -ForegroundColor Red
}
$NewPgHba = ""
(Get-Content -Path $pg_hba) | ForEach-Object {
    $NewPgHba += $_+"`n"
    if($_ -match "# TYPE  DATABASE        USER            ADDRESS                 METHOD") {
        $NewPgHba += "host  all  all 0.0.0.0/0 md5`n"
    }
} 
$NewPgHba | Set-Content -Path $pg_hba


#Restart posgresql service inorder for the changes to take effect
Write-Host "Restarting server" -ForegroundColor Cyan
Restart-Service -Name "postgresql*"


#Allow TCP Port 5432
Write-Host "Allowing TCP port 5432 inbound for all connections" -ForegroundColor Cyan
Invoke-Expression -Command 'netsh advfirewall firewall add rule name="Open Port 5432" dir=in action=allow protocol=TCP localport=5432'


Write-Host "Done" -ForegroundColor Green
Pause
