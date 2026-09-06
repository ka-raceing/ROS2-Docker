#!/bin/bash
# Container entrypoint of ghcr.io/ka-raceing/ros2-driverless.
#
# 1. As root: if HOST_UID (and optionally HOST_GID, defaulting to HOST_UID) is set and differs from
#    the image user `as` (uid/gid 1000 at build time), renumber `as` so files on bind mounts keep the
#    host's ownership (the car runs as 1001). Then drop privileges by re-executing this script as `as`.
# 2. As `as`: source ROS and, when DRIVERLESS_WS is set and built, the workspace, then exec the
#    command. `docker exec` does not pass through here; ~/.bashrc sources the same two files for
#    interactive shells. For a one-off command from outside:
#        docker compose exec -u as car /usr/local/bin/entrypoint.sh ros2 topic list
#
# usermod/chown re-own /home/as; bind-mount only under /workspaces and /data, never inside the home.
set -e
if [ "$(id -u)" = 0 ]; then
    if [ -n "${HOST_UID:-}" ] && [ "${HOST_UID}" != "$(id -u as)" ]; then
        echo "entrypoint: renumbering as to ${HOST_UID}:${HOST_GID:-$HOST_UID}" >&2
        groupmod -g "${HOST_GID:-$HOST_UID}" as
        usermod -u "${HOST_UID}" -g "${HOST_GID:-$HOST_UID}" as
        chown -R as:as /home/as
    fi
    export HOME=/home/as USER=as LOGNAME=as
    exec setpriv --reuid=as --regid=as --init-groups -- "$0" "$@"
fi
# shellcheck disable=SC1091
source /opt/ros/jazzy/setup.bash --
if [ -n "${DRIVERLESS_WS:-}" ] && [ -f "${DRIVERLESS_WS}/install/setup.bash" ]; then
    source "${DRIVERLESS_WS}/install/setup.bash" --
fi
exec "$@"
