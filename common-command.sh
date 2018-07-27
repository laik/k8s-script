
## 常用命令

# Shell

kubectl get po -o wide --all-namespaces

# 查看 Master join Token
kubeadm token create --print-join-command

# 获取token,通过令牌登陆dashboard
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# 查看 Docker log
cat > /usr/bin/inspect <<EOF
docker inspect \$(docker ps -a | grep \$1 | awk '{print \$1}' |head -1)
EOF
chmod +x /usr/bin/inspect


# pv转换属性
kubectl patch pv pvc-210e2481-62ec-11e8-881e-5254005f9478 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'


# 清空 etcd
清空etcd给大家分享一下：kubeadm reset之后，并不会清除etcd里的内容，要清除，需要手工执行
$etcdctl del "" --prefix
命令，但默认etcdctl的API是v2的，无法执行，需要导出环境变量 export ETCDCTL_API=3，然后再执行 etcdctl  del "" —prefix即可成功


# log
kubectl logs --namespace=kube-system $(kubectl get pods --namespace=kube-system -l k8s-app=kube-dns -o name) -c kubedns


# 默认情况下，为了保证master的安全，master是不会被调度到app的。你可以取消这个限制通过输入：
kubectl taint nodes --all node-role.kubernetes.io/master-


# 标记机器
kubectl label node kubenode1 zone=developer