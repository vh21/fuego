# fuego toolchain script
# this sets up the environment needed for fuego to use a toolchain
# this includes the following variables:
# CC, CXX, CPP, CXXCPP, CONFIGURE_FLAGS, AS, LD, ARCH
# CROSS_COMPILE, PREFIX, HOST, SDKROOT
# CFLAGS and LDFLAGS are optional
#
# this script should be sourced by ${FUEGO_RO}/toolchains/tools.sh

PREFIX=aarch64-linux-gnu
SDKROOT=/usr/$PREFIX
export_tools

# avoid "could not find -lm" errors
LDFLAGS=
