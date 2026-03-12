#!/bin/bash
set -e

# 1. Path Setup
WORKSPACE_DIR="$HOME/${PROJECT_NAME:-docker_template}"

echo "--- Running postCreate setup for ${PROJECT_NAME} ---"

# 2. Source ROS 2 Underlay
source /opt/ros/jazzy/setup.bash

# 3. Dependency Check
rosdep update
sudo apt-get update
rosdep install --from-paths "$WORKSPACE_DIR/src" --ignore-src -y -r --rosdistro jazzy

# 4. Ultra-Safe Build (Using Environment Variables to restrict threading)
cd "$WORKSPACE_DIR"

# echo "--- Performing initial build (Sequential & Single Threaded) ---"

# # Restrict CMake and Make to exactly 1 thread at the system level
# export MAKEFLAGS="-j1"
# export CMAKE_BUILD_PARALLEL_LEVEL=1

# # We use 1 parallel worker (1 package at a time)
# colcon build \
#     --symlink-install \
#     --executor sequential \
#     --parallel-workers 1 \
#     --cmake-args \
#         -DCMAKE_BUILD_TYPE=RelWithDebInfo \
#         -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# 5. Success message
echo "--- Workspace is ready! ---"
echo "Remember to source the workspace with the 'sros' alias."
