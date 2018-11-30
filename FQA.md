[√] FQA(关于在部署的过程中遇到一些问题记录)

> 1. cni 问题 Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
>> 删除 /etc/systemd/system/kubelet.service.d/10-kubeadm.conf 中的$ KUBELET_NETWORK_ARGS 参数之后执行
>> 或者 直接安装 Clico 依赖 CNI 容器提供 CNI
`systemctl daemon-reload && systemctl restart kubelet`


> 2. https 访问 dashboard 证书问题
>> 基于docker镜像部署方式
>>>  source url from github [https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above]
>>> 
>>> This way of accessing Dashboard is only recommended for development environments in a single node setup.
>>> 
>>> Edit kubernetes-dashboard service.
>>> ```
>>> $ kubectl -n kube-system edit service kubernetes-dashboard
>>> ```
>>> You should see yaml representation of the service. Change type: ClusterIP to type: NodePort and save file. If it's already changed go to next step.
>>> 
>>> Please edit the object below. Lines beginning with a '#' will be ignored,
>>> and an empty file will abort the edit. If an error occurs while saving this file will be
>>> #### reopened with the relevant failures.
>>> ```
>>> apiVersion: v1
>>> ...
>>>   name: kubernetes-dashboard
>>>   namespace: kube-system
>>>   resourceVersion: "343478"
>>>   selfLink: /api/v1/namespaces/kube-system/services/kubernetes-dashboard-head
>>>   uid: 8e48f478-993d-11e7-87e0-901b0e532516
>>> spec:
>>>   clusterIP: 10.100.124.90
>>>   externalTrafficPolicy: Cluster
>>>   ports:
>>>   - port: 443
>>>     protocol: TCP
>>>     targetPort: 8443
>>>   selector:
>>>     k8s-app: kubernetes-dashboard
>>>   sessionAffinity: None
>>>   type: ClusterIP
>>> status:
>>>   loadBalancer: {}
>>> ```
>>> Next we need to check port on which Dashboard was exposed.
>>> 
>>> ```
>>> $ kubectl -n kube-system get service kubernetes-dashboard
>>> ```
>>> ```
>>> NAME                   CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
>>> kubernetes-dashboard   10.100.124.90   <nodes>       443:31707/TCP   21h
>>> Dashboard has been exposed on port 31707 (HTTPS). Now you can access it from your browser at: https://<master-ip>:31707. master-ip can be found by executing kubectl cluster-info. Usually it is either 127.0.0.1 or IP of your machine, assuming that your cluster is running directly on the machine, on which these commands are executed.
>>> ```
>>> 
>>> #### 当改为节点访问${master}:31707 时会出现"system:serviceaccount:kube-system:kubernetes-dashboard"
>>> 
>>> If you received an error like below, you need to grant access to Kubernetes dashboard to in your cluster.
>>> 
>>> configmaps is forbidden: User "system:serviceaccount:kube-system:kubernetes-dashboard" cannot list configmaps in the namespace "default"
>>> 
>>> If you are planning to access to Kubernetes Dashboard via proxy from remote machine, you will need to grant ClusterRole to allow access to dashboard.
>>> 
>>> Create new file and insert following details.
>>> ```
>>> vi kube-dashboard-access.yaml
>>> ```
>>> ```
>>> apiVersion: rbac.authorization.k8s.io/v1beta1
>>> kind: ClusterRoleBinding
>>> metadata:
>>>   name: kubernetes-dashboard
>>>   labels:
>>>     k8s-app: kubernetes-dashboard
>>> roleRef:
>>>   apiGroup: rbac.authorization.k8s.io
>>>   kind: ClusterRole
>>>   name: cluster-admin
>>> subjects:
>>> - kind: ServiceAccount
>>>   name: kubernetes-dashboard
>>>   namespace: kube-system
>>> ```
>>> Now we will apply changes to Kubernetes Cluster to grant access to dashboard.
>>> ```
>>> kubectl create -f kube-dashboard-access.yaml
>>> ```


