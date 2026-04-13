FROM osrf/ros:jazzy-desktop-full

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DRIVERLESS_ROOT=/workspaces/driverless
ENV DRIVERLESS_WS=${DRIVERLESS_ROOT}/driverless_ws

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV ROS_DOMAIN_ID=26

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
    python3-matplotlib \
    python3-numpy \
    python3-pip \
    python3-sklearn \
    python3-venv \
    qt5-qmake \
    qtdeclarative5-dev \
    ros-dev-tools \
    ros-jazzy-foxglove-bridge \
    ros-jazzy-rmw-cyclonedds-cpp \
    software-properties-common \
    sudo \
    vim \
    wget \
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
    echo 'export RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}]: {message}"' >> /home/${USERNAME}/.bashrc && \
    echo 'export RCUTILS_COLORIZED_OUTPUT=1' >> /home/${USERNAME}/.bashrc && \
    echo '[ -f "${DRIVERLESS_WS}/install/setup.bash" ] && source "${DRIVERLESS_WS}/install/setup.bash"' >> /home/${USERNAME}/.bashrc && \
    echo '[ -f "${DRIVERLESS_ROOT}/scripts/aliases.sh" ] && source "${DRIVERLESS_ROOT}/scripts/aliases.sh"' >> /home/${USERNAME}/.bashrc

# Ensure ~/.bashrc is owned by the non-root user
RUN chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

#-------------------------------------------------
# General Dependencies
#-------------------------------------------------

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

# Refresh linker cache after all installs
RUN ldconfig

#-------------------------------------------------
# Project Environment Setup
#-------------------------------------------------

USER ${USERNAME}
WORKDIR ${DRIVERLESS_WS}

CMD ["bash"]
