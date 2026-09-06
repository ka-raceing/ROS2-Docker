# syntax=docker/dockerfile:1
# ghcr.io/ka-raceing/ros2-driverless
#
# One image for laptops (VS Code Dev Containers), CI and the car. It carries the toolchain and the
# third-party dependencies of the driverless stack, but no facts about the driverless repository:
# where it is mounted, which ROS domain to use and where the DDS config lives are supplied by the
# consumer (devcontainer.json, .gitlab-ci.yml, compose.yaml) through environment variables.
#
# Base image pinned by digest; bump deliberately (see README.md).
FROM osrf/ros:jazzy-desktop-full@sha256:d16957210572c5f919f3f9bd2fb0cc24a82542647489d8b8eda7c3beda31305f

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=as
ARG USER_UID=1000
ARG USER_GID=1000
ARG TERA_RENDERER_VERSION=v0.2.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}]: {message}"
ENV RCUTILS_COLORIZED_OUTPUT=1

# acados / CasADi install locations inside the image.
ENV ACADOS_SOURCE_DIR=/opt/acados
ENV ACADOS_PYTHON_ENV=/opt/acados-venv

#-------------------------------------------------
# Base Development Setup
#-------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    automake \
    bash-completion \
    build-essential \
    can-utils \
    ccache \
    clang \
    clang-format \
    clang-tidy \
    cmake \
    cppcheck \
    curl \
    gdb \
    gfortran \
    git \
    htop \
    iproute2 \
    libeigen3-dev \
    libqglviewer-dev-qt5 \
    libspdlog-dev \
    libsuitesparse-dev \
    libtool \
    lld \
    nano \
    pkg-config \
    python-is-python3 \
    python3-colcon-common-extensions \
    python3-dev \
    python3-matplotlib \
    python3-numpy \
    python3-pip \
    python3-sklearn \
    python3-venv \
    qt5-qmake \
    qtdeclarative5-dev \
    ros-dev-tools \
    ros-jazzy-domain-bridge \
    ros-jazzy-foxglove-bridge \
    ros-jazzy-generate-parameter-library \
    ros-jazzy-rmw-cyclonedds-cpp \
    software-properties-common \
    sudo \
    vim \
    wget \
    patch \
    liblapack-dev \
    libmetis-dev \
    && rm -rf /var/lib/apt/lists/*

#-------------------------------------------------
# User Setup
#-------------------------------------------------

# Rename the base image's uid/gid 1000 user; the entrypoint re-maps the ids at container start
RUN EXISTING_USER="$(getent passwd "${USER_UID}" | cut -d: -f1)" && \
    EXISTING_GROUP="$(getent group "${USER_GID}" | cut -d: -f1)" && \
    usermod -l "${USERNAME}" "${EXISTING_USER}" && \
    usermod -d "/home/${USERNAME}" -m "${USERNAME}" && \
    groupmod -n "${USERNAME}" "${EXISTING_GROUP}" && \
    usermod -g "${USERNAME}" "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

#-------------------------------------------------
# General Dependencies
#-------------------------------------------------

RUN --mount=type=bind,source=dependencies/debs,target=/tmp/debs \
    dpkg -i /tmp/debs/ros-jazzy-rviz-2d-plot-plugin_0.2.0-0noble_amd64.deb

# mcap cli
COPY dependencies/other/mcap-linux-amd64 /usr/local/bin/mcap

# osqp
RUN --mount=type=bind,source=dependencies/osqp,target=/src/osqp \
    cp -r /src/osqp /tmp/osqp && \
    cmake -S /tmp/osqp -B /tmp/osqp/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/osqp/build -j"$(nproc)" && \
    cmake --install /tmp/osqp/build && \
    rm -rf /tmp/osqp

# osqp-eigen
RUN --mount=type=bind,source=dependencies/osqp-eigen,target=/src/osqp-eigen \
    cp -r /src/osqp-eigen /tmp/osqp-eigen && \
    cmake -S /tmp/osqp-eigen -B /tmp/osqp-eigen/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/osqp-eigen/build -j"$(nproc)" && \
    cmake --install /tmp/osqp-eigen/build && \
    rm -rf /tmp/osqp-eigen

# qpmad
RUN --mount=type=bind,source=dependencies/qpmad,target=/src/qpmad \
    cp -r /src/qpmad /tmp/qpmad && \
    cmake -S /tmp/qpmad -B /tmp/qpmad/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/qpmad/build -j"$(nproc)" && \
    cmake --install /tmp/qpmad/build && \
    rm -rf /tmp/qpmad

# Ipopt
RUN --mount=type=bind,source=dependencies/Ipopt,target=/src/Ipopt \
    --mount=type=bind,source=dependencies/ThirdParty-HSL,target=/src/ThirdParty-HSL \
    --mount=type=bind,source=dependencies/other/coinhsl.tar.gz,target=/src/coinhsl.tar.gz \
    cp -r /src/Ipopt /tmp/Ipopt && \
    cp -r /src/ThirdParty-HSL /tmp/Ipopt/ThirdParty-HSL && \
    tar -xzf /src/coinhsl.tar.gz -C /tmp/Ipopt/ThirdParty-HSL && \
    cd /tmp/Ipopt/ThirdParty-HSL && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    cd .. && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf /tmp/Ipopt

#-------------------------------------------------
# GraphSLAM Dependencies
#-------------------------------------------------

# g2o
RUN --mount=type=bind,source=dependencies/g2o,target=/src/g2o \
    cp -r /src/g2o /tmp/g2o && \
    cmake -S /tmp/g2o -B /tmp/g2o/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/g2o/build -j"$(nproc)" && \
    cmake --install /tmp/g2o/build && \
    rm -rf /tmp/g2o

# mrpt
RUN add-apt-repository -y ppa:joseluisblancoc/mrpt-stable && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libmrpt-dev \
        mrpt-apps \
    && rm -rf /var/lib/apt/lists/*

#-------------------------------------------------
# Controller Dependencies
#-------------------------------------------------

# GSL
RUN --mount=type=bind,source=dependencies/GSL,target=/src/gsl \
    cp -r /src/gsl /tmp/gsl && \
    cd /tmp/gsl && \
    ./autogen.sh && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    cd / && \
    rm -rf /tmp/gsl

# acados core library + Python interface
# Only lib/, include/, interfaces/ and bin/ are needed afterwards; the rest of the tree is dropped.
RUN --mount=type=bind,source=dependencies/acados,target=/src/acados \
    cp -r /src/acados "${ACADOS_SOURCE_DIR}" && \
    cmake -S "${ACADOS_SOURCE_DIR}" -B "${ACADOS_SOURCE_DIR}/build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DACADOS_INSTALL_DIR="${ACADOS_SOURCE_DIR}" \
        -DACADOS_WITH_QPOASES=ON \
        -DACADOS_WITH_OSQP=OFF \
        -DACADOS_EXAMPLES=OFF \
        -DACADOS_UNIT_TESTS=OFF && \
    cmake --build "${ACADOS_SOURCE_DIR}/build" -j"$(nproc)" && \
    cmake --install "${ACADOS_SOURCE_DIR}/build" && \
    rm -rf "${ACADOS_SOURCE_DIR}/build" "${ACADOS_SOURCE_DIR}"/examples "${ACADOS_SOURCE_DIR}"/test \
           "${ACADOS_SOURCE_DIR}"/docs "${ACADOS_SOURCE_DIR}"/external "${ACADOS_SOURCE_DIR}"/.git*

# CasADi is installed into a dedicated venv
RUN python3 -m venv "${ACADOS_PYTHON_ENV}" && \
    "${ACADOS_PYTHON_ENV}/bin/pip" install --no-cache-dir --upgrade \
        pip==26.2.1 \
        setuptools==84.0.0 \
        wheel==0.48.0 && \
    "${ACADOS_PYTHON_ENV}/bin/pip" install --no-cache-dir \
        casadi==3.8.0 \
        numpy==2.5.2 \
        scipy==1.18.1 \
        matplotlib==3.11.1 \
        pyyaml==6.0.3 \
        jinja2==3.1.6 \
        future==1.0.0 && \
    "${ACADOS_PYTHON_ENV}/bin/pip" install --no-cache-dir -e "${ACADOS_SOURCE_DIR}/interfaces/acados_template" && \
    mkdir -p "${ACADOS_SOURCE_DIR}/bin" && \
    curl -fsSL -o "${ACADOS_SOURCE_DIR}/bin/t_renderer" \
        "https://github.com/acados/tera_renderer/releases/download/${TERA_RENDERER_VERSION}/t_renderer-${TERA_RENDERER_VERSION}-linux-amd64" && \
    chmod +x "${ACADOS_SOURCE_DIR}/bin/t_renderer" && \
    "${ACADOS_PYTHON_ENV}/bin/python" -c "import casadi, acados_template; print('casadi', casadi.__version__); print('acados_template ok')"

# Make the acados library visible to the dynamic linker without LD_LIBRARY_PATH
RUN echo "${ACADOS_SOURCE_DIR}/lib" > /etc/ld.so.conf.d/acados.conf && ldconfig

#-------------------------------------------------
# Shell and Entrypoint Setup
#-------------------------------------------------

# Image tag shown in the shell prompt.
ARG IMAGE_TAG=dev
ENV DRIVERLESS_IMAGE=ros2-driverless:${IMAGE_TAG}

# ~/.bashrc sources ROS and, when DRIVERLESS_WS is set and built, the workspace for interactive
# shells (docker exec); the entrypoint does the same for the container command. DRIVERLESS_WS /
# DRIVERLESS_ROOT are not set by the image; they come from the consumer.
RUN cat >> "/home/${USERNAME}/.bashrc" <<'EOF'

# Driverless Environment
source /opt/ros/jazzy/setup.bash
if [ -n "${DRIVERLESS_WS}" ] && [ -f "${DRIVERLESS_WS}/install/setup.bash" ]; then
    source "${DRIVERLESS_WS}/install/setup.bash"
fi
if [ -n "${DRIVERLESS_ROOT}" ] && [ -f "${DRIVERLESS_ROOT}/scripts/env.sh" ]; then
    source "${DRIVERLESS_ROOT}/scripts/env.sh"
fi
if [ -n "${DRIVERLESS_ROOT}" ] && [ -f "${DRIVERLESS_ROOT}/scripts/aliases.sh" ]; then
    source "${DRIVERLESS_ROOT}/scripts/aliases.sh"
fi
PS1="[${DRIVERLESS_IMAGE}] ${PS1}"
EOF
RUN sed -i 's/^[[:space:]]*#force_color_prompt=yes/force_color_prompt=yes/' /home/${USERNAME}/.bashrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

# The entrypoint starts as root, aligns ${USERNAME} to HOST_UID/HOST_GID when given, drops
# privileges, sources ROS and the workspace and execs the command. No USER instruction on purpose:
# the renumbering needs root.
COPY --chmod=0755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/${USERNAME}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
