<!--
Author: cnak47
Date: 2020-08-14 14:48:00
LastEditors: cnak47
LastEditTime: 2020-08-18 10:15:15
Description: 
-->

# clickhouse

## 安装

```bash
mkdir -p /Users/ak47/Documents/docker/clickhouse/data
mkdir -p /Users/ak47/Documents/docker/clickhouse/conf
mkdir -p /Users/ak47/Documents/docker/clickhouse/log

#chmod -R 777 /Users/ak47/Documents/docker/clickhouse/data
#chmod -R 777 /Users/ak47/Documents/docker/clickhouse/conf
#chmod -R 777 /Users/ak47/Documents/docker/clickhouse/log
# 拉取镜像
docker pull yandex/clickhouse-server:20.6.3.28
# docker ps --format "table {{.Names}} ------> {{.Ports}}"
# 创建临时容器
docker run --rm -d --name=clickhouse-server \
--ulimit nofile=262144:262144 \
-p 8123:8123 -p 9009:9009 -p 9090:9000 \
yandex/clickhouse-server:20.6.3.28
# 复制临时容器内配置文件到宿主机
docker cp clickhouse-server:/etc/clickhouse-server/config.xml /Users/ak47/Documents/docker/clickhouse/conf/config.xml
docker cp clickhouse-server:/etc/clickhouse-server/users.xml /Users/ak47/Documents/docker/clickhouse/conf/users.xml
# 停掉临时容器
docker stop clickhouse-server
# 创建default账号密码
PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha256sum | tr -d '-'
# 会输出明码和SHA256密码
# 创建root账号密码
PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha256sum | tr -d '-'
# 修改 users.xml default账号设为只读权限，并设置密码
# 新增root账号
# 创建容器
docker run -d --name=clickhouse-server \
-p 8123:8123 -p 9009:9009 -p 9090:9000 \
--ulimit nofile=262144:262144 \
-v /Users/ak47/Documents/docker/clickhouse/data:/var/lib/clickhouse:rw \
-v /Users/ak47/Documents/docker/clickhouse/conf/config.xml:/etc/clickhouse-server/config.xml \
-v /Users/ak47/Documents/docker/clickhouse/conf/users.xml:/etc/clickhouse-server/users.xml \
-v /Users/ak47/Documents/docker/clickhouse/log:/var/log/clickhouse-server:rw \
yandex/clickhouse-server:20.6.3.28

# 用 dbeaver 连接
localhost 8123 root/p8a2csYK default/CVWPdiHF

```
