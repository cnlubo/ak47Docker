<!--
 * @Author: cnak47
 * @Date: 2019-12-19 11:43:00
LastEditors: cnak47
LastEditTime: 2020-07-28 15:36:04
 * @Description: 
 -->

# docker kafka 开发环境

## 启动kafka

```bash
# 创建docker-compose.yml
# 启动三个kafka节点
docker-compose up --scale kafka=3 -d
# kafka manager
docker run -itd --net=kafka_default --name=kafka-manager -p 9000:9000 -e ZK_HOSTS="zookeeper:2181" sheepkiller/kafka-manager
# 容器启动以后访问主机的9000端口
# kafka offsetmonitor

docker run -d \
-p 8080:8080 \
--net=kafka_default \
-e "ZK_HOSTS=zookeeper:2181" \
-e "KAFKA_BROKERS=kafka_kafka_1:9092,kafka_kafka_2:9092,kafka_kafka_3:9092" \
junxy/kafkaoffsetmonitor

```
