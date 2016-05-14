# install hadoop and hbase in a docker
FROM ubuntu:14.04
MAINTAINER KDF5000 <kdf5000@163.com>
RUN mv /etc/apt/sources.list /etc/apt/sources.list.old \
    && echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get -qq update

#RUN apt-get -qqy install wget
#RUN apt-get -qqy install perl
RUN apt-get -qqy install ssh
RUN apt-get -qqy install openssh-server

# auth
RUN mkdir -p /root/.ssh
ADD ssh /root/.ssh
RUN chmod 700 /root/.ssh/id_rsa && chmod 644 /root/.ssh/authorized_keys 

#install jdk, we use openjdk7
RUN apt-get install openjdk-7-jre openjdk-7-jdk -qqy
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" >> /etc/profile 
#ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

#copy hadoop and hbase to /home/bigdata
RUN mkdir -p /home/bigdata 
ADD source /home/bigdata
RUN cd /home/bigdata \
    && tar -zxf hadoop-2.6.4.tar.gz    -C /usr/local && mv /usr/local/hadoop-2.6.4 /usr/local/hadoop \
    && tar -zxf hbase-1.2.1-bin.tar.gz -C /usr/local && mv /usr/local/hbase-1.2.1  /usr/local/hbase


#set env
RUN echo "export HADOOP_HOME=/usr/local/hadoop">>/etc/profile 
RUN echo "export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native" >>/etc/profile 

RUN echo "export HBASE_HOME=/usr/local/hbase" >>/etc/profile 
RUN echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$HBASE_HOME/bin" >>/etc/profile 

RUN echo "export HBASE_CLASSPATH=\$(hbase classpath)">>/etc/profile 
RUN echo "export HADOOP_CLASSPATH=\$(hadoop classpath)"  >>/etc/profile 

RUN echo "export CLASSPATH=\$CLASSPATH:\$HADOOP_CLASSPATH">>/etc/profile

#make the env work
RUN bash /etc/profile

#hadoop configuration
RUN mv /usr/local/hadoop/etc/hadoop/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh.old \
    && mv /usr/local/hadoop/etc/hadoop/core-site.xml /usr/local/hadoop/etc/hadoop/core-site.xml.old \
    && mv /usr/local/hadoop/etc/hadoop/hdfs-site.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml.old 
COPY conf/hadoop-env.sh /usr/local/hadoop/etc/hadoop/
COPY conf/core-site.xml /usr/local/hadoop/etc/hadoop/
COPY conf/hdfs-site.xml /usr/local/hadoop/etc/hadoop/

#namenode format
RUN /usr/local/hadoop/bin/hdfs namenode -format

#habse configure
RUN mv /usr/local/hbase/conf/hbase-env.sh /usr/local/hbase/conf/hbase-env.sh.old \
    && mv /usr/local/hbase/conf/hbase-site.xml /usr/local/hbase/conf/hbase-site.xml.old

COPY conf/hbase* /usr/local/hbase/conf/
COPY start_service.sh /root/start_service.sh
RUN chmod a+x /root/start_service.sh

#SSH port
EXPOSE 22
# HDFS ports
EXPOSE 9000 50010 50020 50070 50075 50090 50475

# YARN ports
EXPOSE 8030 8031 8032 8033 8040 8042 8060 8088 50060

#hbase ports
EXPOSE 60010 60000 60030 60020 8080

CMD "/root/start_service.sh"; "bash"