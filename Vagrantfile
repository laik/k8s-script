# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.


# wget -O Vagrantfile https://raw.githubusercontent.com/laik/k8s-script/master/vgrantfile-tempory.rb


KubernetesHosts = {
    :node1 => '192.168.33.40',
    :node2 => '192.168.33.41',
    :node3 => '192.168.33.42',
}

# Setting all node ip address
$IPADDR = <<SCRIPT 
sudo sh -c  "echo '#
192.168.33.40   node1
192.168.33.41   node2
192.168.33.42   node3
' >> /etc/hosts"
SCRIPT


$DEFAULTSETTING = <<SCRIPT
sudo -i 
yum install -y wget 
wget -O centos7-setting.sh https://raw.githubusercontent.com/laik/k8s-script/master/centos7-setting.sh && sh centos7-setting.sh

echo "vagrant file centos74需要去掉(远程登陆)"
sed -i 's/^#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sed -i 's/^#UsePAM/UsePAM/g' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin/PermitRootLogin/g'  /etc/ssh/sshd_config
systemctl restart sshd


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
                        v.customize ["modifyvm",:id,"--name",app_server_name,"--memory","2048","--cpus","2"]
                end
                app_config.vm.box = "centos74"
                app_config.vm.hostname = app_server_name
                app_config.vm.network :private_network,ip: app_server_ip
                        config.vm.provision "shell",inline: $IPADDR
                        config.vm.provision "shell",inline: $DEFAULTSETTING
                #公有网络可访问
                config.vm.network "public_network",:bridge => 'em2'
             end
             config.vm.synced_folder "tmp","/vagrant", type: "nfs",nfs: true,linux__nfs_options: ['rw','no_subtree_check','all_squash','async']
        end
end