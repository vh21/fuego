#!/bin/bash
# 2019 (c) Toshiba corp. <daniel.sangorrin@toshiba.co.jp>
#
# Usage:
#  $ sudo ./install-debian.sh [--help|-h] [--nojenkins] [<port>]
#
if [ -n "$1" ]; then
	if [ "$1" = "--help" -o "$1" = "-h" ]; then
		cat <<HERE
Usage: sudo ./install-debian.sh [--help|-h] [--nojenkins] [<port>]

Installs fuego on the host Debian filesystem.

options:
 --help       Show usage help
 --nojenkins  Install Fuego without Jenkins
HERE
		exit 0
	fi
fi

if [[ $EUID -ne 0 ]]; then
	echo "Sorry, you need root permissions"
	exit 1
fi

if [ "$1" = "--nojenkins" ]; then
	nojenkins=1
	shift
else
	nojenkins=0
	port=${1:-8080}
fi

# ==============================================================================
# Install Fuego dependencies
# ==============================================================================

# netperf is in non-free
echo deb http://deb.debian.org/debian stretch main non-free > /etc/apt/sources.list
echo deb http://security.debian.org/debian-security stretch/updates main >> /etc/apt/sources.list

apt-get update

# Fuego python dependencies
apt-get -yV install \
	python-lxml python-simplejson python-yaml python-openpyxl \
	python-requests python-reportlab python-parsedatetime \
	python-pip
pip install filelock

# Fuego command dependencies
apt-get -yV install \
	git sshpass openssh-client sudo net-tools wget curl lava-tool \
	bash-completion

# Default SDK for testing locally or on an x86 board
apt-get -yV install \
	gcc g++ make cmake bison flex autoconf automake libtool \
	libelf-dev libssl-dev libsdl1.2-dev libcairo2-dev libxmu-dev \
	libxmuu-dev libglib2.0-dev libaio-dev u-boot-tools pkg-config

# Default test host dependencies
apt-get -yV install \
	iperf iperf3 netperf bzip2 bc python-matplotlib python-xmltodict
pip install flake8

echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
if [ -n "$http_proxy" ]; then
	sed -i -e 's/#use_proxy = on/use_proxy = on/g' /etc/wgetrc
	echo -e "http_proxy=$http_proxy\nhttps_proxy=$https_proxy" >> /etc/environment
fi

# ==============================================================================
# Clone fuego and fuego-core
# ==============================================================================
if [ ! -d "/fuego" ]; then
	cd /
	git clone --branch next --depth=1 https://bitbucket.org/nirrognas/fuego.git
	ln -s /fuego/fuego-ro /fuego-ro
	ln -s /fuego/fuego-rw /fuego-rw
	cd fuego
	git clone --branch next --depth=1 https://bitbucket.org/nirrognas/fuego-core.git
	ln -s /fuego/fuego-core /fuego-core
fi

# ==============================================================================
# Install Jenkins
# ==============================================================================

if [ $nojenkins -eq 0 ]; then
	JENKINS_VERSION=2.32.1
	JENKINS_SHA=bfc226aabe2bb089623772950c4cc13aee613af1
	JENKINS_URL=https://pkg.jenkins.io/debian-stable/binary/jenkins_${JENKINS_VERSION}_all.deb
	JENKINS_HOME=/var/lib/jenkins
	JENKINS_PORT=$port

	# Jenkins dependencies
	apt-get -yV install \
		default-jdk daemon psmisc adduser procps unzip
	pip install python-jenkins==0.4.14

	echo -e "JENKINS_PORT=$JENKINS_PORT" >> /etc/environment
	groupadd jenkins
	useradd -l -m -d "${JENKINS_HOME}" -g jenkins -G sudo -s /bin/bash jenkins
	cd
	wget ${JENKINS_URL}
	echo "${JENKINS_SHA} jenkins_${JENKINS_VERSION}_all.deb" | sha1sum -c -

	# allow Jenkins to start and install plugins, as part of dpkg installation
	printf "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d
	dpkg -i jenkins_${JENKINS_VERSION}_all.deb
	rm jenkins_${JENKINS_VERSION}_all.deb

	# update ownership
	chown -R jenkins:jenkins /fuego
	chown -R jenkins:jenkins /fuego-ro
	chown -R jenkins:jenkins /fuego-rw
	chown -R jenkins:jenkins /fuego-core

	source /etc/default/jenkins && \
		JENKINS_ARGS="$JENKINS_ARGS --prefix=/fuego" && \
		sed -i -e "s#JENKINS_ARGS.*#JENKINS_ARGS\=\"${JENKINS_ARGS}\"#g" /etc/default/jenkins

	source /etc/default/jenkins && \
		JAVA_ARGS="$JAVA_ARGS -Djenkins.install.runSetupWizard=false" && \
		if [ -n "$http_proxy" ]; then \
			PROXYSERVER=$(echo $http_proxy | sed -E 's/^http://' | sed -E 's/\///g' | sed -E 's/(.*):(.*)/\1/') && \
			PROXYPORT=$(echo $http_proxy | sed -E 's/^http://' | sed -E 's/\///g' | sed -E 's/(.*):(.*)/\2/') && \
			JAVA_ARGS="$JAVA_ARGS -Dhttp.proxyHost="${PROXYSERVER}" -Dhttp.proxyPort="${PROXYPORT}" -Dhttps.proxyHost="${PROXYSERVER}" -Dhttps.proxyPort="${PROXYPORT}; \
		fi && \
		sed -i -e "s#^JAVA_ARGS.*#JAVA_ARGS\=\"${JAVA_ARGS}\"#g" /etc/default/jenkins;

	sed -i -e "s#8080#$JENKINS_PORT#g" /etc/default/jenkins

	cp /fuego/frontend-install/install-plugins.sh \
		/fuego/frontend-install/jenkins-support \
		/fuego/frontend-install/clitest \
		/usr/local/bin/

	cp /fuego/frontend-install/config.xml $JENKINS_HOME/config.xml
	ln -s /fuego-rw/logs $JENKINS_HOME/userContent/fuego.logs
	mkdir $JENKINS_HOME/userContent/docs
	cp /fuego/docs/fuego-docs.pdf $JENKINS_HOME/userContent/docs/fuego-docs.pdf
	jenkins cp /fuego/frontend-install/jenkins.model.JenkinsLocationConfiguration.xml $JENKINS_HOME/jenkins.model.JenkinsLocationConfiguration.xml
	sed -i -e "s#8080#$JENKINS_PORT#g" $JENKINS_HOME/jenkins.model.JenkinsLocationConfiguration.xml
	chown -R jenkins:jenkins $JENKINS_HOME/

	# install flot.hpi manually from local file
	service jenkins start && \
		sleep 30 && \
		sudo -u jenkins java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar \
			-s http://localhost:$JENKINS_PORT/fuego install-plugin \
			/fuego/frontend-install/plugins/flot-plotter-plugin/flot.hpi && \
		sleep 10 && \
		service jenkins stop

	# install other plugins from Jenkins update center
	# NOTE: not sure all of these are needed, but keep list
	# compatible with 1.2.1 release for now
	/usr/local/bin/install-plugins.sh ant:1.7 \
		bouncycastle-api:2.16.2 \
		description-setter:1.10 \
		display-url-api:2.1.0 \
		external-monitor-job:1.7 \
		greenballs:1.15 \
		icon-shim:2.0.3 \
		javadoc:1.4 \
		junit:1.21 \
		ldap:1.17 \
		mailer:1.20 \
		matrix-auth:1.7 \
		matrix-project:1.12 \
		antisamy-markup-formatter:1.5 \
		pam-auth:1.3 \
		pegdown-formatter:1.3 \
		script-security:1.35 \
		structs:1.10 \
		windows-slaves:1.3.1

	# make the mod.js symlink well after flot is installed
	service jenkins start && sleep 30 && \
		rm $JENKINS_HOME/plugins/flot/flot/mod.js && \
		ln -s /fuego-core/scripts/mod.js $JENKINS_HOME/plugins/flot/flot/mod.js

	chown -R jenkins:jenkins $JENKINS_HOME/
