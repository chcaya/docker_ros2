#!/bin/bash
set -e

# 1. Dynamically find the workspace using $HOME instead of hardcoded paths
WORKSPACE_DIR="$HOME/${PROJECT_NAME:-docker_template}"
ENV_FILE="$WORKSPACE_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    # Safely load variables from .env
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    # Re-evaluate WORKSPACE_DIR just in case PROJECT_NAME was defined in the .env file
    WORKSPACE_DIR="$HOME/${PROJECT_NAME:-docker_template}"
fi

echo "--- Running postCreate setup for ${PROJECT_NAME:-docker_template} ---"

# 2. Source the ROS 2 Jazzy Underlay (CRITICAL FIX)
# This is what allows CMake to find 'ament_cmake'
source /opt/ros/jazzy/setup.bash

# 3. Update Rosdep to catch any new package additions
rosdep update

# 4. Install any missing dependencies
# We use sudo here because postCreate runs as the non-root user
sudo apt-get update
rosdep install --from-paths "$WORKSPACE_DIR/src" --ignore-src -y -r --rosdistro jazzy

# 5. Initial Build
# We must cd into the workspace directory before running colcon!
cd "$WORKSPACE_DIR"

echo "--- Performing initial build ---"
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo

# 6. Success message
echo "--- Workspace is ready! ---"
echo "Remember to source the workspace with the 'sros' alias."