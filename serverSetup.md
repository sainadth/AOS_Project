## SERVER SETUP
curl -sfL https://get.k3s.io | sh -s - server --tls-san <PUBLIC IP>

sudo ufw allow 6443/tcp
sudo ufw allow 8472/udp
sudo ufw allow 10250/tcp
sudo ufw allow 30090/tcp # Prometheus NodePort
sudo ufw allow 30030/tcp # Grafana NodePort

### K3S_TOKEN
cat /var/lib/rancher/k3s/server/node-token

### config
cat /etc/rancher/k3s/k3s.yaml

### replace local host (127.0.0.1) with <PUBLIC IP>

### Access Prometheus and Grafana
- Prometheus: http://<PUBLIC_IP>:30090
- Grafana: http://<PUBLIC_IP>:30030
