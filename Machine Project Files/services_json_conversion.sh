#!/usr/bin/bash


tmstamps=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="/tmp/services_json_conversion_$tmstamps.log"


saveactv_txt="/opt/services/active/services_active_$tmstamps.txt"
saveinactv_txt="/opt/services/inactive/services_inactive_$tmstamps.csv"


JSON_FILES=$(find /opt -name "*.json")

find /opt/services/active /opt/services/inactive -type f \( -name "*.csv" -o -name "*.txt" \) -mtime +7 -exec rm -f {} \;
find /opt/services -type f -name "*.json" -mtime +7 -exec rm -f {} \;


mkdir -p "/opt/services/active" "/opt/services/inactive"


log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}


if [[ -z "$JSON_FILES" ]]; then
    log_message "No JSON files found. Exiting."
    exit 1
fi

log_message "Processing JSON files..."


for FILE in $JSON_FILES; do
    log_message "Processing file: $FILE"


    actvServices=$(jq -c '.[] | select(.service.status == "active") | .service' "$FILE")
    if [[ -n "$actvServices" ]]; then
        log_message "Writing active services to $saveactv_txt"
        echo "$actvServices" | jq -r '"name: \(.["service-name"])\ndescription: \(.description)\n"' >> "$saveactv_txt"
    else
        log_message "No active services found in $FILE."
    fi


    inactvServices=$(jq -c '.[] | select(.service.status == "inactive" or .service.status == "failed" or .service.status == "exited" or .service.status == "dead") | .service' "$FILE")
    if [[ -n "$inactvServices" ]]; then
        log_message "Writing inactive/failed/exited/dead services to $saveinactv_txt"
        echo "$inactvServices" | jq -r '[.["service-name"], .description, .status] | @csv' >> "$saveinactv_txt"
    else
        log_message "No inactive/failed/exited/dead services found in $FILE."
    fi

done

log_message "Script execution completed."
