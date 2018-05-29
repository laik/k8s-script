helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.9.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default


network:
  public: 192.168.99.0/24
  cluster: 192.168.99.0/24

osd_devices:
  - name: disk1
    device: /disk/d1
    zap: "1"
  - name: disk2
    device: /disk/d2
    zap: "1"

storageclass:
  name: ceph-rbd
  pool: rbd
  user_id: k8s
  
  
# depending images
docker pull docker.io/kolla/ubuntu-source-heat-engine:3.0.3
docker pull docker.io/kolla/ubuntu-source-heat-engine:3.0.3
docker pull docker.io/kolla/ubuntu-source-heat-engine:3.0.3
docker pull docker.io/ceph/daemon:tag-build-master-luminous-ubuntu-16.04
docker pull docker.io/kolla/ubuntu-source-kubernetes-entrypoint:4.0.0
docker pull docker.io/ceph/daemon:tag-build-master-luminous-ubuntu-16.04
docker pull docker.io/port/ceph-config-helper:v1.7.5
docker pull quay.io/external_storage/rbd-provisioner:v0.1.1
docker pull docker.io/alpine:latest

# 常用命令
$helm list
$helm delete 
$helm search local/ceph


$helm reset   或 $helm reset -f(强制删除k8s集群上tiller的pod.)


问题:Cannot initialize Kubernetes connection: Get http://localhost:8080/api: dial tcp [::1]:8080: getsockopt: connection refused

@mattus Thanks a lot, i was stuck for ~ 3 days with this at work trying to deploy a k8s cluster. This should really be documented somewhere.
What i did to solve the issue was:

kubectl --namespace=kube-system edit deployment/tiller-deploy and changed automountServiceAccountToken to true.
Then 'helm list' was giving me:
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
That was fixed with solution from #2687:
kubectl --namespace=kube-system create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default