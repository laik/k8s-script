#!/bin/bash

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

yum install -y yum-utils device-mapper-persistent-data lvm2

wget -O /etc/yum.repos.d/docker-ce.repo https://raw.githubusercontent.com/laik/k8s-script/master/docker-ce.repo
# wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo

# yum-config-manager --enable docker-ce-edge
# 替换清华大学repo
# sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo
yum makecache fast

echo "yum install docker-ce"

# kubernetes 1.10.1 支持最大版本 17.03

yum install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm -y

yum install docker-ce-17.03.2.ce-1.el7.centos -y

echo "使用阿里云加速器"
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://ek7vcrxc.mirror.aliyuncs.com"]
}
EOF

echo "启动 Docker................."
systemctl enable docker && systemctl start docker
systemctl daemon-reload && systemctl restart docker
