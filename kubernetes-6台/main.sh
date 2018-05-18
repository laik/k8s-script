# 安装时遇到了一系列无法解析的问题;

# docker-ce-18.05.0.ce-3.el7.centos.x86_64 有问题,导致kubeadm 启动的时候出现目录不能mount问题
# 以前测试用 docker-ce-18.03.0.ce-3.el7.centos.x86_64 没有问题

# 现用 docker版本,1.13.1测试安装
# Version:         1.13.1
# API version:     1.26

# 全局配置脚本
```

export KUBEM1_NAME=k0
export KUBEM2_NAME=k1
export KUBEM3_NAME=k2
export KUBEM4_NAME=k3
export KUBEM5_NAME=k4
export KUBEM6_NAME=k5
export KUBEM1_IP=192.168.4.110
export KUBEM2_IP=192.168.4.111
export KUBEM3_IP=192.168.4.112
export KUBEM4_IP=192.168.4.113
export KUBEM5_IP=192.168.4.114
export KUBEM6_IP=192.168.4.115
export CLUSTER_IP=192.168.4.100
export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth1 | grep -Po 'inet \K[\d.]+' | head -1)
echo $KUBEM1_NAME $KUBEM2_NAME $KUBEM3_NAME $KUBEM1_IP $KUBEM2_IP $KUBEM3_IP $CLUSTER_IP $PEER_NAME $PRIVATE_IP


```

echo "kubeadm 与 需要安装的版本最好一致"
echo "当前是v1.10.1 kubeadm-1.10.1-0.x86_64"
echo "安装 kube"
yum remove kubelet kubeadm kubectl -y
yum install -y kubelet-1.10.1-0.x86_64 kubeadm-1.10.1-0.x86_64 kubectl-1.10.1-0.x86_64

# 配置keepalived 
参考 keepalived.sh

# 配置 ssl
参考 ssl.sh

# ETCD 配置
参考 etcd.sh

# kubeadm 启动


```
kubeadm init --config config.yaml

```

# 如果使用了kubeadm reset 需要将证书重新拷贝过去
```
# cd /root/ssl && mkdir -p /etc/kubernetes/pki/etcd/ && cp etcd.pem etcd-key.pem ca.pem  /etc/kubernetes/pki/etcd/
```

# 对于root用户 直接放到~/.bash_bashrc
```
export KUBECONFIG=/etc/kubernetes/admin.conf && echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
```

# 默认情况下，为了保证master的安全，master是不会被调度到app的。你可以取消这个限制通过输入：
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```


# 将kubeadm生成证书密码文件分发到 kubem2 和 kubem3 上面去
``` 


scp -r /etc/kubernetes/pki  k1:/etc/kubernetes/
scp -r /etc/kubernetes/pki  k2:/etc/kubernetes/
scp -r /etc/kubernetes/pki  k3:/etc/kubernetes/
scp -r /etc/kubernetes/pki  k4:/etc/kubernetes/
scp -r /etc/kubernetes/pki  k5:/etc/kubernetes/
```

# 以下操作只在kubem1操作
# ------------------------------------
# 以下两个网络组件可以选择一个安装,或者两个都安装

## 用 weave net 安装方法
```
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
systemctl restart docker && systemctl restart kubelet

## 用 Calico 作为网络传输层
kubectl apply -f https://raw.githubusercontent.com/laik/k8s-script/master/calico.yaml
systemctl restart docker && systemctl restart kubelet

#dashboard
kubectl create -f kube-dashboard.yaml

#获取token,通过令牌登陆
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

#heapster 安装
kubectl create -f heapster-all.yaml

#.... 安装插件....等等..... 

#初始化 m2 m3
```