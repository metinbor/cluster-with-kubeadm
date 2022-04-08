#!/bin/bash

#Steps for Master Node (control plane): 
#1. Swap disabled. You MUST disable swap in order for the kubelet to work properly.
#disable swap 

sudo swapoff -a

#keeps the swaf off during reboot

sudo sed -i '/ swap / s/^\(.*\)$/#\1/g'/etc/fstab

#Update the apt package index and install packages needed to use the Kubernetes apt repository
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

#Installing Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# Following configurations are recomended in the kubenetes documentation for Docker runtime. Please refer https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker

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

#3.Add the Kubernetes apt repository:

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#4.Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
#kubeadm: the command to bootstrap the cluster.
#kubelet: the component that runs on all of the machines in your cluster and does things like starting PODs and containers.
#kubectl: the command line until to talk to your cluster.

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl

#for install specific versions 
#sudo apt-get install -y kubelet=1.20.6-00 kubectl=1.20.6-00 kubeadm=1.20.6-00

sudo apt-mark hold kubelet kubeadm kubectl


IPADDR="10.0.0.10"

NODENAME=$(hostname -s)

#To initialize the control-plane node run

sudo kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=192.168.0.0/16 --node-name $NODENAME --ignore-preflight-errors Swap

#This may take several minutes. After it finishes you should see: "Your Kubernetes control-plane has initialized successfully!"

#To start using your cluster, you need to run the following as a regular user:
#To make kubectl work for your non-root user

mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  
 #if you are the root user, you can run:

#export KUBECONFIG=/etc/kubernetes/admin.conf

  

#deploy a Pod network to the cluster
#You must deploy a Container Network Interface (CNI) based Pod network add-on so that your Pods can communicate with each other. Cluster DNS (CoreDNS) will not start up before a network is installed.

#deploy calico
#Calico is an open source networking and network security solution for containers
curl https://docs.projectcalico.org/manifests/calico.yaml -O

kubectl apply -f calico.yaml


