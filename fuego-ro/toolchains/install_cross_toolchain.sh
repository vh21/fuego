#!/bin/bash
# $1: architecture (e.g.: arm64 armel armhf mips mipsel powerpc ppc64el)

if [ -z ${1+x} ]; then
    ARCH=armhf
else
    ARCH=$1
fi

echo deb http://emdebian.org/tools/debian/ jessie main > /etc/apt/sources.list.d/crosstools.list
dpkg --add-architecture $ARCH
curl http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | sudo apt-key add -
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -yV install crossbuild-essential-$ARCH

# libaio is needed for LTP
DEBIAN_FRONTEND=noninteractive apt-get -yV install libaio-dev:$ARCH
