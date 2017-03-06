#!/bin/bash
# $1 - name for the docker container (default: fuego-container)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

DOCKERCONTAINER=${1:-fuego-container}

echo "Starting Fuego container (fuego-container)"
sudo docker start --interactive=true --attach=true ${DOCKERCONTAINER} || \
  echo "Please create Fuego docker container via docker-create-container.sh script"
