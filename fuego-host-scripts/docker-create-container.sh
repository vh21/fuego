#!/bin/bash
# $1 - name for the docker image (default: fuego)
# $2 - name for the docker container (default: fuego-container)

DIR=$(realpath "${BASH_SOURCE[0]}")

DOCKERIMAGE=${1:-fuego}
DOCKERCONTAINER=${2:-fuego-container}

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
    --net="host" ${DOCKERIMAGE} || \
    echo "Could not create fuego-container. See error messages."
