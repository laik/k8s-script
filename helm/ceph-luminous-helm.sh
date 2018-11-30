#可参考https://jimmysong.io/kubernetes-handbook/practice/ceph-helm-install-guide-zh.html
helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.9.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

cat > ~/ceph-overrides.yaml
network:
  public: 10.10.0.0/24
  cluster: 110.10.0.0/24

osd_devices:
  - name: disk1
    device: /docker/ceph
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


#测试时使用模拟磁盘

mkdir /ceph-disk

dd if=/dev/zero of=/ceph-disk/ceph.img bs=4M count=10240 oflag=direct

parted -s /ceph-disk/ceph.img  mklabel gpt

vgcreate ceph-volumes $(losetup --show -f /ceph-disk/ceph.img)

lvcreate -L2G -nceph0 ceph-volumes

lvcreate -L2G -nceph1 ceph-volumes

mkfs.xfs -f /dev/ceph-disk/ceph0

mkfs.xfs -f /dev/ceph-disk/ceph1

mkdir -p /srv/ceph/{osd0,osd1,mon0,mds0}

mount /dev/ceph-disk/ceph0 /srv/ceph/osd0

mount /dev/ceph-disk/ceph1 /srv/ceph/osd1



#安装 K8s 的节点中需要
yum install -y ceph-common

helm init

helm serve &
helm repo add local http://localhost:8879/charts

git clone https://github.com/ceph/ceph-helm
cd ceph-helm/ceph
make


# MGR启动不了,清除机器上的目录,重新初始化一定要清干净.
# 在第一次清除 PurgeData 之后,发生admin_socket: exception getting command descriptions: [Errno 2] No such file or directory
# 清除
helm del ceph --purge
# 删除 RBAC
kubectl delete -f ~/ceph-helm/ceph/rbac.yaml

# 每个节点执行
rm -rf /etc/ceph/*
rm -rf /var/lib/ceph/*
rm -rf /var/log/ceph/*
rm -rf /var/run/ceph/*
rm -rf /var/lib/ceph-helm/*



kubectl create namespace ceph

kubectl create -f ~/ceph-helm/ceph/rbac.yaml





cat <<EOF >~/ceph-overrides.yaml
network:
  public: 192.168.4.0/24
  cluster: 172.16.171.0/24

osd_devices:
  - name: loop
    device: /dev/loop0
    zap: "1" 

storageclass:
  name: ceph-rbd
  pool: rbd
  user_id: k8s
  user_secret_name: pvc-ceph-client-key
  image_format: "2"
  image_features: layering
EOF

# kubectl label nodes ceph-osd=enabled --all

kubectl label node master1 ceph-mon=enabled ceph-mgr=enabled --overwrite
kubectl label node master2 ceph-mon=enabled ceph-mgr=enabled --overwrite

kubectl label node master1 ceph-osd=enabled ceph-osd-device-dev-loop=enabled --overwrite
kubectl label node master2 ceph-osd=enabled ceph-osd-device-dev-loop=enabled --overwrite

# 不用执行以下
kubectl label node master1 ceph-rgw=enabled
kubectl label node master2 ceph-rgw=enabled
kubectl label node master1 ceph-mds=enabled
kubectl label node master2 ceph-mds=enabled


kubectl label node master1 ceph-rgw=disable --overwrite
kubectl label node master2 ceph-rgw=disable --overwrite
kubectl label node master1 ceph-mds=disable --overwrite
kubectl label node master2 ceph-mds=disable --overwrite



helm install --name=ceph local/ceph --namespace=ceph -f ~/ceph-overrides.yaml
#不需要用文件系统
kubectl delete deploy ceph-mds -n ceph
kubectl delete deploy ceph-rgw -n ceph
kubectl delete svc cepg-rgw -n ceph


kubectl -n ceph get pods
kubectl -n ceph exec -ti ceph-mon-gs8qs -c ceph-mon -- ceph -s
kubectl -n ceph exec -ti ceph-mon-9br5b -c ceph-mon -- bash
ceph auth list 
ceph auth get-or-create-key client.k8s mon 'allow r' osd 'allow rwx pool=rbd' 