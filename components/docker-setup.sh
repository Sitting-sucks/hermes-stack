#!/usr/bin/env bash
# docker-setup.sh — Install Docker CE in WSL Ubuntu (no Docker Desktop needed)
#
# Run with: sudo bash docker-setup.sh
#
# This installs Docker CE directly in WSL, which is more reliable than
# Docker Desktop's WSL integration. Docker will start automatically on
# WSL boot via systemd (if enabled) or can be started manually.

set -euo pipefail

echo "=== Installing Docker CE in WSL ==="

# Remove old Docker packages if any
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Set up Docker's apt repository
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
usermod -aG docker "$SUDO_USER"

# Start Docker
systemctl enable docker
systemctl start docker

echo ""
echo "=== Docker installed successfully ==="
docker --version
docker compose version
echo ""
echo "NOTE: Log out and back in (or run 'newgrp docker') to use docker without sudo."
echo "Docker will auto-start on WSL boot via systemd."
