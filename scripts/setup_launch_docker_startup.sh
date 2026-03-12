#!/usr/bin/env bash
set -euo pipefail

# 1. Absolute path discovery
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Find Project Root and Load .env
if [ -f "$SCRIPT_DIR/../.env" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
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

# 3. Re-run as root if needed
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

# Get the actual host user running the sudo command, and their home directory for XAUTHORITY
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "--- Installing Systemd Service: ${SERVICE_NAME} ---"

# 6. Create Wrapper (Maintains container lifecycle tracking)
cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "${SCRIPT_DIR}"

# Spin up the container
"${TARGET}" "\$@"

# Attach to logs to block systemd. If container dies, systemd triggers restart!
exec docker logs -f "${CONTAINER_NAME}"
EOF
chmod +x "$WRAPPER"

# 7. Create Systemd Unit (Inspired by your legacy script)
cat > "$UNIT_PATH" <<EOF
[Unit]
Description=Run ${PROJECT_NAME} Docker container at boot
After=network-online.target docker.service display-manager.service
Wants=network-online.target docker.service display-manager.service
Requires=docker.service

[Service]
Type=simple
User=${REAL_USER}
WorkingDirectory=${SCRIPT_DIR}

# Wait for hardware/network to settle
ExecStartPre=/bin/sleep 5

# Start the wrapper
ExecStart=${WRAPPER}

# Cleanly stop the container
ExecStop=/usr/bin/docker stop ${CONTAINER_NAME}

# Inject GUI environments for host-to-container X11 forwarding
Environment="DISPLAY=${TARGET_DISPLAY}"
Environment="XAUTHORITY=${REAL_HOME}/.Xauthority"

# Reliability settings
TimeoutStartSec=300
Restart=on-failure
RestartSec=10s
StartLimitIntervalSec=300
StartLimitBurst=5
StandardOutput=journal
StandardError=journal
NoNewPrivileges=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# 8. Defensive Permissions and Unmasking
chmod 644 "$UNIT_PATH"
systemctl unmask "${SERVICE_NAME}.service" 2>/dev/null

# 9. Activation
echo "Reloading systemd and enabling service..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"

# Start now
if ! systemctl start "${SERVICE_NAME}.service"; then
  echo "Note: Service failed to start immediately. Check 'journalctl -u ${SERVICE_NAME}'" >&2
fi

echo "-------------------------------------------------------"
echo "Installation Complete"
echo "-------------------------------------------------------"
echo "Service File: ${UNIT_PATH}"
echo "User Account: ${REAL_USER}"
echo "Project Name: ${PROJECT_NAME}"
echo "XAuthority  : ${REAL_HOME}/.Xauthority"
echo ""
echo "To check status: systemctl status ${SERVICE_NAME}"
echo "To view logs:   journalctl -u ${SERVICE_NAME} -f"
echo "-------------------------------------------------------"
