## AGENT SETUP

curl -sfL https://get.k3s.io | K3S_URL=https://<SERVER_IP>:6443 K3S_TOKEN=<K3S_TOKEN> sh -

cd ~

mkdir .kube

cd .kube/

vi config

### insert content from /etc/rancher/k3s/k3s.yaml on server


### check if <PUBLIC IP> is pingable

ping <PUBLIC IP>

kubectl get nodes