else
	sed -i -e 's/jenkins_enabled=1/jenkins_enabled=0/g' /fuego-ro/conf/fuego.conf
fi

# ==============================================================================
# get ttc script and helpers
# ==============================================================================
git clone https://github.com/tbird20d/ttc.git /usr/local/src/ttc
/usr/local/src/ttc/install.sh /usr/local/bin
perl -p -i -e "s#config_dir = \"/etc\"#config_dir = \"/fuego-ro/conf\"#" /usr/local/bin/ttc

# ==============================================================================
# Serial Config
# ==============================================================================
if [ $nojenkins -eq 0 ]; then
	/bin/bash -c 'git clone https://github.com/frowand/serio.git /usr/local/src/serio ;  chown -R jenkins /usr/local/src/serio ; cp /usr/local/src/serio/serio /usr/local/bin/ ; ln -s /usr/local/bin/serio /usr/local/bin/sercp ; ln -s /usr/local/bin/serio /usr/local/bin/sersh'
	/bin/bash -c 'git clone https://github.com/tbird20d/serlogin.git /usr/local/src/serlogin ;  chown -R jenkins /usr/local/src/serlogin ; cp /usr/local/src/serlogin/serlogin /usr/local/bin'
else
	/bin/bash -c 'git clone https://github.com/frowand/serio.git /usr/local/src/serio ;  cp /usr/local/src/serio/serio /usr/local/bin/ ; ln -s /usr/local/bin/serio /usr/local/bin/sercp ; ln -s /usr/local/bin/serio /usr/local/bin/sersh'
	/bin/bash -c 'git clone https://github.com/tbird20d/serlogin.git /usr/local/src/serlogin ;  cp /usr/local/src/serlogin/serlogin /usr/local/bin'
fi

# ==============================================================================
# fserver
# ==============================================================================
git clone https://github.com/tbird20d/fserver.git /usr/local/lib/fserver
ln -s /usr/local/lib/fserver/start_local_bg_server /usr/local/bin/start_local_bg_server

# ==============================================================================
# ftc post installation
# ==============================================================================
ln -s /fuego-core/scripts/ftc /usr/local/bin/
cp /fuego-core/scripts/ftc_completion.sh /etc/bash_completion.d/ftc
echo ". /etc/bash_completion" >> /root/.bashrc

# ==============================================================================
# Lava
# ==============================================================================
ln -s /fuego-ro/scripts/fuego-lava-target-setup /usr/local/bin
ln -s /fuego-ro/scripts/fuego-lava-target-teardown /usr/local/bin

# ==============================================================================
# Small guide
# ==============================================================================
echo "Run 'service netperf start' to start a netperf server"
echo "Run 'iperf3 -V -s -D -f M' to start an iperf3 server"
echo "Run 'ftc list-boards' to see the available boards"
echo "Run 'ftc list-tests' to see the available tests"
echo "Run 'ftc run-test -b local -t Functional.hello_world' to run a hello world"
echo "Run 'ftc run-test -b local -t Benchmark.Dhrystone -s 500M' to run Dhrystone"
echo "Run 'ftc gen-report' to get results"
