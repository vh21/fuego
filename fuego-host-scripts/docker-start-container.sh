#!/bin/bash
# $1 - name for the docker container (default: fuego-container)
DOCKERCONTAINER=${1:-fuego-container}

echo "Starting Fuego container (${DOCKERCONTAINER})"
sudo docker start --interactive=true --attach=true ${DOCKERCONTAINER} || \
  echo "Please create Fuego docker container via docker-create-container.sh script"
