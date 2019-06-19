# k8s-script

## 配置 hosts 集群ip 信息(双主且都是 Node 测试环境)

* 创建版本 - v20180418
* 当前 K8s 版本 v1.10.1

#### Vagrant vm 机器列表(如果真实机器也是如此)
| hosts      | ip            | deploy       |
|:-----------|:--------------|:-------------|
| kubem1     | 192.168.4.240 | master       |
| kubem2     | 192.168.4.241 | node         |
| kubem3     | 192.168.4.242 | node         |
| virtual ip | 192.168.4.245 | virtual ware |


## 虚拟机测试环境用户 Vagrant+Virtualbox
[√] 下载 Vagrantfile
> curl https://raw.githubusercontent.com/laik/k8s-script/master/Vagrantfile > Vagrantfile 

[√] 创建个 tmp 目录共享
> mkdir tmp 

[√] 启动 Vagrant 
> vagrant up


## 生产环境用户

[√] 配置 IP 地址 及下载相关设定
```
sudo sh -c  "echo '#
192.168.4.240   kubem1
192.168.4.241   kubem2
192.168.4.242   kubem3
' >> /etc/hosts"

yum install -y wget 

wget -O centos7-setting.sh https://raw.githubusercontent.com/laik/k8s-script/master/centos7-setting.sh && sh centos7-setting.sh

wget -O docker-ce.sh https://raw.githubusercontent.com/laik/k8s-script/master/docker-ce.sh && sh docker-ce.sh

wget -O kubelet.sh https://raw.githubusercontent.com/laik/k8s-script/master/kubelet.sh && sh kubelet.sh

echo "执行下载镜像脚本"
MY_PASSWORD=SASE!@#!#!RDA
docker login --username=etransk8s --password=${MY_PASSWORD} registry.cn-hangzhou.aliyuncs.com

wget -O k8s-dev.sh https://raw.githubusercontent.com/laik/k8s-script/master/k8s-dev.sh && chmod +x k8s-dev.sh && sh k8s-dev.sh && cd ~



```

## 初始化Kubernetes

[√] 需要手工初始化kubernetes
第一次初始化失败已经存在配置文件,需要加 `--ignore-preflight-errors=all`(参数跟飞机起飞)

```Shell
# 下载镜像
echo "下载 github 下的脚本k8s-dev.sh 下载v1.10.1 所需在镜像文件 需要 docker login 阿里云 Registry 当然,我的密码肯定不是123456啦"
docker login --username=etransk8s --password=123456 registry.cn-hangzhou.aliyuncs.com
wget -O k8s-dev.sh https://raw.githubusercontent.com/laik/k8s-script/master/k8s-dev.sh && chmod +x k8s-dev.sh && sh k8s-dev.sh && cd ~

# centos7.4 kube-v1.10.1 cni 问题 Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
# discard
# sed -i 's/.*cni.*/#&/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf


# 初始化获取当前版本(下面已经指定版本了)
curl https://storage.googleapis.com/kubernetes-release/release/stable-1.10.txt

# 我们使用v1.10.1
kubeadm init --apiserver-advertise-address=192.168.4.240 --kubernetes-version=v1.10.1 --pod-network-cidr=10.244.0.0/16

# 对于非root用户
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 对于root用户 直接放到~/.bash_bashrc
export KUBECONFIG=/etc/kubernetes/admin.conf && echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc

# 默认情况下，为了保证master的安全，master是不会被调度到app的。你可以取消这个限制通过输入：
> kubectl taint nodes --all node-role.kubernetes.io/master-

# addons 
接下来要注意，我们必须自己来安装一个network addon。network addon必须在任何app部署之前安装好。同样的，kube-dns也会在network addon安装好之后才启动 kubeadm只支持CNI-based networks（不支持kubenet）。比较常见的network addon有：Calico, Canal, Flannel, Kube-router, Romana, Weave Net等。这里我们使用Calico。

# 以下两个网络组件可以选择一个安装
## 用 weave net 安装方法
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
systemctl restart docker && systemctl restart kubelet

## 用 Calico 作为网络传输层
kubectl apply -f https://raw.githubusercontent.com/laik/k8s-script/master/calico.yaml
systemctl restart docker && systemctl restart kubelet

# dashboard
kubectl create -f https://raw.githubusercontent.com/laik/k8s-script/master/cluster-configure/kubernetes-dashboard.yaml
kubectl proxy

# heapster 安装(需要改成集群信息配置[暂时不安装])
kubectl apply -f https://raw.githubusercontent.com/laik/k8s-script/master/heapster-controller-standalone.yaml

# dashboard access配置 并修改服务使用 NodePort 访问
kubectl -n kube-system edit service kubernetes-dashboard
type: ClusterIP
改成
type: NodePort

下载 Access 访问权限配置
kubectl apply -f https://raw.githubusercontent.com/laik/k8s-script/master/kube-dashboard-access.yaml

然后就可以以主机 ip:端口的方式访问啦!


# 获取token,通过令牌登陆
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')


Done!!! 


---
基于上面配置 LVS+Keepalived (Kube-HA)

```


[√] 清除当前集群信息

```
kubeadm reset
```

Enjoy it!!

配置完成后信息:
```
[root@node4 ~]# kubectl get po -o wide --all-namespaces

NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE       IP              NODE
kube-system   etcd-node4                              1/1       Running   1          8m        192.168.33.40   node4
kube-system   kube-apiserver-node4                    1/1       Running   1          8m        192.168.33.40   node4
kube-system   kube-controller-manager-node4           1/1       Running   1          8m        192.168.33.40   node4
kube-system   kube-dns-86f4d74b45-kghhf               3/3       Running   0          10m       10.32.0.2       node4
kube-system   kube-proxy-4m7q6                        1/1       Running   1          10m       192.168.33.40   node4
kube-system   kube-scheduler-node4                    1/1       Running   1          8m        192.168.33.40   node4
kube-system   kubernetes-dashboard-7d5dcdb6d9-9gsxs   1/1       Running   0          6m        10.32.0.3       node4
kube-system   weave-net-6575v                         2/2       Running   0          9m        192.168.33.40   node4
[root@node4 ~]# 
[root@node4 ~]# 
[root@node4 ~]# 
[root@node4 ~]# 
[root@node4 ~]# kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   10m
[root@node4 ~]# kubectl get svc --all-namespaces
NAMESPACE     NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
default       kubernetes             ClusterIP   10.96.0.1      <none>        443/TCP         11m
kube-system   kube-dns               ClusterIP   10.96.0.10     <none>        53/UDP,53/TCP   11m
kube-system   kubernetes-dashboard   NodePort    10.102.52.30   <none>        443:32093/TCP   7m

```
