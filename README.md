# ROS2-Docker

Builds `ghcr.io/ka-raceing/ros2-driverless`, the single Docker image used by the KA-RaceIng
`driverless` stack on laptops (VS Code Dev Containers), in GitLab CI and on the car.

## What is in the image

Based on `osrf/ros:jazzy-desktop-full` (Ubuntu 24.04, ROS 2 Jazzy, rviz, Gazebo) plus:

- Toolchain: gcc, clang/clang-format/clang-tidy, lld, cmake, ccache, gdb, cppcheck, colcon,
  ros-dev-tools, `generate_parameter_library`, `rmw_cyclonedds_cpp`, `domain_bridge`,
  `foxglove_bridge`, the `rviz_2d_plot_plugin` deb and the `mcap` CLI.
- Solvers and libraries built from the git submodules under `dependencies/`: osqp, osqp-eigen,
  qpmad, Ipopt with CoinHSL, g2o, GSL, acados (with a CasADi venv at `/opt/acados-venv`) and MRPT
  from the `joseluisblancoc/mrpt-stable` PPA.
- A non-root user `as` (uid/gid 1000 at build time) with password-less sudo.

The image describes only itself. It sets `RMW_IMPLEMENTATION`, `RCUTILS_*`, the acados locations
(`ACADOS_SOURCE_DIR`, `ACADOS_PYTHON_ENV`), `DRIVERLESS_IMAGE` (the tag, shown in the prompt) and
`DRIVERLESS_USER`. Everything about the repository is supplied by the consumer:

| Variable | Set by | Used for |
| --- | --- | --- |
| `DRIVERLESS_ROOT` | devcontainer.json / compose / CI | `~/.bashrc` sources `$DRIVERLESS_ROOT/scripts/aliases.sh` if it exists |
| `DRIVERLESS_WS` | devcontainer.json / compose / CI | `~/.bashrc` sources `$DRIVERLESS_WS/install/setup.bash` if it exists |
| `ROS_DOMAIN_ID` | devcontainer.json / compose / CI | 20 on laptops, 19 on the car |
| `CYCLONEDDS_URI` | the `dds_config` ament package of the driverless repo | DDS configuration |
| `HOST_UID`, `HOST_GID` | compose on the car, `docker run -e` | see below |

The driverless repo is mounted at `/workspaces/driverless` by convention, but the image does not
depend on that path.

## User and entrypoint

The container starts as root in `docker/entrypoint.sh`. If `HOST_UID` (and optionally `HOST_GID`,
defaulting to `HOST_UID`) is set and differs from the ids of `as`, the entrypoint re-numbers `as`
and fixes the ownership of `/home/as`, `/opt/acados` and `/opt/acados-venv` without descending into
bind mounts. It then drops privileges to `as` and hands over to `/ros_entrypoint.sh`, so the
command always runs as `as` with `/opt/ros/jazzy/setup.bash` sourced.

Because the image has no `USER` instruction, `docker exec` lands as root unless you pass `-u as`
(VS Code does this via `"remoteUser": "as"`). On the car the electronics account owns uid 1000, so
the driverless container runs with `HOST_UID=1001`:

```sh
docker run --rm -it --network=host -e HOST_UID=1001 -e HOST_GID=1001 \
  -e DRIVERLESS_ROOT=/workspaces/driverless -e DRIVERLESS_WS=/workspaces/driverless/driverless_ws \
  -e ROS_DOMAIN_ID=19 -v /home/as/driverless:/workspaces/driverless \
  ghcr.io/ka-raceing/ros2-driverless:1.0.0
```

## Building locally

```sh
git submodule update --init --recursive
docker build -t ghcr.io/ka-raceing/ros2-driverless:candidate \
  --build-arg IMAGE_TAG=candidate -f docker/Dockerfile .
```

`IMAGE_TAG` only feeds the prompt prefix (`[ros2-driverless:candidate] as@host:~$`). It is declared
at the end of the Dockerfile so a different tag does not invalidate the build cache. A full build
takes about 20 minutes with a warm cache, longer from scratch.

## Tags

The GitHub Actions workflow (`.github/workflows/docker-publish.yml`) builds every push and pull
request and pushes to GHCR on pushes only:

| Event | Tags pushed |
| --- | --- |
| git tag `v1.2.3` | `1.2.3`, `1.2`, `1`, `sha-<short>` |
| push to `main` | `sha-<short>`, `latest` |
| pull request | build only, nothing pushed |

Consumers (devcontainer.json, `.gitlab-ci.yml`, the car's compose file) reference an exact
version tag such as `1.0.0`. `latest` and `1` are still published for convenience but nothing
should depend on them: they float, and the car has already run a stale `latest` for months.

## Cutting a release

1. Merge the change to `main` and let the workflow build it (the `sha-<short>` image is a good
   candidate to test in the driverless repo before tagging).
2. `git tag v1.2.3 && git push origin v1.2.3`.
3. Update the tag in the consumers.

Bump the **major** version when a consumer has to change (a renamed environment variable, a
removed library, a different user or mount convention), the **minor** version when something is
added or a dependency is upgraded (base image digest, submodule tag, pip pin) and the **patch**
version for fixes that do not change what consumers see.

## What is pinned and how to update it

| Component | Pin | Where |
| --- | --- | --- |
| Base image | `osrf/ros:jazzy-desktop-full` by digest | `FROM` line in `docker/Dockerfile` |
| pip packages in the CasADi venv | exact versions (`casadi==3.8.0`, ...) | `docker/Dockerfile` |
| tera renderer for acados | `TERA_RENDERER_VERSION` build arg | `docker/Dockerfile` |
| osqp | tag `v1.0.0` | submodule |
| osqp-eigen | tag `v0.11.0` | submodule |
| qpmad | tag `1.4.0` | submodule |
| Ipopt | tag `releases/3.14.20` | submodule |
| ThirdParty-HSL | tag `releases/2.2.6` (CoinHSL tarball in `dependencies/other`) | submodule |
| acados | tag `v0.5.4` | submodule |
| g2o | KA-RaceIng fork `ka-raceing/g2o`, `master` commit | submodule |
| GSL | KA-RaceIng fork `ka-raceing/GSL`, `master` commit | submodule |
| MRPT | not pinned (PPA, old versions are removed upstream) | `docker/Dockerfile` |

g2o and GSL are team forks with local patches, so they stay on the fork's commit rather than an
upstream release tag; bump them by moving the submodule to a newer fork commit.

To refresh the base image digest:

```sh
docker buildx imagetools inspect osrf/ros:jazzy-desktop-full --format '{{.Manifest.Digest}}'
```

To move a submodule to a new tag:

```sh
git -C dependencies/osqp fetch --tags && git -C dependencies/osqp checkout v1.1.0
git add dependencies/osqp
```

Every change to a pin needs a full build and a run of the driverless workspace (`colcon build`,
`colcon test`, `sim`) against the resulting image before it is tagged.

## Layout

```
docker/Dockerfile          the image
docker/entrypoint.sh       uid/gid alignment and privilege drop
dependencies/              git submodules and vendored files (debs, CoinHSL, mcap)
.github/workflows/         build and publish
```