>> #### 二进制部署的改造方法(没试过)
>>> ##### Kubernetes API Server新增了 –anonymous-auth 选项，允许匿名请求访问secure port。没有被其他authentication方法拒绝的请求即Anonymous requests， 这样的匿名请求的username为system:anonymous, 归属的组为system:unauthenticated。并且该选线是默认的。这样一来，当采用chrome浏览器访问dashboard UI时很可能无法弹出用户名、密码输入对话框，导致后续authorization失败。为了保证用户名、密码输入对话框的弹出，需要将 –anonymous-auth 设置为 false。
>>> 
>>> #### 解决方法1：
>>> 在api-server配置文件中添加 –anonymous-auth=false
>>> ```
>>> [root@master1 dashboard]# vim /etc/systemd/system/kube-apiserver.service
>>> ```
>>> ```
>>> [Unit]
>>> Description=Kubernetes API Server
>>> Documentation=https://github.com/GoogleCloudPlatform/kubernetes
>>> After=network.target
>>> After=etcd.service
>>> 
>>> [Service]
>>> ExecStart=/usr/local/bin/kube-apiserver \
>>>   --logtostderr=true \
>>>   --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota,NodeRestriction \
>>>   --advertise-address=192.168.161.161 \
>>>   --bind-address=192.168.161.161 \
>>>   --insecure-bind-address=127.0.0.1 \
>>>   --authorization-mode=Node,RBAC \
>>>   --anonymous-auth=false \
>>>   --basic-auth-file=/etc/kubernetes/basic_auth_file \
>>>   --runtime-config=rbac.authorization.k8s.io/v1alpha1 \
>>>   --kubelet-https=true \
>>>   --enable-bootstrap-token-auth \
>>>   --token-auth-file=/etc/kubernetes/token.csv \
>>>   --service-cluster-ip-range=10.254.0.0/16 \
>>>   --service-node-port-range=8400-10000 \
>>>   --tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem \
>>>   --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
>>>   --client-ca-file=/etc/kubernetes/ssl/ca.pem \
>>>   --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \
>>>   --etcd-cafile=/etc/kubernetes/ssl/ca.pem \
>>>   --etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem \
>>>   --etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem \
>>>   --etcd-servers=https://192.168.161.161:2379,https://192.168.161.162:2379,https://192.168.161.163:2379 \
>>>   --enable-swagger-ui=true \
>>>   --allow-privileged=true \
>>>   --apiserver-count=3 \
>>>   --audit-log-maxage=30 \
>>>   --audit-log-maxbackup=3 \
>>>   --audit-log-maxsize=100 \
>>>   --audit-log-path=/var/lib/audit.log \
>>>   --event-ttl=1h \
>>>   --v=2
>>> Restart=on-failure
>>> RestartSec=5
>>> Type=notify
>>> LimitNOFILE=65536
>>> 
>>> [Install]
>>> WantedBy=multi-user.target
>>> ```
>>> #### Unauthorized问题
>>> 解决了上面那个问题之后，再度访问dashboard页面，发现还是有问题，出现下面这个问题：
>>> ```
>>> {
>>>   "kind": "Status",
>>>   "apiVersion": "v1",
>>>   "metadata": {
>>> 
>>>   },
>>>   "status": "Failure",
>>>   "message": "Unauthorized",
>>>   "reason": "Unauthorized",
>>>   "code": 401
>>> }
>>> ```
>>> ##### Unauthorized解决方法1：
>>> 新建 /etc/kubernetes/basic_auth_file 文件，并在其中添加：
>>> 
>>> admin123,admin,1002
>>> 文件内容格式：password,username,uid
>>> 
>>> 然后在api-server配置文件（即上面的配置文件）中添加：
>>> ```
>>> --basic-auth-file=/etc/kubernetes/basic_auth_file \
>>> ```
>>> #### 保存重启kube-apiserver：
>>> ```
>>> systemctl daemon-reload
>>> systemctl restart kube-apiserver
>>> systemctl status kube-apiserver
>>> 最后在kubernetes上执行下面这条命令：
>>> ```
>>> ```
>>> kubectl create clusterrolebinding login-dashboard-admin --clusterrole=cluster-admin --user=admin
>>> ```
>>> 将访问账号名admin与dashboard.yaml文件中指定的cluster-admin关联，获得访问权限。
>>> 
>>> 
>>> ##### Unauthorized解决方法2:
>>> ```
>>> nohup kubectl proxy --accept-hosts='^*$' > /tmp/proxy.log 2>&1 &
>>> ```


