#!/bin/bash
echo "Installing Postgresql"
sudo apt-get install wget ca-certificates -y
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt-get update -y
sudo apt-get install postgresql postgresql-contrib -y
echo "Configuring postgresql"
postgresql_conf=$(sudo find / -name 'postgresql.conf' | grep main)
pg_hba=$(sudo find / -name 'pg_hba.conf' | grep main)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" ${postgresql_conf}
sudo sed -i "/# TYPE  DATABASE        USER            ADDRESS                 METHOD/a host  all  all 0.0.0.0/0 md5" ${pg_hba}
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password '123123';"
sudo service postgresql restart
echo "Allowing port 5432 TCP in FW"
sudo ufw allow 5432/tcp
echo "Checking port 5432:"
sudo lsof -n -P | grep 5432
echo "Please restart the server"
exit
