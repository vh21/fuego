#!/bin/bash

# Usage subsitute_jen_url_prefix.sh <catalogue>

if [ -z ${URL_PREFIX+x} ]; then
    echo "URL_PREFIX variable is not defined" >&3
    exit 1
fi

if [ -z ${1+x} ]; then
    echo "Plese call with catalogue or filename as first argument" >&3
    exit 1
fi

echo "Subsituting WEBROOT_PREFIX_PLACEHOLDER -> $URL_PREFIX in $1"

if [[ -d "$1" ]]; then
    find $1 -type f -exec sed -i -e "s#WEBROOT_PREFIX_PLACEHOLDER#$URL_PREFIX#g" {} \;
else
    sed -i -e "s#WEBROOT_PREFIX_PLACEHOLDER#$URL_PREFIX#g" $1
fi

if [ $? -ne 0 ]; then
    echo "Error: No substitutions done in $1" >&3
    exit 1
fi

  
