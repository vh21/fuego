# ==============================================================================
# WARNING: this Dockerfile assumes that the container will be created with
# several volume bind mounts (see docker-create-container.sh)
# ==============================================================================

FROM debian:jessie
MAINTAINER tim.bird@sony.com

# ==============================================================================
# Proxy variables
# ==============================================================================

ARG HTTP_PROXY
ENV http_proxy ${HTTP_PROXY}
ENV https_proxy ${HTTP_PROXY}

# ==============================================================================
# Prepare basic image
# ==============================================================================

WORKDIR /
RUN echo deb http://httpredir.debian.org/debian jessie main non-free > /etc/apt/sources.list
RUN echo deb http://httpredir.debian.org/debian jessie-updates main non-free >> /etc/apt/sources.list
RUN echo deb http://security.debian.org/ jessie/updates main >> /etc/apt/sources.list
RUN if [ -n "$HTTP_PROXY" ]; then echo 'Acquire::http::proxy "'$HTTP_PROXY'";' > /etc/apt/apt.conf.d/80proxy; fi
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -yV install \
	apt-utils daemon gcc make cmake python-paramiko python-lxml python-simplejson \
	python-matplotlib python-serial python-yaml python-openpyxl python-requests \
	python-reportlab libtool xmlstarlet autoconf automake rsync openjdk-7-jre openjdk-7-jdk \
	iperf netperf netpipe-tcp sshpass wget git diffstat sudo net-tools vim curl \
	inotify-tools g++ bzip2 bc libaio-dev gettext pkg-config libglib2.0-dev \
	time python-pip python-xmltodict at minicom lzop bsdmainutils u-boot-tools \
	mc netcat lava-tool openssh-server python-parsedatetime \
	libsdl1.2-dev libcairo2-dev libxmu-dev libxmuu-dev iperf3

RUN pip install python-jenkins==0.4.14
RUN pip install filelock
RUN pip install flake8
RUN /bin/bash -c 'echo "dash dash/sh boolean false" | debconf-set-selections ; DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash'
RUN if [ -n "$HTTP_PROXY" ]; then echo "use_proxy = on" >> /etc/wgetrc; fi
RUN if [ -n "$HTTP_PROXY" ]; then echo -e "http_proxy=$HTTP_PROXY\nhttps_proxy=$HTTP_PROXY" >> /etc/environment; fi

# ==============================================================================
# Install Jenkins with the same UID/GID as the host user
# ==============================================================================

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=${uid}
ARG JENKINS_VERSION=2.32.1
ARG JENKINS_SHA=bfc226aabe2bb089623772950c4cc13aee613af1
ARG JENKINS_URL=https://pkg.jenkins.io/debian-stable/binary/jenkins_${JENKINS_VERSION}_all.deb
ENV JENKINS_HOME=/var/lib/jenkins

RUN groupadd -g ${gid} ${group} \
	&& useradd -l -m -d "${JENKINS_HOME}" -u ${uid} -g ${gid} -G sudo -s /bin/bash ${user}
RUN wget -nv ${JENKINS_URL}
RUN echo "${JENKINS_SHA} jenkins_${JENKINS_VERSION}_all.deb" | sha1sum -c -
RUN dpkg -i jenkins_${JENKINS_VERSION}_all.deb
RUN rm jenkins_${JENKINS_VERSION}_all.deb

# ==============================================================================
# get ttc script and helpers
# ==============================================================================
RUN git clone https://github.com/tbird20d/ttc.git /usr/local/src/ttc
RUN /usr/local/src/ttc/install.sh /usr/local/bin
RUN perl -p -i -e "s#config_dir = \"/etc\"#config_dir = \"/fuego-ro/conf\"#" /usr/local/bin/ttc

# ==============================================================================
# Serial Config
# ==============================================================================

RUN /bin/bash -c 'git clone https://github.com/frowand/serio.git /usr/local/src/serio ;  chown -R jenkins /usr/local/src/serio ; cp /usr/local/src/serio/serio /usr/local/bin/ ; ln -s /usr/local/bin/serio /usr/local/bin/sercp ; ln -s /usr/local/bin/serio /usr/local/bin/sersh'

