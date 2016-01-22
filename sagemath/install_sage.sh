#!/bin/bash

number_cores=$(cat /proc/cpuinfo | grep processor | wc -l)

export SAGE_FAT_BINARY="yes"
export MAKE="make -j${number_cores}"


cd /opt
sudo wget http://www-ftp.lip6.fr/pub/math/sagemath/src/sage-7.0.tar.gz
sudo tar -xf sage-7.0.tar.gz
sudo rm sage-7.0.tar.gz
sudo chown -R sage:sage /opt/sage-7.0
sudo ln -sf sage-7.0 sage

cd sage
make