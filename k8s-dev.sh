#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

USERNAME=asan
PASSWORD=!@#@!DSADSA

KUBE_VERSION=v1.10.1
KUBE_PAUSE_VERSION=3.1
ETCD_VERSION=3.1.12
DNS_VERSION=1.14.4
DASHBOARD_VERSION=v1.8.3
ADDON_VERSION=v8.6

GCR_URL=k8s.gcr.io
REGISTRY=registry.cn-hangzhou.aliyuncs.com
ALIYUN_URL=${REGISTRY}/etrans

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
)

docker login --username=${USERNAME} --password=${PASSWORD} ${REGISTRY}

for imageName in ${images[@]} ; do
  docker pull $ALIYUN_URL/$imageName
  docker tag $ALIYUN_URL/$imageName $GCR_URL/$imageName
  docker rmi $ALIYUN_URL/$imageName
done