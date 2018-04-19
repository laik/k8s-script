# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.


# wget -O Vagrantfile https://raw.githubusercontent.com/laik/k8s-script/master/vgrantfile-tempory.rb


KubernetesHosts = {
    :node1 => '192.168.33.10',
    :node2 => '192.168.33.20',
    :node3 => '192.168.33.30',
}

# Setting all node ip address
$IPADDR = <<SCRIPT 
sudo sh -c  "echo '192.168.33.10   node1
192.168.33.20   node2
192.168.33.30   node3
' >> /etc/hosts"
SCRIPT


$DEFAULTSETTING = <<SCRIPT
sudo -i 

echo "关闭Swap"
swapoff -a 
sed 's/.*swap.*/#&/' /etc/fstab

echo "关闭防火墙"
systemctl disable firewalld.service
systemctl stop firewalld.service

echo "安装 wget"
yum install wget -y

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
echo 'echo nameserver 114.114.114.114
nameserver 202.96.128.66
nameserver 202.96.128.166
nameserver 1.1.1.1
nameserver 1.0.0.1
>>/etc/resolv.conf' | sh

echo "在RHEL/CentOS 7 系统上可能会路由失败,添加配置"s
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

echo "安装 kube-comp"
yum install -y kubelet kubeadm kubectl docker

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
systemctl enable kubelet && systemctl start kubelet

echo "执行下载镜像脚本"
cd /vagrant && chmod +x k8s-dev.sh && sh k8s-dev.sh && cd ~

SCRIPT


# Map 配置文件自动创建多台相同的 Centos 主机
Vagrant.configure("2") do |config|
        # KubernetesServer map，将key和value分别赋值给app_server_name和app_server_ip
        KubernetesHosts.each do |app_server_name, app_server_ip|
             #针对每一个app_server_name，来配置config.vm.define配置节点，命名为app_config
             config.vm.define app_server_name do |app_config|
                app_config.vm.provider :virtualbox do |v|
                        v.customize ["modifyvm",:id,"--name",app_server_name,"--memory","1024","--cpus","1"]
                end
                app_config.vm.box = "centos7"
                app_config.vm.hostname = app_server_name
                app_config.vm.network :private_network,ip: app_server_ip
                        config.vm.provision "shell",inline: $IPADDR
                        config.vm.provision "shell",inline: $DEFAULTSETTING
             end
             config.vm.synced_folder "tmp","/vagrant", type: "nfs",nfs: true,linux__nfs_options: ['rw','no_subtree_check','all_squash','async']
        end
end