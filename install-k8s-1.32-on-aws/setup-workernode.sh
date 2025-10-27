#!/bin/sh

set -ex

exec > /var/log/user-data.log 2>&1
# Source: https://kubernetes.io/docs/reference/setup-tools/kubeadm
KUBE_VERSION=1.31

#Update System Packages
sudo apt-get update
sudo apt-get upgrade -y

#Set Hostname
#sudo hostnamectl set-hostname "worker-$(hostname -I | awk '{print $1}')"

#Install Required Packages
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

#Disable Swap (Required for K8s)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#Install and Configure containerd
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

#Enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd


#Add Kubernetes v1.31 APT Repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | 
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#Install Kubernetes Components
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl       #apt-mark hold ensures these packages aren’t upgraded unintentionally.


#Load Required Kernel Modules
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo ""
echo "done for worker node setup. Now get the kubeadm join command from master and run of worker nodes !!!"
echo ""

# tail -100f /var/log/user-data.log 