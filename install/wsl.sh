#!/usr/bin/env bash
set -euo pipefail

echo "[*] WSL detected — using Docker Desktop backend"

# Kubernetes tooling (kubectl/helm/k9s/kubectx) is installed by common.sh.
# WSL should use Docker Desktop (enable WSL integration in its settings); we
# only install the CLI so `docker` resolves inside the distro.
sudo apt install -y docker.io
