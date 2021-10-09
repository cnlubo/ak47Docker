<!--
 * @Author: cnak47
 * @Date: 2019-11-28 15:36:53
 * @LastEditors  : cnak47
 * @LastEditTime : 2019-12-27 17:24:21
 * @Description: 
 -->

# Docker部署 Oracle Server

## Mac

参考:https://oraclespin.com/2018/03/30/docker-installation-of-oracle-database-12c-on-mac/

## Docker 环境

<https://store.docker.com/editions/community/docker-ce-desktop-mac>

## 下载 Oracle Docker Image

```bash
git clone https://github.com/oracle/docker-images
```

## 下载Oracle 安装包

Oracle Database 12c Release 2 (12.2.0.1.0) - Standard Edition 2 and Enterprise Edition

<https://download.oracle.com/otn/linux/oracle12c/122010/linuxx64_12201_database.zip>

## build Docker image 文件

```bash
# 拷贝安装文件
cp linuxx64_12201_database.zip docker-images/OracleDatabase/SingleInstance/dockerfiles/12.2.0.1/
# build image
cd docker-images/OracleDatabase/SingleInstance/dockerfiles
./buildDockerImage.sh -v 12.2.0.1 -e
```

## 创建和运行数据库

```bash
# 初始化数据库启动
docker run --name oracle -p 1521:1521 -p 5500:5500 -v /Users/ak47/oradata:/opt/oracle/oradata oracle/database:12.2.0.1-ee
# -p 指定端口映射，主机到Docker的端口对应
# -v 指定数据库的对应存储路径，我指定了一个Docker之外的本地存储，将数据库独立出来
# 自定义sid
docker run -d -it --name oracle -p 1521:1521 -P 5500:5500 \
 --env-file ora.conf \
 -v /Users/ak47/oradata:/opt/oracle/oradata \
 oracle/database:12.2.0.1-ee

# 由于数据库缺省会指定用户口令，所以我们可以通过如下命令来修改口令：
 docker exec oracle ./setPassword.sh youpassword
# 其它命令
docker start oracle
docker stop oracle
docker logs oracle
```

### 连接oracle 数据库

# Docker 部署 Oracle Instant Client
