# ==============================================================================
# WARNING: containter created from this image should be run with userdata mounted at /userdata inside docker fs
# ==============================================================================

FROM debian:jessie
MAINTAINER dmitrii.cherkasov@cogentembedded.com

ENV INST_JTA_ENGINE_PATH /home/jenkins
ENV INST_JTA_FRONTEND_PATH /var/lib/jenkins

# ==============================================================================
# Prepare basic image
# ==============================================================================
WORKDIR /jta-install

RUN dpkg --add-architecture i386
RUN echo deb http://ftp.us.debian.org/debian jessie main non-free >> /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -yV install apt-utils daemon gcc make python-paramiko python-lxml python-simplejson python-matplotlib libtool xmlstarlet autoconf automake rsync openjdk-7-jre openjdk-7-jdk iperf netperf netpipe-tcp texlive-latex-base sshpass wget git sudo net-tools vim openssh-server
RUN /bin/bash -c 'echo "dash dash/sh boolean false" | debconf-set-selections ; DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash'
COPY frontend-install/jenkins_1.509.2_all.deb /jta-install/
RUN dpkg -i /jta-install/jenkins_1.509.2_all.deb
RUN /bin/bash -c 'wget -nv "http://downloads.sourceforge.net/project/getfo/texml/texml-2.0.2/texml-2.0.2.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fgetfo%2F&ts=1398789654&use_mirror=sunet" -O texml.tar.gz ; tar xvf texml.tar.gz; cd texml-2.0.2 ; python setup.py install; cd -'
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# ==============================================================================
# get JTA core via git
# ==============================================================================
RUN mkdir -p /home/jenkins
RUN echo lsls
RUN git clone https://cogentembedded@bitbucket.org/cogentembedded/jta-core.git $INST_JTA_ENGINE_PATH/jta
RUN ln -s $INST_JTA_ENGINE_PATH/jta/engine/* $INST_JTA_ENGINE_PATH/
RUN ln -s $INST_JTA_ENGINE_PATH/jta/jobs $INST_JTA_FRONTEND_PATH/jobs

COPY frontend-install/jenkins.cfg /etc/default/jenkins
COPY docs/jta-docs.pdf $INST_JTA_FRONTEND_PATH/jta-docs.pdf

# ==============================================================================
# init userdata
# ==============================================================================

RUN ln -s /userdata/buildzone $INST_JTA_ENGINE_PATH/buildzone
RUN ln -s /userdata/work $INST_JTA_ENGINE_PATH/work
RUN ln -s /userdata/logs $INST_JTA_ENGINE_PATH/logs 
RUN ln -s /userdata/logs $INST_JTA_FRONTEND_PATH/logs

RUN ln -s /userdata/conf/boards $INST_JTA_ENGINE_PATH/overlays/boards
RUN ln -s /userdata/conf/config.xml $INST_JTA_FRONTEND_PATH/config.xml
RUN ln -s /userdata/conf/tools.sh $INST_JTA_ENGINE_PATH/scripts/tools.sh
#RUN mkdir $INST_JTA_ENGINE_PATH/logs/logruns

# ==============================================================================
# Install Jenkins UI updates
# ==============================================================================

RUN chown -R jenkins  $INST_JTA_ENGINE_PATH $INST_JTA_FRONTEND_PATH /var/cache/jenkins /etc/default/jenkins
COPY frontend-install/plugins $INST_JTA_FRONTEND_PATH/
COPY frontend-install/jenkins-updates /jta-install/jenkins-updates
WORKDIR /jta-install/jenkins-updates
RUN echo "installing custom UI updates"
RUN /etc/init.d/jenkins start && ./updates.sh

RUN ln -s $INST_JTA_ENGINE_PATH/logs $INST_JTA_FRONTEND_PATH/userContent/jta.logs
