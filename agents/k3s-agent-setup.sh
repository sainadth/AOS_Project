#!/bin/bash

# Install K3s agent
SERVER_IP="<server-ip>"  # Replace with the server's IP address
K3S_TOKEN="<server-token>"  # Replace with the token from the server

curl -sfL https://get.k3s.io | K3S_URL=https://$SERVER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
# curl -sfL https://get.k3s.io | K3S_URL=https://3.149.240.74:6443 K3S_TOKEN=K10bff926202f76342e30363648898f09ec0df4228223c26f2af9144802d50d9db1::server:ee43256d58a53d141be4c19928d06fca sh -

# Check K3s agent status
sudo systemctl status k3s-agent

# Enable K3s agent service
sudo systemctl enable k3s-agent

# Verify K3s agent installation
kubectl get nodes

# Test connectivity to the server
ping -c 4 $SERVER_IP
