#!/bin/bash

# 1. Absolute path discovery
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Find Project Root and Load .env
# Specifically looking for the .env in the root folder above /scripts
if [ -f "$SCRIPT_DIR/../.env" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
elif [ -f "$SCRIPT_DIR/.env" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
fi

# Fallback variable
CONTAINER_NAME="${PROJECT_NAME:-docker_template}"

# 3. Check and Stop
# FIX: Added -n and wrapped the regex filter in quotes to prevent bash expansion errors
if [ -n "$(docker ps -a -q -f name="^/${CONTAINER_NAME}$")" ]; then
    echo "Stopping and removing container: ${CONTAINER_NAME}..."
    
    # Stop the container
    docker stop "$CONTAINER_NAME" > /dev/null
    
    # Since we use --rm in docker_run, it usually deletes itself,
    # but 'docker rm' here acts as a safety for failed cleanup.
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    
    echo "Done. Environment for ${CONTAINER_NAME} is clean."
else
    echo "Container '${CONTAINER_NAME}' is not currently running."
fi
