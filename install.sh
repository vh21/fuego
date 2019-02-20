#!/bin/bash
#
# install.sh [--help] [--priv] [<image_name>] [<port>]
#

if [ -n "$1" ]; then
    if [ "$1" = "--help" -o "$1" = "-h" ]; then
        cat <<HERE
Usage: install.sh [--help] [--priv] [<image_name>] [<port>]

Create the docker image and container with the Fuego test distribution.
If no <image_name> is provided, the image will be named 'fuego'.
The container name will be: '<image-name>-container'.
  (default: 'fuego-container')

options:
 --help   Show usage help
 --priv   Create a privileged container, that can access serial ports
          and USB devices.  This may be needed if you have tests or
          test infrastructure that requires access to serial and usb
          devices.
HERE
        exit 0
    fi
fi

priv=0
if [ "$1" = "--priv" ]; then
    priv=1
    shift
fi

# get fuego-core repository, if not already present
if [ ! -f fuego-core/scripts/ftc ] ; then
    # set fuego-core branch to same as current fuego branch
    # get current git branch
    set -o noglob
    while IFS=" " read -r part1 part2 ; do
        if [ $part1 = "*" ] ; then
            branch=$part2
        fi
    done < <(git branch)
    set +o noglob
    git clone -b $branch https://bitbucket.org/fuegotest/fuego-core.git
fi

image_name=${1:-fuego}
jenkins_port=${2:-8080}
container_name="${image_name}-container"

set -e

source fuego-host-scripts/docker-build-image.sh ${image_name} ${jenkins_port}
if [ "$priv" == "0" ]; then
    fuego-host-scripts/docker-create-container.sh ${image_name} ${container_name}
else
    fuego-host-scripts/docker-create-usb-privileged-container.sh ${image_name} ${container_name}
fi

# copy host's ttc.conf file (if present) into the fuego configuration directory
sudo /bin/sh -c "if [ -f /etc/ttc.conf -a ! -f fuego-ro/conf/ttc.conf ] ; then cp /etc/ttc.conf fuego-ro/conf/ttc.conf ; fi"

echo "Docker container '${container_name}' is ready with Fuego installation."
echo "To start, run: ./start.sh ${container_name}"
