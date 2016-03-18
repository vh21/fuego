#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

CONTAINER_ID_FILE="$DIR/../last_fuego_container.id"

if [[ -f "$CONTAINER_ID_FILE" ]]
then
    CONTAINER_ID=`cat $CONTAINER_ID_FILE`
    echo "Starting Fuego container $CONTAINER_ID"
    sudo docker start --interactive=true --attach=true $CONTAINER_ID
else
    echo "Please create Fuego docker container via docker-create-container.sh script"
fi
