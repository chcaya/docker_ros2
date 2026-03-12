#!/bin/bash

# 1. Absolute path discovery
# This finds where the script lives (e.g., project_root/scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Search for .env and determine Project Root
# Based on your setup, .env is one level up from the scripts folder
if [ -f "$SCRIPT_DIR/../.env" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    # This loads PROJECT_NAME, USERNAME, etc. into the script's memory
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
else
    echo "Error: .env file not found in project root ($SCRIPT_DIR/..)"
    exit 1
fi

# Fallback variable from .env
CONTAINER_NAME="${PROJECT_NAME:-docker_template}"
# Fallback for user just in case it's missing from .env
TARGET_USER="${USERNAME:-ros}"

# 3. Handle Running Container
# Prevents building if a container is currently locking resources
if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    read -p "Container '${CONTAINER_NAME}' is running. Stop it? (y/n): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Stopping ${CONTAINER_NAME}..."
        docker stop "$CONTAINER_NAME"
    else
        echo "Build aborted by user."
        exit 0
    fi
fi

# 4. Run the Build from the Project Root
# This is critical so the COPY commands in the Dockerfile can see the /src folder
cd "$PROJECT_ROOT"

echo "Building Docker image: ${CONTAINER_NAME}:latest for user: ${TARGET_USER}..."

docker build \
    --network host \
    --build-arg USER_UID=$(id -u) \
    --build-arg USER_GID=$(id -g) \
    --build-arg PROJECT_NAME="${CONTAINER_NAME}" \
    --build-arg USERNAME="${TARGET_USER}" \
    -t "${CONTAINER_NAME}:latest" \
    -f ./docker/Dockerfile .

# 5. Result check
if [ $? -eq 0 ]; then
    echo "-------------------------------------------------------"
    echo "Successfully built ${CONTAINER_NAME}."
    echo "Build Context: $PROJECT_ROOT"
    echo "User Identity: $TARGET_USER"
    echo "Dockerfile   : ./docker/Dockerfile"
    echo "-------------------------------------------------------"
else
    echo "ERROR: Build failed. Check the logs above."
    exit 1
fi
