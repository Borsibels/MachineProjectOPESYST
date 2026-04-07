#!/bin/bash

# Variables
SRC_DIR="/tmp"
DEST_DIR="/opt/services"
SERVER_CONN="admin@192.168.190.129"
LOG_FILE="/tmp/send_json_services_status_to_server2_$(date '+%Y%m%d_%H%M%S').log"

# Ensure passwordless SSH/SFTP is set up
echo "Checking SSH connection to $SERVER_CONN..." >> "$LOG_FILE"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$SERVER_CONN" true; then
    echo "Passwordless SSH is not set up. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

# Find the latest JSON file
JSON_FILE=$(ls -t $SRC_DIR/services_*.json 2>/dev/null | head -n 1)

if [[ -z "$JSON_FILE" ]]; then
    echo "No JSON files found in $SRC_DIR. Exiting." | tee -a "$LOG_FILE"
    exit 1
else
    echo "Found JSON file: $JSON_FILE" | tee -a "$LOG_FILE"
fi

# Ensure the destination directory exists on Server 2 with correct permissions
echo "Ensuring $DEST_DIR exists on $SERVER_CONN..." | tee -a "$LOG_FILE"
ssh "$SERVER_CONN" "sudo mkdir -p $DEST_DIR && sudo chown $(whoami):$(whoami) $DEST_DIR" >> "$LOG_FILE" 2>&1

# Transfer the JSON file via SCP
echo "Transferring $JSON_FILE to $SERVER_CONN:$DEST_DIR..." | tee -a "$LOG_FILE"
scp "$JSON_FILE" "$SERVER_CONN:$DEST_DIR/" >> "$LOG_FILE" 2>&1

if [[ $? -eq 0 ]]; then
    echo "File transferred successfully: $JSON_FILE" | tee -a "$LOG_FILE"
    rm -f "$JSON_FILE"
    echo "File deleted locally: $JSON_FILE" | tee -a "$LOG_FILE"
else
    echo "File transfer failed: $JSON_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

exit 0
