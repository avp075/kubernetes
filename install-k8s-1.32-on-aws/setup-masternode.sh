#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

echo "[INFO] Disabling swap..."
sudo swapoff -a
#sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/' /etc/fstab

echo "[INFO] Loading kernel modules..."
sudo modprobe overlay
sudo modprobe br_netfilter

echo "[INFO] Setting sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

echo "[INFO] Installing containerd..."
sudo apt-get update
sudo apt-get install -y containerd jq 

echo "[INFO] Installing CNI plugin..."
sudo mkdir -p /opt/cni/bin
CNI_VERSION=$(curl -sSL "https://api.github.com/repos/containernetworking/plugins/releases/latest" | jq -r '.tag_name')
wget -q "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
sudo tar Cxzf /opt/cni/bin "cni-plugins-linux-amd64-${CNI_VERSION}.tgz"

echo "[INFO] Configuring containerd..."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

echo "[INFO] Setting systemd as cgroup driver (step 1)..."
sudo sed -i 's/^\s*SystemdCgroup\s*=.*/    SystemdCgroup = true/' /etc/containerd/config.toml

echo "[INFO] Update sandbox image..."
sudo sed -i 's#^\s*sandbox_image\s*=.*#    sandbox_image = "registry.k8s.io/pause:3.10"#' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd


echo "[INFO] Installing kubernetes tools..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo apt update
sudo apt-get install -y kubelet kubeadm kubectl

echo "[INFO] Initializing Kubernetes control plane..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version=1.32.0

echo "[INFO] Configuring kubeconfig for current user..."
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

echo "[INFO] Installing Calico CNI..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml


echo "[INFO] Control plane setup completed on Ubuntu."

