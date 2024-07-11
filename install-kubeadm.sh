#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo chmod 777 /var/run/docker.sock




# Add docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor \
  -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add docker apt repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list

# Fetch the package lists from docker repository
sudo apt-get update -y

# Install docker and containerd
sudo apt-get install -y docker-ce docker-ce-cli containerd.io



# Configure docker to use overlay2 storage and systemd
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {"max-size": "100m"},
    "storage-driver": "overlay2"
}
EOF

# Restart docker to load new configuration
sudo systemctl restart docker

# Add docker to start up programs
sudo systemctl enable docker

# Allow current user access to docker command line
sudo usermod -aG docker $USER

# Download cri-dockerd
curl -sSLo cri-dockerd_0.2.3.3-0.ubuntu-focal_amd64.deb \
  https://github.com/Mirantis/cri-dockerd/releases/download/v0.2.3/cri-dockerd_0.2.3.3-0.ubuntu-focal_amd64.deb

# Install cri-dockerd for Kubernetes 1.24 support
sudo dpkg -i cri-dockerd_0.2.3.3-0.ubuntu-focal_amd64.deb




curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y

sudo apt install kubeadm kubelet kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a
sudo sed -i -e '/swap/d' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
sudo hostnamectl set-hostname master-node

cat <<EOF | sudo tee /etc/default/kubelet
echo KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"
EOF


cat <<EOF | sudo tee /etc/docker/daemon.json
{
      "exec-opts": ["native.cgroupdriver=systemd"],
      "log-driver": "json-file",
      "log-opts": {
      "max-size": "100m"
   },
       "storage-driver": "overlay2"
       }
EOF

sudo systemctl daemon-reload && sudo systemctl restart docker
