# 全局配置脚本
```
export KUBEM1_NAME=kubem1
export KUBEM2_NAME=kubem2
export KUBEM3_NAME=kubem3
export KUBEM1_IP=192.168.4.240
export KUBEM2_IP=192.168.4.241
export KUBEM3_IP=192.168.4.242
export CLUSTER_IP=192.168.4.245
export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth1 | grep -Po 'inet \K[\d.]+' | head -1)
echo $KUBEM1_NAME $KUBEM2_NAME $KUBEM3_NAME $KUBEM1_IP $KUBEM2_IP $KUBEM3_IP $CLUSTER_IP $PEER_NAME $PRIVATE_IP
```

# 安装预设 (如果是 Vagrant 提供 Virtual 不需要重复执行)

wget -O centos7-setting.sh https://raw.githubusercontent.com/laik/k8s-script/master/centos7-setting.sh && sh centos7-setting.sh

wget -O docker-ce.sh https://raw.githubusercontent.com/laik/k8s-script/master/docker-ce.sh && sh docker-ce.sh

wget -O kubelet.sh https://raw.githubusercontent.com/laik/k8s-script/master/kubelet.sh && sh kubelet.sh

echo "执行下载镜像脚本"
MY_PASSWORD=SASE!@#!#!RDA
docker login --username=etransk8s --password=${MY_PASSWORD} registry.cn-hangzhou.aliyuncs.com

wget -O k8s-dev.sh https://raw.githubusercontent.com/laik/k8s-script/master/k8s-dev.sh && chmod +x k8s-dev.sh && sh k8s-dev.sh && cd ~



# 配置keepalived 
参考 keepalived.sh

# 配置 ssl(必要配置)

### 如果没有 cfssl,需要下载安装
```
$yum install golang git -y
$export GOPATH=/usr/local
$go get -u github.com/cloudflare/cfssl/cmd/...
$ls /usr/local/bin/cfssl*
cfssl cfssl-bundle cfssl-certinfo cfssljson cfssl-newkey cfssl-scan

或 下载二进制安装
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*
export PATH=$PATH:/usr/local/bin
```

参考 ssl.sh

# ETCD 配置
参考 etcd.sh

# kubeadm 启动
```
cd /etc/kubernetes/
wget https://raw.githubusercontent.com/laik/k8s-script/master/cluster-configure/kubeadm-init-config.sh
sh kubeadm-init-config.sh
kubeadm init --config kubeadm-init-config.yaml
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


# 以下操作只在kubem1操作
# ------------------------------------
# 以下两个网络组件可以选择一个安装,或者两个都安装
需要注意 初始化的网段,每个cni组件支持的网络不一样(我这里使用192.168.0.0/16 - clico 组件支持)
参考: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network

```
## 用 Calico 作为网络传输层
kubectl apply -f https://raw.githubusercontent.com/laik/k8s-script/master/calico.yaml

#heapster
kubectl create -f https://raw.githubusercontent.com/laik/k8s-script/master/cluster-configure/heapster-all.yaml

#dashboard
kubectl create -f https://raw.githubusercontent.com/laik/k8s-script/master/cluster-configure/kubernetes-dashboard.yaml

#获取token,通过令牌登陆
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```



# 初始化 m2 m3,将kubeadm生成证书密码文件分发到 kubem2 和 kubem3 上面去

``` 
scp -r /etc/kubernetes/pki  ${KUBEM2_NAME}:/etc/kubernetes/
scp -r /etc/kubernetes/pki  ${KUBEM3_NAME}:/etc/kubernetes/
```

# kubem2 & kubem3使用同一份配置文件初始化加入集群 Master
```
cd /etc/kubernetes/
wget https://raw.githubusercontent.com/laik/k8s-script/master/cluster-configure/kubeadm-init-config.sh
sh kubeadm-init-config.sh
kubeadm init --config kubeadm-init-config.yaml
```
