# ==============================================================================
# WARNING: this Dockerfile assumes that the container will be created with
# several volume bind mounts (see docker-create-container.sh)
# ==============================================================================

FROM debian:jessie
MAINTAINER tim.bird@am.sony.com

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
RUN if [ -n "$HTTP_PROXY" ]; then echo 'Acquire::http::proxy "'$HTTP_PROXY'";' > /etc/apt/apt.conf.d/80proxy; fi
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -yV install \
	apt-utils daemon gcc make python-paramiko python-lxml python-simplejson \
	python-matplotlib python-serial python-yaml python-openpyxl python-requests \
	libtool xmlstarlet autoconf automake rsync openjdk-7-jre openjdk-7-jdk iperf \
	netperf netpipe-tcp sshpass wget git diffstat sudo net-tools vim curl \
	inotify-tools g++ bzip2 bc libaio-dev gettext pkg-config libglib2.0-dev \
	time
RUN /bin/bash -c 'echo "dash dash/sh boolean false" | debconf-set-selections ; DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash'
RUN if [ -n "$HTTP_PROXY" ]; then echo "use_proxy = on" >> /etc/wgetrc; fi

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
# Serial Config
# ==============================================================================

RUN /bin/bash -c 'git clone "https://github.com/frowand/serio" ;  chown -R jenkins serio ; cd serio ; cp serio /usr/local/bin/ ; ln -s /usr/local/bin/serio /usr/local/bin/sercp ; ln -s /usr/local/bin/serio /usr/local/bin/sersh ; cd -'

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

RUN service jenkins start && \
	sleep 30 && \
	sudo -u jenkins java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/fuego install-plugin description-setter && \
	sudo -u jenkins java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/fuego install-plugin pegdown-formatter

RUN ln -s /fuego-rw/logs $JENKINS_HOME/userContent/fuego.logs
COPY frontend-install/plugins/flot-plotter-plugin/flot.hpi $JENKINS_HOME/plugins/
COPY docs/fuego-docs.pdf $JENKINS_HOME/userContent/docs/fuego-docs.pdf

RUN ln -s /fuego-core/engine/scripts/ftc /usr/local/bin/
RUN ln -s /fuego-ro/scripts/nodes/fuego-create-node /usr/local/bin/
RUN ln -s /fuego-ro/scripts/nodes/fuego-delete-node /usr/local/bin/
RUN ln -s /fuego-ro/scripts/jobs/fuego-create-jobs /usr/local/bin/
RUN ln -s /fuego-ro/scripts/jobs/fuego-delete-jobs /usr/local/bin/
COPY frontend-install/config.xml $JENKINS_HOME/config.xml

RUN chown -R jenkins:jenkins $JENKINS_HOME/

# ==============================================================================
# Setup startup command
# ==============================================================================

ENTRYPOINT service jenkins start && /bin/bash
