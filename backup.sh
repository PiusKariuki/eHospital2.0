#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo ".env file not found."
  exit 1
fi

# Variables
BACKUP_DIR="/opt"
DATE=$(date +%d%m%Y_%H%M%S)
BACKUP_FILE="SJH_DATA_BACKUP_${DATE}.sql"
LOCAL_DIR="$HOME/Data_Backup"

# Check Docker container status
docker ps -a | grep $DB_CONTAINER > /dev/null
if [ $? -ne 0 ]; then
  echo "Docker container $DB_CONTAINER not found."
  exit 1
fi

# Create backup inside Docker container
docker exec -it $DB_CONTAINER bash -c "mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/$BACKUP_FILE"
if [ $? -ne 0 ]; then
  echo "Failed to create backup."
  exit 1
fi

# Create local backup directory if it doesn't exist
if [ ! -d "$LOCAL_DIR" ]; then
  mkdir -p "$LOCAL_DIR"
fi

# Copy the latest backup file to local directory
LATEST_BACKUP=$(docker exec $DB_CONTAINER ls -t $BACKUP_DIR | grep SJH_DATA_BACKUP_ | head -n 1)
docker cp $DB_CONTAINER:$BACKUP_DIR/$LATEST_BACKUP $LOCAL_DIR/
if [ $? -ne 0 ]; then
  echo "Failed to copy backup file to local directory."
  exit 1
fi

echo "Backup completed $BACKUP_FILE and file copied to $LOCAL_DIR successfully."
exit 0