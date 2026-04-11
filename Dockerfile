FROM osrf/ros:jazzy-desktop-full

#-------------------------------------------------
# Base System Setup
#-------------------------------------------------
RUN apt-get update && apt-get install --install-recommends -y \
    automake \
    bash-completion \
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
    libspdlog-dev \
    libsuitesparse-dev \
    libqglviewer-dev-qt5 \
    libtool \
    lld \
    nano \
    pkg-config \
    python3-pip \
    python3-venv \
    python3-matplotlib \
    python3-numpy \
    python3-sklearn \
    qt5-qmake \
    qtdeclarative5-dev \
    ros-dev-tools \
    ros-jazzy-foxglove-bridge \
    software-properties-common \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

#-------------------------------------------------
# General Dependencies
#-------------------------------------------------

# osqp
COPY dependencies/osqp /tmp/osqp
RUN mkdir /tmp/osqp/build
WORKDIR /tmp/osqp/build
RUN cmake .. && cmake --build . && cmake --install .
RUN ldconfig

# osqp-eigen
COPY dependencies/osqp-eigen /tmp/osqp-eigen
RUN mkdir /tmp/osqp-eigen/build
WORKDIR /tmp/osqp-eigen/build
RUN cmake .. && cmake --build . && cmake --install .
RUN ldconfig

# qpmad
COPY dependencies/qpmad /tmp/qpmad
RUN mkdir /tmp/qpmad/build
WORKDIR /tmp/qpmad/build
RUN cmake .. && cmake --build . && cmake --install .
RUN ldconfig

#-------------------------------------------------
# GraphSLAM Dependencies
#-------------------------------------------------

# g2o
COPY dependencies/g2o /tmp/g2o
RUN mkdir /tmp/g2o/build
WORKDIR /tmp/g2o/build
RUN cmake .. && make -j3 && make install
RUN ldconfig

# mrpt
RUN add-apt-repository -y ppa:joseluisblancoc/mrpt-stable
RUN apt-get update && apt-get install -y \
    libmrpt-dev \
    mrpt-apps \
    && rm -rf /var/lib/apt/lists/*

#-------------------------------------------------
# Controller Dependencies
#-------------------------------------------------

# GSL
COPY dependencies/GSL /tmp/gsl
WORKDIR /tmp/gsl
RUN ./autogen.sh
RUN ./configure
RUN make -j3 && make install
RUN ldconfig

# Refresh linker cache after all installs
RUN ldconfig

#-------------------------------------------------
# Project Environment Setup
#-------------------------------------------------

COPY .bash_aliases /root/.bash_aliases

RUN echo 'source /opt/ros/jazzy/setup.bash' >> /root/.bashrc && \
    echo 'if [ -f /root/driverless/driverless_ws/install/setup.bash ]; then source /root/driverless/driverless_ws/install/setup.bash; fi' >> /root/.bashrc && \
    echo 'export ROS_DOMAIN_ID=26' >> /root/.bashrc && \
    echo 'export RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}]: {message}"' >> /root/.bashrc && \
    sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc

RUN mkdir -p /root/driverless/driverless_ws
WORKDIR /root/driverless/driverless_ws
CMD ["bash"]
