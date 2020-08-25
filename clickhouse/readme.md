<!--
Author: cnak47
Date: 2020-08-14 14:48:00
<<<<<<< HEAD
 * @LastEditors: cnak47
 * @LastEditTime: 2020-08-25 19:50:20
=======
 * @LastEditors: cnak47
 * @LastEditTime: 2020-08-24 10:27:34
>>>>>>> 509a3306943234e2e35b3289ece7307adadeac76
Description: 
-->

# clickhouse

## 安装

### docker 单机

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
yandex/clickhouse-server:20.6.4.44
# 复制临时容器内配置文件到宿主机
docker cp clickhouse-server:/etc/clickhouse-server/config.xml /Users/ak47/Documents/docker/clickhouse/conf/config.xml
docker cp clickhouse-server:/etc/clickhouse-server/users.xml /Users/ak47/Documents/docker/clickhouse/conf/users.xml
docker cp clickhouse-server:/etc/clickhouse-server/config.d/docker_related_config.xml D:\workspace\data\ch-server\ch1\conf\
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

docker run -it --rm --net clickhouse_default --link clickhouse-server yandex/clickhouse-client:20.6.3.28 --host clickhouse-server --user root --password p8a2csYK

docker run -it --rm --net clickhouse_default yandex/clickhouse-client:20.6.3.28 --host clickhouse-server --user root --password p8a2csYK --multiline

```

### centos7

```bash
# centos7
#查看cpu是否支持sse4
grep -q sse4_2 /proc/cpuinfo && echo "SSE 4.2 supported" || echo "SSE 4.2 not supported"
# 下载rpm 包
sudo wget https://repo.yandex.ru/clickhouse/rpm/stable/x86_64/clickhouse-server-20.6.4.44-2.noarch.rpm
sudo wget https://repo.yandex.ru/clickhouse/rpm/stable/x86_64/clickhouse-client-20.6.4.44-2.noarch.rpm
sudo wget https://repo.yandex.ru/clickhouse/rpm/stable/x86_64/clickhouse-common-static-20.6.4.44-2.x86_64.rpm
# 安装
sudo rpm -ivh *.rpm

```

### 分片表

从实体表层面来看，一张分片表由两部分组成：

- 本地表：通常以_local为后缀进行命名。本地表是承接数据的载体，可以使用非Distributed的任意表引擎，一张本地表对应了一个数据分片。
- 分布式表：通常以_all为后缀进行命名。分布式表只能使用Distributed表引擎，它与本地表形成一对多的映射关系，日后将通过分布式表代理操作多张本地表。要彻底删除一张分布式表，则需要分别删除分布式表和本地表

```bash
# 分布式DDL
# 查询宏变量
SELECT * FROM system.macros m

SELECT * FROM system.zookeeper where path = '/clickhouse/task_queue/ddl';
SELECT * FROM system.zookeeper where path = '/clickhouse/task_queue/ddl/query-0000000005/finished';
# 查询远程
select * from remote('ch-server-12:9000','system','macros','root','p8a2csYK')
# 创建数据库
create database dm on cluster chk_shard2_rep0
# 创建表
create table dm.test_1_local on cluster chk_shard2_rep0 (
id UInt64
) engine = ReplicatedMergeTree('/clickhouse/tables/{shard}/test_1','{replica}')
order by id
# del 表
drop table dm.test_1_local on cluster chk_shard2_rep0

# 创建分布式表
CREATE TABLE dm.test_shard_2_all ON CLUSTER chk_shard2_rep0 (
    id UInt64
) ENGINE = Distributed(chk_shard2_rep0,dm,test_shard_2_local,intHash64(id));

create table dm.test_shard_2_local on cluster chk_shard2_rep0 (
id UInt64
) engine = MergeTree()
order by id

```
