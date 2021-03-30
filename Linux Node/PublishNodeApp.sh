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
    sudo curl -L "https://raw.githubusercontent.com/tj/n/master/bin/n" -o n
    echo "NInstalling now..."
    sudo bash n lts
    
    isNodeInstaleld="node -v" 
    isNpmInstaleld="npm -v" 
fi

echo "NodeJS/NPM installed." 
echo "NodeJS Version=$($isNodeInstaleld)" 
echo "NPM Version=$($isNpmInstaleld)" 
echo


#Create App Directory
echo "Looking for default working Dir" 
wwwDir=~/wwwroot
if [ ! -d "$wwwDir" ]; then
    echo "$wwwDir is missing, creating now..."
    sudo mkdir "$wwwDir"
    else
    echo "$wwwDir has been found"  
fi
echo

echo "Settings new working dir:" 
cd "$wwwDir"
pwd
echo


#Clone app and Install missing packages
echo "Clonning app from git" 
gitUrl="https://github.com/Eduardgur/WeightTrackerTst.git"
repoName="${gitUrl%.git}"
repoName="${repoName##*/}"
sudo git clone "$gitUrl"
echo "Settings new working dir:" 
cd "$repoName"
pwd
echo

echo "Installing missing packages" 
sudo npm install
echo


#Installing net tools
sudo apt install net-tools
echo


#Editing .env file --- Add manual mode
echo "Configuring .env file" 
defaultExternalIp="{EXTERNAL_IP}"
defaultPublicIp="{PUBLIC_IP}"
defaultOktaUrl="{OKTA_URL}"
defaultOktaId="{OKTA_ID}"
defaultOktSec="{OKTA_SECRET}"
defaultDbIp="{DB_IP}"

repoDir="$wwwDir/$repoName"
envFile="$repoDir/.env"

externalIp="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"
publicIp="$(curl -s ipinfo.io/ip)"
read -p "Please type postgres ip address: " dbIp
read -p "Please type okta full url (including https://): " oktaUrl
read -p "Please type okta client ID: " oktaId
read -p "Please type okta client secret: " oktaSec

sudo sed -i "s/"$defaultExternalIp"/"$externalIp"/" "$envFile"
sudo sed -i "s/"$defaultPublicIp"/"$publicIp"/" "$envFile"
sudo sed -i "s,$defaultOktaUrl,$oktaUrl," "$envFile"
sudo sed -i "s/"$defaultOktaId"/"$oktaId"/" "$envFile"
sudo sed -i "s/"$defaultOktSec"/"$oktaSec"/" "$envFile"
sudo sed -i "s/"$defaultDbIp"/"$dbIp"/" "$envFile"
echo
cat $envFile
echo
echo ".env file edited" 
echo


#Initializing DB
echo "Initializing DB" 
sudo npm run initdb
echo


#Allow TCP Port 80
echo "Allowing TCP port 80 inbound for all connections"
sudo ufw allow 80/tcp
echo

#PM2
echo "Installing PM2"
sudo npm install -g pm2
echo "Starting bootstrap.js" 
sudo pm2 start "$repoDir\bootstrap.js"
echo "Saving state" 
sudo pm2 save -f
echo

#Create server restart task
echo "Registering startup task"
sudo pm2 startup
echo
sudo pm2 status


echo "Done !"  
 
pause