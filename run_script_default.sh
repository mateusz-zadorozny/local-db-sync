#!/bin/bash

# Define your settings
KEY_PATH="/Users/username/keyname"
IP_ADDRESS="123.456.123.456"
SITE_NAME="site.url"
LOCAL_DIRECTORY="/path/to/local/directory"

# Use GP WP CLI to export the database
echo "Exporting the database..."
ssh -i $KEY_PATH root@$IP_ADDRESS "gp wp $SITE_NAME db export /var/www/$SITE_NAME/htdocs/to_local.sql --all-tablespaces --add-drop-table"

# SCP to download the exported .sql file
echo "Downloading the database..."
scp -i $KEY_PATH root@$IP_ADDRESS:/var/www/$SITE_NAME/htdocs/to_local.sql $LOCAL_DIRECTORY

echo "Process complete."