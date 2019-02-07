#!/bin/bash
# $1 - name for the docker image (default: fuego)
# $2 - name for the docker container (default: fuego-container)

DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))

DOCKERIMAGE=${1:-fuego}
DOCKERCONTAINER=${2:-fuego-container}

if [ ! -d $DIR/../fuego-core ]; then
   echo "You need to clone fuego-core at $DIR/../fuego-core"
   exit 1
fi

sudo docker create -it --name ${DOCKERCONTAINER} \
    --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /boot:/boot:ro \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /dev/ttyACM0:/dev/ttyACM0 \
    -v /dev/ttyACM1:/dev/ttyACM1 \
    -v /dev/ttyUSB0:/dev/ttyUSB0 \
    -v /dev/serial:/dev/serial \
    -v $DIR/../fuego-rw:/fuego-rw \
    -v $DIR/../fuego-ro:/fuego-ro:ro \
    -v $DIR/../fuego-core:/fuego-core:ro \
    --env no_proxy="$no_proxy" \
    --net="host" ${DOCKERIMAGE} || \
    echo "Could not create fuego-container. See error messages."
