#!/usr/bin/bash

tmstamps=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="/tmp/send_email_services_$tmstamps.log"

csv_file=$(find /opt/services/inactive/ -name "*.csv" -print -quit)

echo "[$(date)] Checking for CSV file..." | tee -a "$LOG_FILE"

if [ ! -f "$csv_file" ]; then
    echo "[$(date)] ERROR: CSV file does not exist" | tee -a "$LOG_FILE"
    exit 1
fi

echo "[$(date)] Extracting failed services from CSV..." | tee -a "$LOG_FILE"
extract_csv=$(grep "failed" "$csv_file" | awk -F, '{print "Service Name: "$1"\nDescription: "$2"\n"}')
hostname_IP=$(hostname -I | awk '{print $1}')

if [ -z "$extract_csv" ]; then
    echo "[$(date)] No failed services found." | tee -a "$LOG_FILE"
    exit 0
fi

echo "[$(date)] Failed services found, preparing email..." | tee -a "$LOG_FILE"
email="azhdenize20@gmail.com"
subject="[FAILED] ALMALINUX SERVER SERVICES"

body="Hi,

Please start the following services immediately:

Hostname IP address: $hostname_IP

$extract_csv

-----------------------------------------
Do Not Reply, this is an Automated Email.

Thank you."


echo "[$(date)] Sending email to $email..." | tee -a "$LOG_FILE"
echo "$body" | s-nail -s "$subject" "$email"

if [ $? -eq 0 ]; then
    echo "[$(date)] Email sent successfully." | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Failed to send email." | tee -a "$LOG_FILE"
fi
