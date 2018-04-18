# k8s-script




## 配置 hosts 集群ip 信息(双主且都是 Node 测试环境)

| hosts           | ip            | delopy             |
|:----------------|:--------------|:-------------------|
| node1           | 192.168.33.10 | images for docker  |
| node2           | 192.168.33.11 | images for docker  |
| node3           | 192.168.33.12 | images for docker  |



## Vagrant+Virtualbox

[√] 下载 Vagrantfile
> curl https://raw.githubusercontent.com/laik/k8s-script/master/vagrantfile-tempory.rb > Vagrantfile 

[√] 开始下载准备好的镜像(`tmp/k8s-dev.sh`需要修改里面的用户密码[自己去阿里云搞个用户])
> mkdir tmp
> curl https://raw.githubusercontent.com/laik/k8s-script/master/k8s-dev.sh > tmp/k8s-dev.sh

[√] 启动 Vagrant 
> vagrant up

Enjoy it!!