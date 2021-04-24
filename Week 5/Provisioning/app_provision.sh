#!/bin/bash
# Parameters: VM IP , Port ,Public IP , Postgres Server IP , Okta Url  including https:# , Okta Id , Okta Code , DB Port , DB User , DB name , DB pass

echo "Welcome to this NodeJS app deployment script"

#Install NodeJS/NPM
echo "Fatching NodeJS/NPM installation files.."
sudo curl -L "https://raw.githubusercontent.com/tj/n/master/bin/n" -o n
echo "NInstalling now..."
sudo bash n lts    
echo "NodeJS Version=$($isNodeInstaleld)" 
echo "NPM Version=$($isNpmInstaleld)" 

#Create App Directory
echo "Creating default working Dir" 
wwwDir=~/wwwroot
sudo mkdir "$wwwDir"
cd "$wwwDir"
pwd

#Clone app and Install missing packages
echo "Clonning app from git" 
gitUrl="https://github.com/Eduardgur/WeightTrackerTst.git"
repoName="${gitUrl%.git}"
repoName="${repoName##*/}"
sudo git clone "$gitUrl"
echo "Settings new working dir:" 
cd "$repoName"
pwd

echo "Installing missing packages" 
sudo -H npm install

#Installing net tools
sudo apt install net-tools
echo

#Editing .env file --- Add manual mode
echo "Configuring .env file" 
defaultExternalIp="{EXTERNAL_IP}"
defaultPublicIp="{PUBLIC_IP}"
defaultPort="{PORT}"
defaultOktaUrl="{OKTA_URL}"
defaultOktaId="{OKTA_ID}"
defaultOktSec="{OKTA_SECRET}"
defaultDbIp="{DB_IP}"
defaultDBPort="{POSTGRE_PORT}"
defaultDBUser="{POSTGRE_USER}"
defaultDBName="{POSTGRE_DB_NAME}"
defaultDBPass="{POSTGRE_PASS}"

repoDir="$wwwDir/$repoName"
envBackupFile="$repoDir/.env.back"
cp $envBackupFile "$repoDir/.env"
envFile="$repoDir/.env"

externalIp=$1 
port=$2 
publicIp=$3 
dbIp=$4
oktaUrl=$5
oktaId=$6
oktaSec=$7
dbPort=$8
dbUser=$9
dbName=${10}
dbPass=${11}

sudo sed -i "s/"$defaultExternalIp"/"$externalIp"/" "$envFile"
sudo sed -i "s/"$defaultPort"/"$port"/" "$envFile"
sudo sed -i "s/"$defaultPublicIp"/"$publicIp"/" "$envFile"
sudo sed -i "s,$defaultOktaUrl,$oktaUrl," "$envFile"
sudo sed -i "s/"$defaultOktaId"/"$oktaId"/" "$envFile"
sudo sed -i "s/"$defaultOktSec"/"$oktaSec"/" "$envFile"
sudo sed -i "s/"$defaultDbIp"/"$dbIp"/" "$envFile"
sudo sed -i "s/"$defaultDBPort"/"$dbPort"/" "$envFile"
sudo sed -i "s/"$defaultDBUser"/"$dbUser"/" "$envFile"
sudo sed -i "s/"$defaultDBName"/"$dbName"/" "$envFile"
sudo sed -i "s/"$defaultDBPass"/"$dbPass"/" "$envFile"
cat $envFile
echo ".env file edited" 


#Initializing DB
echo "Initializing DB" 
sudo npm run initdb

#Allow TCP Port 80
echo "Allowing TCP port 80 inbound for all connections"
sudo ufw allow 80/tcp

#PM2
echo "Installing PM2"
sudo -H npm install -g pm2
echo "Starting bootstrap.js" 
sudo pm2 start "$repoDir/bootstrap.js"
echo "Saving state" 
sudo pm2 save -f

#Create server restart task
echo "Registering startup task"
sudo pm2 startup
sudo pm2 status

#Create jenkins user 
user="jenkins"
pass=$(perl -e 'print crypt($ARGV[0], "salt")' $dbPass)
useradd -s /bin/bash -m -p $pass $user

echo "Done !"  
exit