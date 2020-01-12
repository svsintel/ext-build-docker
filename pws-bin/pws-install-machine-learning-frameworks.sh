#!/bin/bash
#######################################################################
# Install TensorFlow, SSD Caffe, and RefineDet Caffe.
######################################################################

# Exit on any failure.
set -x
# Exit if unitialized variable used.
set -u
# A temporary work directory.
WORK_DIR=$(mktemp -d)


##############################################################################
# Tidies up (eg removes temporary files) at end of script.
# Globals:
#   WORK_DIR
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function _finally() { 
  [ -n "${WORK_DIR}" ] && rm -Rf "${WORK_DIR}" 
}


##############################################################################
# Extracts installer from NCSDK archive and installs Caffe and Tensorflow.
# Globals:
#   WORK_DIR
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function setup() {
  cd ${WORK_DIR}
  # Extract the NCSDK from its archive.
  printf "TARNC $(pwd); $(ls /opt/pws/var/assets/)"
  
  tar -xf /opt/pws/var/assets/Neural_Compute_v2.10.00.04.tar.gz 
  
  # Customize the NCSDK installer to install the required packages.
  
  # Tweak: do not want to install MDK toolkit.
  sed -i s'/INSTALL_TOOLKIT=yes/INSTALL_TOOLKIT=no/'  Neural_Compute_v2.10.00.04/ncsdk/ncsdk.conf 
  
  # Tweak: get over spurious pip module check failure.
  sed -i '395iRC=0' Neural_Compute_v2.10.00.04/ncsdk/install.sh
  
  # Tweak: installer only supports Ubuntu 16.04 but need to install Caffe in Ubuntu 18.04
  sed -i 's/1604/1804/' Neural_Compute_v2.10.00.04/ncsdk/install.sh
  
  # Tweak: git clone https:// does not work inside installer.
  sed -i 's/CAFFE_SRC="https:\/\/github.com/CAFFE_SRC="http:\/\/github.com/' Neural_Compute_v2.10.00.04/ncsdk/install.sh
  
  # Tweak: Add support for a RefineDet Caffe version.
  sed -i '578i        elif [ "${CAFFE_FLAVOR}" = "RefineDet" ]; then\n        CAFFE_SRC="http://github.com/sfzhang15/RefineDet.git"\n        CAFFE_VER=""\n        CAFFE_DIR=RefineDet-caffe\n        CAFFE_BRANCH=""' Neural_Compute_v2.10.00.04/ncsdk/install.sh
  sed -i '497i         sed -i "s/^add_subdirectory(examples)/## add_subdirectory(examples)/" CMakeLists.txt'  Neural_Compute_v2.10.00.04/ncsdk/install.sh
  sed -i '497i         sed -i "s/^add_subdirectory(docs)/## add_subdirectory(docs)/" CMakeLists.txt'  Neural_Compute_v2.10.00.04/ncsdk/install.sh
  
  # The final version of Caffe installed becomes the default version.
  # The default version is whatever the symbolic link /opt/movidius/caffe points to.
  
  # Tweak: set RefineDet as version of Caffe to install.
  sed -i s'/CAFFE_FLAVOR=.*/CAFFE_FLAVOR=RefineDet/'  Neural_Compute_v2.10.00.04/ncsdk/ncsdk.conf 
  
  cat Neural_Compute_v2.10.00.04/ncsdk/ncsdk.conf
  # Install RefineDet Caffe, TensorFlow and dependencies.
  cd Neural_Compute_v2.10.00.04/ncsdk && make install
  cd ${WORK_DIR}
  
  # Tweak: set SSD as version of Caffe to install.
  sed -i s'/CAFFE_FLAVOR=.*/CAFFE_FLAVOR=ssd/'  Neural_Compute_v2.10.00.04/ncsdk/ncsdk.conf 
  
  # Install SSD Caffe.
  cat Neural_Compute_v2.10.00.04/ncsdk/ncsdk.conf
  cd Neural_Compute_v2.10.00.04/ncsdk && make install
  cd ${WORK_DIR}

  # Install specific libs for Fathom
  pip3 install numpy==1.16.4 scipy==1.2.0 scikit-image==0.14.2 ordered_set metis --user scikit-learn
  pip3 install tensorflow==1.12
}



##############################################################################
# Script main entry point.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function main() {
  trap _finally EXIT
  setup "$@"
}


main "$@"

