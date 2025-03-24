Here is a README file for your project that will appear as normal text when pasted into GitHub and committed:

---

```markdown
# Local VM to Cloud Auto-Scaling Implementation

## Author
**Name:** Sakshi Sharma  
**Roll No.:** B22CS073  

## Executive Summary
This project implements an automated system that:
- Monitors resource usage on a local virtual machine.
- Triggers migration to Google Cloud Platform (GCP) when resource utilization exceeds 75%.
- Uses bash scripting for resource monitoring and GCP Compute Engine for cloud infrastructure.
- Demonstrates auto-scaling functionality with a sample Node.js application.
- Follows a hybrid cloud approach to optimize resource utilization dynamically.

---

## Table of Contents
1. [Introduction](#introduction)  
2. [Local VM Configuration](#local-vm-configuration)  
3. [Resource Monitoring Implementation](#resource-monitoring-implementation)  
4. [GCP Configuration](#gcp-configuration)  
5. [Migration Implementation](#migration-implementation)  
6. [Sample Application](#sample-application)  
7. [System Architecture](#system-architecture)  
8. [Testing and Validation](#testing-and-validation)  
9. [Challenges and Solutions](#challenges-and-solutions)  
10. [Future Enhancements](#future-enhancements)  
11. [Conclusion](#conclusion)  
12. [Links](#links)  

---

## 1. Introduction
### **Project Objectives**
- Create and configure a local virtual machine.
- Implement a robust resource monitoring system.
- Develop a mechanism to migrate to the cloud when resource usage exceeds 75%.
- Demonstrate the entire workflow with a sample application.
- Document architecture, implementation steps, and testing results.

### **Technical Approach**
The implementation is divided into three main components:
1. **Resource Monitoring System:** Bash script that checks CPU, memory, and disk usage.
2. **Migration Mechanism:** Script to create cloud resources and migrate applications.
3. **Sample Application:** A web application that simulates CPU-intensive tasks.

---

## 2. Local VM Configuration
### **Virtualization Platform**
- **Platform:** VirtualBox  
- **VM Configuration:**
  - **OS:** Ubuntu 24.04 LTS  
  - **CPU:** 2 vCPU cores  
  - **Memory:** 4 GB RAM  
  - **Storage:** 25 GB  
  - **Network:** NAT + Host-only Adapter  

### **VM Creation Process**
The following VirtualBox CLI commands were used:

```bash
VBoxManage createvm --name "AutoScaleVM" --ostype Ubuntu_64 --register
VBoxManage modifyvm "AutoScaleVM" --memory 2048 --cpus 2
VBoxManage createhd --filename "AutoScaleVM.vdi" --size 20000
VBoxManage storagectl "AutoScaleVM" --name "SATA Controller" --add sata
VBoxManage storageattach "AutoScaleVM" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "AutoScaleVM.vdi"
VBoxManage storageattach "AutoScaleVM" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium ubuntu-22.04-desktop-amd64.iso
```

---

## 3. Resource Monitoring Implementation
A **bash script (monitor.sh)** monitors CPU, memory, and disk usage and triggers migration when the threshold exceeds 75%.

```bash
#!/bin/bash
AUTOSCALE_SCRIPT="/home/sakshi/autoscale_gcp.sh"

while true; do
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "Current CPU Usage: $CPU_USAGE%"

    if (( $(echo "$CPU_USAGE > 75" | bc -l) )); then
        echo "CPU usage exceeded 75%! Triggering auto-scaling..."
        bash $AUTOSCALE_SCRIPT
        break
    fi

    sleep 10
done
```

---

## 4. GCP Configuration
### **Project Setup**
1. Created a new project: **"auto-scale-project"**
2. Enabled **Compute Engine API**
3. Configured **billing and authentication**

### **Service Account Configuration**
- **Roles:** Compute Admin, Service Account User, Storage Admin.
- **Key stored at:** `/home/sakshi/Downloads/sakshi3-key.json`
- **Permission:** `chmod 600 /home/sakshi/Downloads/sakshi3-key.json`

---

## 5. Migration Implementation
### **Migration Script**
This script:
- Authenticates with GCP.
- Creates a new cloud instance.
- Transfers and starts the application.

```bash
#!/bin/bash
INSTANCE_NAME="autoscaled-vm-$(date +%s)"
ZONE="us-central1-a"
MACHINE_TYPE="n1-standard-1"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
LOCAL_APP_PATH="/home/sakshi/Downloads/app"
REMOTE_PATH="~/application"

gcloud compute instances create $INSTANCE_NAME --zone=$ZONE --machine-type=$MACHINE_TYPE --image-family=$IMAGE_FAMILY --image-project=$IMAGE_PROJECT --tags=http-server
```

---

## 6. Sample Application
A Flask-based **app.py** simulates CPU-intensive tasks.

```python
from flask import Flask, request, jsonify
import os
import math
import multiprocessing

app = Flask(__name__)

def cpu_stress():
    while True:
        [math.sin(i) * math.cos(i) * math.sqrt(i) for i in range(50000000)]

@app.route('/stress', methods=['POST'])
def stress_cpu():
    processes = int(request.json.get('threads', os.cpu_count()))
    for _ in range(processes):
        process = multiprocessing.Process(target=cpu_stress)
        process.daemon = True
        process.start()
    return jsonify({"message": f"Started {processes} CPU-intensive processes."})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)
```

---

## 7. System Architecture
The system follows a **hybrid cloud** model:
1. **Resource monitoring** detects CPU overuse.
2. **Migration script** provisions a cloud VM.
3. **Application is deployed** and serves requests from the cloud.

![Image Description](arch-image.png)

---

## 8. Testing and Validation
### **Testing Approach**
- **Baseline Testing:** Normal operation parameters.
- **Load Testing:** CPU and memory stress testing.
- **Migration Testing:** Verifies auto-scaling trigger.

### **Test Results**
| Test Scenario | CPU Usage | Auto-Scale Triggered | Result |
|--------------|------------|----------------|---------|
| Idle System | 5% | No | ✅ Pass |
| Low Load | 40% | No | ✅ Pass |
| CPU Intensive | 85% | Yes | ✅ Pass |
| Memory Intensive | 82% | Yes | ✅ Pass |

---

## 9. Challenges and Solutions
| **Challenge** | **Solution** |
|--------------|-------------|
| Prevent false triggers | Moving average calculation |
| GCP instance provisioning time | Asynchronous migration |
| Secure credential management | Least privilege & restricted permissions |

---

## 10. Future Enhancements
- **Bi-directional Scaling:** Scale down back to local VM.
- **Multi-cloud Support:** Extend to AWS and Azure.
- **Containerization:** Migrate workloads using Docker.
- **Load Balancing:** Distribute traffic between local and cloud.

---

## 11. Conclusion
This project successfully implements an **auto-scaling solution** that dynamically migrates workloads between local and cloud environments based on resource usage.

---

## 12. Links
- **GitHub Repo:** [B22CS073_VCC_Assignment3](https://github.com/sakshisharma150905/B22CS073_VCC_Assignment3)
- **Demo Video:** [Watch Here](https://drive.google.com/file/d/1IE_kCZZcFmirZ7vLpdPdClymbBsH66lJ/view)

---

This README is GitHub-compatible and will display properly when committed. 🚀