> #### 3. 关于"Failed to create summary reader for "/system.slice/auditd.service": none of the resources are being tracked."
>> ##### 总结: 以下那么长的解释就是为了在 /etc/systemd/system/kubelet.service.d/10-kubeadm.conf Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=cgroupfs --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice" 加入后面 --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice 这一段
>> 
>> ##### ---------------------分隔线------------------------------------------
>> 
>> I've got the same errors on
>> 
>> CentOS 7.4.1708
>> docker 1.12.6
>> kubeadm v1.9.4
>> Mar 14 08:32:35 ksa-m1.blue kubelet[9322]: E0314 08:32:34.998853    9322 summary.go:92] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
>> Mar 14 08:32:35 ksa-m1.blue kubelet[9322]: E0314 08:32:34.998879    9322 summary.go:92] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"
>> And the above fix works for me.
>> On CentOS I can add these options in /etc/systemd/system/kubelet.service.d/10-kubeadm.conf:
>> ```
>> egrep KUBELET_CGROUP_ARGS= /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
>> ```
>> ```
>> Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=cgroupfs --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice"
>> ```
>> Should we have this fix added to the kubeadm RPM by default?
>> Environment:
>> 
>> cat /etc/redhat-release 
>> CentOS Linux release 7.4.1708 (Core) 
>> 
>> uname -a
>> Linux ksa-m1.blue 3.10.0-514.6.1.el7.x86_64 #1 SMP Wed Jan 18 13:06:36 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
>> 
>> kubectl version
>> Client Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.4", GitCommit:"bee2d1505c4fe820744d26d41ecd3fdd4a3d6546", GitTreeState:"clean", BuildDate:"2018-03-12T16:29:47Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
>> Server Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.4", GitCommit:"bee2d1505c4fe820744d26d41ecd3fdd4a3d6546", GitTreeState:"clean", BuildDate:"2018-03-12T16:21:35Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
>> 
>> rpm -qa | egrep kube
>> kubernetes-cni-0.6.0-0.x86_64
>> kubelet-1.9.4-0.x86_64
>> kubectl-1.9.4-0.x86_64
>> kubeadm-1.9.4-0.x86_64
>> 
>> docker version 
>> Client:
>>  Version:         1.12.6
>>  API version:     1.24
>>  Package version: docker-1.12.6-71.git3e8e77d.el7.centos.1.x86_64
>>  Go version:      go1.8.3
>>  Git commit:      3e8e77d/1.12.6
>>  Built:           Tue Jan 30 09:17:00 2018
>>  OS/Arch:         linux/amd64
>> 
>> Server:
>>  Version:         1.12.6
>>  API version:     1.24
>>  Package version: docker-1.12.6-71.git3e8e77d.el7.centos.1.x86_64
>>  Go version:      go1.8.3
>>  Git commit:      3e8e77d/1.12.6
>>  Built:           Tue Jan 30 09:17:00 2018
>>  OS/Arch:         linux/amd64

--- 
>> #### kubernetes（k8s）DNS 服务反复重启解决：k8s.io/dns/pkg/dns/dns.go:150: Failed to list *v1.Service: Get https://10.96.0.1:443/api/v1/services?resourceVersion=0: dial tcp 10.96.0.1:443: getsockopt: no route to host
>>> ```
>>> systemctl stop kubelet && systemctl stop docker
>>> iptables --flush && iptables -tnat --flush
>>> systemctl start kubelet && systemctl start docker
>>> ```



#### fatal: parameter inet_interfaces: no local interface found for ::1
```
sed -i 's/inet_interfaces = localhost/inet_protocols = all/g' /etc/postfix/main.cf
grep inet_protocols /etc/postfix/main.cf
service postfix start
```