#!/bin/bash
#############################################################################
# Builds a Docker image that includes the necessary dependencies for Fathom.
#############################################################################
set -eu

# Primary group of user.
GID=$(id -g)
PROG_NAME=$(basename $0)
PWS_IMAGE=${PWS_IMAGE:-movidiusbuild}
export STEM_ROOT="${STEM_ROOT:-}"
TMP_ROOT=""

declare -a EXPORT_VARS=("GID" "TIMEZONE" "UID" "USER" )

function fatal() { printf "*** ${PROG_NAME}: %s\n" "$@"; exit 1; }

#[ -n ${STEM_ROOT} ] || fatal "\$STEM_ROOT not defined"
#[ -d ${STEM_ROOT} ] || fatal "Directory \$STEM_ROOT ($STEM_ROOT) not found"


##############################################################################
# Displays help/usage.
# Globals:
#   PROG_NAME
# Arguments:
#  None
# Returns:
#   None
##############################################################################
function show_usage() {
  cat <<-__END_HELP__
Usage: ${PROG_NAME} [<options>]

Builds a Docker container which supports Fathom development by
including necessary dependencies.

--clean         : Clean build directory, but do not build.
--help|-h       : Display this help message.

__END_HELP__
}



##############################################################################
# Configures script.
# Globals:
#   SRC_ASSETS_DIR
#   TIMEZONE
# Arguments:
#   Command line params.
# Returns:
#   None
##############################################################################
function setup() {
  while [ $# -gt 0 ]; do
    case $1 in
      --help|-h) show_usage ; exit 1 ;;
      -*) fatal " Unsupported option: $1" ;;
      *) break ;;
    esac
    shift
  done

  TIMEZONE=$(date +%Z)
}


##############################################################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   Command line params.
# Returns:
#   None
##############################################################################
function main() {
  local key
  local value
  local pwd
  umask a+rwx

  setup "$@"
  pwd=$PWD; 
  cd /tmp
  TMP_ROOT="/tmp/$(mktemp -d build-pws-XXXXXXXX)"
  cd $pwd
  printf "(TMP_ROOT=%s)\n" "${TMP_ROOT}"
  mkdir -p ${TMP_ROOT}/bin ${TMP_ROOT}/assets

  cp -ar ./assets ${TMP_ROOT}
  chmod a+r ${TMP_ROOT}/assets/*
  chmod a-x ${TMP_ROOT}/assets/*
  cp ./pws-bin/* ${TMP_ROOT}/bin
  chmod a+rx ${TMP_ROOT}/bin/*
  cp ./config/Dockerfile.template ${TMP_ROOT}/Dockerfile
  cd ${TMP_ROOT}
  ls -lg assets ${TMP_ROOT}/assets/* ${TMP_ROOT}/bin ${TMP_ROOT}

  # Copy contents (if any) of var directory into temporary directory that
  for f in `ls ./assets | sort -r`; do
    echo "COPY asset $f"
    sed -i "/PLACEHOLDER_COPY_VAR_FILES/a COPY assets\/$f \/opt\/pws\/var\/assets" \
           Dockerfile
  done
    

  # Copy contents (if any) of bin directory
  for f in `ls ./bin | sort -r`; do
    sed -i "/PLACEHOLDER_COPY_BIN_FILES/a COPY bin\/$f \/opt\/pws\/bin" Dockerfile
  done

  for key in "${EXPORT_VARS[@]}"; do
    set +u
    value="${!key}"
    value="${value//\//\\/}"
    set -u
    sed -i "/PLACEHOLDER_SET_ENV_VARIABLES/a ENV ${key}=${value}" Dockerfile
    sed -i "/PLACEHOLDER_SET_ENV_VARIABLES/a ENV echo \"${key}=${value}\" >> /etc/bash.bashrc" Dockerfile
    sed -i "s/__${key}__/${value}/g" Dockerfile
  done

  if [ -n "${HTTP_PROXY}" ]; then
    echo $PWD
    ls -lg
    printf "Acquire::http::Proxy \"%s/\";\n" "${HTTP_PROXY}" > ./assets/apt.conf
    printf "Acquire::https::Proxy \"%s/\";\n" "${HTTPS_PROXY}" >> ./assets/apt.conf
    sed -i "/PLACEHOLDER_COPY_APT_CONF/a COPY assets\/apt.conf \/etc\/apt\/apt.conf" Dockerfile
  fi

  # Build the Docker image.
  #docker build -t "${PWS_IMAGE}"  .
  docker build -t "${PWS_IMAGE}"
    
  # If the Docker image name is of the form  <URI>/<name>, then push
  # it to the appropriate Docker respository.
  if [[ "${PWS_IMAGE}" =~ / ]]; then
    docker push "${PWS_IMAGE}"
  fi
}
    

main "$@"
# rm -Rf ${TMP_ROOT}
