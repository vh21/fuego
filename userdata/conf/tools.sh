# Copyright (c) 2014 Cogent Embedded, Inc.

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# DESCRIPTION
# This script defines (or calls env. setup script) build variables for ${PLATFORM}


function export_tools () {
    AS=$PREFIX-as
    CC=$PREFIX-gcc
    AR=$PREFIX-ar
    RANLIB=$PREFIX-ranlib
    CXX=$PREFIX-g++
    CPP=$PREFIX-cpp
    CXXCPP=$PREFIX-cpp
    LD=$PREFIX-ld
    #LDFLAGS="--sysroot ${SDKROOT} -lm"
}

if [ "${PLATFORM}" = "intel-minnow" ];
then
        SDKROOT=$JTA_ENGINE_PATH/tools/intel-minnow/sysroots/core2-32-osv-linux/
        # environment script changes PATH in the way that python uses libs from sysroot which is not what we want, so save it and use later
        ORIG_PATH=$PATH
        PREFIX=i586-osv-linux
        source $JTA_ENGINE_PATH/tools/intel-minnow/environment-setup-core2-32-osv-linux

        HOST=arm-osv-linux-gnueabi
        
        unset PYTHONHOME
        env -u PYTHONHOME

elif [ "${PLATFORM}" = "renesas-arm" ];
then
        SDKROOT=$JTA_ENGINE_PATH/tools/renesas-arm/sysroots/cortexa15hf-vfp-neon-osv-linux-gnueabi
        # environment script changes PATH in the way that python uses libs from sysroot which is not what we want, so save it and use later
        ORIG_PATH=$PATH
        PREFIX=arm-osv-linux-gnueabi
        source $JTA_ENGINE_PATH/tools/renesas-arm/environment-setup-cortexa15hf-vfp-neon-osv-linux-gnueabi
	
        HOST=arm-osv-linux-gnueabi
        
        unset PYTHONHOME
        env -u PYTHONHOME
elif [ "${PLATFORM}" = "qemu-armv7hf" ];
then
    export CC=arm-linux-gnueabihf-gcc
    export CXX=arm-linux-gnueabihf-g++
    export CXX=arm-linux-gnueabihf-g++
    export CONFIGURE_FLAGS="--target=arm-linux-gnueabihf --host=arm-linux-gnueabihf --build=x86_64-linux"
    export AS=arm-linux-gnueabihf-as
    export LD=arm-linux-gnueabihf-ld
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabihf-
    export PREFIX=arm-linux-gnueabihf-

    # environment script changes PATH in the way that python uses libs from sysroot which is not what we want, so save it and use later

    ORIG_PATH=$PATH
    HOST=arm-linux

    unset PYTHONHOME
    env -u PYTHONHOME
fi
