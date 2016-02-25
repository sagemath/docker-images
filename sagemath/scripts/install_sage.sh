#!/bin/bash
# !!!NOTE!!! This script is intended to be run with root privileges
# It will run as the 'sage' user when the time is right.
SAGE_SRC_TARGET=${1%/}
BRANCH=$2

if [ -z $SAGE_SRC_TARGET ]; then
  >&2 echo "Must specifiy a target directory for the sage source checkout"
  exit 1
fi

if [ -z $BRANCH ]; then
  >&2 echo "Must specify a branch to build"
  exit 1
fi

N_CORES=$(cat /proc/cpuinfo | grep processor | wc -l)

export SAGE_FAT_BINARY="yes"
export MAKE="make -j${N_CORES}"
cd "$SAGE_SRC_TARGET"
git clone --depth 1 --branch ${BRANCH} https://github.com/sagemath/sage.git
chown -R sage:sage sage
cd sage

# Sage can't be built as root, for reasons...
# Here -E inherits the environment from root, however it's important to
# include -H to set HOME=/home/sage, otherwise DOT_SAGE will not be set
# correctly and the build will fail!
sudo -H -E -u sage make || exit 1

# Put scripts to start gap, gp, maxima, ... in /usr/bin
./sage --nodotsage -c "install_scripts('/usr/bin')"

# Add aliases for sage and sagemath
ln -sf "${SAGE_SRC_TARGET}/sage/sage" /usr/bin/sage
ln -sf "${SAGE_SRC_TARGET}/sage/sage" /usr/bin/sagemath

# Setup the admin password for Sage's lecacy notebook to avoid need for later
# user interaction
# This should also be run as the 'sage' user to ensure that the resulting
# configuration is written to their DOT_SAGE
sudo -H -u sage ./sage <<EOFSAGE
    from sage.misc.misc import DOT_SAGE
    from sagenb.notebook import notebook
    directory = DOT_SAGE+'sage_notebook'
    nb = notebook.load_notebook(directory)
    nb.user_manager().add_user('admin', 'sage', '', force=True)
    nb.save()
    quit
EOFSAGE

# Clean up artifacts from the sage build that we don't need for runtime or
# running the tests
#
# Unfortunately none of the existing make targets for sage cover this ground
# exactly
make misc-clean
make -C src/ clean
rm -rf upstream/
rm -rf src/doc/output/doctrees/
