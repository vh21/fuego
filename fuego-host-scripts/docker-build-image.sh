#!/bin/bash
# $1 - name for the docker image (default: fuego)
# $2 - port for jenkins (default: 8090)
# $3 - Dockerfile or Dockerfile.nojenkins
#
# Example:
#  ./fuego-host-scripts/docker-build-image.sh --no-cache myfuegoimg 8082 Dockerfile.nojenkins
#
if [ "$1" = "--no-cache" ]; then
	NO_CACHE=--no-cache
	shift
fi

DOCKERIMAGE=${1:-fuego}
JENKINS_PORT=${2:-8090}
DOCKERFILE=${3:-Dockerfile}

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
