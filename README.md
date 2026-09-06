# ROS2-Docker

Builds `ghcr.io/ka-raceing/ros2-driverless`: the one image the KA-RaceIng `driverless` stack runs
in, on laptops (VS Code Dev Containers), in GitLab CI and on the car.

## Contents

`osrf/ros:jazzy-desktop-full` (pinned by digest) plus the build toolchain, `rmw_cyclonedds_cpp`,
`domain_bridge`, `foxglove_bridge`, `generate_parameter_library`, the `mcap` CLI, and the solvers
built from the submodules under `dependencies/`: osqp, osqp-eigen, qpmad, Ipopt + CoinHSL, g2o,
GSL, acados with a CasADi venv (`/opt/acados-venv`), MRPT from its PPA.

The image knows nothing about the driverless repository. The consumer (devcontainer.json, the
car's compose file, `.gitlab-ci.yml`) supplies:

| Variable | Meaning |
| --- | --- |
| `DRIVERLESS_ROOT` | repo checkout, `/workspaces/driverless` by convention; `scripts/env.sh` and `scripts/aliases.sh` are sourced from it when present |
| `DRIVERLESS_WS` | the colcon workspace, `$DRIVERLESS_ROOT/driverless_ws`; its `install/setup.bash` is sourced when present |
| `ROS_DOMAIN_ID` | 20 laptops, 19 car |
| `HOST_UID`, `HOST_GID` | host ids to adopt at start, see below |

`CYCLONEDDS_URI` comes from the workspace (`dds_config` package). Bags and maps live under
`/data/bags` and `/data/maps` by convention; the launch files hardcode them. The image itself sets
only `RMW_IMPLEMENTATION`, `RCUTILS_*`, the acados locations and `DRIVERLESS_IMAGE` (the tag shown
in the prompt).

## User and entrypoint

The image user is `as`, uid 1000 at build time, with password-less sudo. `docker/entrypoint.sh`
starts as root: if `HOST_UID` (and `HOST_GID`, default `HOST_UID`) differs from `as`, it renumbers
`as` and re-owns `/home/as` (nothing else: `/opt/acados*` stays root-owned and is only read); then
it drops to `as`, sources ROS, the workspace and `$DRIVERLESS_ROOT/scripts/env.sh` if present, and
execs the command. Bind-mount only under `/workspaces` and `/data`, never inside `/home/as`.

`docker exec` bypasses the entrypoint: pass `-u as` (VS Code: `"remoteUser": "as"`). An
interactive shell gets the environment and the aliases from `~/.bashrc`; a one-off command goes
through the entrypoint, which sources the environment but not the aliases:
`docker compose exec -u as car /usr/local/bin/entrypoint.sh ros2 topic list`.

The car runs with `HOST_UID=1001` because uid 1000 belongs to the electronics account there.

## Tags and releases

| Event | Pushed |
| --- | --- |
| git tag `v2.0.1` | `2.0.1`, `2.0`, `2`, `sha-<short>` |
| push to `main` | `sha-<short>` |
| pull request | build only |

Consumers pin the minor tag (`2.0`). A patch release moves it on purpose and needs no consumer
change; a minor or major release never moves an existing minor tag and consumers bump explicitly.
There is no `latest`. Major = a consumer must change; minor = something added or a dependency
bumped; patch = a fix invisible to consumers.

To release: merge to `main`, test the `sha-<short>` image in the driverless repo, then
`git tag v2.0.1 && git push origin v2.0.1`.

## Pins

Base image digest, the pip packages of the venv, the tera renderer version and the submodule
commits are all pinned in `docker/Dockerfile` and the submodule pointers. osqp, osqp-eigen, qpmad and Ipopt
are on the same commits as the 1.8 images so that 2.0 changes packaging only. g2o and GSL are
team forks. MRPT is the only unpinned dependency (the PPA removes old versions). Every pin change
needs a full build plus `colcon build`, `colcon test` and `sim` in the driverless repo.

## Building locally

```sh
git submodule update --init --recursive
docker build -t ghcr.io/ka-raceing/ros2-driverless:2.0 --build-arg IMAGE_TAG=2.0 -f docker/Dockerfile .
```

`IMAGE_TAG` is only shown in the shell prompt. About 20 minutes with a warm cache.

`ros2-dev:1.8` and `ros2-runtime:1.8` (git tag `v1.8.0`) are the last images of the previous
two-image layout; nothing new should reference them.
