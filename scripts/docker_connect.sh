#!/bin/bash

# 1. Absolute path discovery
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Find Project Root and Load .env
# We know .env is in the root, and this script is in /scripts
if [ -f "$SCRIPT_DIR/../.env" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
elif [ -f "$SCRIPT_DIR/.env" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
fi

# Fallback variables
CONTAINER_NAME="${PROJECT_NAME:-docker_template}"
TARGET_USER="${USERNAME:-ros}"

# 3. Prevent "Nesting" (Check if we are already inside the container)
if [ -f /.dockerenv ]; then
    echo "You are already inside a Docker container!"
    exit 0
fi

# 4. Check if the container is actually running
# The ^/ and $ ensure we don't match 'docker_template_v2' by accident
if [ -z "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Error: Container '${CONTAINER_NAME}' is not running."
    echo "Run './scripts/docker_run.sh' first."
    exit 1
fi

# 5. Execute bash
echo "Connecting to ${CONTAINER_NAME} as ${TARGET_USER}..."
# Using --user ensures you don't accidentally enter as root
docker exec -it --user "$TARGET_USER" "$CONTAINER_NAME" /bin/bash
