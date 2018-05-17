export KUBEM1_NAME=k0         
export KUBEM2_NAME=k1         
export KUBEM3_NAME=k2         
export KUBEM4_NAME=k3         
export KUBEM5_NAME=k4         
export KUBEM6_NAME=k5         
export KUBEM1_IP=192.168.4.110
export KUBEM2_IP=192.168.4.111
export KUBEM3_IP=192.168.4.112
export KUBEM4_IP=192.168.4.113
export KUBEM5_IP=192.168.4.114
export KUBEM6_IP=192.168.4.115
export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth1 | grep -Po 'inet \K[\d.]+' | head -1)

# kube v1.10.1 安装etcd 3.1.12
yum install etcd -y


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
  --initial-cluster ${KUBEM1_NAME}=https://${KUBEM1_IP}:2380,${KUBEM2_NAME}=https://${KUBEM2_IP}:2380,${KUBEM3_NAME}=https://${KUBEM3_IP}:2380,${KUBEM4_NAME}=https://${KUBEM4_IP}:2380,${KUBEM5_NAME}=https://${KUBEM5_IP}:2380,${KUBEM6_NAME}=https://${KUBEM6_IP}:2380 \
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

# 启动后 check
etcdctl --cert-file=/etc/kubernetes/pki/etcd/etcd.pem  --key-file=/etc/kubernetes/pki/etcd/etcd-key.pem --ca-file=/etc/kubernetes/pki/etcd/ca.pem --endpoints=https://${KUBEM1_IP}:2379,https://${KUBEM2_IP}:2379,https://${KUBEM3_IP}:2379,https://${KUBEM4_IP}:2379,https://${KUBEM5_IP}:2379,,https://${KUBEM6_IP}:2379 cluster-health