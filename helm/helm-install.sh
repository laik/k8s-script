helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.9.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts




#初始化后出现 system:default not sufficient for helm, but works for kubectl
# 参考 https://github.com/kubernetes/helm/issues/2687
问题:Cannot initialize Kubernetes connection: Get http://localhost:8080/api: dial tcp [::1]:8080: getsockopt: connection refused

@mattus Thanks a lot, i was stuck for ~ 3 days with this at work trying to deploy a k8s cluster. This should really be documented somewhere.
What i did to solve the issue was:

kubectl --namespace=kube-system edit deployment/tiller-deploy and changed automountServiceAccountToken to true.


Then 'helm list' was giving me:
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
That was fixed with solution from #2687:

kubectl --namespace=kube-system create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

