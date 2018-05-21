export KUBEM1_NAME=k0
export KUBEM2_NAME=k1
export KUBEM3_NAME=k2
export KUBEM4_NAME=k3
export KUBEM5_NAME=k4
export KUBEM6_NAME=k5    
export KUBEM1_IP=172.16.171.10
export KUBEM2_IP=172.16.171.11
export KUBEM3_IP=172.16.171.12
export KUBEM4_IP=172.16.171.13
export KUBEM5_IP=172.16.171.14
export KUBEM6_IP=172.16.171.15
export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth2 | grep -Po 'inet \K[\d.]+' | head -1)

# 写配置文件
cd /etc/kubernetes/

cat <<EOF > config.yaml 
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
etcd:
  endpoints:
  - https://${KUBEM1_IP}:2379
  - https://${KUBEM2_IP}:2379
  - https://${KUBEM3_IP}:2379
  - https://${KUBEM4_IP}:2379
  - https://${KUBEM5_IP}:2379
  - https://${KUBEM6_IP}:2379
  caFile: /etc/kubernetes/pki/etcd/ca.pem
  certFile: /etc/kubernetes/pki/etcd/etcd.pem
  keyFile: /etc/kubernetes/pki/etcd/etcd-key.pem
  dataDir: /var/lib/etcd
networking:
  podSubnet: 10.244.0.0/16
kubernetesVersion: 1.10.1
api:
  advertiseAddress: "${PRIVATE_IP}"
apiServerCertSANs:
- ${KUBEM1_NAME}
- ${KUBEM2_NAME}
- ${KUBEM3_NAME}
- ${KUBEM4_NAME}
- ${KUBEM5_NAME}
- ${KUBEM6_NAME}
- ${KUBEM1_IP}
- ${KUBEM2_IP}
- ${KUBEM3_IP}
- ${KUBEM4_IP}
- ${KUBEM5_IP}
- ${KUBEM6_IP}
featureGates:
  CoreDNS: true
EOF


kubeadm init --config config.yaml