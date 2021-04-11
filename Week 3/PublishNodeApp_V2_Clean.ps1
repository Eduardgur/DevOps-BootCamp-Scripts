param(
    [Parameter(Mandatory,Position=0)][string]$PublicIp,
    [Parameter(Mandatory,Position=1)][string]$DbIp,
    [Parameter(Mandatory,Position=2)][string]$OktaUrl,
    [Parameter(Mandatory,Position=3)][string]$OktaId,
    [Parameter(Mandatory,Position=4)][string]$OktaSec
)

Write-Output "Welcome to this NodeJS app deployment script"

#Refresh env vars
$RefEnv = '$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")'


#Check if choco is installed
Write-Output "Checking if Chocolatey is installed"
$IsChocoInstaleld = Invoke-Expression -Command "choco -v" 
if(-Not($IsChocoInstaleld)){
    Write-Output "Chocolatley is missing, fatching installation files.."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    Invoke-Expression -Command $RefEnv
    $IsChocoInstaleld = Invoke-Expression -Command "choco -v"  
} 
Write-Output "Chocolatey is installed."
Write-Output "Choco Version = $IsChocoInstaleld"



#Install NodeJS/NPM
Write-Output "Checking if NodeJS/NPM is installed"
$IsNodeInstaleld = Invoke-Expression -Command "node -v" 
$IsNpmInstaleld = Invoke-Expression -Command "npm -v" 

if(-Not($IsNodeInstaleld) -Or -Not($IsNpmInstaleld)){
    Write-Output "NodeJS/NPM is missing, fatching installation files.."
    Invoke-Expression -Command "choco install nodejs -yf"
    Invoke-Expression -Command $RefEnv
    $IsNodeInstaleld = Invoke-Expression -Command "node -v" 
    $IsNpmInstaleld = Invoke-Expression -Command "npm -v" 
} 
Write-Output "NodeJS/NPM installed."
Write-Output "NodeJS Version = $IsNodeInstaleld"
Write-Output "NPM Version = $IsNpmInstaleld"



#Install Git
Write-Output "Checking if Git is installed"
$IsGitInstaleld = Invoke-Expression -Command "git --version" 
if(-Not($IsGitInstaleld)){
    Write-Output "Git is missing, fatching installation files.."
    Invoke-Expression -Command "choco install git.install -yf --params '/GitOnlyOnPath'"
    Invoke-Expression -Command $RefEnv
    $IsGitInstaleld = Invoke-Expression -Command "git --version" 
} 
Write-Output "Git is installed."
Write-Output "Git Version = $IsGitInstaleld"



#Create App Directory
Write-Output "Looking for default working Dir"
$WwwDir = "c:\wwwroot"
if(-Not (Test-Path $WwwDir)){
    Write-Output "$WwwDir is missing, creating now..."
    New-Item -ItemType directory -Path $WwwDir 
}
Write-Output "$WwwDir has been found"  

Write-Output "Settings new working dir to: $WwwDir"
Set-Location -Path $WwwDir


#Clone app and Install missing packages
Write-Output "Clonning app from git"
$GitUrl = "https://github.com/Eduardgur/WeightTrackerTst.git"
$RepoName = $GitUrl.SubString($GitUrl.LastIndexOf('/') + 1, $GitUrl.LastIndexOf('.') - $GitUrl.LastIndexOf('/')-1);
$RepoDir = Join-Path $WwwDir $RepoName
Invoke-Expression -Command "git clone $GitUrl" 

Write-Output "Settings new working dir to: $RepoDir"
Write-Output "Installing missing packages"
Set-Location -Path $RepoDir
Invoke-Expression -Command "npm install"

#Editing .env file --- Add manual mode
Write-Output "Configuring .env file"
$DefaultExternalIp = "{EXTERNAL_IP}"
$DefaultPublicIp = "{PUBLIC_IP}"
$DefaultOktaUrl = "{OKTA_URL}"
$DefaultOktaId = "{OKTA_ID}"
$DefaultOktSec = "{OKTA_SECRET}"
$DefaultDbIp = "{DB_IP}"

$EnvFilePath = Join-Path -Path $RepoDir ".env"
$ExternalIp = (Get-NetIPAddress -AddressFamily IPv4 | ? {$_.InterfaceAlias -like "Ethe*"}).IPAddress


(Get-Content $EnvFilePath) | ForEach-Object {
    $_.Replace($DefaultPublicIp, $PublicIp).Replace($DefaultExternalIp, $ExternalIp).Replace($DefaultOktaUrl, $OktaUrl).Replace($DefaultOktaId, $OktaId).Replace($DefaultOktSec, $OktaSec).Replace($DefaultDbIp, $DbIp) 
 } | Set-Content $EnvFilePath

Write-Output ".env file edited" 



<# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 Install DB first (from app srv - no internet connection)
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #> 



#Initializing DB
Write-Output "Initializing DB"
Invoke-Expression -Command "npm run initdb"

#Allow TCP Port 80
Write-Host "Allowing TCP port 80 inbound for all connections"
Invoke-Expression -Command 'netsh advfirewall firewall add rule name="Open Port 80" dir=in action=allow protocol=TCP localport=80'
Write-Host

#PM2
Write-Output "Installing PM2"
Invoke-Expression -Command "npm install -g pm2" 
Invoke-Expression -Command "npm install -g @innomizetech/pm2-windows-service"
Invoke-Expression -Command $RefEnv
Write-Output "Starting bootstrap.js"
Invoke-Expression -Command "pm2 start $RepoDir\bootstrap.js --name WeightTrackerApp" 
Write-Output "Saving state"
Invoke-Expression -Command "pm2 save -f" 
Invoke-Expression -Command "pm2 kill"
Invoke-Expression -Command "pm2 resurrect" 
Invoke-Expression -Command "pm2-service-install -n PM2 --unattended" 

Write-Output "Done !" 
 
