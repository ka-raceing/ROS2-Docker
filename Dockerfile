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
WORKDIR /tmp/osqp
RUN mkdir build && cd build &&
RUN cmake .. && cmake --build . && cmake --install .

# osqp-eigen
COPY dependencies/osqp-eigen /tmp/osqp-eigen
WORKDIR /tmp/osqp-eigen
RUN mkdir build && cd build &&
RUN cmake .. && cmake --build . && cmake --install .

# qpmad
COPY dependencies/qpmad /tmp/qpmad
WORKDIR /tmp/qpmad
RUN mkdir build && cd build &&
RUN cmake .. && cmake --build . && cmake --install .

#-------------------------------------------------
# GraphSLAM Dependencies
#-------------------------------------------------

# g2o
COPY dependencies/g2o /tmp/g2o
RUN mkdir /tmp/g2o/build
WORKDIR /tmp/g2o/build
RUN cmake .. && make -j3 && make install

# mrpt
RUN add-apt-repository -y ppa:joseluisblancoc/mrpt-stable
RUN apt-get update && apt-get install -y \
    libmrpt-dev \
    mrpt-apps

#-------------------------------------------------
# Controller Dependencies
#-------------------------------------------------

# GSL
COPY dependencies/GSL /tmp/gsl
WORKDIR /tmp/gsl
RUN ./autogen.sh
RUN ./configure
RUN make -j3 && make install

#-------------------------------------------------
# Project Environment Setup
#-------------------------------------------------

# Shell setup
COPY .bash_aliases /root/.bash_aliases
RUN sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc
RUN echo "source scripts/source_env.sh" >> /root/.bashrc

WORKDIR /
CMD ["bash"]
