# k8s-script

## 配置 hosts 集群ip 信息(双主且都是 Node 测试环境)

* 创建版本 - v20180418
* 当前 K8s 版本 v1.10.1

#### Vagrant vm 机器列表
| hosts           | ip            | delopy             |
|:----------------|:--------------|:-------------------|
| node1           | 192.168.33.10 | images for docker  |
| node2           | 192.168.33.11 | images for docker  |
| node3           | 192.168.33.12 | images for docker  |


## Vagrant+Virtualbox

[√] 下载 Vagrantfile
> curl https://raw.githubusercontent.com/laik/k8s-script/master/vagrantfile-tempory.rb > Vagrantfile 

[√] 开始下载准备好的镜像(`tmp/k8s-dev.sh`需要修改里面的用户密码[自己去阿里云搞个用户])
> mkdir tmp &&
> curl https://raw.githubusercontent.com/laik/k8s-script/master/k8s-dev.sh > tmp/k8s-dev.sh

[√] 启动 Vagrant 
> vagrant up

[√] 初始化kubernetes

> 获取 发行稳定版本  https://storage.googleapis.com/kubernetes-release/release/stable-1.10.txt 
 初始化时如果国内环境需要定义版本,不然会访问不了 google 地址,需要合理上网才能够访问
 第一次初始化失败已经存在配置文件,需要加 `--ignore-preflight-errors=all`(参数跟飞机起飞一样屌)


> KUBEVERSION=`curl https://storage.googleapis.com/kubernetes-release/release/stable-1.10.txt`

---

> kubeadm init --kubernetes-version=${KUBEVERSION} --pod-network-cidr=10.244.0.0/16

# 对于非root用户
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 对于root用户
$ export KUBECONFIG=/etc/kubernetes/admin.conf
# 也可以直接放到~/.bash_profile
$ echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc

# 默认情况下，为了保证master的安全，master是不会被调度到app的。你可以取消这个限制通过输入(单机测试)：
> kubectl taint nodes --all node-role.kubernetes.io/master-

```
接下来要注意，我们必须自己来安装一个network addon。network addon必须在任何app部署之前安装好。同样的，kube-dns也会在network addon安装好之后才启动 kubeadm只支持CNI-based networks（不支持kubenet）。比较常见的network addon有：Calico, Canal, Flannel, Kube-router, Romana, Weave Net等。这里我们使用Calico。

用 Calico 作为网络传输层
>  kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
```

[√] 清除当前集群信息
```
   kubeadm reset
```

Enjoy it!!

[√] FQA
   > 1. cni 问题 Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
    >> 删除/etc/systemd/system/kubelet.service.d/10-kubeadm.conf中的$ KUBELET_NETWORK_ARGS systemctl启用kubelet && systemctl启动kubelet

---


## 常用命令

```Shell
kubectl get po -o wide --all-namespaces
```

```
  kubeadm join 10.0.2.15:6443 --token 6y08dg.q977edbxcjepnq68 --discovery-token-ca-cert-hash sha256:003ade97af781e60aba97817f0330f512a531336e604950b694ebfa3fcd0b6cd
```