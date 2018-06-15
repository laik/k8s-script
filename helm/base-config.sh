
#mysql
helm install --name etrans --set mysqlRootPassword=rootplatform,mysqlUser=dxp,mysqlPassword=dxpplatform,mysqlDatabase=etbasedata stable/mysql

#postgresql
helm install --name-template etrans-greenplum --set postgresUser=gpadmin,postgresPassword=gpadmin,postgresDatabase=default_raw,service.type=NodePort,persistence.size=40 stable/postgresql
