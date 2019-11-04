#!/bin/bash
#
# install.sh [--help] [--priv] [--no-cache] [--nojenkins] [<image_name>] [<port>]
#

# $1 is the exit code after usage is shown
usage() {
    exit_code="$1"
    cat <<HERE
Usage: install.sh [--help] [--priv] [--no-cache]
                  [--jenkins <no|install|prebuilt>] [--jenkins-url <url>]
                  [<image_name>]
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
 --no-cache Don't use cache when creating the docker image
 --jenkins <install|prebuilt|no>
            install: Creates a docker image and container with Jenkins
           prebuilt: Creates a docker image and container with externally
                     prebuilt Jenkins
                 no: Creates a docker image and container without Jenkins
 --jenkins-url <url>
           enkins url when select "--jenkins=install|prebuilt". Only port is
           used in 'install' case.
HERE
    exit $exit_code
}

if [ -n "$1" ]; then
    if [ "$1" = "--help" -o "$1" = "-h" ]; then
        usage 0
    fi
fi

priv=0
NOCACHE=""
dockerfile="Dockerfile"
JENKINS="install"
JENKINS_URL="http://localhost:8090/"

POSITIONAL=()
while [[ $# -gt 0 ]] ; do
  case $1 in
    --priv)
      priv=1
      shift
      ;;
    --no-cache)
      NOCACHE="--no-cache"
      shift
      ;;
    --jenkins)
      JENKINS="$2"
      shift 2
      ;;
    --jenkins-url)
      JENKINS_URL="$2"
      shift 2
      ;;
    --)
      shift
      ;;
    *)
      POSITIONAL+=("$1") # save argument for later
      shift
  esac
done

jenkins_info=`echo $JENKINS_URL|awk -F '[/:]' '{print $5}'`
if [ "$JENKINS" == "no" ]; then
  dockerfile="Dockerfile.nojenkins"
elif [[ "$JENKINS" == "prebuilt" ]]; then
  dockerfile="Dockerfile.jenkins-prebuilt"
  jenkins_info=${JENKINS_URL:-http://localhost:8090}
fi

set -- "${POSITIONAL[@]}" # restore positional arguments

image_name=${1:-fuego}
container_name="${image_name}-container"

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

set -e

source fuego-host-scripts/docker-build-image.sh $NOCACHE ${image_name} ${jenkins_info} ${dockerfile}
if [ "$priv" == "0" ]; then
    fuego-host-scripts/docker-create-container.sh ${image_name} ${container_name}
else
    fuego-host-scripts/docker-create-usb-privileged-container.sh ${image_name} ${container_name}
fi

# copy host's ttc.conf file (if present) into the fuego configuration directory
sudo /bin/sh -c "if [ -f /etc/ttc.conf -a ! -f fuego-ro/conf/ttc.conf ] ; then cp /etc/ttc.conf fuego-ro/conf/ttc.conf ; fi"

echo "Docker container '${container_name}' is ready with Fuego installation."
echo "To start, run: ./start.sh ${container_name}"
