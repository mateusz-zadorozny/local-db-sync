#!/bin/bash

# Define your settings
KEY_PATH="/Users/username/keyname"
IP_ADDRESS="123.456.123.456"
SITE_NAME="site.url"
LOCAL_DIRECTORY="/Users/username/Local Sites/site/app/public/local-db-sync"
LOCAL_WP_ROOT="/Users/username/Local Sites/site/app/public"
OLD_DOMAIN="https://site.url"
NEW_DOMAIN="https://site.local"

# Database parameters
DB_NAME="local"
DB_USER="root"
DB_PASSWORD="root"
DB_HOST="localhost"

# Check if the backup.sql file is present
if [ -f "$LOCAL_DIRECTORY/backup.sql" ]; then
    read -p "Backup file found. Do you want to run the whole process or just restore from the backup? (whole/restore) " answer
    if [[ $answer = restore ]] ; then
        echo "Restoring the database from backup..."
        wp db import "$LOCAL_DIRECTORY/backup.sql" --path="$LOCAL_WP_ROOT"
        exit 0
    fi
fi

# If the to_local.sql file is present, ask the user if they want to import again
if [ ! -f "$LOCAL_DIRECTORY/to_local.sql" ] || { 
    [ -f "$LOCAL_DIRECTORY/to_local.sql" ] && read -p "Imported database found. Want to import again from the remote server? Type 'n' to use the file in the folder (y/n): " choice && [[ "$choice" == "y" || "$choice" == "Y" ]]; 
}; then
    # Remote code
    # Use WP CLI to export the database
    echo "Exporting the database..."
    ssh -i "$KEY_PATH" root@"$IP_ADDRESS" "gp wp $SITE_NAME db export /var/www/$SITE_NAME/htdocs/to_local.sql --all-tablespaces --add-drop-table"

    # SCP to download the exported .sql file
    echo "Downloading the database..."
    scp -i "$KEY_PATH" root@"$IP_ADDRESS":/var/www/"$SITE_NAME"/htdocs/to_local.sql "$LOCAL_DIRECTORY"

    # Remove the .sql file from the remote server
    echo "Removing the .sql file from the remote server..."
    ssh -i "$KEY_PATH" root@"$IP_ADDRESS" "rm /var/www/$SITE_NAME/htdocs/to_local.sql"
fi

# Backup the local database
if [ ! -f "$LOCAL_DIRECTORY/backup.sql" ]; then
    echo "Backing up the local database..."
    wp db export "$LOCAL_DIRECTORY/backup.sql" --path="$LOCAL_WP_ROOT"
else
    read -p "A backup already exists. Do you want to overwrite it? (y/n) " answer
    if [[ $answer = y ]] ; then
        rm "$LOCAL_DIRECTORY/backup.sql"
        echo "Backing up the local database..."
        wp db export "$LOCAL_DIRECTORY/backup.sql" --path="$LOCAL_WP_ROOT"
    else
        echo "Skipping database backup..."
    fi
fi

# Import the .sql file to the local database
if [ ! -f "$LOCAL_DIRECTORY/import.done" ]; then
    echo "Importing the database to local..."
    wp db import "$LOCAL_DIRECTORY/to_local.sql" --path="$LOCAL_WP_ROOT"

    read -p "Did the import go well? (y/n) " answer
    if [[ $answer = y ]] ; then
        touch "$LOCAL_DIRECTORY/import.done"
    else
        echo "Please fix the issues and run the script again."
        exit 1
    fi
fi

# Check if Search-Replace-DB folder exists, if not, clone it from GitHub
if [ ! -d "$LOCAL_DIRECTORY/Search-Replace-DB" ]; then
  echo "Cloning Search-Replace-DB..."
  git clone https://github.com/interconnectit/Search-Replace-DB.git "$LOCAL_DIRECTORY/Search-Replace-DB"
fi

# Run Search-Replace-DB script
if [ ! -f "$LOCAL_DIRECTORY/rewrite.done" ]; then
    echo "Running Search-Replace-DB script..."
    php "$LOCAL_DIRECTORY/Search-Replace-DB/srdb.cli.php" -h "$DB_HOST" -n "$DB_NAME" -u "$DB_USER" -p "$DB_PASSWORD" -s "$OLD_DOMAIN" -r "$NEW_DOMAIN"

    read -p "Did the rewrite go well? (y/n) " answer
    if [[ $answer = y ]] ; then
        touch "$LOCAL_DIRECTORY/rewrite.done"
    else
        echo "Please fix the issues and run the script again."
        exit 1
    fi
fi

read -p "Is everything working on the local site? (y/n) " answer
if [[ $answer = y ]] ; then
    rm "$LOCAL_DIRECTORY/import.done"
    rm "$LOCAL_DIRECTORY/rewrite.done"
    rm "$LOCAL_DIRECTORY/to_local.sql"
else
    echo "Please fix the issues and run the script again."
    exit 1
fi

echo "Process complete."
