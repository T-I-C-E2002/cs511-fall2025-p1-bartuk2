####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

FROM openjdk:8

RUN apt update && \
    apt upgrade --yes && \
    apt install ssh openssh-server --yes

# Setup common SSH key.
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/shared_rsa -C common && \
    cat ~/.ssh/shared_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Setup HDFS/Spark resources here
ENV HADOOP_VERSION=3.3.6 
ENV SPARK_VERSION=3.4.1 
ENV HADOOP_HOME=/opt/hadoop-${HADOOP_VERSION} \
    SPARK_HOME=/opt/spark-${SPARK_VERSION}-bin-hadoop3

ENV PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}" \
    HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop \
    SPARK_CONF_DIR=${SPARK_HOME}/conf

WORKDIR /opt

RUN curl -fsSL "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" -o hadoop.tar.gz && \
    tar -xzf hadoop.tar.gz && \
    rm hadoop.tar.gz && \
    curl -fsSL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" -o spark.tgz && \
    tar -xzf spark.tgz && \
    rm spark.tgz

COPY resources /opt/resources

RUN mkdir -p /data/hdfs/namenode /data/hdfs/datanode /data/spark/events /data/spark/work && \
    chmod -R 755 /data && \
    echo "export HADOOP_HOME=${HADOOP_HOME}" > /etc/profile.d/hadoop_spark.sh && \
    echo "export SPARK_HOME=${SPARK_HOME}" >> /etc/profile.d/hadoop_spark.sh && \
    echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> /etc/profile.d/hadoop_spark.sh && \
    echo "export SPARK_CONF_DIR=${SPARK_CONF_DIR}" >> /etc/profile.d/hadoop_spark.sh && \
    echo "export PATH=${PATH}" >> /etc/profile.d/hadoop_spark.sh

WORKDIR /
