#!/bin/bash
echo deb http://emdebian.org/tools/debian/ jessie main > /etc/apt/sources.list.d/crosstools.list
dpkg --add-architecture armhf
curl http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | sudo apt-key add -
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -yV install crossbuild-essential-armhf
