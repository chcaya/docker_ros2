#!/bin/bash
set -e

# 1. Path Setup
# We use $HOME and the PROJECT_NAME passed from the environment
WORKSPACE_DIR="$HOME/${PROJECT_NAME:-docker_template}"

echo "--- Initializing ROS 2 Jazzy Environment: ${PROJECT_NAME} ---"

# 2. Source Standard ROS 2 Underlay (Jazzy Jalisco)
if [ -f "/opt/ros/jazzy/setup.bash" ]; then
    source /opt/ros/jazzy/setup.bash
else
    echo "ERROR: ROS 2 Jazzy not found in /opt/ros/jazzy/"
    exit 1
fi

# 3. Source Project Workspace Overlay
# Points to the dynamically named install folder
WORKSPACE_SETUP="${WORKSPACE_DIR}/install/setup.bash"

if [ -f "$WORKSPACE_SETUP" ]; then
    source "$WORKSPACE_SETUP"
    echo "--- Project workspace sourced: ${WORKSPACE_DIR} ---"
else
    echo "--- Warning: Workspace 'install' folder not found. Have you run 'build' yet? ---"
fi

# 4. Standard ROS 2 Networking & Python settings
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export PYTHONUNBUFFERED=1

# 5. Signal Handoff
# 'exec' is critical: it allows the ROS nodes to receive shutdown signals 
# (like Ctrl+C or systemd stop) directly from the host.
echo "Executing: $@"
exec "$@"
