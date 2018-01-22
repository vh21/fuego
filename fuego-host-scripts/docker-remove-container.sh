#!/bin/bash
# $1 - name for the docker container (default: fuego-container)
DOCKERCONTAINER=${1:-fuego-container}

sudo docker rm ${DOCKERCONTAINER}
