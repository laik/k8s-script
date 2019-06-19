#! /bin/bash

# 红帽包管理工具（RPM）¶  安装 Ceph
sudo yum install -y yum-utils && sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ && sudo yum install --nogpgcheck -y epel-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && sudo rm /etc/yum.repos.d/dl.fedoraproject.org*

sudo yum install ceph-deploy  ntp ntpdate ntp-doc -y


# 优先级/首选项 确保你的包管理器安装了优先级/首选项包且已启用。在 CentOS 上你也许得安装 EPEL ，在 RHEL 上你也许得启用可选软件库。
sudo yum install yum-plugin-priorities -y 


# 比如在 RHEL 7 服务器上，可用下列命令安装 yum-plugin-priorities并启用 rhel-7-server-optional-rpms 软件库：
sudo yum install yum-plugin-priorities --enablerepo=rhel-7-server-optional-rpms


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

# 关闭ipv6
cat <<EOF >/etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

sysctl -p

# admin node
su - cephnode
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa -q
ssh-copy-id ...


# 注意在控制服务器上加,先测试下不要加错,不然错误多多......
# all node 国内加速
cat >> ~/.bashrc <<EOF
export CEPH_DEPLOY_REPO_URL=http://mirrors.163.com/ceph/rpm-jewel/el7
export CEPH_DEPLOY_GPG_URL=http://mirrors.163.com/ceph/keys/release.asc
EOF
#或者香港
cat >> ~/.bashrc <<EOF
export CEPH_DEPLOY_REPO_URL=http://hk.ceph.com/rpm-jewel/el7
export CEPH_DEPLOY_GPG_URL=http://hk.ceph.com/keys/release.asc
EOF

# add dns
cat > /etc/resolv.conf<<EOF
nameserver 202.96.128.166
nameserver 202.96.128.66
EOF

# add cephnode user /*当然,我是用 root 来搞的*/
useradd cephnode 
echo '123' | passwd --stdin cephnode
echo "cephnode ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/cephnode
chmod 0440 /etc/sudoers.d/cephnode 

# install ntp server sync
yum install ntp ntpdate ntp-doc -y
crontab -e
*/1 * * * * /usr/sbin/ntpdate time7.aliyun.com >/dev/null 2>&1


# node1 install ceph-deploy
cat << EOM > /etc/yum.repos.d/ceph.repo
[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-jewel/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
EOM

yum install ceph-deploy -y


# STARTING OVER
# if at any point you run into trouble and you want to start over, execute the following to purge the Ceph packages, and erase all its data and configuration:
ceph-deploy purge {ceph-node} [{ceph-node}]
ceph-deploy purgedata {ceph-node} [{ceph-node}]
ceph-deploy forgetkeys
rm ceph.*

# 清除 PurgeData 之后,发生admin_socket: exception getting command descriptions: [Errno 2] No such file or directory
rm -rf /etc/ceph/*
rm -rf /var/lib/ceph/*/*
rm -rf /var/log/ceph/*
rm -rf /var/run/ceph/*

前提:
将 /u06目录授权
chown -R 777 /u06
chown -R cephnode:cephnode /u06
----
ceph-deploy new master1 master2 --public_network-network=192.168.4.0/24 --cluster-network=172.16.171.0/24 --repo-url=http://mirrors.aliyun.com/ceph/rpm-jewel/el7/

ceph-deploy install master1 master2

ceph-deploy mon create-initial

ceph-deploy osd prepare master1:/u06 master2:/u06

ceph-deploy osd activate master1:/u06 master2:/u06