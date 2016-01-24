#!/bin/bash

cd /opt/sage

# Put scripts to start gap, gp, maxima, ... in /usr/bin
sudo sage --nodotsage -c "install_scripts('/usr/bin')"

# Add aliases for sage and sagemath
sudo ln -sf /opt/sage/sage /usr/bin/sage
sudo ln -sf /opt/sage/sage /usr/bin/sagemath

# Setup the admin password for Sage's lecacy notebook to avoid need for later user interaction
./sage <<EOFSAGE
    from sage.misc.misc import DOT_SAGE
    from sagenb.notebook import notebook
    directory = DOT_SAGE+'sage_notebook'
    nb = notebook.load_notebook(directory)
    nb.user_manager().add_user('admin', 'sage', '', force=True)
    nb.save()
    quit
EOFSAGE
