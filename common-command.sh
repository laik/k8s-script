
## 常用命令

```Shell
kubectl get po -o wide --all-namespaces

# 查看 Master join Token
kubeadm token create --print-join-command

# 获取token,通过令牌登陆dashboard
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# 查看 Docker log
docker inspect $(docker ps -a | grep dashboard | awk '{print $1}' |head -1) | grep logpath
```

```
kubeadm join ${ipaddr}:${proxy} --token 6y08dg.q977edbxcjepnq68 --discovery-token-ca-cert-hash sha256:003ade97af781e60aba97817f0330f512a531336e604950b694ebfa3fcd0b6cd
```