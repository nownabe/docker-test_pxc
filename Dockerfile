FROM centos:centos6
MAINTAINER nownabe

RUN yum -y update
RUN echo 'root:p@ssw0rd' | chpasswd

## Setup SSH
RUN yum install -y openssh-server
RUN sed -ri 's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
RUN mkdir -p /root/.ssh
RUN chmod 700 /root/.ssh
ADD id_rsa.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh
RUN [[ ! -f /etc/ssh/ssh_host_rsa_key ]] && service sshd start && service sshd stop

## Setup Supervisor for SSH
RUN yum install -y python-setuptools
RUN easy_install supervisor
ADD supervisord.conf /etc/supervisord.conf

## Setup Percona XtraDB Cluster
RUN rpm -ivh http://ftp.riken.jp/Linux/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -ivh http://www.percona.com/redir/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
RUN yum install -y compat-readline5 which
RUN yum install -y Percona-XtraDB-Cluster-55
ADD my.cnf /etc/my.cnf

## Port
EXPOSE 22 3306 4444 4567 4568

CMD ["/usr/bin/supervisord"]

