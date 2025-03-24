#!/bin/bash

# Set variables
INSTANCE_NAME="autoscaled-vm-$(date +%s)"  # Unique VM name
ZONE="us-central1-a"
MACHINE_TYPE="n1-standard-1"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
LOCAL_APP_PATH="/home/sakshi/Downloads/app"      
REMOTE_PATH="~/application"

# Ensure gcloud is authenticated (use default credentials)
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "."; then
    echo "❌ No active gcloud session found. Run 'gcloud auth login'."
    exit 1
fi

# Set the active project (replace with your project ID)
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project not set. Run: gcloud config set project [YOUR_PROJECT_ID]"
    exit 1
fi

# Create the VM
echo "🚀 Creating VM: $INSTANCE_NAME in project $PROJECT_ID"
gcloud compute instances create $INSTANCE_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --tags=http-server

echo "✅ VM creation initiated..."

# Wait for the VM to become available
echo "⏳ Waiting for VM to start..."
sleep 30

# Fetch external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "📌 VM External IP: $EXTERNAL_IP"

# Ensure SSH key exists or create one
SSH_KEY_PATH="$HOME/.ssh/gcp_key"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "🔐 Generating SSH key..."
    ssh-keygen -t rsa -f $SSH_KEY_PATH -N ""
    gcloud compute os-login ssh-keys add --key-file="$SSH_KEY_PATH.pub"
fi

# Transfer the application to the VM
echo "📤 Transferring application to VM..."
scp -i $SSH_KEY_PATH $LOCAL_APP_PATH user@$EXTERNAL_IP:$REMOTE_PATH

echo "🚀 GCP VM created and application deployed."
