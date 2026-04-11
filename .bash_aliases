# Custom Variables
export CONTAINER_NAME="ros2-docker"
export PROJECT_ROOT="/root/driverless"
export WORKSPACE="$PROJECT_ROOT/driverless_ws"
export SCRIPTS="${PROJECT_ROOT}/scripts"
export CARPC_IP="192.168.25.19"

# Car PC connection
alias carpc="ssh as@$CARPC_IP -t tmux new -A -s main"

# Directory navigation
alias cdws="cd $WORKSPACE"
alias cdmaps="cd /root/maps"
alias cdbags="cd /root/bags"

# Source commands
alias srcros="source /opt/ros/jazzy/setup.bash"
alias srcws="[ -f '$WORKSPACE/install/setup.bash' ] && source '$WORKSPACE/install/setup.bash'"

# Build and clean commands
alias build="cdws; srcros; colcon build --cmake-args -Wno-dev; srcws"
alias buildseq="cdws; srcros; colcon build --cmake-args -Wno-dev --executor sequential; srcws"
alias colconclean="cdws; rm -rf build/ install/ log/; unset AMENT_PREFIX_PATH CMAKE_PREFIX_PATH COLCON_PREFIX_PATH; srcros"
alias ros2kill="pkill -f ros2; pkill -f rviz2;"
alias sc="sudo ip link set can0 up type can bitrate 1000000 ; sudo ip link set can1 up type can bitrate 1000000"

# Launch commands
alias sim="cdws; ros2 launch simulator simulator.launch.py"
alias sup="cdws; ros2 launch supervisor supervisor.launch.py"
alias fox="cdws; ros2 launch foxglove_bridge foxglove_bridge_launch.xml"
alias viz="cdws; ros2 launch visualizer visualizer.launch.py"

alias startcar="cdws; ros2 topic pub /system/actuation_allowed std_msgs/msg/Bool '{data: true}'"

# Script shortcuts
alias genpkg="$SCRIPTS/package_generator/generate_package.sh"
