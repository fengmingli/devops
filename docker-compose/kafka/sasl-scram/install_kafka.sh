#!/bin/bash

set -e

IP_ADDR=$1

ZOOKEEPER_IMAGE=zookeeper:3.5.5
KAFKA_IMAGE=confluentinc/cp-kafka:5.5.0


if [ ! $IP_ADDR ];then
echo "address is empty, please input the ip address of this host."
exit 1
fi

CURR_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

DC_EXIST=`docker-compose -version | awk '{print $3}'`
if [ ! ${DC_EXIST%?} ];then
curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

docker-compose -version
if [ $? -ne 0 ];then
echo "docker-compose install failed, please check."
exit 1
fi

#Create network for zookeeper-kafka cluster
zknet=`docker network ls | grep zookeeper_kafka | awk {'print $2'}`
if [ -n "$zknet" ]
then
    echo 'The zookeeper_kafka is already existed.'
else
    echo 'Create zookeeper_kafka.'
    docker network create --subnet 172.30.0.0/16 zookeeper_kafka
fi

echo "create local dir for kafka cluster"
mkdir -p $CURR_DIR/kafka_data/kafka0/data
mkdir -p $CURR_DIR/kafka_data/kafka1/data
mkdir -p $CURR_DIR/kafka_data/kafka2/data
mkdir -p $CURR_DIR/kafka_data/conf

echo "create local dir for zookeeper cluster"
mkdir -p $CURR_DIR/zookeeper_data/zookeeper0/{data,datalog}
mkdir -p $CURR_DIR/zookeeper_data/zookeeper1/{data,datalog}
mkdir -p $CURR_DIR/zookeeper_data/zookeeper2/{data,datalog}
mkdir -p $CURR_DIR/zookeeper_data/conf



if [ ! -e $CURR_DIR/kafka-compose.yaml ];then
cat > $CURR_DIR/kafka-compose.yaml << EOF
version: '3.3'

