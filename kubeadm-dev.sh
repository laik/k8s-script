# 需要检查 docker
# https://kubernetes.io/docs/setup/independent/install-kubeadm/

docker info | grep -i cgroup

cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf



// 获取 发行稳定版本  https://storage.googleapis.com/kubernetes-release/release/stable-1.10.txt 
// 初始化时如果国内环境需要定义版本,不然会访问不了 google 地址,需要合理上网才能够访问
// 第一次初始化失败已经存在配置文件,需要加 `--ignore-preflight-errors=all`(参数跟飞机起飞一样屌)

kubeadm init --kubernetes-version=v1.10.1 --ignore-preflight-errors=all