#!/bin/bash
set -euo pipefail
####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

/etc/init.d/ssh start
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/shared_rsa

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################



# Start HDFS/Spark worker here

export JAVA_HOME=/usr/local/openjdk-8
HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop-3.3.6}
SPARK_HOME=${SPARK_HOME:-/opt/spark-3.4.1-bin-hadoop3}
HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-${HADOOP_HOME}/etc/hadoop}
SPARK_CONF_DIR=${SPARK_CONF_DIR:-${SPARK_HOME}/conf}

${HADOOP_HOME}/bin/hdfs --daemon start datanode

${SPARK_HOME}/sbin/start-worker.sh spark://main:7077

tail -f /dev/null