#! /bin/bash

# prompt for archiving bucket and key if available
echo 'WebPageTest server install script for servers running on Google Compute Engine.'
printf "\n"
echo 'If tests are to be archived to Google cloud storage you will need a developer key and a bucket configured in cloud storage.'
echo 'To generate a developer key:'
echo '    1. Open the Cloud Storage Settings page in the Google Cloud Platform Console:'
echo '          https://console.cloud.google.com/storage/settings?_ga=2.247736327.-1841576041.1479520090'
echo '    2. Select Interoperability.'
echo '    3. If you have not set up interoperability before, click Enable interoperability access.'
echo '    4. Click Create a new key.'
read -p "Bucket name (leave empty if not using cloud storage): " STORAGE_BUCKET
if [ $STORAGE_BUCKET != '' ]; then
    while [[ $STORAGE_KEY == '' ]]
    do
        read -p "Developer Key: " STORAGE_KEY
    done
    while [[ $STORAGE_SECRET == '' ]]
    do
        read -p "Developer Secret: " STORAGE_SECRET
    done
fi

printf "\nStarting installation"
sudo date

# First run the common ubuntu installer
cd ~
wget https://raw.githubusercontent.com/WPO-Foundation/wptserver-install/master/ubuntu.sh
chmod +x ubuntu.sh
./ubuntu.sh

if [ $STORAGE_BUCKET != '' ]; then
    echo "archive_days=1" >> /var/www/webpagetest/www/settings/settings.ini
    echo "archive_api=1" >> /var/www/webpagetest/www/settings/settings.ini
    echo "archive_s3_server=commondatastorage.googleapis.com" >> /var/www/webpagetest/www/settings/settings.ini
    echo "archive_s3_key=$STORAGE_KEY" >> /var/www/webpagetest/www/settings/settings.ini
    echo "archive_s3_secret=$STORAGE_SECRET" >> /var/www/webpagetest/www/settings/settings.ini
    echo "archive_s3_bucket=$STORAGE_BUCKET" >> /var/www/webpagetest/www/settings/settings.ini
fi

cp /var/www/webpagetest/www/settings/locations.ini.GCE-sample /var/www/webpagetest/www/settings/locations.ini
INSTANCE_NAME=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
PROJECT_ID=$(curl "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
clear
echo 'Setup is complete. System reboot is recommended.'
echo 'Locations have been configured for all of the GCE regions in /var/www/webpagetest/www/settings/locations.ini'
echo 'The settings can be tweaked if needed in /var/www/webpagetest/www/settings/settings.ini'
printf "\n"
echo "The location key to use when configuring agents is: $LOCATIONKEY"
echo "The 'wpt_data' metadata for agents to connect to this server is:"
echo "    wpt_server=$INSTANCE_NAME.c.$PROJECT_ID.internal wpt_key=$LOCATIONKEY"
echo "An API key to use for automated testing is: $APIKEY"
