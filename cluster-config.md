### 集群配置

* cluster host inventory

| hosts      | ip            | delopy     | proxy            |
|:-----------|:--------------|:-----------|:-----------------|
| kubem1     | 192.168.4.240 | host or vm | keepalived + lvs |
| kubem2     | 192.168.4.241 | host or vm |                  |
| kubem3     | 192.168.4.242 | host or vm |                  |
| virtual ip | 192.168.4.245 | host or vm |                  |


* 配置 Keepalived (lvs)
参考: keepalived-config.sh


* 配置 kubem1 ssh-key
ssh-keygen  #一路回车即可
ssh-copy-id  kubem2
ssh-copy-id  kubem3


* 配置 cfssl 环境
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*


* 创建 CA 配置文件（下面配置的IP为etc节点的IP）

> SSH into etcd0 and run the following:

```Shell
mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd
```

```
cat >ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

cat >ca-csr.json <<EOF
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    }
}
EOF

cat >client.json <<EOF
{
    "CN": "client",
    "hosts": [
        "127.0.0.1",
        "192.168.4.240",
        "192.168.4.241",
        "192.168.4.242"
      ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOF

```

> Next, generate the CA certs && Etcd Client certs like so:

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client
```

> kubem1 分发etcd证书到kubem2、kubem3

```
#在kubem2 kubem3创建
mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd
```

```
#在 kubem1上执行

kubes=(kubem2 kubem3)
for kubenode in ${kubes[@]} ; do
scp * ${kubenode}:/etc/kubernetes/pki/etcd/ 
done
```


* 每个节点安装 etcd

```

#取本地名(注意PRIVATE_IP 的网卡名eth1)

export PEER_NAME=$(hostname)
export PRIVATE_IP=$(ip addr show eth1 | grep -Po 'inet \K[\d.]+' | head -1)
echo $PEER_NAME
echo $PRIVATE_IP

```

```
export ETCD_VERSION=v3.1.12
curl -sSL https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/
rm -rf etcd-$ETCD_VERSION-linux-amd64*

```

```
touch /etc/etcd.env
echo "PEER_NAME=$PEER_NAME" >> /etc/etcd.env
echo "PRIVATE_IP=$PRIVATE_IP" >> /etc/etcd.env


cat >/etc/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
EnvironmentFile=/etc/etcd.env
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/local/bin/etcd --name ${PEER_NAME} \
    --data-dir /var/lib/etcd \
    --listen-client-urls https://${PRIVATE_IP}:2379 \
    --advertise-client-urls https://${PRIVATE_IP}:2379 \
    --listen-peer-urls https://${PRIVATE_IP}:2380 \
    --initial-advertise-peer-urls https://${PRIVATE_IP}:2380 \
    --cert-file=/etc/kubernetes/pki/etcd/server.pem \
    --key-file=/etc/kubernetes/pki/etcd/server-key.pem \
    --client-cert-auth \
    --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
    --peer-cert-file=/etc/kubernetes/pki/etcd/peer.pem \
    --peer-key-file=/etc/kubernetes/pki/etcd/peer-key.pem \
    --peer-client-cert-auth \
    --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.pem \
    --initial-cluster kubem1=https://192.168.4.240:2380,kubem2=https://192.168.4.241:2380,kubem3=https://192.168.4.242:2380 \
    --initial-cluster-token my-etcd-token \
    --initial-cluster-state new

[Install]
WantedBy=multi-user.target
EOF

```

* 配置 Etcd (这里使用 Static Pods)方式(3个master 节点都需要)
```

cat >/etc/kubernetes/manifests/etcd.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
labels:
    component: etcd
    tier: control-plane
name: etcd-${PEER_NAME}
namespace: kube-system
spec:
containers:
- command:
    - etcd --name ${PEER_NAME} \
    - --data-dir /var/lib/etcd \
    - --listen-client-urls https://${PRIVATE_IP}:2379 \
    - --advertise-client-urls https://${PRIVATE_IP}:2379 \
    - --listen-peer-urls https://${PRIVATE_IP}:2380 \
    - --initial-advertise-peer-urls https://${PRIVATE_IP}:2380 \
    - --cert-file=/certs/server.pem \
    - --key-file=/certs/server-key.pem \
    - --client-cert-auth \
    - --trusted-ca-file=/certs/ca.pem \
    - --peer-cert-file=/certs/peer.pem \
    - --peer-key-file=/certs/peer-key.pem \
    - --peer-client-cert-auth \
    - --peer-trusted-ca-file=/certs/ca.pem \
    - --initial-cluster etcd0=https://kubem1:2380,etcd1=https://kubem2:2380,etcd2=https://kubem3:2380 \
    - --initial-cluster-token my-etcd-token \
    - --initial-cluster-state new
    image: k8s.gcr.io/etcd-amd64:3.1.12
    livenessProbe:
    httpGet:
        path: /health
        port: 2379
        scheme: HTTP
    initialDelaySeconds: 15
    timeoutSeconds: 15
    name: etcd
    env:
    - name: PUBLIC_IP
    valueFrom:
        fieldRef:
        fieldPath: status.hostIP
    - name: PRIVATE_IP
    valueFrom:
        fieldRef:
        fieldPath: status.podIP
    - name: PEER_NAME
    valueFrom:
        fieldRef:
        fieldPath: metadata.name
    volumeMounts:
    - mountPath: /var/lib/etcd
    name: etcd
    - mountPath: /certs
    name: certs
hostNetwork: true
volumes:
- hostPath:
    path: /var/lib/etcd
    type: DirectoryOrCreate
    name: etcd
- hostPath:
    path: /etc/kubernetes/pki/etcd
    name: certs
EOF
```


* 配置集群配置文件
```
cat >/etc/kubernetes/manifests/config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
  advertiseAddress: 192.168.4.245
etcd:
  endpoints:
  - https://kubem1:2379
  - https://kubem2:2379
  - https://kubem3:2379
  caFile: /etc/kubernetes/pki/etcd/ca.pem
  certFile: /etc/kubernetes/pki/etcd/client.pem
  keyFile: /etc/kubernetes/pki/etcd/client-key.pem
networking:
  podSubnet: 10.244.0.0/16
kubernetesVersion: 1.10.1
apiServerCertSANs:
- kubem1
- kubem2
- kubem3
apiServerExtraArgs:
  apiserver-count: "3"
EOF
```

* 初始化 kubem1
```
cd /etc/kubernetes/manifests
kubeadm init --config=config.yaml
```