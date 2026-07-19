FROM osrf/ros:jazzy-desktop-full

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG TERA_RENDERER_VERSION=v0.2.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DRIVERLESS_ROOT=/workspaces/driverless
ENV DRIVERLESS_WS=${DRIVERLESS_ROOT}/driverless_ws
ENV BAGS_PATH=/data/bags
ENV MAPS_PATH=/data/maps

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV ROS_DOMAIN_ID=20
ENV RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}]: {message}"
ENV RCUTILS_COLORIZED_OUTPUT=1
ENV CYCLONEDDS_URI=file://${DRIVERLESS_ROOT}/cyclonedds.xml

# acados / CasADi
ENV ACADOS_SOURCE_DIR=/opt/acados
ENV ACADOS_SOLVER_DIR=${DRIVERLESS_WS}/src/control/controller/src/lateral_control/generated/acados
ENV ACADOS_PYTHON_ENV=/opt/acados-venv
ENV LD_LIBRARY_PATH=${ACADOS_SOURCE_DIR}/lib:${ACADOS_SOLVER_DIR}:/usr/local/lib

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
# SHELL Environment Setup
#-------------------------------------------------

# User Setup (Reuse existing UID/GID 1000 from base image)
RUN EXISTING_USER="$(getent passwd "${USER_UID}" | cut -d: -f1)" && \
    EXISTING_GROUP="$(getent group "${USER_GID}" | cut -d: -f1)" && \
    usermod -l "${USERNAME}" "${EXISTING_USER}" && \
    usermod -d "/home/${USERNAME}" -m "${USERNAME}" && \
    groupmod -n "${USERNAME}" "${EXISTING_GROUP}" && \
    usermod -g "${USERNAME}" "${USERNAME}" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Configure Shell Startup
RUN echo '' >> /home/${USERNAME}/.bashrc && \
    echo '# Driverless Environment' >> /home/${USERNAME}/.bashrc && \
    echo 'source /opt/ros/jazzy/setup.bash' >> /home/${USERNAME}/.bashrc && \
    echo '[ -f "${DRIVERLESS_WS}/install/setup.bash" ] && source "${DRIVERLESS_WS}/install/setup.bash"' >> /home/${USERNAME}/.bashrc && \
    echo '[ -f "${DRIVERLESS_ROOT}/scripts/aliases.sh" ] && source "${DRIVERLESS_ROOT}/scripts/aliases.sh"' >> /home/${USERNAME}/.bashrc && \
    echo 'export LD_LIBRARY_PATH="${ACADOS_SOURCE_DIR}/lib:${ACADOS_SOLVER_DIR}:/usr/local/lib:${LD_LIBRARY_PATH}"' >> /home/${USERNAME}/.bashrc

# Enable colored bash prompt
RUN sed -i 's/^[[:space:]]*#force_color_prompt=yes/force_color_prompt=yes/' /home/${USERNAME}/.bashrc

# Ensure ~/.bashrc is owned by the non-root user
RUN chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

#-------------------------------------------------
# General Dependencies
#-------------------------------------------------

COPY dependencies/debs /tmp/debs
RUN dpkg -i /tmp/debs/ros-jazzy-rviz-2d-plot-plugin_0.2.0-0noble_amd64.deb && rm -rf /tmp/debs

# mcap cli
COPY dependencies/other/mcap-linux-amd64 /usr/local/bin/mcap

# osqp
COPY dependencies/osqp /tmp/osqp
RUN cmake -S /tmp/osqp -B /tmp/osqp/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/osqp/build -j"$(nproc)" && \
    cmake --install /tmp/osqp/build && \
    rm -rf /tmp/osqp

# osqp-eigen
COPY dependencies/osqp-eigen /tmp/osqp-eigen
RUN cmake -S /tmp/osqp-eigen -B /tmp/osqp-eigen/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/osqp-eigen/build -j"$(nproc)" && \
    cmake --install /tmp/osqp-eigen/build && \
    rm -rf /tmp/osqp-eigen

