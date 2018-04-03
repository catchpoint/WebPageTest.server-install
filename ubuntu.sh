#!/bin/bash

# Prompt for the configuration options
echo "Automatic server install and configuration."

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
until sudo apt-get install -y git screen nginx beanstalkd\
    php-fpm php-apcu php-sqlite3 php-curl php-gd php-zip php-mbstring php-xml \
    imagemagick ffmpeg libjpeg-turbo-progs libimage-exiftool-perl \
    software-properties-common python2.7 python-pip python-software-properties \
    psmisc
do
    sleep 1
done
until sudo pip install monotonic pillow psutil requests ujson
do
    sleep 1
done
sudo chown -R $USER:$USER /var/www
cd /var/www
until git clone https://github.com/WPO-Foundation/webpagetest.git
do
    sleep 1
done
cd ~
until git clone https://github.com/WPO-Foundation/wptserver-install.git
do
    sleep 1
done

# Configure the OS and software
echo cat wptserver-install/configs/sysctl.conf | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
echo cat wptserver-install/configs/fstab | sudo tee -a /etc/fstab
sudo mount -a
echo cat wptserver-install/configs/security/limits.conf | sudo tee -a /etc/security/limits.conf
echo cat wptserver-install/configs/default/beanstalkd | sudo tee /etc/default/beanstalkd
sudo service beanstalkd restart

#php
echo cat wptserver-install/configs/php/php.ini | sudo tee /etc/php/7.0/fpm/php.ini
echo cat wptserver-install/configs/php/pool.www.conf | sed "s/%USER%/$USER/" | sudo tee /etc/php/7.0/fpm/pool.d/www.conf
sudo service php7.0-fpm restart

#nginx
echo cat wptserver-install/configs/nginx/fastcgi.conf | sudo tee /etc/nginx/fastcgi.conf
echo cat wptserver-install/configs/nginx/fastcgi_params | sudo tee /etc/nginx/fastcgi_params
echo cat wptserver-install/configs/nginx/nginx.conf | sed "s/%USER%/$USER/" | sudo tee /etc/nginx/nginx.conf
echo cat wptserver-install/configs/nginx/sites.default | sudo tee /etc/nginx/sites-available/default
sudo service nginx restart

echo 'Setup is complete.  Reboot is recommended'

