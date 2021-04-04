#Request elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

Write-Host "Welcome to this NodeJS app deployment script"
Write-Host

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

Write-Host



#Install NodeJS/NPM
Write-Host "Checking if NodeJS/NPM is installed" -ForegroundColor Cyan
$IsNodeInstaleld = Invoke-Expression -Command "node -v" 2>$null
$IsNpmInstaleld = Invoke-Expression -Command "npm -v" 2>$null

Write-Host
if(-Not($IsNodeInstaleld) -Or -Not($IsNpmInstaleld)){
    Write-Host "NodeJS/NPM is missing, fatching installation files.." -ForegroundColor Red
    Write-Host
    Invoke-Expression -Command "choco install nodejs -yf"
    Invoke-Expression -Command $RefEnv
    $IsNodeInstaleld = Invoke-Expression -Command "node -v" 2>$null
    $IsNpmInstaleld = Invoke-Expression -Command "npm -v" 2>$null
} 
Write-Host "NodeJS/NPM installed." -ForegroundColor Green;
Write-Host "NodeJS Version = $IsNodeInstaleld" -ForegroundColor Green;
Write-Host "NPM Version = $IsNpmInstaleld" -ForegroundColor Green;
Write-Host



#Install Git
Write-Host "Checking if Git is installed" -ForegroundColor Cyan
$IsGitInstaleld = Invoke-Expression -Command "git --version" 2>$null
Write-Host
if(-Not($IsGitInstaleld)){
    Write-Host "Git is missing, fatching installation files.." -ForegroundColor Red
    Write-Host
    Invoke-Expression -Command "choco install git.install -yf --params '/GitOnlyOnPath'"
    Invoke-Expression -Command $RefEnv
    $IsGitInstaleld = Invoke-Expression -Command "git --version" 2>$null
} 
Write-Host "Git is installed." -ForegroundColor Green;
Write-Host "Git Version = $IsGitInstaleld" -ForegroundColor Green;
Write-Host


#Create App Directory
Write-Host "Looking for default working Dir" -ForegroundColor Cyan
$WwwDir = "c:\wwwroot"
if(-Not (Test-Path $WwwDir)){
    Write-Host "$WwwDir is missing, creating now..." -ForegroundColor Red
    New-Item -ItemType directory -Path $WwwDir 2>$null
}
Write-Host "$WwwDir has been found" -ForegroundColor Green 

Write-Host "Settings new working dir to: $WwwDir" -ForegroundColor Cyan
Set-Location -Path $WwwDir
Write-Host

#Clone app and Install missing packages
Write-Host "Clonning app from git" -ForegroundColor Cyan
$GitUrl = "https://github.com/Eduardgur/WeightTrackerTst.git"
$RepoName = $GitUrl.SubString($GitUrl.LastIndexOf('/') + 1, $GitUrl.LastIndexOf('.') - $GitUrl.LastIndexOf('/')-1);
$RepoDir = Join-Path $WwwDir $RepoName
Invoke-Expression -Command "git clone $GitUrl" 2>$null

Write-Host "Settings new working dir to: $RepoDir" -ForegroundColor Cyan
Write-Host "Installing missing packages" -ForegroundColor Cyan
Set-Location -Path $RepoDir
Invoke-Expression -Command "npm install"
Write-Host

#Editing .env file --- Add manual mode
Write-Host "Configuring .env file" -ForegroundColor Cyan
$DefaultExternalIp = "{EXTERNAL_IP}"
$DefaultPublicIp = "{PUBLIC_IP}"
$DefaultOktaUrl = "{OKTA_URL}"
$DefaultOktaId = "{OKTA_ID}"
$DefaultOktSec = "{OKTA_SECRET}"
$DefaultDbIp = "{DB_IP}"

$EnvFilePath = Join-Path -Path $RepoDir ".env"
#Add check if exists or create 

$ExternalIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPv4Address
#$InternalIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "vEthernet (nat)").IPAddress
$PublicIp = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$DbIp = Read-Host "Please type postgres ip address"
$OktaUrl = Read-Host "Please type okta full url (including https://)"
$OktaId = Read-Host "Please type okta client ID"
$OktaSec = Read-Host "Please type okta client secret"

(Get-Content $EnvFilePath) | ForEach-Object {
    $_.Replace($DefaultPublicIp, $PublicIp).Replace($DefaultExternalIp, $ExternalIp).Replace($DefaultOktaUrl, $OktaUrl).Replace($DefaultOktaId, $OktaId).Replace($DefaultOktSec, $OktaSec).Replace($DefaultDbIp, $DbIp) 
 } | Set-Content $EnvFilePath

Write-Host ".env file edited" -ForegroundColor Green
Write-Host


#Initializing DB
Write-Host "Initializing DB" -ForegroundColor Cyan
Invoke-Expression -Command "npm run initdb"
Write-Host


#Allow TCP Port 80
Write-Host "Allowing TCP port 80 inbound for all connections"
Invoke-Expression -Command 'netsh advfirewall firewall add rule name="Open Port 80" dir=in action=allow protocol=TCP localport=80'
Write-Host

#PM2
Write-Host "Installing PM2"-ForegroundColor Cyan
Invoke-Expression -Command "npm install -g pm2" 2>$null
Write-Host "Starting bootstrap.js" -ForegroundColor Cyan
Invoke-Expression -Command "pm2 start $RepoDir\bootstrap.js" 2>$null
Write-Host "Saving state" -ForegroundColor Cyan
Invoke-Expression -Command "pm2 save -f" 2>$null
Write-Host

#Create server restart task
Write-Host "Registering startup task"
$TaskName = "NodeJS App"
$RestartScriptName = "PM2Resurrect.ps1"
New-Item -Path $RepoDir -Name $RestartScriptName -ItemType "file" -Value "Invokexpression -Command 'pm2 resurrect'" -Force 2>$null
$TaskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-File "$RepoDir\$RestartScriptName"'
$TaskTrigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
$TaskDefinition = New-ScheduledTask -Action $TaskAction -Principal $TaskPrincipal -Trigger $TaskTrigger  -Description "Run $($TaskName) at startup"
Register-ScheduledTask -TaskName $taskName -InputObject $TaskDefinition


Write-Host "Done !" -ForegroundColor Green  
 
pause