# qpmad
COPY dependencies/qpmad /tmp/qpmad
RUN cmake -S /tmp/qpmad -B /tmp/qpmad/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/qpmad/build -j"$(nproc)" && \
    cmake --install /tmp/qpmad/build && \
    rm -rf /tmp/qpmad

# Ipopt
COPY dependencies/Ipopt /tmp/Ipopt
COPY dependencies/ThirdParty-HSL /tmp/Ipopt/ThirdParty-HSL
COPY dependencies/other/coinhsl.tar.gz /tmp/Ipopt/ThirdParty-HSL/
RUN tar -xzf /tmp/Ipopt/ThirdParty-HSL/coinhsl.tar.gz -C /tmp/Ipopt/ThirdParty-HSL && \
    cd /tmp/Ipopt/ThirdParty-HSL && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    cd .. && \
    ./configure && \
    mkdir build && \
    make -j"$(nproc)" && \
    make install && \
    rm -rf /tmp/Ipopt

#-------------------------------------------------
# GraphSLAM Dependencies
#-------------------------------------------------

# g2o
COPY dependencies/g2o /tmp/g2o
RUN cmake -S /tmp/g2o -B /tmp/g2o/build -DCMAKE_BUILD_TYPE=Release && \
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
COPY dependencies/GSL /tmp/gsl
RUN cd /tmp/gsl && \
    ./autogen.sh && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    cd / && \
    rm -rf /tmp/gsl

# acados core library + Python interface.
COPY dependencies/acados /opt/acados
RUN cmake -S "${ACADOS_SOURCE_DIR}" -B "${ACADOS_SOURCE_DIR}/build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DACADOS_INSTALL_DIR="${ACADOS_SOURCE_DIR}" \
        -DACADOS_WITH_QPOASES=ON \
        -DACADOS_WITH_OSQP=OFF \
        -DACADOS_EXAMPLES=OFF \
        -DACADOS_UNIT_TESTS=OFF && \
    cmake --build "${ACADOS_SOURCE_DIR}/build" -j"$(nproc)" && \
    cmake --install "${ACADOS_SOURCE_DIR}/build" && \
    rm -rf "${ACADOS_SOURCE_DIR}/build"

# CasADi is installed into a dedicated venv so it does not pollute the ROS Python environment.
RUN python3 -m venv "${ACADOS_PYTHON_ENV}" && \
    "${ACADOS_PYTHON_ENV}/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel && \
    "${ACADOS_PYTHON_ENV}/bin/pip" install --no-cache-dir \
        casadi \
        numpy \
        scipy \
        matplotlib \
        pyyaml \
        jinja2 \
        future && \
    "${ACADOS_PYTHON_ENV}/bin/pip" install --no-cache-dir -e "${ACADOS_SOURCE_DIR}/interfaces/acados_template" && \
    mkdir -p "${ACADOS_SOURCE_DIR}/bin" && \
    curl -L -o "${ACADOS_SOURCE_DIR}/bin/t_renderer" \
        "https://github.com/acados/tera_renderer/releases/download/${TERA_RENDERER_VERSION}/t_renderer-${TERA_RENDERER_VERSION}-linux-amd64" && \
    chmod +x "${ACADOS_SOURCE_DIR}/bin/t_renderer" && \
    "${ACADOS_PYTHON_ENV}/bin/python" -c "import casadi, acados_template; print('casadi', casadi.__version__); print('acados_template ok')" && \
    chown -R "${USERNAME}:${USERNAME}" "${ACADOS_SOURCE_DIR}" "${ACADOS_PYTHON_ENV}"

# Refresh linker cache after all installs
RUN ldconfig

#-------------------------------------------------
# Project Environment Setup
#-------------------------------------------------

USER ${USERNAME}
WORKDIR ${DRIVERLESS_WS}

CMD ["bash"]
