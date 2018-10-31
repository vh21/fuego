#!/bin/bash
#
# install.sh [<image-name>] [--priv]
#

if [ -n "$1" ]; then
    if [ "$1" = "--help" -o "$1" = "-h" ]; then
        cat <<HERE
Usage: install.sh [--help] [--priv] [<image_name>]

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

image_name=${1:-fuego}
container_name="${image_name}-container"

set -e

source fuego-host-scripts/docker-build-image.sh ${image_name}
if [ "$priv" == "0" ]; then
    fuego-host-scripts/docker-create-container.sh ${image_name} ${container_name}
else
    fuego-host-scripts/docker-create-usb-privileged-container.sh ${image_name} ${container_name}
fi

# copy host's ttc.conf file (if present) into the fuego configuration directory
sudo /bin/sh -c "if [ -f /etc/ttc.conf -a ! -f fuego-ro/conf/ttc.conf ] ; then cp /etc/ttc.conf fuego-ro/conf/ttc.conf ; fi"

echo "Docker container '${container_name}' is ready with Fuego installation."
echo "To start, run: ./start.sh ${container_name}"
