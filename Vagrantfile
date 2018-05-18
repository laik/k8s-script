# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.


# wget -O Vagrantfile https://raw.githubusercontent.com/laik/k8s-script/master/vgrantfile-tempory.rb


KubernetesHosts = {
    :kubem1 => '192.168.4.240',
    :kubem2 => '192.168.4.241',
    :kubem3 => '192.168.4.242',
}

# Setting all node ip address
$IPADDR = <<SCRIPT 
sudo sh -c  "echo '#
192.168.4.240   kubem1
192.168.4.241   kubem2
192.168.4.242   kubem3
' >> /etc/hosts"
SCRIPT


$DEFAULTSETTING = <<SCRIPT
sudo -i 
yum install -y wget 

echo "vagrant file centos74需要去掉(远程登陆)"
sed -i 's/^#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sed -i 's/^#UsePAM/UsePAM/g' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin/PermitRootLogin/g'  /etc/ssh/sshd_config
systemctl restart sshd

wget -O centos7-setting.sh https://raw.githubusercontent.com/laik/k8s-script/master/centos7-setting.sh && sh centos7-setting.sh

wget -O docker-ce.sh https://raw.githubusercontent.com/laik/k8s-script/master/docker-ce.sh && sh docker-ce.sh

wget -O kubelet.sh https://raw.githubusercontent.com/laik/k8s-script/master/kubelet-ce.sh && sh kubelet.sh

echo "执行下载镜像脚本"
MY_PASSWORD=W123455
docker login --username=etransk8s --password=${MY_PASSWORD} registry.cn-hangzhou.aliyuncs.com

wget -O k8s-dev.sh https://raw.githubusercontent.com/laik/k8s-script/master/k8s-dev.sh && chmod +x k8s-dev.sh && sh k8s-dev.sh && cd ~

SCRIPT


# Map 配置文件自动创建多台相同的 Centos 主机
Vagrant.configure("2") do |config|
        # KubernetesServer map，将key和value分别赋值给app_server_name和app_server_ip
        KubernetesHosts.each do |app_server_name, app_server_ip|
             #针对每一个app_server_name，来配置config.vm.define配置节点，命名为app_config
             config.vm.define app_server_name do |app_config|
                #公有网络可访问
                config.vm.network "public_network",:bridge => 'em2',ip: app_server_ip
                #私有网络使用 DHCP
                app_config.vm.network :public_network, type: "static"

                app_config.vm.provider :virtualbox do |v|
                        v.customize ["modifyvm",:id,"--name",app_server_name,"--memory","2048","--cpus","2"]
                end
                app_config.vm.box = "centos74"
                app_config.vm.hostname = app_server_name
             end

                # 执行脚本
                config.vm.provision "shell",inline: $IPADDR
                config.vm.provision "shell",inline: $DEFAULTSETTING
                 # 如果需要 nfs
                config.vm.synced_folder "tmp","/vagrant", type: "nfs",nfs: true,linux__nfs_options: ['rw','no_subtree_check','all_squash','async']
        end
end