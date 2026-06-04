#!/usr/bin/env bash
set -euo pipefail

echo "[*] Ubuntu VM detected"

# Kubernetes tooling (kubectl/helm/k9s/kubectx) is installed by common.sh.
# Ubuntu runs its own Docker daemon.
sudo apt install -y docker.io
sudo systemctl enable --now docker

# Let the current user run docker without sudo (takes effect on next login).
if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    echo "[*] Added $USER to docker group — log out/in for it to take effect."
fi
