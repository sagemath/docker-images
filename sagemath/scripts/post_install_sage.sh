#!/bin/bash
# Additional setup to perform after building and installing Sage
# This is broken out into a separate script so it can be run as
# a separate step in the Dockerfile without performing a full
# rebuild.  This script is run as the 'sage' user.

SAGE_SRC_TARGET=${1%/}
if [ -z $SAGE_SRC_TARGET ]; then
  >&2 echo "Must specify a target directory for the sage source checkout"
  exit 1
fi

# Put scripts to start gap, gp, maxima, ... in /usr/bin
sudo sage --nodotsage -c "install_scripts('/usr/bin')"

# Setup the admin password for Sage's lecacy notebook to avoid need for later
# user interaction
# This should also be run as the 'sage' user to ensure that the resulting
# configuration is written to their DOT_SAGE
sage <<EOFSAGE
    from sage.misc.misc import DOT_SAGE
    from sagenb.notebook import notebook
    directory = DOT_SAGE+'sage_notebook'
    nb = notebook.load_notebook(directory)
    nb.user_manager().add_user('admin', 'sage', '', force=True)
    nb.save()
    quit
EOFSAGE

# Install additional Python packages into the sage Python distribution...
# Install terminado for terminal support in the Jupyter Notebook
# Upgrade Jupyter notebook to 5.x
# Install additional Jupyter kernels
sage -pip install \
    terminado \
    'notebook>=5' \
    'ipykernel>=4.6'

sage -i \
    gap_jupyter \
    singular_jupyter \
    pari_jupyter


# Generate the sage-entrypoint.sh script which sets the sage environment for
# all commands run in the container; first we output 'set' in the default
# environment, then 'set' in the sage environment and take only those settings
# that are added by the sage environment
bash -c set | sort > /tmp/orig_env.txt
sage -sh -c set | sort > /tmp/sage_env.txt
envvars=$(diff /tmp/orig_env.txt /tmp/sage_env.txt | grep '^> ' | grep -v '^SHLVL=\|^_=' | cut -d' ' -f2-)
envvars=$(echo "$envvars" | sed 's/^/export /')
cat > "$SAGE_SRC_TARGET/sage/local/bin/sage-entrypoint.sh" <<_EOF_
#!/bin/bash
${envvars}
exec "\$@"
_EOF_
chmod +x "$SAGE_SRC_TARGET/sage/local/bin/sage-entrypoint.sh"
rm -f /tmp/*_env.txt
sudo ln -s "$SAGE_SRC_TARGET/sage/local/bin/sage-entrypoint.sh" /usr/local/bin/sage-entrypoint
