#!/bin/bash
# $1 - name for the docker image (default: fuego)
DOCKERIMAGE=${1:-fuego}

sudo docker rmi ${DOCKERIMAGE}
