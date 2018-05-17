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

wget -O /etc/yum.repod/docker-ce.repo https://raw.githubusercontent.com/laik/k8s-script/master/docker-ce.repo
# wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo

# yum-config-manager --enable docker-ce-edge
# 替换清华大学repo
# sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo
yum makecache fast

echo "yum install docker-ce"

yum install docker-ce -y

echo "使用阿里云加速器"
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://ek7vcrxc.mirror.aliyuncs.com"]
}
EOF

echo "启动 Docker................."
systemctl daemon-reload && systemctl restart docker
systemctl enable docker && systemctl start docker