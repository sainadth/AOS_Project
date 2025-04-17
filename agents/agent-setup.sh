#!/bin/bash

LOG_FILE="/var/log/agent-setup.log"

# Start logging
exec > >(tee -a $LOG_FILE) 2>&1
echo "Starting agent setup at $(date)"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "Error: kubectl is not installed. Install it before running this script."
  exit 1
fi

# Install required tools
sudo apt-get update
sudo apt-get install -y sqlite3 mosquitto-clients inotify-tools

# Install Python and Flask
sudo apt-get install -y python3 python3-pip
pip3 install flask sqlite3

# Check if sqlite-deployment.yaml exists
if [ ! -f "sqlite-deployment.yaml" ]; then
  echo "Error: sqlite-deployment.yaml file not found. Ensure the file exists in the current directory."
  exit 1
fi

# Deploy SQLite as a Kubernetes deployment
kubectl apply -f sqlite-deployment.yaml
echo "Deployed SQLite as a Kubernetes deployment."

# Configure network settings
SERVER_IP="<server-ip>"  # Replace with the server's IP address
MQTT_PORT=1883           # Default Mosquitto MQTT port

# Test connectivity to the server
echo "Testing connectivity to the server at $SERVER_IP..."
ping -c 4 $SERVER_IP

# Configure log rotation
cat <<EOF | sudo tee /etc/logrotate.d/agent-setup
$LOG_FILE {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root root
}
EOF
echo "Log rotation configured for $LOG_FILE."

# Start the synchronization script
nohup ./agent-sync.sh > agent-sync.log 2>&1 &
echo "Agent setup complete. Synchronization script is running in the background."

# Start the web app for CRUD operations
nohup python3 webapp.py > webapp.log 2>&1 &
echo "Web app for CRUD operations is running in the background."
