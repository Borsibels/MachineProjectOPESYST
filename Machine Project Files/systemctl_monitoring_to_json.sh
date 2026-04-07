#!/bin/bash

OutPTDIR="/tmp"
tMstamp=$(date '+%Y%m%d_%H%M%S')
outptFile="$OutPTDIR/services_$tMstamp.json"
logs="$OutPTDIR/systemctl_monitoring_to_json_$tMstamp.log"

echo "Starting service monitoring script..." > "$logs"
echo "Output JSON: $outptFile" >> "$logs"

echo "[" > "$outptFile"
id=1

states=("active" "exited" "failed" "dead")

for state in "${states[@]}"; do
    echo "Checking services with state: $state" >> "$logs"

    #List services and remove invalid characters
    if [[ "$state" == "failed" ]]; then
    services=$(systemctl list-units --failed --type=service --no-pager --no-legend | sed 's/●/ /g' | awk '{print $1}')
else
    services=$(systemctl list-units --type=service --state="$state" --no-pager --no-legend | sed 's/●/ /g' | awk '{print $1}')
fi

    for service in $services; do
        desc=$(systemctl show "$service" --property=Description --value 2>/dev/null)

        echo "  {" >> "$outptFile"
        echo "    \"service\": {" >> "$outptFile"
        echo "      \"service-name\": \"$service\"," >> "$outptFile"
        echo "      \"description\": \"$desc\"," >> "$outptFile"
        echo "      \"status\": \"$state\"," >> "$outptFile"
        echo "      \"id_number\": $id" >> "$outptFile"
        echo "    }" >> "$outptFile"
        echo "  }," >> "$outptFile"

        echo "Logged service: $service (State: $state, ID: $id)" >> "$logs"

        ((id++))
    done
done

# Remove trailing comma
sed -i '$ s/,$//' "$outptFile"
echo "]" >> "$outptFile"

echo "JSON file created: $outptFile" >> "$logs"
echo "Script execution completed." >> "$logs"

exit 0
