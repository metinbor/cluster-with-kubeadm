#!/bin/bash

#Steps for Master Node (control plane): 

#Enable iptables Bridged Traffic

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system



# Swap disabled. You MUST disable swap in order for the kubelet to work properly.
#disable swap 

sudo swapoff -a

#keeps the swaf off during reboot

sudo sed -i '/ swap / s/^\(.*\)$/#\1/g'/etc/fstab

#Install the required packages for Docker
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release


#Add the Docker GPG key and apt repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
 #Installing Docker 

sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y


#Add the docker daemon configurations to use systemd as the cgroup driver.
#Configure the Cgroup driver

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

#Start and enable the docker service

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Docker Runtime Configured Successfully"

#Installing kubeadm, kubelet and kubectl 

#1.Update the apt package index and install packages needed to use the Kubernetes apt repository:

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

#2.Download the Google Cloud public signing key:
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

#3.Add the GPG key and the Kubernetes apt repository:

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#4.Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
#kubeadm: the command to bootstrap the cluster.
#kubelet: the component that runs on all of the machines in your cluster and does things like starting PODs and containers.
#kubectl: the command line until to talk to your cluster.

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl

#for install specific versions 
#sudo apt-get install -y kubelet=1.20.6-00 kubectl=1.20.6-00 kubeadm=1.20.6-00

you can use the following commands to find the latest versions.

#apt update
#apt-cache madison kubeadm | tac


#Add hold to the packages to prevent upgrades.
sudo apt-mark hold kubelet kubeadm kubectl
