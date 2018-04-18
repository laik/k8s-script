

## 常用命令

```Shell
# 删除有复制镜像
docker images | awk '{c=$1":"$2; print c}' | xargs docker rmi
Kubectl 管理

kubectl controls the Kubernetes cluster manager.

Find more information at https://github.com/kubernetes/kubernetes.

Basic Commands (Beginner):
  create         Create a resource from a file or from stdin.
  expose         使用 replication controller, service, deployment 或者 pod 并暴露它作为一个 新的
Kubernetes Service
  run            在集群中运行一个指定的镜像
  set            为 objects 设置一个指定的特征
  run-container  在集群中运行一个指定的镜像. This command is deprecated, use "run" instead

Basic Commands (Intermediate):
  get            显示一个或更多 resources
  explain        查看资源的文档
  edit           在服务器上编辑一个资源
  delete         Delete resources by filenames, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout        Manage the rollout of a resource
  rolling-update 完成指定的 ReplicationController 的滚动升级
  scale          为 Deployment, ReplicaSet, Replication Controller 或者 Job 设置一个新的副本数量
  autoscale      自动调整一个 Deployment, ReplicaSet, 或者 ReplicationController 的副本数量

Cluster Management Commands:
  certificate    修改 certificate 资源.
  cluster-info   显示集群信息
  top            Display Resource (CPU/Memory/Storage) usage.
  cordon         标记 node 为 unschedulable
  uncordon       标记 node 为 schedulable
  drain          Drain node in preparation for maintenance
  taint          更新一个或者多个 node 上的 taints

Troubleshooting and Debugging Commands:
  describe       显示一个指定 resource 或者 group 的 resources 详情
  logs           输出容器在 pod 中的日志
  attach         Attach 到一个运行中的 container
  exec           在一个 container 中执行一个命令
  port-forward   Forward one or more local ports to a pod
  proxy          运行一个 proxy 到 Kubernetes API server
  cp             复制 files 和 directories 到 containers 和从容器中复制 files 和 directories.
  auth           Inspect authorization

Advanced Commands:
  apply          通过文件名或标准输入流(stdin)对资源进行配置
  patch          使用 strategic merge patch 更新一个资源的 field(s)
  replace        通过 filename 或者 stdin替换一个资源
  convert        在不同的 API versions 转换配置文件

Settings Commands:
  label          更新在这个资源上的 labels
  annotate       更新一个资源的注解
  completion     Output shell completion code for the specified shell (bash or zsh)

Other Commands:
  api-versions   Print the supported API versions on the server, in the form of "group/version"
  config         修改 kubeconfig 文件
  help           Help about any command
  plugin         Runs a command-line plugin
  version        输出 client 和 server 的版本信息

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).
			
```


## 配置 hosts 集群ip 信息(双主且都是 Node 测试环境)

| hosts           | ip            | delopy             |
|:----------------|:--------------|:-------------------|
| node1           | 192.168.5.252 | images for docker  |
| node2           | 192.168.5.253 | images for docker  |
| docker-registry | 192.168.5.252 | docker.io/registry |


```Shell
# 配置主机用户名
hostnamectl --static set-hostname  node{N}
```

```Scripts
sudo sh -c  "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.5.252   node1
192.168.5.253   node2' > /etc/hosts"
```



## 一些配置(官方文档上写的 v1.10.1)

```Scripts
echo "关闭Swap"
sudo -i
swapoff -a 
sed 's/.*swap.*/#&/' /etc/fstab

echo "关闭防火墙"
echo 'systemctl disable firewalld && systemctl stop firewalld && systemctl status firewalld' | sudo sh


echo "关闭Selinux"
setenforce  0
echo 'sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config'|sudo sh

getenforce

echo "增加DNS"
echo 'echo nameserver 114.114.114.114
nameserver 1.1.1.1
nameserver 1.0.0.1
>>/etc/resolv.conf' |sudo sh

# 在RHEL/CentOS 7 系统上可能会路由失败
echo 'cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF' | sudo sh

sysctl -p /etc/sysctl.conf

# 阿里 K8s yum 源
echo 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64-unstable
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF' |  sh

yum install -y kubelet kubeadm kubectl docker


# 检查 Docker 存储CgroupDriver 与 Kubelet 的一致性
iscgroupfs=`docker info | grep -i cgroup | grep cgroupfs | wc -l` && if [ 1 -eq $iscgroupfs ]; then \
sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

# kubelet 关闭swap
echo 'Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"' > /etc/systemd/system/kubelet.service.d/90-local-extras.conf


# 需要访问下当前 Kubeadm 安装时会选择什么样的镜像版本
systemctl daemon-reload
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet

```
