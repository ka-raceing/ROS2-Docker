#!/bin/bash
# Container entrypoint of ghcr.io/ka-raceing/ros2-driverless.
#
# Runs as root. If HOST_UID / HOST_GID are set and differ from the image user's ids, the image
# user is re-numbered so that files on bind mounts keep the host's ownership (the car runs the
# stack as uid 1001, laptops usually as 1000). Then privileges are dropped and control passes to
# the ROS entrypoint, which sources /opt/ros/jazzy/setup.bash and execs the command.
set -euo pipefail

user="${DRIVERLESS_USER:-as}"
home="/home/${user}"

fail() {
    echo "entrypoint: $*" >&2
    exit 1
}

remap_user() {
    local host_uid="$1" host_gid="$2"
    local cur_uid cur_gid group owner
    cur_uid="$(id -u "${user}")"
    cur_gid="$(id -g "${user}")"
    group="$(id -gn "${user}")"

    if [[ "${host_uid}" == "${cur_uid}" && "${host_gid}" == "${cur_gid}" ]]; then
        return
    fi

    if owner="$(getent passwd "${host_uid}" | cut -d: -f1)" && [[ -n "${owner}" && "${owner}" != "${user}" ]]; then
        fail "HOST_UID=${host_uid} is already used by user '${owner}'"
    fi
    if owner="$(getent group "${host_gid}" | cut -d: -f1)" && [[ -n "${owner}" && "${owner}" != "${group}" ]]; then
        fail "HOST_GID=${host_gid} is already used by group '${owner}'"
    fi

    echo "entrypoint: re-mapping ${user} from ${cur_uid}:${cur_gid} to ${host_uid}:${host_gid}" >&2
    groupmod -g "${host_gid}" "${group}"
    # usermod -u re-owns the whole home tree and does not stop at bind mounts, so park the home
    # elsewhere for the id change and fix ownership below without crossing mount points.
    usermod -d /nonexistent "${user}"
    usermod -u "${host_uid}" -g "${host_gid}" "${user}"
    usermod -d "${home}" "${user}"
    # Fix ownership of what the image gave to the user. -xdev keeps bind mounts untouched.
    find "${home}" "${ACADOS_SOURCE_DIR:-/opt/acados}" "${ACADOS_PYTHON_ENV:-/opt/acados-venv}" -xdev \
        \( -uid "${cur_uid}" -o -gid "${cur_gid}" \) -exec chown -h "${host_uid}:${host_gid}" {} +
}

if [[ "$(id -u)" -ne 0 ]]; then
    # Started with --user or via docker exec as a non-root user: nothing to re-map.
    exec /ros_entrypoint.sh "$@"
fi

if [[ -n "${HOST_UID:-}" || -n "${HOST_GID:-}" ]]; then
    [[ "${HOST_UID:-}" =~ ^[0-9]+$ ]] || fail "HOST_UID must be numeric (got '${HOST_UID:-}')"
    HOST_GID="${HOST_GID:-${HOST_UID}}"
    [[ "${HOST_GID}" =~ ^[0-9]+$ ]] || fail "HOST_GID must be numeric (got '${HOST_GID}')"
    remap_user "${HOST_UID}" "${HOST_GID}"
fi

export HOME="${home}" USER="${user}" LOGNAME="${user}"
exec setpriv --reuid="${user}" --regid="${user}" --init-groups -- /ros_entrypoint.sh "$@"
