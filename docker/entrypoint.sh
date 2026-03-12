#!/bin/bash
set -e

# 1. Absolute path discovery
# Locates where the script is running inside the container
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Search for .env to get the PROJECT_NAME
# This ensures environment variables like PROJECT_NAME are available to ROS
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
elif [ -f "/home/ros/${PROJECT_NAME:-docker_template}/.env" ]; then
    export $(grep -v '^#' "/home/ros/${PROJECT_NAME:-docker_template}/.env" | xargs)
fi

# Fallback
CONTAINER_NAME="${PROJECT_NAME:-docker_template}"

# 3. Source Standard ROS 2 Jazzy (2026 Standard)
# Ubuntu 24.04 / ROS 2 Jazzy Jalisco
if [ -f "/opt/ros/jazzy/setup.bash" ]; then
    source /opt/ros/jazzy/setup.bash
else
    echo "ERROR: ROS 2 Jazzy not found in /opt/ros/jazzy/"
    exit 1
fi

# 4. Source Project Workspace
# Anchored to the user home and the dynamic project name
WORKSPACE_SETUP="/home/ros/${CONTAINER_NAME}/install/setup.bash"

if [ -f "$WORKSPACE_SETUP" ]; then
    source "$WORKSPACE_SETUP"
    echo "--- Project workspace sourced: ${CONTAINER_NAME} ---"
else
    echo "--- Note: Workspace 'install' not found yet. ---"
fi

# 5. Export ROS Environment Variables
# Essential for discovery and logging
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export PYTHONUNBUFFERED=1

# 

# 6. Execute the command passed to docker run
# If no command was provided (e.g., tail -f /dev/null), $@ handles it.
# exec ensures the command receives signals (like SIGINT/Ctrl+C) directly.
echo "Executing: $@"
exec "$@"
