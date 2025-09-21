#!/bin/sh

set -ex

exec > /var/log/user-data.log 2>&1
# Source: https://kubernetes.io/docs/reference/setup-tools/kubeadm

KUBE_VERSION=1.31

#Set Hostname
hostnamectl set-hostname master

#Update System Packages
sudo apt-get update
sudo apt-get upgrade -y

#Install Required Packages
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

#Disable Swap (Required for K8s)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#Install and Configure containerd
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i '/SandboxImage/s|".*"|"registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml 

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


##Initialize Kubernetes Control Plane
# PRIVATE_IP=$(hostname -I | awk '{print $1}') ; echo $PRIVATE_IP
# sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$PRIVATE_IP


##Set up kubectl for your user on master node
# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config
# export KUBECONFIG=$HOME/.kube/config


##Install Calico CNI (For v1.31 Compatibility). This installs the Tigera Operator, which manages the Calico automatically
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml   
# kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/custom-resources.yaml

# run kubeadm join command from the output of below command on worker nodes to join the cluster
# kubeadm token create --print-join-command     

echo "\ndone for master node setup!!!. Run kubeadm init on master then run kubeadm join on all worker nodes to join the cluster\n"


# tail -100f /var/log/user-data.log 

# Use IP:Port to test the nginx service from outside the cluster
# kubectl create deployment nginx-deployment --image=nginx:latest --replicas=3
# kubectl expose deployment nginx-deployment --name=nginx-service --port=80 --target-port=80 --type=NodePort

##fix worker nodes label
# kubectl label node ip-172-31-66-147 node-role.kubernetes.io/worker=worker
