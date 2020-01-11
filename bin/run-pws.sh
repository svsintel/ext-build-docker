#!/bin/bash
##############################################################################
# Runs a Docker container which has the dependencies necessary for Fathom
# development already installed.
##############################################################################
set -u

declare -a ENV_ARGS=()
NUM_CONSUMED_ARGS=0
OPT_AUTO_DELETE="--rm"
OPT_PRIVILEGE=""
PROG_NAME=$(basename $0)
PWS_IMAGE=${PWS_IMAGE:-af01p-ir.devtools.intel.com:6560/mvstemdockerrepo-ir-local/mig_ci_u18_ng:stable}
SHARES_DIR="${PWS_SHARES_DIR:-/srv/docker-helper/shares}"
WANT_DEBUG=no
WANT_GID=$(id -g)
WANT_LOGIN=""
WANT_MOUNT_HOME=yes
WANT_UID=$(id -u)
WANT_USER="$USER"
WANT_HOSTNAME=""
MESH_AGENT="no"

function fatal() { printf "*** ${PROG_NAME}: %s\n" "$@"; exit 1; }


##############################################################################
# Displays help/usage.
# Globals:
#   PROG_NAME
# Arguments:
#   None
# Returns:
#   None
##############################################################################
function show_usage() {
  cat <<-__END_HELP__
Usage: ${PROG_NAME} [<options>] [<cmd>]

Starts a Docker container and runs an interactive Bash shell in it.
The container has support for building and running Fathom.

--help|-h       : Display this help message.
--shares=<dir>  : Directory containing directories to mount.
                  Default is /srv/docker-helper/shares
                  Set --shares= to disable.
--user=<username>: Username to run as.
--uid=<UID>     : UID to run as.
--gid=<GID>     : GID to run as.
--debug         : Enable some debug.
--home-mount=no : Do not auto-mount /srv/docker-helper/shares/home/<user> as 
                  home directory.
--mesh-agent    : Start a mesh agent.
--hostname=<name> : Set hostname.
--persist|-p    : Default is to remove the Docker container instance when the
                  interactive shell exits. Saves having to manually remove
                  the stopped container. The perist option prevents this,
                  allowing the container to be restarted at a later time. 
                  However, the container must then be removed manually.

--privilege|-P  : Grant the user privileged access.

[<cmd>]         : Instead of starting an interactive Bash shell, run the
                  specified command. Notes that changes will not persist when
                  the command ends (except to \$HOME).
                      
__END_HELP__

}


##############################################################################
# Configures script.
# Globals:
#   OPT_AUTO_DELETE
#   OPT_PRIVILEGE
# Arguments:
#   Command line params.
# Returns:
#   None
##############################################################################
function setup() {
  local env_arg
  # Parse command line options. Assume anything with a hyphen prefix is a
  # command line option and that the first parameter without a prefix narks
  # the start of a command line to be executed inside the container.
  while [ $# -gt 0 ]; do
    case $1 in
      --debug) WANT_DEBUG="yes" ;;
      --env=*) env_arg="${1#*=}" ; ENV_ARGS+=(" $env_arg") ;;
      --gid=*) WANT_GID="${1#*=}" ;;
      --help|-h) show_usage ; exit 1 ;;
      --login=*) WANT_LOGIN="${1#*=}" ;;
      --mount-home=no) WANT_MOUNT_HOME=no; ;;
      --persist|-p) OPT_AUTO_DELETE="" ;;
      --mesh-agent) MESH_AGENT=yes ;;
      --privilege|-P) OPT_PRIVILEGE="--privileged" ;;
      --shares=*) SHARES_DIR="${1#*=}" ;;
      --hostname=*) WANT_HOSTNAME="${1#*=}" ;;
      --uid=*) WANT_UID="${1#*=}" ;;
      --user=*) WANT_USER="${1#*=}" ;;
      -*) fatal "Unsupported option: $1" ;;
      *) break ;;
    esac
    shift
    (( ++NUM_CONSUMED_ARGS ))
  done
  if [ -n "${SHARES_DIR}" ]; then
    [ -d "${SHARES_DIR}" ] || fatal "Media directory (${SHARES_DIR}) not found."
  fi
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
  local inject_home_mounts=""
  local home_mount=""
  local hostname_opt=""
  local t
  local d
  local mounts=""
  local env_args=""
  local want_user=""
  setup "$@"
    
  # Skip the command line args already consumed during setup.
  for (( ; NUM_CONSUMED_ARGS > 0; --NUM_CONSUMED_ARGS )); do
    shift
  done

  if [ -n "${SHARES_DIR}" ]; then
    abs_mount_dir="$(readlink -f ${SHARES_DIR})"
    # find -L : accept symlinks to directories too. 
    for d in `cd ${abs_mount_dir} && find -L . -maxdepth 1  -type d | egrep [a-zA-Z0-9_]`; do
      d=${d#./}
      d_prefix=${d%.*}
      d_suffix=${d#*.}
      [ "${d_suffix}" == "ro" ] || d_suffix="rw"

      if [ "$d_prefix" == "home" ]; then
        if [[ "${WANT_MOUNT_HOME}" == "yes" &&  -d ${abs_mount_dir}/$d/${WANT_USER} ]]; then
          echo "Mount home: ${abs_mount_dir}/$d/${WANT_USER}"
          home_mount="-v ${abs_mount_dir}/$d/${WANT_USER}:/home/${WANT_USER}"
        fi
      else
        mounts+=" -v ${abs_mount_dir}/$d:/opt/pws/mnt/$d_prefix:$d_suffix"
      fi
    done
  fi
  if [ "${#ENV_ARGS[@]}" -gt 0 ]; then
    # TODO: escape env args
    for i in "${ENV_ARGS[@]}"; do
      env_args+=" -e $i"
    done
  fi
  env_args+=" -e WANT_DEBUG=${WANT_DEBUG}"
  env_args+=" -e WANT_GID=${WANT_GID}"
  env_args+=" -e WANT_LOGIN=${WANT_LOGIN}"
  env_args+=" -e WANT_MOUNT_HOME=${WANT_MOUNT_HOME}"
  env_args+=" -e WANT_UID=${WANT_UID}"
  env_args+=" -e WANT_USER=${WANT_USER}"
  env_args+=" -e MESH_AGENT=${MESH_AGENT}"
  printf "(%s)\n" "${PWS_IMAGE}"
  [[ -n "${WANT_HOSTNAME}" ]] && hostname_opt="-h ${WANT_HOSTNAME}"

#        --net=host 
  docker run ${OPT_AUTO_DELETE}  ${OPT_PRIVILEGE} \
    ${env_args} \
    ${home_mount} \
    ${hostname_opt} \
    ${mounts} \
    --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
    -v /dev:/dev \
    -ti ${PWS_IMAGE} $@
}


main "$@"
