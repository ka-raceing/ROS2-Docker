#!/usr/bin/env bash
WORKSPACE="/root/driverless/driverless_ws"
ROS_DISTRO="jazzy"

# Source ROS 2 and the driverless workspace
source "/opt/ros/$ROS_DISTRO/setup.bash"
source "$WORKSPACE/install/setup.bash" 2>/dev/null || true

# Notify user if in interactive shell
if [[ $- == *i* ]]; then
  echo "[ROS 2] ROS 2 $ROS_DISTRO sourced."
  if [ -f "$WORKSPACE/install/setup.bash" ]; then
    echo "[ROS 2] Driverless workspace sourced."
  else
    echo "[ROS 2] Workspace overlay missing, run: colcon build"
  fi
fi

# ROS Domain ID
export ROS_DOMAIN_ID=26

# Console output format
export RCUTILS_CONSOLE_OUTPUT_FORMAT='[{severity}]: {message}'

# Update shared library cache
sudo ldconfig