RUN /bin/bash -c 'git clone https://github.com/tbird20d/serlogin.git /usr/local/src/serlogin ;  chown -R jenkins /usr/local/src/serlogin ; cp /usr/local/src/serlogin/serlogin /usr/local/bin'

# ==============================================================================
# Post installation
# ==============================================================================

RUN source /etc/default/jenkins && \
	JENKINS_ARGS="$JENKINS_ARGS --prefix=/fuego" && \
	sed -i -e "s#JENKINS_ARGS.*#JENKINS_ARGS\=\"${JENKINS_ARGS}\"#g" /etc/default/jenkins

RUN source /etc/default/jenkins && \
	JAVA_ARGS="$JAVA_ARGS -Djenkins.install.runSetupWizard=false" && \
	if [ -n "$HTTP_PROXY" ]; then \
		PROXYSERVER=$(echo $http_proxy | sed -E 's/^http://' | sed -E 's/\///g' | sed -E 's/(.*):(.*)/\1/') && \
		PROXYPORT=$(echo $http_proxy | sed -E 's/^http://' | sed -E 's/\///g' | sed -E 's/(.*):(.*)/\2/') && \
		JAVA_ARGS="$JAVA_ARGS -Dhttp.proxyHost="${PROXYSERVER}" -Dhttp.proxyPort="${PROXYPORT}" -Dhttps.proxyHost="${PROXYSERVER}" -Dhttps.proxyPort="${PROXYPORT}; \
	fi && \
	sed -i -e "s#^JAVA_ARGS.*#JAVA_ARGS\=\"${JAVA_ARGS}\"#g" /etc/default/jenkins;

COPY frontend-install/plugins/flot-plotter-plugin/flot.hpi /tmp

RUN service jenkins start && \
	sleep 30 && \
	sudo -u jenkins java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/fuego install-plugin description-setter && \
	sudo -u jenkins java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/fuego install-plugin pegdown-formatter && \
    sudo -u jenkins java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/fuego install-plugin /tmp/flot.hpi && \
    sleep 10

# Let Jenkins install flot before making the symlink
RUN service jenkins restart && sleep 30 && \
    rm $JENKINS_HOME/plugins/flot/flot/mod.js && \
    ln -s /fuego-core/engine/scripts/mod.js $JENKINS_HOME/plugins/flot/flot/mod.js

RUN ln -s /fuego-rw/logs $JENKINS_HOME/userContent/fuego.logs
COPY docs/fuego-docs.pdf $JENKINS_HOME/userContent/docs/fuego-docs.pdf

RUN ln -s /fuego-core/engine/scripts/ftc /usr/local/bin/
COPY frontend-install/config.xml $JENKINS_HOME/config.xml
COPY frontend-install/jenkins.model.JenkinsLocationConfiguration.xml $JENKINS_HOME/jenkins.model.JenkinsLocationConfiguration.xml

RUN chown -R jenkins:jenkins $JENKINS_HOME/

# ==============================================================================
# Lava
# ==============================================================================

RUN ln -s /fuego-ro/scripts/fuego-lava-target-setup /usr/local/bin
RUN ln -s /fuego-ro/scripts/fuego-lava-target-teardown /usr/local/bin
# CONVENIENCE HACKS
# not mounted, yet
#RUN echo "fuego-create-node --board raspberrypi3" >> /root/firststart.sh
#RUN echo "fuego-create-jobs --board raspberrypi3 --testplan testplan_docker --distrib nosyslogd.dist" >> /root/firststart.sh

RUN echo "deb http://emdebian.org/tools/debian/ jessie main" > /etc/apt/sources.list.d/crosstools.list
RUN dpkg --add-architecture armhf
RUN curl http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | sudo apt-key add -
RUN DEBIAN_FRONTEND=noninteractive apt-get update
# TRB-2018-03-19 - don't automatically install emdebian armhf toolchains
# These are old, and have conflicts with recent Debian package releases.
# Also, users should be encouraged to install the correct toolchain for
# their board.
#RUN DEBIAN_FRONTEND=noninteractive apt-get -yV install crossbuild-essential-armhf cpp-arm-linux-gnueabihf gcc-arm-linux-gnueabihf binutils-arm-linux-gnueabihf

# ==============================================================================
# Setup startup command
# ==============================================================================

ENTRYPOINT service jenkins start && service netperf start && iperf3 -V -s -D -f M && /bin/bash
