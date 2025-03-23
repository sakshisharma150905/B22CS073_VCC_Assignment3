# B22CS073_VCC_Assignment3


This report details the implementation of an automated system that monitors resource usage on a local virtual machine and triggers migration to Google Cloud Platform (GCP) when resource utilization exceeds a predefined threshold of 75%. The solution employs bash scripting for resource monitoring, GCP's Compute Engine for cloud infrastructure, and a sample Node.js application to demonstrate the auto-scaling functionality. This implementation showcases a hybrid cloud approach that optimizes resource utilization by leveraging both local infrastructure and cloud resources dynamically based on actual demand.

## 1. Introduction

### 1.1 Project Objectives

The primary objectives of this project were to:
- Create and configure a local virtual machine environment
- Implement a robust resource monitoring system
- Develop a mechanism to trigger migration to a public cloud when resource usage exceeds 75%
- Demonstrate the entire workflow with a sample application
- Document the architecture, implementation steps, and testing results

### 1.2 Technical Approach

The implementation follows a modular approach with three main components:
1. **Resource Monitoring System**: A bash script that periodically checks CPU, memory, and disk usage
2. **Migration Mechanism**: A script that handles the creation of cloud resources and migration of the application
3. **Sample Application**: A Node.js application with endpoints to simulate various load conditions

## 2. Local VM Configuration

### 2.1 Virtualization Platform

VirtualBox was selected as the virtualization platform due to its cross-platform compatibility, robust feature set, and open-source nature. The local VM was configured with the following specifications:

| Component       | Specification         |
|-----------------|-----------------------|
| Operating System| Ubuntu 22.04 LTS      |
| CPU            | 2 vCPU cores          |
| Memory         | 2 GB RAM              |
| Storage        | 20 GB                 |
| Network        | NAT + Host-only Adapter|

### 2.2 VM Creation Process

The VM was created using VirtualBox's command-line interface for repeatability:

```bash
VBoxManage createvm --name "AutoScaleVM" --ostype Ubuntu_64 --register
VBoxManage modifyvm "AutoScaleVM" --memory 2048 --cpus 2
VBoxManage createhd --filename "AutoScaleVM.vdi" --size 20000
VBoxManage storagectl "AutoScaleVM" --name "SATA Controller" --add sata
VBoxManage storageattach "AutoScaleVM" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "AutoScaleVM.vdi"
VBoxManage storageattach "AutoScaleVM" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium ubuntu-22.04-desktop-amd64.iso
```

### 2.3 System Dependencies

The following packages were installed on the VM to support the implementation:

```bash
sudo apt-get update
sudo apt-get install -y bc htop nodejs npm stress git curl unzip
```

## 3. Resource Monitoring Implementation

### 3.1 Monitoring Script Architecture

The resource monitoring system is built around a bash script that performs the following functions:
- Collects CPU, memory, and disk usage metrics
- Logs resource utilization data
- Compares current usage against the 75% threshold
- Triggers the migration process when the threshold is exceeded

### 3.2 Implementation Details

The monitoring script (`monitor_resources.sh`) uses native Linux tools like `top`, `free`, and `df` to gather resource utilization data:

```bash
#!/bin/bash

# File to keep track of scaling status
SCALING_STATUS_FILE="/tmp/scaling_status"

# Function to get current resource usage
get_resource_usage() {
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    MEMORY_USAGE=$(free -m | awk '/Mem:/ {print $3/$2 * 100}')
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%" >> /var/log/resource_monitor.log
}

# Function to check if we need to scale to cloud
check_scaling_threshold() {
    if [ -f "$SCALING_STATUS_FILE" ]; then
        CURRENT_STATUS=$(cat "$SCALING_STATUS_FILE")
        if [ "$CURRENT_STATUS" == "SCALING" ] || [ "$CURRENT_STATUS" == "SCALED" ]; then
            echo "Already in $CURRENT_STATUS state. Skipping check."
            return 1
        fi
    fi

    if (( $(echo "$CPU_USAGE > 75" | bc -l) )) || (( $(echo "$MEMORY_USAGE > 75" | bc -l) )); then
        echo "THRESHOLD EXCEEDED - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%"
        return 0
    fi

    return 1
}

# Function to trigger cloud scaling
trigger_cloud_scaling() {
    echo "SCALING" > "$SCALING_STATUS_FILE"
    /usr/local/bin/migrate_to_gcp.sh
    echo "SCALED" > "$SCALING_STATUS_FILE"
}

get_resource_usage

if check_scaling_threshold; then
    trigger_cloud_scaling
else
    echo "Resource usage within acceptable limits."
fi
```

### 3.3 Scheduling and Automation

The monitoring script is scheduled to run at regular intervals using cron:

```bash
*/5 * * * * /usr/local/bin/monitor_resources.sh
```

## 4. GCP Configuration

### 4.1 Project Setup

1. Created a new project named "auto-scale-project"
2. Enabled the Compute Engine API
3. Set up billing for the project

### 4.2 Service Account Configuration

A service account with Compute Admin, Service Account User, and Storage Admin roles was created. The service account key was securely stored:

```bash
sudo chmod 600 /etc/gcp/service-account-key.json
```

### 4.3 Google Cloud SDK Installation

```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-397.0.0-linux-x86_64.tar.gz
tar -xzf google-cloud-sdk-397.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
```

## 5. Migration Implementation

The migration script manages authentication, instance creation, and data transfer, ensuring a seamless transition to the cloud.

## 6. Conclusion

The local VM to cloud auto-scaling system efficiently monitors resource usage and seamlessly migrates workloads to Google Cloud when thresholds are exceeded. This approach ensures high availability and optimal resource utilization, demonstrating the feasibility of hybrid cloud solutions.

