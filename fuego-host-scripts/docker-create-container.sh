#!/bin/bash
# $1 - name for the docker image (default: fuego)
# $2 - name for the docker container (default: fuego-container)
# $3 - overrides JENKINS_PORT env variable
#      Additionally you need to change the port on the config manually
#      docker# sed -i -e 's#8080#8082#g' /etc/default/jenkins
#      docker# service jenkins restart

DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))

DOCKERIMAGE=${1:-fuego}
DOCKERCONTAINER=${2:-fuego-container}

if [ -z "${3}" ]; then
    JENKINS_PORT_ENV=""
else
    JENKINS_PORT_ENV="--env JENKINS_PORT=${3}"
fi

if [ ! -d $DIR/../fuego-core ]; then
   echo "You need to clone fuego-core at $DIR/../fuego-core"
   exit 1
fi

sudo docker create -it --name ${DOCKERCONTAINER} \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /boot:/boot:ro \
    -v $DIR/../fuego-rw:/fuego-rw \
    -v $DIR/../fuego-ro:/fuego-ro:ro \
    -v $DIR/../fuego-core:/fuego-core:ro \
    --env no_proxy="$no_proxy" \
    $JENKINS_PORT_ENV \
    --net="host" ${DOCKERIMAGE} || \
    echo "Could not create fuego-container. See error messages."
