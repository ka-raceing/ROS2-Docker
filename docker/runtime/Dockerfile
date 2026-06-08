FROM ros:jazzy-ros-core

ARG DEBIAN_FRONTEND=noninteractive
ARG TERA_RENDERER_VERSION=v0.2.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DRIVERLESS_ROOT=/workspaces/driverless
ENV DRIVERLESS_WS=${DRIVERLESS_ROOT}/driverless_ws
ENV BAGS_PATH=/data/bags
ENV MAPS_PATH=/data/maps

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV ROS_DOMAIN_ID=19
ENV RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}]: {message}"
ENV RCUTILS_COLORIZED_OUTPUT=1
ENV CYCLONEDDS_URI=file://${DRIVERLESS_ROOT}/cyclonedds.xml

# acados / CasADi
ENV ACADOS_SOURCE_DIR=/opt/acados
ENV ACADOS_SOLVER_DIR=${DRIVERLESS_WS}/src/control/controller/src/lateral_control/generated/acados
ENV ACADOS_PYTHON_ENV=/opt/acados-venv
ENV LD_LIBRARY_PATH=${ACADOS_SOURCE_DIR}/lib:${ACADOS_SOLVER_DIR}:/usr/local/lib

#-------------------------------------------------
# Base Runtime Setup
#-------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    automake \
    bash-completion \
    can-utils \
    cmake \
    curl \
    gfortran \
    iproute2 \
    libeigen3-dev \
    libfreeimage-dev \
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
    ros-dev-tools \
    ros-jazzy-domain-bridge \
    ros-jazzy-foxglove-bridge \
    ros-jazzy-message-filters \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-pcl-ros \
    ros-jazzy-ros2bag \
    ros-jazzy-rosbag2-storage-default-plugins \
    ros-jazzy-rviz-common \
    software-properties-common \
    wget \
    patch \
    liblapack-dev \
    libmetis-dev \
    && rm -rf /var/lib/apt/lists/*

#-------------------------------------------------
# SHELL Environment Setup
#-------------------------------------------------

# Configure Shell Startup
RUN echo '' >> /root/.bashrc && \
    echo '# Driverless Environment' >> /root/.bashrc && \
    echo 'source /opt/ros/jazzy/setup.bash' >> /root/.bashrc && \
    echo '[ -f "${DRIVERLESS_WS}/install/setup.bash" ] && source "${DRIVERLESS_WS}/install/setup.bash"' >> /root/.bashrc && \
    echo '[ -f "${DRIVERLESS_ROOT}/scripts/aliases.sh" ] && source "${DRIVERLESS_ROOT}/scripts/aliases.sh"' >> /root/.bashrc && \
    echo 'export LD_LIBRARY_PATH="${ACADOS_SOURCE_DIR}/lib:${ACADOS_SOLVER_DIR}:/usr/local/lib:${LD_LIBRARY_PATH}"' >> /root/.bashrc

# Enable colored bash prompt
RUN sed -i 's/^[[:space:]]*#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc

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
    "${ACADOS_PYTHON_ENV}/bin/python" -c "import casadi, acados_template; print('casadi', casadi.__version__); print('acados_template ok')"


# Refresh linker cache after all installs
RUN ldconfig

#-------------------------------------------------
# Project Environment Setup
#-------------------------------------------------

WORKDIR ${DRIVERLESS_WS}
CMD ["bash"]
