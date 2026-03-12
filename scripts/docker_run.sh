#!/bin/bash

# 1. Absolute path discovery
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Search for .env and determine PROJECT_ROOT
# Looking in the parent folder because this script is in /scripts
if [ -f "$SCRIPT_DIR/../.env" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [ -f "$SCRIPT_DIR/.env" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
else
    echo "Error: .env file not found. Ensure it is in the project root."
    exit 1
fi

# Load variables from root .env
export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)

# Fallback variables
CONTAINER_NAME="${PROJECT_NAME:-docker_template}"
TARGET_USER="${USERNAME:-ros}"
IMAGE_NAME="${CONTAINER_NAME}:latest"

# 3. Handle GUI/Display Permissions (X11)
if [ -n "$DISPLAY" ]; then
    echo "Setting up X11 display permissions..."
    xhost +local:root > /dev/null 2>&1 || true
fi

# 4. Check for existing container
# Added -n and quotes here for bash safety!
if [ -n "$(docker ps -q -f name="^/${CONTAINER_NAME}$")" ]; then
    read -p "Container '${CONTAINER_NAME}' is already running. Restart it? (y/n): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Stopping existing container..."
        docker stop "$CONTAINER_NAME"
        sleep 1
    else
        echo "Exiting to avoid conflicts."
        exit 0
    fi
fi

echo "Launching ${CONTAINER_NAME} in ROS 2 Jazzy as ${TARGET_USER}..."

# 5. Start the container
docker run -itd \
  --name "$CONTAINER_NAME" \
  --rm \
  --privileged \
  --network host \
  --ipc host \
  --user "$TARGET_USER" \
  --ulimit rtprio=90 \
  --ulimit memlock=-1 \
  --cap-add=sys_nice \
  --cap-add=ipc_lock \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "/etc/localtime:/etc/localtime:ro" \
  -v "${PROJECT_ROOT}:/home/${TARGET_USER}/${CONTAINER_NAME}" \
  -v "${PROJECT_ROOT}/../rosbags:/home/${TARGET_USER}/rosbags" \
  --env-file "$PROJECT_ROOT/.env" \
  -e DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  "$IMAGE_NAME" \
  tail -f /dev/null

echo "--- Status ---"
docker ps -f name="^/${CONTAINER_NAME}$"
