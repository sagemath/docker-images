#!/bin/bash

number_cores=$(cat /proc/cpuinfo | grep processor | wc -l)

export SAGE_FAT_BINARY="yes"
export MAKE="make -j${number_cores}"


cd /opt
sudo git clone --depth 1 --branch develop https://github.com/sagemath/sage.git
sudo chown -R sage:sage /opt/sage

cd sage
make

sudo ./sage <<EOFSAGE
    install_scripts("/usr/bin")
EOFSAGE

./sage <<EOFSAGE
    from sage.misc.misc import DOT_SAGE
    from sagenb.notebook import notebook
    directory = DOT_SAGE+'sage_notebook'
    nb = notebook.load_notebook(directory)
    nb.user_manager().add_user('admin', 'sage', '', force=True)
    nb.save()
    quit
EOFSAGE

sudo ln -sf /opt/sage/sage /usr/bin/sage
sudo ln -sf /opt/sage/sage /usr/bin/sagemath
