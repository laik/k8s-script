#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [ "$#" -ne 2 ]; then
        echo "本工具只适合在天朝之外的主机使用; 你需要传入 username,password"
        exit
fi

if [ -n "$1" ]; then
        USERNAME="$1"
        PASSWORD="$2"
fi


KUBE_VERSION=v1.10.1
KUBE_PAUSE_VERSION=3.1
ETCD_VERSION=3.1.12
DNS_VERSION=1.14.8
DASHBOARD_VERSION=v1.8.3
ADDON_VERSION=v8.6
FLANNEL_VERSION=v0.9.1-amd64
HEAPSTER_VERSION=v1.4.2


GCR_URL=k8s.gcr.io
ALIYUN_URL=registry.cn-hangzhou.aliyuncs.com/etrans
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
)

coreos_images=(
flannel:${FLANNEL_VERSION}
etcd:v3.1.10
)

calico_images=(
node:v3.0.5
kube-controllers:v2.0.3
)

docker login --username=${USERNAME} --password=${PASSWORD} registry.cn-hangzhou.aliyuncs.com

for imageName in ${images[@]} ; do
  docker pull $GCR_URL/$imageName
  docker tag $GCR_URL/$imageName $ALIYUN_URL/$imageName
  docker push $ALIYUN_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done

for imageName in ${coreos_images[@]} ; do
  docker pull $COREOS_URL/$imageName
  docker tag $COREOS_URL/$imageName $ALIYUN_URL/$imageName
  docker push $ALIYUN_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done

for imageName in ${calico_images[@]} ; do
  docker pull $CALICO_URL/$imageName
  docker tag $CALICO_URL/$imageName $ALIYUN_URL/$imageName
  docker push $ALIYUN_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done