Prepare EC2 Instances for Kubernetes  
EC2 Instance: 4 x t3.2xlarge (1 master, 3 worker)  
Add keypair  
Security Group: Allow SSH, TCP, HTTP, HTTPS (separate for Ingress&Egress)  

# 1.Update Hostnames
Change the hostnames on each node for easier identification and name resolution.  
`sudo hostnamectl set-hostname controlplane`  
`sudo hostnamectl set-hostname worker1`  
`sudo hostnamectl set-hostname worker2`  

# 2. Verify mac addresses and product uid are unique:
Each node is likely to have a unique UUID and MAC address, but it’s a good idea to verify

`ip link`  
`cat /sys/class/dmi/id/product_uuid`  

# 3. Disable swap
Swap must be disabled for kubelet (a core Kubernetes component) to start.  

`sudo swapoff -a`  

# 4. Installing container runtime  
We need container runtime to run containers. For runtime to work, IPv4 packet forwarding should be enabled for packets to be routed between interfaces.  

## 4.1 Enable IPv4 packet forwarding  
`echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf`  
`sudo sysctl --system`  

## 4.2 Verify  
`sysctl net.ipv4.ip_forward`  

## 4.3 Install containerd using package manager  
`sudo apt update && sudo apt upgrade -y`  
`sudo apt-get install containerd`  

## 4.4 Verify installation:  
`ctr --version`  

# 5. Installing CNI plugins  
CNI plugins are required for Kubernetes networking to work. When we later installed Calico networking plugin, this is a prereq 

`sudo mkdir -p /opt/cni/bin` 
`CNI_VERSION=$(curl -sSL "https://api.github.com/repos/containernetworking/plugins/releases/latest" | jq -r '.tag_name')`  
`wget -q "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"`  
`sudo tar Cxzf /opt/cni/bin "cni-plugins-linux-amd64-${CNI_VERSION}.tgz"`  

# 6. Configure containerd  
## 6.1 Generate config file  
`mkdir /etc/containerd` – might be there already  
`containerd config default > /etc/containerd/config.toml`  

## 6.2 Ensure the CRI runtime is enabled (this step may not be necessary).  
Check if CRI is in disabled_plugins (at the top of the file ) list within /etc/containerd/config.toml  

`head /etc/containerd/config.toml`  
restart containerd ( if performed above step)  
`sudo systemctl restart containerd`  

## 6.3 Configure the systemd cgroup driver  
`sudo vi /etc/containerd/config.toml`  
Within [plugins.”io.containerd.grpc.v1.cri”.containerd.runtimes.runc.options] section update SystemCgroup to true  
`SystemdCgroup = true`  
Within [plugins.”io.containerd.grpc.v1.cri”] section  
Update sandbox image to 3.10  
`sandbox_image = "registry.k8s.io/pause:3.10"`  
restart containerd  
`sudo systemctl restart containerd`  

# 7. Install Kubernetes tools:  
## 7.1 Update system, add sha keys, and add kubernetes repo  
`echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list  

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg  

sudo apt update`  

## 7.2 Install Kubelet and kubeadm  

`sudo apt-get install -y kubelet kubeadm kubectl`  

# 8. Install kubectl on controlplane  
*** Run this command on control plane node only ***  

`sudo apt-get install -y kubectl`  

Our nodes are ready to be setup for kubernetes!!  

# Creating a cluster  
## 1. Initializing control plane node  
`sudo kubeadm init --pod-network-cidr=192.168.0.0/16`  

Take note of the join command displayed in the output  .

## 2. Join Worker Nodes  
Just an example command:  
`kubeadm join 172.31.25.150:6443 --token 2i8vrs.wsshnhe5zf87rhhu --discovery-token-ca-cert-hash sha256:eacbaf01cc58203f3ddd69061db2ef8e64f450748aef5620ec04308eac44bd77`  

**make sure traffic is allowed between these nodes; otherwise, worker nodes cannot join the cluster. Check the security groups or firewall rules if necessary**  

## 3. Install networking plugin – calico  
`kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml  
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml  
watch kubectl get pods -n calico-system`  

**If you have used different pod network, update custom-resources yaml file  

## 4. Configure kubectl on controlplane so non-root users can use it.  
`mkdir -p $HOME/.kube`  
`sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`  
`sudo chown $(id -u):$(id -g) $HOME/.kube/config`  

switch to a regular user and list nodes using kubectl  
`kubectl get nodes -o wide`  

# Setup your machine to access cluster from  
## 1. Installing Kubectl on you machine  
`sudo apt-get update  
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt | sed 's/\.0//')"  
sudo apt-get install -y apt-transport-https ca-certificates curl gpg  
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${RELEASE}/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg  
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${RELEASE}/deb/ /" > sudo tee /etc/apt/sources.list.d/kubernetes.list  
sudo apt-get update  
sudo apt-get install -y kubectl`  

## 2. Move the config file
`scp root@<control-plane-ip>:/etc/kubernetes/admin.conf .kube/conf`  

If you can’t ssh to control plane, manually move the admin.conf to .kube/conf file/  

## 3. Test and run kubectl now  
`kubectl get nodes`  

