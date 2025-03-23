#!/bin/bash

# File to keep track of scaling status
SCALING_STATUS_FILE="/tmp/scaling_status"

# Function to get current resource usage
get_resource_usage() {
    # Get CPU usage (average over all cores)
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # Get memory usage percentage
    MEMORY_USAGE=$(free -m | awk '/Mem:/ {print $3/$2 * 100}')
    
    # Get disk usage percentage for root filesystem
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%" >> /var/log/resource_monitor.log
}

# Function to check if we need to scale to cloud
check_scaling_threshold() {
    # If we're already scaling or scaled, don't trigger again
    if [ -f "$SCALING_STATUS_FILE" ]; then
        CURRENT_STATUS=$(cat "$SCALING_STATUS_FILE")
        if [ "$CURRENT_STATUS" == "SCALING" ] || [ "$CURRENT_STATUS" == "SCALED" ]; then
            echo "Already in $CURRENT_STATUS state. Skipping check."
            return 1
        fi
    fi
    
    # Check if any resource exceeds threshold
    if (( $(echo "$CPU_USAGE > 75" | bc -l) )) || (( $(echo "$MEMORY_USAGE > 75" | bc -l) )); then
        echo "THRESHOLD EXCEEDED - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%"
        echo "THRESHOLD EXCEEDED - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%" >> /var/log/resource_monitor.log
        return 0
    fi
    
    return 1
}

# Function to trigger cloud scaling
trigger_cloud_scaling() {
    echo "SCALING" > "$SCALING_STATUS_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Initiating migration to GCP..." >> /var/log/resource_monitor.log
    
    # Execute migration script
    /usr/local/bin/migrate_to_gcp.sh
    
    # Update status
    echo "SCALED" > "$SCALING_STATUS_FILE"
}

# Main execution
get_resource_usage

if check_scaling_threshold; then
    echo "Resource usage exceeds 75% threshold. Triggering auto-scaling..."
    trigger_cloud_scaling
else
    echo "Resource usage within acceptable limits."
fi

3.3 Scheduling and Automation
The monitoring script is scheduled to run at regular intervals using cron:
# Run the resource monitoring script every 5 minutes
*/5 * * * * /usr/local/bin/monitor_resources.sh
