#!/bin/bash
set -euo pipefail

export JAVA_HOME=/usr/local/openjdk-8
HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop-3.3.6}
SPARK_HOME=${SPARK_HOME:-/opt/spark-3.4.1-bin-hadoop3}
HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-${HADOOP_HOME}/etc/hadoop}
SPARK_CONF_DIR=${SPARK_CONF_DIR:-${SPARK_HOME}/conf}
####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

# Exchange SSH keys.
/etc/init.d/ssh start
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/shared_rsa
ssh-copy-id -i ~/.ssh/id_rsa -o 'IdentityFile ~/.ssh/shared_rsa' -o StrictHostKeyChecking=no -f worker1
ssh-copy-id -i ~/.ssh/id_rsa -o 'IdentityFile ~/.ssh/shared_rsa' -o StrictHostKeyChecking=no -f worker2

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Start HDFS/Spark main here

if [ ! -f /data/hdfs/namenode/current/VERSION ]; then
  ${HADOOP_HOME}/bin/hdfs namenode -format -force -nonInteractive
fi

${HADOOP_HOME}/bin/hdfs --daemon start namenode
${HADOOP_HOME}/bin/hdfs --daemon start datanode

export SPARK_MASTER_HOST=main
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080

${SPARK_HOME}/sbin/start-master.sh
${SPARK_HOME}/sbin/start-worker.sh spark://main:7077

tail -f /dev/null