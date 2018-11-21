
#mysql
helm install --name etrans --set mysqlRootPassword=rootplatform,mysqlUser=dxp,mysqlPassword=dxpplatform,mysqlDatabase=etbasedata stable/mysql

#postgresql
helm install --name-template etrans-greenplum --set postgresUser=gpadmin,postgresPassword=gpadmin,postgresDatabase=default_raw,service.type=NodePort,persistence.size=20Gi stable/postgresql




# upgrade
helm upgrade -f ./mysql/values.yaml gps-web-mysql ./mysql



helm install --name saturn-db -f ./mysql/values.yaml stable/mysql