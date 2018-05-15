#! /bin/bash

# 红帽包管理工具（RPM）¶  安装 Ceph
sudo yum install -y yum-utils && sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ && sudo yum install --nogpgcheck -y epel-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && sudo rm /etc/yum.repos.d/dl.fedoraproject.org*

sudo yum update && sudo yum install ceph-deploy  ntp ntpdate ntp-doc -y


# 优先级/首选项 确保你的包管理器安装了优先级/首选项包且已启用。在 CentOS 上你也许得安装 EPEL ，在 RHEL 上你也许得启用可选软件库。

sudo yum install yum-plugin-priorities -y 
# 比如在 RHEL 7 服务器上，可用下列命令安装 yum-plugin-priorities并启用 rhel-7-server-optional-rpms 软件库：

sudo yum install yum-plugin-priorities --enablerepo=rhel-7-server-optional-rpms






[ceph]
name=ceph
baseurl=http://mirrors.163.com/ceph/rpm-luminous/el7/x86_64/
gpgcheck=0
[ceph-noarch]
name=cephnoarch
baseurl=http://mirrors.163.com/ceph/rpm-luminous/el7/noarch/
gpgcheck=0


echo "关闭防火墙"
systemctl disable firewalld.service
systemctl stop firewalld.service

echo "关闭Selinux"
setenforce  0
echo 'sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config'| sh
getenforce


#优先级/首选项
#确保你的包管理器安装了优先级/首选项包且已启用。在 CentOS 上你也许得安装 EPEL ，在 RHEL 上你也许得启用可选软件库。

sudo yum install yum-plugin-priorities
#如在 RHEL 7 服务器上，可用下列命令安装 yum-plugin-priorities并启用 rhel-7-server-optional-rpms 软件库：

sudo yum install yum-plugin-priorities --enablerepo=rhel-7-server-optional-rpms