services:
  zookeeper0:
    image: $ZOOKEEPER_IMAGE
    restart: always
    hostname: zookeeper0
    container_name: zookeeper0
    ports:
    - 12181:2181
    volumes:
    - $CURR_DIR/zookeeper_data/zookeeper0/data:/data
    - $CURR_DIR/zookeeper_data/zookeeper0/datalog:/datalog
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888;2181 server.2=zookeeper1:2888:3888;2181 server.3=zookeeper2:2888:3888;2181
      JAR
  zookeeper1:
    image: $ZOOKEEPER_IMAGE
    restart: always
    hostname: zookeeper1
    container_name: zookeeper1
    ports:
    - 12182:2181
    volumes:
    - $CURR_DIR/zookeeper_data/zookeeper1/data:/data
    - $CURR_DIR/zookeeper_data/zookeeper1/datalog:/datalog
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zookeeper0:2888:3888;2181 server.2=0.0.0.0:2888:3888;2181 server.3=zookeeper2:2888:3888;2181
  zookeeper2:
    image: $ZOOKEEPER_IMAGE
    restart: always
    hostname: zookeeper2
    container_name: zookeeper2
    ports:
    - 12183:2181
    volumes:
    - $CURR_DIR/zookeeper_data/zookeeper2/data:/data
    - $CURR_DIR/zookeeper_data/zookeeper2/datalog:/datalog
    environment:
      ZOO_MY_ID: 3
      ZOO_SERVERS: server.1=zookeeper0:2888:3888;2181 server.2=zookeeper1:2888:3888;2181 server.3=0.0.0.0:2888:3888;2181
  kafka0:
    image: $KAFKA_IMAGE
    restart: always
    depends_on:
      - zookeeper0
      - zookeeper1
      - zookeeper2
    container_name: kafka0
    ports:
      - 19092:9092
    environment:
      KAFKA_ADVERTISED_LISTENERS: SASL_PLAINTEXT://$IP_ADDR:19092
      KAFKA_LISTENERS: SASL_PLAINTEXT://0.0.0.0:9092
      KAFKA_ZOOKEEPER_CONNECT: zookeeper0:2181,zookeeper1:2181,zookeeper2:2181
      KAFKA_BROKER_ID: 0
      KAFKA_LOG_DIRS: /opt/kafka/data/logs
      KAFKA_ALLOW_EVERYONE_IF_NO_ACL_FOUND: "false"
      KAFKA_AUTHORIZER_CLASS_NAME: kafka.security.auth.SimpleAclAuthorizer
      KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
      KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
      KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SASL_PLAINTEXT
      KAFKA_SUPER_USERS: User:admin
      KAFKA_OPTS: -Djava.security.auth.login.config=/etc/kafka/jaas/kafka-server-jaas.conf
        -Dzookeeper.sasl.clientconfig=zookeeper
        -Dzookeeper.sasl.clientconfig=Client
        -Dzookeeper.sasl.client=true
    volumes:
      - $CURR_DIR/kafka_data/kafka2/data:/opt/kafka/data
      - $CURR_DIR/kafka_data/conf/kafka-server-jaas.conf:/etc/kafka/jaas/kafka-server-jaas.conf
  kafka1:
    image: $KAFKA_IMAGE
    restart: always
    depends_on:
      - zookeeper0
      - zookeeper1
      - zookeeper2
    container_name: kafka1
    ports:
      - 19093:9093
    environment:
      KAFKA_ADVERTISED_LISTENERS: SASL_PLAINTEXT://$IP_ADDR:19093
      KAFKA_LISTENERS: SASL_PLAINTEXT://0.0.0.0:9093
      KAFKA_ZOOKEEPER_CONNECT: zookeeper0:2181,zookeeper1:2181,zookeeper2:2181
      KAFKA_BROKER_ID: 1
      KAFKA_ALLOW_EVERYONE_IF_NO_ACL_FOUND: "false"
      KAFKA_AUTHORIZER_CLASS_NAME: kafka.security.auth.SimpleAclAuthorizer
      KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
      KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
      KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SASL_PLAINTEXT
      KAFKA_SUPER_USERS: User:admin
      KAFKA_OPTS: -Djava.security.auth.login.config=/etc/kafka/jaas/kafka-server-jaas.conf
        -Dzookeeper.sasl.clientconfig=zookeeper
        -Dzookeeper.sasl.clientconfig=Client
        -Dzookeeper.sasl.client=true
    volumes:
      - $CURR_DIR/kafka_data/kafka2/data:/opt/kafka/data
      - $CURR_DIR/kafka_data/conf/kafka-server-jaas.conf:/etc/kafka/jaas/kafka-server-jaas.conf
  kafka2:
    image: $KAFKA_IMAGE
    restart: always
    depends_on:
      - zookeeper0
      - zookeeper1
      - zookeeper2
    container_name: kafka2
    ports:
      - 19094:9094
    environment:
      KAFKA_ADVERTISED_LISTENERS: SASL_PLAINTEXT://$IP_ADDR:19094
      KAFKA_LISTENERS: SASL_PLAINTEXT://0.0.0.0:9094
      KAFKA_ZOOKEEPER_CONNECT: zookeeper0:2181,zookeeper1:2181,zookeeper2:2181
      KAFKA_BROKER_ID: 2
      KAFKA_ALLOW_EVERYONE_IF_NO_ACL_FOUND: "false"
      KAFKA_AUTHORIZER_CLASS_NAME: kafka.security.auth.SimpleAclAuthorizer
      KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
      KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
      KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SASL_PLAINTEXT
      KAFKA_SUPER_USERS: User:admin
      KAFKA_OPTS: -Djava.security.auth.login.config=/etc/kafka/jaas/kafka-server-jaas.conf
        -Dzookeeper.sasl.clientconfig=zookeeper
        -Dzookeeper.sasl.clientconfig=Client
        -Dzookeeper.sasl.client=true
    volumes:
      - $CURR_DIR/kafka_data/kafka2/data:/opt/kafka/data
      - $CURR_DIR/kafka_data/conf/kafka-server-jaas.conf:/etc/kafka/jaas/kafka-server-jaas.conf
networks:
  default:
    external:
      name: zookeeper_kafka
EOF
fi

#创建配置文件
cat > $CURR_DIR/kafka_data/conf/kafka-server-jaas.conf <<EOF
KafkaServer {
  org.apache.kafka.common.security.scram.ScramLoginModule required
  username="admin"
  password="admin123456";
};
KafkaClient {
  org.apache.kafka.common.security.scram.ScramLoginModule required
  username="admin"
  password="admin123456";
};

EOF


cat > $CURR_DIR/zookeeper_data/conf/zk_server_jaas.conf <<EOF
Server {
  org.apache.zookeeper.server.auth.DigestLoginModule required
  username="admin"
  password="admin123456";
  user_admin="admin123456";
  user_zookeeper="admin123456"
};

EOF




#创建启动脚本
cat > $CURR_DIR/startup.sh <<EOF
#!/bin/bash

docker-compose -f $CURR_DIR/kafka-compose.yaml up -d

docker-compose -f $CURR_DIR/kafka-compose.yaml ps

EOF

#创建停止脚本
cat > $CURR_DIR/stop.sh <<EOF
#!/bin/bash

docker-compose -f $CURR_DIR/kafka-compose.yaml down

EOF

#赋予shell脚本可执行权限
chmod +x $CURR_DIR/*.sh

