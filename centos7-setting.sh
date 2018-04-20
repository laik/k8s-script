#!/bin/bash

echo "关闭Swap"
swapoff -a 
sed 's/.*swap.*/#&/' /etc/fstab

echo "关闭防火墙"
systemctl disable firewalld.service
systemctl stop firewalld.service

echo "使用163的centos repo"
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
yum makecache


echo "安装....一些需要安装的"
yum install git lsof go -y 

echo "关闭Selinux"
setenforce  0
echo 'sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config'| sh
getenforce

echo "增加DNS"
echo 'echo #--------------
nameserver 114.114.114.114
nameserver 202.96.128.66
nameserver 202.96.128.166
nameserver 1.1.1.1
nameserver 1.0.0.1
>>/etc/resolv.conf' | sh

echo "在RHEL/CentOS 7 系统上可能会路由失败,添加配置"
echo 'cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF' |  sh
sysctl -p /etc/sysctl.conf

echo "更改kubernetes 阿里 K8s yum 源"
echo 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64-unstable
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF' |  sh

echo "安装 docker-ce"
 yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine -y

 yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum-config-manager --enable docker-ce-edge

yum install docker-ce -y


echo "安装 kube"
yum install -y kubelet kubeadm kubectl

echo "使用阿里云加速器"
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://ek7vcrxc.mirror.aliyuncs.com"]
}
EOF

echo "启动 Docker................."
systemctl daemon-reload && systemctl restart docker
systemctl enable docker && systemctl start docker


echo "检查 Docker 存储CgroupDriver 与 Kubelet 的一致性"
iscgroupfs=`docker info | grep -i cgroup | grep cgroupfs | wc -l` && if [ 1 -eq $iscgroupfs ]; then \
sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

echo "kubelet 增加不使用swap配置"
echo 'Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"' > /etc/systemd/system/kubelet.service.d/90-local-extras.conf


echo "启动kubelet"
systemctl daemon-reload
systemctl enable kubelet
