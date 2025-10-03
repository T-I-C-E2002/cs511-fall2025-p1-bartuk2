#!/bin/bash
set -euo pipefail

export JAVA_HOME=/usr/local/openjdk-8
HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop-3.3.6}
SPARK_HOME=${SPARK_HOME:-/opt/spark-3.4.1-bin-hadoop3}
HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-${HADOOP_HOME}/etc/hadoop}
SPARK_CONF_DIR=${SPARK_CONF_DIR:-${SPARK_HOME}/conf}
####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Setup HDFS/Spark worker here
mkdir -p /data/hdfs/namenode /data/hdfs/datanode /data/spark/events /data/spark/work

cat > "${HADOOP_CONF_DIR}/core-site.xml" <<'EOF'
<?xml version="1.0"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://main:9000</value>
  </property>
</configuration>
EOF

cat > "${HADOOP_CONF_DIR}/hdfs-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>3</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///data/hdfs/datanode</value>
  </property>
  <property>
    <name>dfs.permissions.enabled</name>
    <value>false</value>
  </property>
</configuration>
EOF

cat > "${HADOOP_CONF_DIR}/workers" <<'EOF'
main
worker1
worker2
EOF

cat > "${HADOOP_CONF_DIR}/hadoop-env.sh" <<'EOF'
export JAVA_HOME=/usr/local/openjdk-8
export HDFS_DATANODE_USER=root
EOF

cat > "${SPARK_CONF_DIR}/spark-env.sh" <<'EOF'
export JAVA_HOME=/usr/local/openjdk-8
export HADOOP_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop
export SPARK_WORKER_DIR=/data/spark/work
export SPARK_LOCAL_DIRS=/data/spark/work
EOF

cat > "${SPARK_CONF_DIR}/spark-defaults.conf" <<'EOF'
spark.master spark://main:7077
spark.eventLog.enabled true
spark.eventLog.dir file:///data/spark/events
spark.history.fs.logDirectory file:///data/spark/events
EOF