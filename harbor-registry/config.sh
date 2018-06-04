Harbor使用 -- 修改80端口
在公网上，一般情况下都不暴露默认端口，避免被攻击！

以下修改harbor的默认80端口为其他端口！

我这里示例修改为1180端口！

 

注意：以下步骤都是在harbor目录下操作！！！

1、修改docker-compose.yml文件映射为1180端口：

复制代码
 1 #vim docker-compose.yml
 2 
 3 proxy:
 4     image: nginx:1.11.5
 5     container_name: nginx
 6     restart: always
 7     volumes:
 8       - ./common/config/nginx:/etc/nginx
 9     ports:
10       - 1180:80
11       - 1143:443
12     depends_on:
13       - mysql
14       - registry
15       - ui
16       - log
复制代码
 

2、修改common/templates/registry/config.yml文件加入1180端口：

复制代码
#vim common/templates/registry/config.yml

auth:
  token:
    issuer: registry-token-issuer
    realm: $ui_url:1180/service/token
    rootcertbundle: /etc/registry/root.crt
    service: token-service
复制代码
 

3、停止harbor，重新启动并生成配置文件：

#docker-compose stop
# ./install.sh
 

4、修改docker启动文件，设置信任的主机与端口：

#vim /usr/lib/systemd/system/docker.service  修改如下一行
ExecStart=/usr/bin/dockerd --insecure-registry=172.16.103.99:1180
 

5、重新启动docker：

systemctl daemon-reload
systemctl restart docker.service
 

最后，测试验证：

# docker login 172.16.103.99:1180
Username: huangjc
Password: 
Login Succeeded
ok，完成！

记得登录时是1180这个端口哦！！

 

常见的2个报错信息解答：

（1）Error response from daemon: Get https://172.16.103.99/v1/users/: dial tcp 172.16.103.99:443: getsockopt: connection refused

（2）Error response from daemon: Get https://172.16.103.99:1180/v1/users/: http: server gave HTTP response to HTTPS client

报这2个错误的都是如下2个原因：

1、是端口错了！

2、未在docker启动文件中添加--insecure-registry信任关系！

大多数这个错误是第2个原因，因为你没有添加信任关系的话，docker默认使用的是https协议，所以端口不对(443)，会报连接拒绝这个错误；

或者提示你 "服务器给HTTPS端的是HTTP响应" 这个错误，因为你没添加端口信任，服务器认为这是默认的https访问，返回的却是http数据！

 

解决方法：

正确的添加信任关系包括端口号：

--insecure-registry=172.16.103.99:1180

一定要把主机与端口同时添加进去！