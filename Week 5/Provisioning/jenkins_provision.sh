#!/bin/bash

user="jenkins"
password="QWer1234Q"
pass=$(perl -e 'print crypt($ARGV[0], "salt")' $password)
useradd -s /bin/bash -m -p $pass $user

sudo add-apt-repository universe
sudo apt update -y
sudo apt install default-jre -y
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install jenkins -y

exit