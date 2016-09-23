# fuego toolchain script
# this sets up the environment needed for fuego to use a toolchain
# this includes the following variables:
# CC, CXX, CPP, CXXCPP, CONFIGURE_FLAGS, AS, LD, ARCH
# CROSS_COMPILE, PREFIX, HOST, SDKROOT
# CFLAGS and LDFLAGS are optional
# 
# this script is sourced by /userdata/conf/tools.sh

export PREFIX=arm-linux-gnueabihf
export CC=${PREFIX}-gcc
export CXX=${PREFIX}-g++
export CONFIGURE_FLAGS="--target=${PREFIX} --host=arm-linux-gnueabihf --build=x86_64-linux"
export AS=${PREFIX}-as
export LD=${PREFIX}-ld
export AR=${PREFIX}-ar
export RANLIB=${PREFIX}-ranlib
export ARCH=arm
export CROSS_COMPILE=${PREFIX}-
HOST=arm-linux

# save original path, to get to non-toolchain version of python
ORIG_PATH=$PATH
unset PYTHONHOME
env -u PYTHONHOME
