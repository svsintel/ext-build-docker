#!/bin/bash
##############################################################################
# Installs common dependencies for NN architecture development on Ubuntu 16.04
##############################################################################

set -u
WORK_DIR=$(mktemp -d)

function _finally() { rm -Rf "${WORK_DIR}"; } 


##############################################################################
# Downloads & installs git LFS support.
# Globals:
#   WORK_DIR
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function install_git_lfs() {
    local opt_proxy=""

#    [ -n "${http_proxy}" ] && opt_proxy="--proxy $http_proxy"
    cd $WORK_DIR
    # git-lfs install has a bug: it expects to run inside a git repository.
    # Download a minimal git repository and run the git lfs installer inside it.
    
    # Clone command complains about redirecting http to https.
    # That is ok: cloning https fails,
    git clone http://github.com/githubtraining/hellogitworld.git || exit 1
    wget -q  https://github.com/git-lfs/git-lfs/releases/download/v1.5.6/git-lfs-linux-amd64-1.5.6.tar.gz || exit 1
    cd hellogitworld
    tar -xf ../git-lfs-linux-amd64-1.5.6.tar.gz > /dev/null
    cd git-lfs-1.5.6
    sed -i 's/^\s*install /sudo install /' install.sh
    sed -i 's/^git lfs install$/git lfs install --local/' install.sh
    ./install.sh

    # Install encrypted .netrc credential helper.
#*    curl ${opt_proxy} -o ~/.local/bin/git-credential-netrc https://raw.githubusercontent.com/git/git/master/contrib/credential/netrc/git-credential-netrc

}
  


##############################################################################
# Main script enty point.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function main() {
    local f
    local linaro_file="gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz" 
    trap _finally EXIT
    install_git_lfs
    /opt/pws/bin/pws-install-machine-learning-frameworks.sh
    pip3 install tensorpack opencv-python
    pip3 uninstall -y numpy==1.17.0 || true
    pip3 install  numpy==1.16.4 || true
    pip3 uninstall -y networkx || true
    pip3 install networkx==2.3
    mkdir -p /opt/pws/assets
    ls -lg /opt/pws/var/assets; bash
    if [ -f "/opt/pws/var/assets/${linaro_file}" ]; then
        cp "/opt/pws/var/assets/${linaro_file}" /opt/pws/assets
    fi

    # wget -q   https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz
    # ls && chmod a+r *

    mkdir -p /opt/pws/var/home/original

    # /home/$USER will be mounted and content will not be accessible.
    # Move content elsewhere so it can be accessed later.
    for f in `ls -a ${HOME}| egrep -v '^\.\.*$'`; do
        echo "Move $f to /opt/pws/var/home/original."
        mv  ${HOME}/$f /opt/pws/var/home/original
    done
}


main "$@"

