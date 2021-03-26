#!/bin/bash
echo "Welcome to this NodeJS app deployment script"
echo

#Install NodeJS/NPM
echo "Checking if NodeJS/NPM is installed" 
isNodeInstaleld="node -v" 
isNpmInstaleld="npm -v" 

echo
if [[ -z "$isNodeInstaleld" ]] || [[ -z "$isNpmInstaleld" ]]; then
    echo "NodeJS/NPM is missing, fatching installation files.."
    echo
    sudo curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n
    echo "NInstalling now..."
    sudo bash n lts
    
    isNodeInstaleld="node -v" 
    isNpmInstaleld="npm -v" 
fi

echo "NodeJS/NPM installed." 
echo "NodeJS Version=$($isNodeInstaleld)" 
echo "NPM Version=$($)isNpmInstaleld)" 
echo


#Create App Directory
echo "Looking for default working Dir" 
wwwDir="./wwwroot"
if [ ! -d "$wwwDir" ]; then
    echo "$($wwwDir) is missing, creating now..."
    mkdir "$wwwDir"
fi

echo "$($wwwDir) has been found"  

echo "Settings new working dir to: $wwwDir" 
cd "$wwwDir"
echo


#Clone app and Install missing packages
echo "Clonning app from git" 
gitUrl="https://github.com/Eduardgur/WeightTrackerTst.git"
repoName="${gitUrl%.git}"
repoName="${repoName##*/}"
cd "$repoName"
sudo git clone "$gitUrl"

echo "Installing missing packages" 
sudo npm install
echo


#Installing net tools
sudo apt install net-tools


#Editing .env file --- Add manual mode
echo "Configuring .env file" 
defaultExternalIp="{EXTERNAL_IP}"
defaultPublicIp="{PUBLIC_IP}"
defaultOktaUrl="{OKTA_URL}"
defaultOktaId="{OKTA_ID}"
defaultOktSec="{OKTA_SECRET}"
defaultDbIp="{DB_IP}"

envFile="$($wwwRoot)$($repoName).env"

externalIp="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"
publicIp="$(curl ipinfo.io/ip)"
read "Please type postgres ip address" dbIp
oktaUrl=Read-Host "Please type okta full url (including https://)"
oktaId=Read-Host "Please type okta client ID"
oktaSec=Read-Host "Please type okta client secret"

(Get-Content $EnvFilePath) | ForEach-Object {
    $_.Replace($DefaultPublicIp, $PublicIp).Replace($DefaultExternalIp, $ExternalIp).Replace($DefaultOktaUrl, $OktaUrl).Replace($DefaultOktaId, $OktaId).Replace($DefaultOktSec, $OktaSec).Replace($DefaultDbIp, $DbIp) 
 } | Set-Content $EnvFilePath

echo ".env file edited" isNpmInstaleld
echo


#Initializing DB
echo "Initializing DB" 
sudo npm run initdb
echo


#Allow TCP Port 80
echo "Allowing TCP port 80 inbound for all connections"
'netsh advfirewall firewall add rule name="Open Port 80" dir=in action=allow protocol=TCP localport=80'
echo

#PM2
echo "Installing PM2"
"npm install -g pm2" 
echo "Starting bootstrap.js" 
"pm2 start $repoDir\bootstrap.js" 
echo "Saving state" 
"pm2 save -f" 
echo

#Create server restart task
echo "Registering startup task"
$TaskName="NodeJS App"
$RestartScriptName="PM2Resurrect.ps1"
New-Item -Path $repoDir -Name $RestartScriptName -ItemType "file" -Value "Invokexpression -Command 'pm2 resurrect'" -Force 
$TaskAction=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-File "$repoDir\$RestartScriptName"'
$TaskTrigger=New-JobTrigger -AtStartup -RandomDelay 00:00:30
$TaskPrincipal=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
$TaskDefinition=New-ScheduledTask -Action $TaskAction -Principal $TaskPrincipal -Trigger $TaskTrigger  -Description "Run $($TaskName) at startup"
Register-ScheduledTask -TaskName $taskName -InputObject $TaskDefinition

#Register-ScheduledJob -Trigger $TaskTrigger -FilePath "$repoDir\PM2Resurrect.ps1" -Name $TaskName 


echo "Done !" isNpmInstaleld  
 
pause