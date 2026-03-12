#!/usr/bin/env bash
set -euo pipefail

# 1. Absolute path discovery
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Find Project Root and Load .env
# Using a more robust lookup for the .env file
if [ -f "$SCRIPT_DIR/../.env" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    # Load variables while ignoring comments and empty lines
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
elif [ -f "$SCRIPT_DIR/.env" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
else
    PROJECT_ROOT="$SCRIPT_DIR"
fi

# Fallback variables
PROJECT_NAME="${PROJECT_NAME:-docker_template}"
CONTAINER_NAME="${PROJECT_NAME}"
TARGET_DISPLAY="${DISPLAY:-:0}"

# 3. Re-run as root if needed (Standard elevation)
if [[ $EUID -ne 0 ]]; then
  echo "Elevating privileges to install systemd service..."
  exec sudo -E bash "$0" "$@"
fi

# 4. Resolve Target Script
TARGET="${SCRIPT_DIR}/docker_run.sh"
if [[ ! -f "$TARGET" ]]; then
  echo "ERROR: ${TARGET} not found." >&2
  exit 1
fi
chmod +x "$TARGET"

# 5. Define Service Names
SERVICE_NAME="${PROJECT_NAME}-startup"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
WRAPPER="/usr/local/bin/${SERVICE_NAME}-wrapper.sh"

# Get host user details for X11/Volume permissions
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "--- Installing Systemd Service: ${SERVICE_NAME} ---"

# 6. Create Wrapper 
# We improved the wrapper to be more resilient to container state
cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "${SCRIPT_DIR}"

# 1. Ensure any stale container instance is cleared before starting
docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true

# 2. Spin up the container using your existing run script
"${TARGET}"

# 3. Block and track the container lifecycle
# Using 'docker wait' ensures systemd understands when the process actually ends
exec docker wait "${CONTAINER_NAME}"
EOF
chmod +x "$WRAPPER"

# 7. Create Systemd Unit
# We use 'Type=exec' (available in modern systemd) for better process tracking
cat > "$UNIT_PATH" <<EOF
[Unit]
Description=ROS 2 Startup Service: ${PROJECT_NAME}
After=network-online.target docker.service display-manager.service
Wants=network-online.target docker.service display-manager.service
Requires=docker.service

[Service]
Type=simple
User=${REAL_USER}
Group=docker
WorkingDirectory=${SCRIPT_DIR}

# Wait for hardware/drivers (GPUs/USB) to settle
ExecStartPre=/bin/sleep 5

# Start the wrapper
ExecStart=${WRAPPER}

# Cleanly stop the container on shutdown
ExecStop=/usr/bin/docker stop ${CONTAINER_NAME}

# Environment for X11 Forwarding
Environment="DISPLAY=${TARGET_DISPLAY}"
Environment="XAUTHORITY=${REAL_HOME}/.Xauthority"
Environment="PYTHONUNBUFFERED=1"

# Restart logic
Restart=always
RestartSec=10s
StartLimitIntervalSec=0

# Logging
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 8. Permissions and Reload
chmod 644 "$UNIT_PATH"
systemctl unmask "${SERVICE_NAME}.service" 2>/dev/null
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"

echo "-------------------------------------------------------"
echo "Installation Complete"
echo "-------------------------------------------------------"
echo "To start:       sudo systemctl start ${SERVICE_NAME}"
echo "To check logs:  journalctl -u ${SERVICE_NAME} -f"
echo "-------------------------------------------------------"
