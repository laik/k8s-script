# kube v1.10.1 安装etcd 3.1.12
yum install etcd-3.2.15-1.el7.x86_64 -y


# service 
ETCD_BINARY=`which etcd`
cat <<EOF >/etc/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=${ETCD_BINARY} \
  --name ${PEER_NAME} \
  --cert-file=/etc/kubernetes/pki/etcd/etcd.pem \
  --key-file=/etc/kubernetes/pki/etcd/etcd-key.pem \
  --peer-cert-file=/etc/kubernetes/pki/etcd/etcd.pem \
  --peer-key-file=/etc/kubernetes/pki/etcd/etcd-key.pem \
  --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
  --initial-advertise-peer-urls https://${PRIVATE_IP}:2380 \
  --listen-peer-urls https://${PRIVATE_IP}:2380 \
  --listen-client-urls https://${PRIVATE_IP}:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://${PRIVATE_IP}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster ${KUBEM1_NAME}=https://${KUBEM1_IP}:2380,${KUBEM2_NAME}=https://${KUBEM2_IP}:2380,${KUBEM3_NAME}=https://${KUBEM3_IP}:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF


# etcd 至少需要2个节点才能启动
systemctl daemon-reload
systemctl start etcd
systemctl enable etcd

# 启动后 check (旧版本)3.2.15以前
etcdctl --cert-file=/etc/kubernetes/pki/etcd/etcd.pem  --key-file=/etc/kubernetes/pki/etcd/etcd-key.pem --ca-file=/etc/kubernetes/pki/etcd/ca.pem --endpoints=https://${KUBEM1_IP}:2379,https://${KUBEM2_IP}:2379,https:/${KUBEM3_IP}:2379 cluster-health

# or 声明了ectdctl api =3 需要清除才能用kubeadm init 不然会有一系列想像不到的后果
export ETCDCTL_API=3
etcdctl --cert=/etc/kubernetes/pki/etcd/etcd.pem  --key=/etc/kubernetes/pki/etcd/etcd-key.pem --cacert=/etc/kubernetes/pki/etcd/ca.pem --endpoints=[${KUBEM1_IP}:2379,${KUBEM2_IP}:2379,${KUBEM3_IP}:2379] member list
