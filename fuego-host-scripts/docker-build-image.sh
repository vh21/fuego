#!/bin/bash
# $1 - name for the docker image (default: fuego)
# $2 - port for jenkins (default: 8080)
# $3 - Dockerfile or Dockerfile.nojenkins
#
# Example:
#  ./fuego-host-scripts/docker-build-image.sh myfuegoimg 8082 Dockerfile.nojenkins
#
DOCKERIMAGE=${1:-fuego}
JENKINS_PORT=${2:-8080}
DOCKERFILE=${3:-Dockerfile}

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

echo "Using Port $JENKINS_PORT"

sudo docker build ${NO_CACHE} -t ${DOCKERIMAGE} --build-arg HTTP_PROXY=$http_proxy \
	--build-arg uid=$JENKINS_UID --build-arg gid=$JENKINS_GID \
	--build-arg JENKINS_PORT=$JENKINS_PORT -f $DOCKERFILE .
