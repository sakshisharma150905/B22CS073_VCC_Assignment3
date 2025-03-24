#!/bin/bash

# Paths to necessary files
AUTOSCALE_SCRIPT="/home/sakshi/autoscale_gcp.sh"

# Monitoring loop
while true; do
    # Get CPU usage (in percentage)
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

    echo "Current CPU Usage: $CPU_USAGE%"

    # Check if CPU usage exceeds 75%
    if (( $(echo "$CPU_USAGE > 75" | bc -l) )); then
        echo "🚨 CPU usage exceeded 75%! Triggering auto-scaling..."
        
        # Run the GCP auto-scaling script
        bash $AUTOSCALE_SCRIPT
        break
    fi
    
    # Check CPU every 10 seconds
    sleep 10
done
