#!/bin/bash

# Configuration
PROJECT_ID="auto-scale-project-1234"
ZONE="us-central1-a"
INSTANCE_NAME="auto-scaled-instance"
MACHINE_TYPE="e2-medium"
SOURCE_APP_DIR="/opt/sample-app"
CREDENTIALS_FILE="/etc/gcp/service-account-key.json"

# Log file
LOG_FILE="/var/log/gcp_migration.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Authenticate with GCP if not already done
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    log "Authenticating with GCP..."
    gcloud auth activate-service-account --key-file="$CREDENTIALS_FILE"
    gcloud config set project "$PROJECT_ID"
fi

# Check if instance already exists
if gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" &>/dev/null; then
    log "Instance $INSTANCE_NAME already exists. Checking status..."
    
    STATUS=$(gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --format="value(status)")
    
    if [ "$STATUS" != "RUNNING" ]; then
        log "Instance is not running. Starting instance..."
        gcloud compute instances start "$INSTANCE_NAME" --zone="$ZONE"
    else
        log "Instance is already running."
    fi
else
    # Create a new VM instance in GCP
    log "Creating new GCP instance $INSTANCE_NAME..."
    
    gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-project=ubuntu-os-cloud \
        --image-family=ubuntu-2204-lts \
        --boot-disk-size=20GB \
        --tags=http-server,https-server
    
    # Wait for instance to be ready
    log "Waiting for instance to initialize..."
    sleep 30
    
    # Allow HTTP/HTTPS traffic
    gcloud compute firewall-rules create allow-http \
        --allow tcp:80 --target-tags http-server --project "$PROJECT_ID"
    gcloud compute firewall-rules create allow-https \
        --allow tcp:443 --target-tags https-server --project "$PROJECT_ID"
fi

# Get the external IP of the instance
INSTANCE_IP=$(gcloud compute instances describe "$INSTANCE_NAME" \
    --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

log "Instance external IP: $INSTANCE_IP"

# Package the application
log "Packaging application for migration..."
APP_PACKAGE="/tmp/sample-app.tar.gz"
tar -czf "$APP_PACKAGE" -C "$(dirname "$SOURCE_APP_DIR")" "$(basename "$SOURCE_APP_DIR")"

# Copy application files to GCP instance
log "Copying application files to GCP instance..."
gcloud compute scp "$APP_PACKAGE" "ubuntu@${INSTANCE_NAME}:/tmp/" --zone="$ZONE"

# Setup the application on the GCP instance
log "Setting up application on GCP instance..."
gcloud compute ssh "ubuntu@${INSTANCE_NAME}" --zone="$ZONE" -- "
    sudo mkdir -p /opt/sample-app
    sudo tar -xzf /tmp/sample-app.tar.gz -C /opt/
    sudo chown -R ubuntu:ubuntu /opt/sample-app
    cd /opt/sample-app
    
    # Install dependencies
    sudo apt-get update
    sudo apt-get install -y nodejs npm
    npm install
    
    # Start the application
    nohup npm start > /opt/sample-app/app.log 2>&1 &
    
    echo 'Application deployed successfully!'
"

log "Migration completed successfully! Application is now running on GCP."
log "Application URL: http://$INSTANCE_IP"

# Update local status file
echo "SCALED" > /tmp/scaling_status
