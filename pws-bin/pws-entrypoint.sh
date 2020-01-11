#!/bin/bash
CUR_USER=$USER
CUR_UID=$(id -u)
CUR_GID=$(id -g)
user=${WANT_USER:-$CUR_USER}
uid=${WANT_UID:-$CUR_UID}
gid=${WANT_GID:-$CUR_GID}
WANT_LOGIN=${WANT_LOGIN:-no}
WANT_DEBUG="${WANT_DEBUG:-yes}"
LOGIN=""
[[ "${WANT_LOGIN}" == "yes" ]] && LOGIN="-i"
LOGIN_OPTS=""
#* START_MESH_CMD="/opt/pws/bin/pws-start-mesh-agent.sh"

[[ "${user}" == "testuser" ]] || LOGIN_OPTS="sudo -E -H -g #${gid} -u ${user} ${LOGIN}"
[[ "${WANT_DEBUG}" == "yes" ]] && printf "User info: UID=%s GID=%d USERNAME=%s LOGIN_OPTS=%s\n" ${uid} ${gid} "${user}" "${LOGIN_OPTS}"

if [[ "${UID}" != 0 ]]; then
    if ! $(getent group ${gid} > /dev/null); then
        sudo groupadd -g ${gid} "${user}"
    fi

    if ! $(getent passwd ${user} > /dev/null) ; then
        sudo useradd -u ${uid} -g ${gid} -m  -s /bin/bash ${user}
        sudo bash -c "echo '$user  ALL=(ALL)    NOPASSWD:ALL' >> /etc/sudoers.d/extra"
    fi
    if [[ ! -f /home/$user/.firststime.ok ]]; then
        if [[ -d /opt/pws/var/home/original ]]; then
            (cd /opt/pws/var/home/original; sudo tar --owner=$user --group=:${gid} -cf - .) | sudo tar xf - -C /home/${user}
        fi
        sudo -E touch /home/${user}/.firststime.ok
    fi
fi

export UID=${uid}
export GID=${gid}
export WANT_DEBUG
cd /home/${user}
export PATH=$HOME/.local/bin:$PATH

# Need sync point when starting Docker container via Jenkins as latter runs initial
# test command but does not wait for it to complete before running next command
# (it expects particular output and aborts when it does not see it - a plugin bug).
# The Jenkins standard job runner script can then wait until the following file
# appears (meaning entrypoint initialization has completed) before continuing.
touch /home/${user}/.pws-entrypoint.ready

if [ "$#" -gt 0 ]; then
    ${LOGIN_OPTS} /bin/bash -c  "$*"
else
    ${LOGIN_OPTS} /bin/bash
fi

