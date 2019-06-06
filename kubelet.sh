#!/bin/bash

echo "kubeadm 与 需要安装的版本最好一致"
echo "当前是v1.10.1 kubeadm-1.10.1-0.x86_64"
echo "安装 kube"

yum install -y kubelet-1.10.1-0.x86_64 && yum install -y kubeadm-1.10.1-0.x86_64

echo "检查 Docker 存储CgroupDriver 与 Kubelet 的一致性"
iscgroupfs=`docker info | grep -i cgroup | grep cgroupfs | wc -l` && if [ 1 -eq $iscgroupfs ]; then \
sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
else 
sed -i "s/cgroup-driver=cgroupfs/cgroup-driver=systemd/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

echo "kubelet 增加不使用swap配置"
echo 'Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"' > /etc/systemd/system/kubelet.service.d/90-local-extras.conf

echo "启动kubelet"
systemctl daemon-reload
systemctl enable kubelet
