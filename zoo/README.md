<!--
 * @Author: cnak47
 * @Date: 2020-07-29 15:21:38
 * @LastEditors: cnak47
 * @LastEditTime: 2020-07-31 14:18:06
 * @Description: 
-->  

# zoo 笔记

## 启动

```bash
# 新建网络
docker network create --driver bridge --subnet 172.23.0.0/25 --gateway 172.23.0.1  zookeeper_network
docker-compose -f docker-compose.yml up -d

```