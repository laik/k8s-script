# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.


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
systemctl disable firewalld.service
systemctl stop firewalld.service

sudo yum install lsof wget git go -y

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
                        # config.vm.provision "shell",inline: $ETCD //基于 Kubeadm 不需要手工安装 etcd
             end
             config.vm.synced_folder "/root/virtual/dxp/tmp","/vagrant", type: "nfs",nfs: true,linux__nfs_options: ['rw','no_subtree_check','all_squash','async']
        end
end