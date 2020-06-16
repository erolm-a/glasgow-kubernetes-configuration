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
pystream-protobuf==1.5.1

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
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info"
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PYSPARK_PYTHON=python3


# Install Jena - abridged from stain/jena

# Update below according to https://jena.apache.org/download/ 
# and checksum for apache-jena-3.x.x.tar.gz.sha512
ENV JENA_SHA512 ba2e966df3ff2c8727b02f95771aa9f9953687fadbd51a95fff3709bb342ca64c1ac54bc25c9e24432b038c14737979c48fad5885e5841d6c15cc4967859b037
ENV JENA_VERSION 3.14.0

# No need for https due to sha512 checksums below
ENV ASF_MIRROR http://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=
ENV ASF_ARCHIVE http://archive.apache.org/dist/
WORKDIR /tmp
# sha512 checksum
RUN echo "$JENA_SHA512  jena.tar.gz" > jena.tar.gz.sha512
# Download/check/unpack/move in one go (to reduce image size)
RUN     (curl --location --silent --show-error --fail --retry-connrefused --retry 3 --output jena.tar.gz ${ASF_MIRROR}jena/binaries/apache-jena-$JENA_VERSION.tar.gz || \
         curl --fail --silent --show-error --retry-connrefused --retry 3 --output jena.tar.gz $ASF_ARCHIVE/jena/binaries/apache-jena-$JENA_VERSION.tar.gz) && \
	sha512sum -c jena.tar.gz.sha512 && \
	tar zxf jena.tar.gz && \
	mv apache-jena* /jena && \
	rm jena.tar.gz* && \
	cd /jena && rm -rf *javadoc* *src* bat

# Add to PATH
ENV PATH $PATH:/jena/bin
# Check it works
RUN riot  --version

# Default dir /rdf, can be used with
# --volume
RUN mkdir /rdf
WORKDIR /rdf
#VOLUME /rdf
CMD ["/jena/bin/riot"]
