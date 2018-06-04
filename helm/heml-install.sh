helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.9.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default


# 常用命令
$helm list
$helm delete 
$helm search local/ceph

helm serve &
helm repo add local http://localhost:8879/charts


$helm reset   或 $helm reset -f(强制删除k8s集群上tiller的pod.)


问题:Cannot initialize Kubernetes connection: Get http://localhost:8080/api: dial tcp [::1]:8080: getsockopt: connection refused

@mattus Thanks a lot, i was stuck for ~ 3 days with this at work trying to deploy a k8s cluster. This should really be documented somewhere.
What i did to solve the issue was:

kubectl --namespace=kube-system edit deployment/tiller-deploy and changed automountServiceAccountToken to true.
Then 'helm list' was giving me:
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
That was fixed with solution from #2687:
kubectl --namespace=kube-system create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default