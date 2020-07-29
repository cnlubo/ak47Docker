version: "2.1"
services:
  zookeeper:
    image: wurstmeister/zookeeper
    ports:
      - "2181:2181"
  kafka:
    image: wurstmeister/kafka
    ports:
      - "9092:9092"
      - "9093:9093"
    links:
      - zookeeper
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_HOST_NAME: 192.168.0.102
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
  kafkamanger:
    image: sheepkiller/kafka-manager
    ports:
      - "9000"
    environment: 
      ZK_HOSTS: zookeeper:2181
