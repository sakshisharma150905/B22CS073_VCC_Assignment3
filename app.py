from flask import Flask, request, jsonify
import time
import threading
import os
import math
import multiprocessing

app = Flask(__name__)

# More CPU-intensive task
def cpu_stress():
    print(f"Starting intensive CPU stress task in process {os.getpid()}...")
    while True:
        [math.sin(i) * math.cos(i) * math.sqrt(i) for i in range(50000000)]

# Trigger CPU-intensive work
@app.route('/stress', methods=['POST'])
def stress_cpu():
    processes = int(request.json.get('threads', os.cpu_count()))

    for _ in range(processes):
        process = multiprocessing.Process(target=cpu_stress)
        process.daemon = True
        process.start()

    return jsonify({"message": f"Started {processes} CPU-intensive processes."})

# Monitor CPU usage and trigger GCP autoscaling
@app.route('/monitor', methods=['GET'])
def monitor():
    cpu_usage = os.popen("top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'").read().strip()
    try:
        usage_percent = float(cpu_usage)

        if usage_percent > 75:
            print("🚀 High CPU detected. Triggering auto-scaling...")
            os.system("./autoscale_gcp.sh")  # Call the script to deploy to GCP

        return jsonify({"cpu_usage": usage_percent})

    except ValueError:
        return jsonify({"error": "Failed to retrieve CPU usage"}), 500

@app.route('/')
def home():
    return "Welcome to the CPU Stress Test Application! Use /stress to load CPU."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)
