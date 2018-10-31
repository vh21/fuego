#!/bin/bash
#
# start.sh [<container-name>]
#

if [ -n "$1" ]; then
    if [ "$1" = "--help" -o "$1" = "-h" ]; then
        cat <<HERE
Usage: start.sh [--help] [<container_name>]

Start the docker container which contains the Fuego test system.
If no <container_name> is provided, start one named 'fuego-container'.

options:
 --help   Show usage help
HERE
        exit 0
    fi
fi

container_name="${1:-fuego-container}"

set -e

fuego-host-scripts/docker-start-container.sh ${container_name}
