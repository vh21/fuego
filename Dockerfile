# ==============================================================================
# WARNING: containter created from this image should be run with userdata mounted at /userdata inside docker fs
# ==============================================================================

FROM debian:jessie
MAINTAINER dmitrii.cherkasov@cogentembedded.com

# ==============================================================================
# Influential environment variables
# ==============================================================================
ENV INST_FUEGO_ENGINE_PATH /home/jenkins
ENV INST_FUEGO_FRONTEND_PATH /var/lib/jenkins
ENV INST_FUEGO_CORE_GIT_REVISION c71e42e2d000cd16b7181af4e2b020800479f654
# URL_PREFIX sets Jenkins URL --prefix note: no trailing "/" at the end!
ENV URL_PREFIX /fuego

# ==============================================================================
# Prepare basic image
# ==============================================================================
WORKDIR /fuego-install
RUN dpkg --add-architecture i386
RUN echo deb http://ftp.us.debian.org/debian jessie main non-free >> /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -yV install apt-utils daemon gcc make python-paramiko python-lxml python-simplejson python-matplotlib libtool xmlstarlet autoconf automake rsync openjdk-7-jre openjdk-7-jdk iperf netperf netpipe-tcp texlive-latex-base sshpass wget git sudo net-tools vim openssh-server curl inotify-tools
RUN /bin/bash -c 'echo "dash dash/sh boolean false" | debconf-set-selections ; DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash'
COPY frontend-install/jenkins_1.509.2_all.deb /fuego-install/
RUN dpkg -i /fuego-install/jenkins_1.509.2_all.deb
RUN /bin/bash -c 'wget -nv "http://downloads.sourceforge.net/project/getfo/texml/texml-2.0.2/texml-2.0.2.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fgetfo%2F&ts=1398789654&use_mirror=sunet" -O texml.tar.gz ; tar xvf texml.tar.gz; cd texml-2.0.2 ; python setup.py install; cd -'
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# ==============================================================================
# Install debian armhf cross toolchain
# ==============================================================================

COPY fuego-scripts/install-arm-linux-gnueabihf-toolchain.sh /fuego-install/
RUN bash /fuego-install/install-arm-linux-gnueabihf-toolchain.sh

# ==============================================================================
# get Fuego core via git
# ==============================================================================

RUN mkdir -p /home/jenkins
RUN git clone https://cogentembedded@bitbucket.org/cogentembedded/fuego-core.git $INST_FUEGO_ENGINE_PATH/fuego && cd $INST_FUEGO_ENGINE_PATH/fuego && git reset --hard $INST_FUEGO_CORE_GIT_REVISION && cd /fuego-install
RUN ln -s $INST_FUEGO_ENGINE_PATH/fuego/engine/* $INST_FUEGO_ENGINE_PATH/
RUN ln -s $INST_FUEGO_ENGINE_PATH/fuego/jobs $INST_FUEGO_FRONTEND_PATH/jobs


COPY docs $INST_FUEGO_FRONTEND_PATH/userContent/docs/

# ==============================================================================
# copy a miscelaneous Fuego script
# ==============================================================================
COPY fuego-scripts/maintain_config_link.sh /usr/local/bin/

# ==============================================================================
# Init userdata
# ==============================================================================

RUN ln -s /userdata/buildzone $INST_FUEGO_ENGINE_PATH/buildzone
RUN ln -s /userdata/work $INST_FUEGO_ENGINE_PATH/work
RUN ln -s /userdata/logs $INST_FUEGO_ENGINE_PATH/logs 
RUN ln -s /userdata/logs $INST_FUEGO_FRONTEND_PATH/logs

RUN ln -s /userdata/conf/boards $INST_FUEGO_ENGINE_PATH/overlays/boards
RUN ln -s /userdata/conf/config.xml $INST_FUEGO_FRONTEND_PATH/config.xml
RUN ln -s /userdata/conf/tools.sh $INST_FUEGO_ENGINE_PATH/scripts/tools.sh
#RUN mkdir $INST_FUEGO_ENGINE_PATH/logs/logruns

# ==============================================================================
# Initialize Jenkins plugin configs
# ==============================================================================

RUN ln -s $INST_FUEGO_ENGINE_PATH/fuego/plugins-conf/scriptler $INST_FUEGO_FRONTEND_PATH/
RUN ln -s $INST_FUEGO_ENGINE_PATH/fuego/plugins-conf/sidebar-link.xml $INST_FUEGO_FRONTEND_PATH/

COPY frontend-install/jenkins.cfg /etc/default/jenkins
COPY fuego-scripts/subsitute_jen_url_prefix.sh /fuego-install/
RUN /fuego-install/subsitute_jen_url_prefix.sh /etc/default/jenkins

# ==============================================================================
# Install Jenkins UI updates
# ==============================================================================

RUN chown -R jenkins  $INST_FUEGO_ENGINE_PATH $INST_FUEGO_FRONTEND_PATH /var/cache/jenkins /etc/default/jenkins
COPY frontend-install/plugins $INST_FUEGO_FRONTEND_PATH/
COPY frontend-install/jenkins-updates /fuego-install/jenkins-updates
RUN /fuego-install/subsitute_jen_url_prefix.sh /fuego-install/jenkins-updates
WORKDIR /fuego-install/jenkins-updates
RUN echo "installing custom UI updates"
RUN /etc/init.d/jenkins start && ./updates.sh
RUN ln -s $INST_FUEGO_ENGINE_PATH/logs $INST_FUEGO_FRONTEND_PATH/userContent/fuego.logs

RUN ln -s $INST_FUEGO_ENGINE_PATH/fuego/jobs/tests.info $INST_FUEGO_FRONTEND_PATH/userContent/tests.info

# ==============================================================================
# Setup daemons config
# ==============================================================================

COPY container-cfg/sshd_config /etc/ssh/sshd_config
COPY fuego-scripts/user-setup.sh /fuego-install/
RUN /fuego-install/user-setup.sh

# ==============================================================================
# Clear workspace
# ==============================================================================

WORKDIR /home/jenkins


# ==============================================================================
# Setup startup command
# ==============================================================================
COPY fuego-scripts /
COPY fuego-scripts/fuego-start-cmd.sh /etc/
CMD /etc/fuego-start-cmd.sh

