#   Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements.  See the NOTICE file distributed with
#   this work for additional information regarding copyright ownership.
#   The ASF licenses this file to You under the Apache License, Version 2.0
#   (the "License"); you may not use this file except in compliance with
#   the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Abridged from ainmackie/trec-car-entity-processing

# By default, Ubuntu 19.10 uses Python3.7 which is required for pyspark
FROM ubuntu:19.10

MAINTAINER Enrico Trombetta <trombetta.enricom@protonmail.com>

USER root

# Install essentials

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
software-properties-common \
wget \
make \
gcc \
curl \
git

# Install java 8
RUN apt-get update && apt-get install openjdk-8-jdk -y
ENV JAVA_VERSION="java-8-openjdk-amd64"
ENV JAVA_HOME=/usr/lib/jvm/$JAVA_VERSION
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install scala
RUN apt-get update && apt-get install scala -y

# ...and sbt
RUN echo "deb https://dl.bintray.com/sbt/debian /" > /etc/apt/sources.list.d/sbt.list
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add
RUN apt-get update && apt-get install -y sbt

# Install lightcopy parquet-index
RUN cd /tmp && git clone https://github.com/erolm-a/parquet-index && cd parquet-index && sbt package && cp /tmp/parquet-index/target/scala-2.11/parquet-index_2.11-0.4.1-SNAPSHOT.jar /lib

# Install python
RUN apt-get update && apt-get install -y python3 \
python3-pip \
python-setuptools


RUN pip3 install \
numpy \
pandas \
jupyter \
jupyterlab \
cbor \
transformers \
nltk \
torch \
pyarrow \
protobuf \
py4j \
pystream-protobuf==1.5.1 \
spylon-kernel

# Install Jupyter Scala support
RUN python3 -m spylon_kernel install

# Install Spark
ENV APACHE_SPARK_VERSION=2.4.5 \
HADOOP_VERSION=2.7
RUN cd /tmp && \
wget -q $(wget -qO- https://www.apache.org/dyn/closer.lua/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz\?as_json | \
python3 -c "import sys, json; content=json.load(sys.stdin); print(content['preferred']+content['path_info'])") && \
echo "2426a20c548bdfc07df288cd1d18d1da6b3189d0b78dee76fa034c52a4e02895f0ad460720c526f163ba63a17efae4764c46a1cd8f9b04c60f9937a554db85d2 *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local/share/ --owner root --group root --no-same-owner && \
rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
ENV SPARK_HOME=/usr/local/share/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx12288M --driver-java-options=-Dlog4j.logLevel=info"
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PYSPARK_PYTHON=python3


RUN mkdir /nfs
WORKDIR /nfs
CMD ["/bin/bash"]
