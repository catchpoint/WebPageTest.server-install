#!/bin/bash

# Prompt for the configuration options
echo "WebPageTest automatic server install."

# Pre-prompt for the sudo authorization so it doesn't prompt later
sudo date

cd ~
until sudo apt-get update
do
    sleep 1
done
until sudo DEBIAN_FRONTEND=noninteractive apt-get -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
do
    sleep 1
done
until sudo apt-get install -y git screen nginx beanstalkd zip unzip curl \
    php-fpm php-apcu php-sqlite3 php-curl php-gd php-zip php-mbstring php-xml \
    imagemagick ffmpeg libjpeg-turbo-progs libimage-exiftool-perl \
    software-properties-common python2.7 python-pip python-software-properties python-numpy python-scipy \
    psmisc
do
    sleep 1
done
until sudo pip install --upgrade pip
do
    sleep 1
done
until sudo pip install monotonic pillow psutil requests ujson pyssim
do
    sleep 1
done
sudo chown -R $USER:$USER /var/www
cd /var/www
until git clone https://github.com/WPO-Foundation/webpagetest.git
do
    sleep 1
done
cd /var/www/webpagetest
git checkout origin/release
git branch -D master
git pull origin release
cd ~
until git clone https://github.com/WPO-Foundation/wptserver-install.git
do
    sleep 1
done

# Configure the OS and software
cat wptserver-install/configs/sysctl.conf | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
cat wptserver-install/configs/fstab | sudo tee -a /etc/fstab
sudo mount -a
cat wptserver-install/configs/security/limits.conf | sudo tee -a /etc/security/limits.conf
cat wptserver-install/configs/default/beanstalkd | sudo tee /etc/default/beanstalkd
sudo service beanstalkd restart

#php
cat wptserver-install/configs/php/php.ini | sudo tee /etc/php/7.0/fpm/php.ini
cat wptserver-install/configs/php/pool.www.conf | sed "s/%USER%/$USER/" | sudo tee /etc/php/7.0/fpm/pool.d/www.conf
sudo service php7.0-fpm restart

#nginx
cat wptserver-install/configs/nginx/fastcgi.conf | sudo tee /etc/nginx/fastcgi.conf
cat wptserver-install/configs/nginx/fastcgi_params | sudo tee /etc/nginx/fastcgi_params
cat wptserver-install/configs/nginx/nginx.conf | sed "s/%USER%/$USER/" | sudo tee /etc/nginx/nginx.conf
cat wptserver-install/configs/nginx/sites.default | sudo tee /etc/nginx/sites-available/default
sudo service nginx restart

# WebPageTest Settings
LOCATIONKEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
SERVERKEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
SERVERSECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
APIKEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
cat wptserver-install/webpagetest/settings.ini | sed "s/%LOCATIONKEY%/$LOCATIONKEY/" | tee /var/www/webpagetest/www/settings/settings.ini
cat wptserver-install/webpagetest/keys.ini | sed "s/%SERVERSECRET%/$SERVERSECRET/" | sed "s/%SERVERKEY%/$SERVERKEY/" | sed "s/%APIKEY%/$APIKEY/" | tee /var/www/webpagetest/www/settings/keys.ini
cat wptserver-install/webpagetest/locations.ini | tee /var/www/webpagetest/www/settings/locations.ini
cp /var/www/webpagetest/www/settings/connectivity.ini.sample /var/www/webpagetest/www/settings/connectivity.ini

# Crontab to tickle the WebPageTest cron jobs every 5 minutes
CRON_ENTRY="*/5 * * * * curl --silent http://127.0.0.1/work/getwork.php"
( crontab -l | grep -v -F "$CRON_ENTRY" ; echo "$CRON_ENTRY" ) | crontab -

clear
echo 'Setup is complete. System reboot is recommended.'
echo 'The locations need to be configured manually in /var/www/webpagetest/www/settings/locations.ini'
echo 'The settings can be tweaked in /var/www/webpagetest/www/settings/settings.ini'
printf "\n"
echo "The location key to use when configuring agents is: $LOCATIONKEY"
echo "An API key to use for automated testing is: $APIKEY"
