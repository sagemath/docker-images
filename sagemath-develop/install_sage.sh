#!/bin/bash

number_cores=$(cat /proc/cpuinfo | grep processor | wc -l)

export SAGE_FAT_BINARY="yes"
export MAKE="make -j${number_cores}"


cd /opt
sudo git clone --depth 1 --branch develop https://github.com/sagemath/sage.git
sudo chown -R sage:sage /opt/sage

cd sage
make

