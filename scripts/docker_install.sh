#!/bin/bash
set -euo pipefail

# 1. Absolute path discovery
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Re-run as root if needed
if [[ $EUID -ne 0 ]]; then
  echo "Elevating privileges to install Docker..."
  exec sudo -E bash "$0" "$@"
fi

# 3. Identify the real user (the one who called sudo)
TARGET_USER="${SUDO_USER:-$USER}"

echo "--- Removing conflicting packages ---"
OLD_PKGS=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)
for pkg in "${OLD_PKGS[@]}"; do
    apt-get remove -y "$pkg" || true
done

echo "--- Setting up Docker Repository for Ubuntu 24.04+ ---"
apt-get update
apt-get install -y ca-certificates curl gnupg

# Modern GPG handling
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources using the GPG key
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "--- Installing Docker Engine ---"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "--- Configuring Permissions for $TARGET_USER ---"
if ! getent group docker > /dev/null; then
    groupadd docker
fi
usermod -aG docker "$TARGET_USER"

# Enable and start Docker services
systemctl enable docker.service
systemctl enable containerd.service

echo "--- Testing Installation ---"
# Check if we can run docker without sudo (might require newgrp in current shell)
sudo -u "$TARGET_USER" docker run --rm hello-world || echo "Note: Initial test without sudo failed as expected; shell restart required."

echo "--------------------------------------------------------"
echo "Installation complete for user: ${TARGET_USER}"
echo "--------------------------------------------------------"
echo "CRITICAL STEP: To use Docker without 'sudo', you MUST"
echo "log out and log back in, OR run the following command:"
echo ""
echo "    newgrp docker"
echo ""
echo "Then try running 'docker ps' to verify."
echo "--------------------------------------------------------"
