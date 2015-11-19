#!/bin/bash
CONTAINER_ID=`sudo docker ps -l -q`
echo "trying to start $CONTAINER_ID"
sudo docker start --interactive=true --attach=true $CONTAINER_ID
