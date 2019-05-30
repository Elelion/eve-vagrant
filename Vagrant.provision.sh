#!/usr/bin/env bash
sudo apt install -y ca-certificates apt-transport-https
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list
sudo apt-get update

sudo apt-get install -y php7.1 php7.1-cli php7.1-common php7.1-curl php7.1-fpm php7.1-gd php7.1-json php7.1-mbstring
sudo apt-get install -y php7.1-mysql php7.1-soap php7.1-xml php7.1-xmlrpc php7.1-zip php7.1-bcmath php-amqplib
sudo apt-get install -y nginx composer git nano
sudo apt-get install -y redis-server
sudo systemctl enable redis-server.service
sudo apt-get install -y php7.1-redis
sudo apt-get install -y rabbitmq-server

DATABASE_NAME='eveservice'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
apt-get install -y mysql-server mysql-client mysql-common
mysql -uroot -ppassword -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;";
mysql -uroot -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password';"
mysql -uroot -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password';"
sudo service mysql restart

sudo cp /vagrant/provision/nginx/sites-enabled/* /etc/nginx/sites-enabled/

cd /var/www/html/
composer create-project --prefer-dist yiisoft/yii2-app-basic eve-service
cd eve-service
git init
git remote add origin https://andrewverner:sin45sqrt22@github.com/andrewverner/eve-service.git
git fetch origin
git reset --hard origin/master
cp /vagrant/provision/db/* /var/www/html/eve-service/config/
./yii migrate --interactive=0
composer install

scp -o 'StrictHostKeyChecking no' -i /vagrant/provision/ssh/fornex_rsa root@5.187.4.2:/tmp/eveservice.sql /tmp/eveservice.sql
cd /tmp
mysql -u root -ppassword eveservice < eveservice.sql

sudo apt-get install -y php7.1-xdebug
cat >> /etc/php/7.1/mods-available/xdebug.ini <<'EOF'
xdebug.remote_enable=1
xdebug.remote_host=localhost
xdebug.idekey=PHPSTORM
EOF

sudo mkdir /var/www/log
sudo touch /var/www/log/eve_access.log
sudo touch /var/www/log/eve_error.log

sudo service rabbitmq-server start
sudo service nginx restart
sudo service php7.1-fpm restart
sudo service redis-server restart