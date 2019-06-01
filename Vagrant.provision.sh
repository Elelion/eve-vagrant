#!/usr/bin/env bash
sudo apt-get install -y php7.2 php7.2-cli php7.2-common php7.2-curl php7.2-fpm php7.2-gd php7.2-json php7.2-mbstring
sudo apt-get install -y php7.2-mysql php7.2-soap php7.2-xml php7.2-xmlrpc php7.2-zip php7.2-bcmath php-amqplib
sudo apt-get install -y nginx composer git nano mc
sudo apt-get install -y redis-server
sudo systemctl enable redis-server.service
sudo apt-get install -y php7.2-redis
sudo apt-get install -y rabbitmq-server

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
sudo apt-get install -y mysql-server mysql-client mysql-common
mysql -uroot -ppassword -e "CREATE DATABASE IF NOT EXISTS eveservice;";
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
sudo rm composer.lock
composer install

scp -o 'StrictHostKeyChecking no' -i /vagrant/provision/ssh/fornex_rsa root@5.187.4.2:/tmp/eveservice.sql /tmp/eveservice.sql
cd /tmp
mysql -u root -ppassword eveservice < eveservice.sql

sudo apt-get install -y php7.2-xdebug
sudo cat >> /etc/php/7.2/mods-available/xdebug.ini <<'EOF'
xdebug.remote_enable=1
xdebug.remote_host=localhost
xdebug.idekey=PHPSTORM
EOF

sudo mkdir /var/www/log
sudo touch /var/www/log/eve_access.log
sudo touch /var/www/log/eve_error.log

sudo service rabbitmq-server start
sudo service nginx restart
sudo service php7.2-fpm restart
sudo service redis-server restart