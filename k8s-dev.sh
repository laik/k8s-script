#!/bin/bash
# 下载etrans 的 K8s 镜像
set -o errexit
set -o nounset
set -o pipefail


KUBE_VERSION=v1.10.1
KUBE_PAUSE_VERSION=3.1
ETCD_VERSION=3.1.12
DNS_VERSION=1.14.8
DASHBOARD_VERSION=v1.8.3
ADDON_VERSION=v8.6
FLANNEL_VERSION=v0.9.1-amd64
HEAPSTER_VERSION=v1.4.2


GCR_URL=k8s.gcr.io
REGISTRY=registry.cn-hangzhou.aliyuncs.com
ALIYUN_URL=${REGISTRY}/etrans
COREOS_URL=quay.io/coreos
CALICO_URL=quay.io/calico



images=(
kube-proxy-amd64:${KUBE_VERSION}
kube-scheduler-amd64:${KUBE_VERSION}
kube-controller-manager-amd64:${KUBE_VERSION}
kube-apiserver-amd64:${KUBE_VERSION}
pause-amd64:${KUBE_PAUSE_VERSION}
etcd-amd64:${ETCD_VERSION}
k8s-dns-sidecar-amd64:${DNS_VERSION}
k8s-dns-kube-dns-amd64:${DNS_VERSION}
k8s-dns-dnsmasq-nanny-amd64:${DNS_VERSION}
kubernetes-dashboard-amd64:${DASHBOARD_VERSION}
kube-addon-manager:${ADDON_VERSION}
heapster-amd64:${HEAPSTER_VERSION}
heapster-influxdb-amd64:v1.3.3
heapster-grafana-amd64:v4.4.3
)

coreos_images=(
flannel:${FLANNEL_VERSION}
etcd:v3.1.10
)


calico_images=(
node:v3.1.1
kube-controllers:v2.0.4
cni:v3.1.1
)


CEPH_URL=gcr.io/kubernetes-helm
ceph_images=(
tiller:v2.9.0
)

RDB_URL=quay.io/external_storage
rbd_provisioner=(
rbd-provisioner:v0.1.1
)

#docker login --username=${USERNAME} --password=${PASSWORD} ${REGISTRY}

for imageName in ${images[@]} ; do
  docker pull $ALIYUN_URL/$imageName
  docker tag $ALIYUN_URL/$imageName $GCR_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done


for imageName in ${coreos_images[@]} ; do
  docker pull $ALIYUN_URL/$imageName
  docker tag $ALIYUN_URL/$imageName $COREOS_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done

for imageName in ${calico_images[@]} ; do
  docker pull $ALIYUN_URL/$imageName
  docker tag $ALIYUN_URL/$imageName $CALICO_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done


for imageName in ${ceph_images[@]} ; do
  docker pull $ALIYUN_URL/$imageName
  docker tag $ALIYUN_URL/$imageName $CEPH_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done


for imageName in ${rbd_provisioner[@]} ; do
  docker pull $ALIYUN_URL/$imageName
  docker tag $ALIYUN_URL/$imageName $RDB_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done
