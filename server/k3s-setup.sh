#!/bin/bash

LOG_FILE="/var/log/server-setup.log"

# Start logging
exec > >(tee -a $LOG_FILE) 2>&1
echo "Starting server setup at $(date)"

# Install K3s
curl -sfL https://get.k3s.io | sh -
echo "Installed K3s."

# Check K3s status
sudo systemctl status k3s

# Enable K3s service
sudo systemctl enable k3s
echo "Enabled K3s service."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "Error: kubectl is not installed. Install it before running this script."
  exit 1
fi

# Deploy Mosquitto (for data synchronization)
if ! kubectl apply -f mosquitto-deployment.yaml; then
  echo "Error: Failed to deploy Mosquitto."
  exit 1
fi
echo "Deployed Mosquitto."

# Deploy Prometheus (for monitoring)
if ! kubectl apply -f prometheus-deployment.yaml; then
  echo "Error: Failed to deploy Prometheus."
  exit 1
fi
echo "Deployed Prometheus."

# Deploy Prometheus Service
if ! kubectl apply -f prometheus-service.yaml; then
  echo "Error: Failed to deploy Prometheus Service."
  exit 1
fi
echo "Deployed Prometheus Service."

# Deploy Grafana (for visualization)
if ! kubectl apply -f grafana-deployment.yaml; then
  echo "Error: Failed to deploy Grafana."
  exit 1
fi
echo "Deployed Grafana."

# Deploy Grafana Service
if ! kubectl apply -f grafana-service.yaml; then
  echo "Error: Failed to deploy Grafana Service."
  exit 1
fi
echo "Deployed Grafana Service."

# Create PersistentVolume for TimescaleDB
if ! kubectl apply -f timescaledb-pv.yaml; then
  echo "Error: Failed to create PersistentVolume for TimescaleDB."
  exit 1
fi
echo "Created PersistentVolume for TimescaleDB."

# Deploy TimescaleDB
if ! kubectl apply -f timescaledb-deployment.yaml; then
  echo "Error: Failed to deploy TimescaleDB."
  exit 1
fi
echo "Deployed TimescaleDB."

# Verify K3s installation
kubectl get nodes
echo "Server setup complete at $(date)."

# Display server IP and token for agents
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

echo "Server IP: $SERVER_IP"
echo "Server Token: $SERVER_TOKEN"

# Configure firewall rules
echo "Configuring firewall rules..."
sudo ufw allow 30030/tcp # Grafana
sudo ufw allow 30090/tcp # Prometheus
sudo ufw allow 10250/tcp # Kubelet
sudo ufw --force enable
sudo ufw reload
echo "Firewall rules configured."

# Configure log rotation
cat <<EOF | sudo tee /etc/logrotate.d/server-setup
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