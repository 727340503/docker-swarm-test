# LNMP 集群示例

这是之前 LNMP 单机示例的扩展版本，可以将 Nginx, PHP 服务在 Swarm 集群中横向扩容。由于 Swarm 的横向扩展需求，不应该使用挂载目录的形式，因此这个示例中，所有配置文件、站点文件均打入了镜像，并且使用了版本进行控制。

## 建立 swarm 集群

在安装有 `docker-machine` 以及 VirtualBox 的虚拟机上（比如装有 Docker Toolbox 的Mac/Windows），使用 `run.sh` 脚本即可创建集群：

```bash
./run.sh create
```

## 启动

```bash
./run.sh up
```

## 横向扩展

```bash
./run.sh scale 3 5
```

这里第一个参数是 nginx 容器的数量，第二个参数是 php 容器的数量。

## 访问服务

`nginx` 将会守候 80 端口。利用 `docker ps` 可以查看具体集群哪个节点在跑 nginx 以及 IP 地址。如

```bash
$ eval $(./run.sh env)
$ docker ps
CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS                                NAMES
b7c38fb39723        twang2218/lnmp-php:latest     "php-fpm"                2 minutes ago       Up 2 minutes        9000/tcp                             node1/dockerlnmp_php_5
b82f629c5fa0        twang2218/lnmp-php:latest     "php-fpm"                2 minutes ago       Up 2 minutes        9000/tcp                             master/dockerlnmp_php_3
e1f1ebf383a3        twang2218/lnmp-php:latest     "php-fpm"                2 minutes ago       Up 2 minutes        9000/tcp                             node2/dockerlnmp_php_4
a6f1ffd63394        twang2218/lnmp-php:latest     "php-fpm"                2 minutes ago       Up 2 minutes        9000/tcp                             node1/dockerlnmp_php_2
c949792eedba        twang2218/lnmp-nginx:latest   "nginx -g 'daemon off"   2 minutes ago       Up 2 minutes        192.168.99.110:80->80/tcp, 443/tcp   node3/dockerlnmp_nginx_3
096a3a47aa51        twang2218/lnmp-nginx:latest   "nginx -g 'daemon off"   2 minutes ago       Up 2 minutes        192.168.99.109:80->80/tcp, 443/tcp   master/dockerlnmp_nginx_2
e0e8b56c34fe        twang2218/lnmp-nginx:latest   "nginx -g 'daemon off"   10 minutes ago      Up 2 minutes        192.168.99.112:80->80/tcp, 443/tcp   node2/dockerlnmp_nginx_1
0f411d1342ec        twang2218/lnmp-php:latest     "php-fpm"                10 minutes ago      Up 2 minutes        9000/tcp                             node1/dockerlnmp_php_1
dc1bb1e5ee59        twang2218/lnmp-mysql:latest   "docker-entrypoint.sh"   10 minutes ago      Up 2 minutes        3306/tcp                             node3/dockerlnmp_mysql_1
```

如这种情况，就可以使用 <http://192.168.99.109>, <http://192.168.99.110>, <http://192.168.99.112> 来访问服务。

## 停止服务

```bash
./run.sh down
```

## 销毁集群

```bash
./run.sh remove
```
