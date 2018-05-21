#!/bin/bash

# all node 国内加速
cat >> ~/.bashrc <<EOF
export CEPH_DEPLOY_REPO_URL=http://mirrors.163.com/ceph/debian-jewel 
export CEPH_DEPLOY_GPG_URL=http://mirrors.163.com/ceph/keys/release.asc
EOF

# add dns
echo "我的是 K8s的节点 ,已经可以访问外网了"

# 如果机器已经做ntp同步,就不需要安装
echo "我的是 K8s的节点 ,已经做ntp同步,就不需要安装"

# add 163 yum repo
echo '#...
[ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/$basearch
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://mirrors.163.com/ceph/keys/release.asc
priority=1

[ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/noarch
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://mirrors.163.com/ceph/keys/release.asc
priority=1

[ceph-source]
name=Ceph source packages
baseurl=http://mirrors.163.com/ceph/rpm-jewel/el7/SRPMS
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://mirrors.163.com/ceph/keys/release.asc
priority=1' > /etc/yum.repos.d/ceph.repo


yum makecache fast

# node1 install ceph-deploy
yum -y install ceph-deploy

# 我这里用 K0作为管理节点
mkdir ceph-cluster && cd ceph-cluster

ceph-deploy new k1 k2 k4 k5
