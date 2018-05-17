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


kubeadm init --config=config.yaml