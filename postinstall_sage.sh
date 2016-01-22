#!/bin/bash

sudo ./sage --nodotsage <<EOFSAGE
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

sudo ln -sf /opt/sage/sage /usr/bin/sagemath