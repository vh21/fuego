#!/bin/bash
# $1 - name for the docker image (default: fuego)
DOCKERIMAGE=${1:-fuego}

# uncomment this to avoid using the docker cache while building
# (for testing)
#NO_CACHE=--no-cache

if [ "$(id -u)" == "0" ]; then
	JENKINS_UID=$(id -u $SUDO_USER)
	JENKINS_GID=$(id -g $SUDO_USER)
else
	JENKINS_UID=$(id -u $USER)
	JENKINS_GID=$(id -g $USER)
fi

sudo docker build ${NO_CACHE} -t ${DOCKERIMAGE} --build-arg HTTP_PROXY=$http_proxy --build-arg uid=$JENKINS_UID --build-arg gid=$JENKINS_GID .
