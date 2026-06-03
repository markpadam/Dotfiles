#!/usr/bin/env bash
set -euo pipefail

echo "[*] WSL detected — using Docker Desktop backend"

# WSL should use Docker Desktop; install the CLI helper packages and common tools.
sudo apt install -y docker.io

if ! command -v kubectl >/dev/null 2>&1; then
    curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /tmp/kubectl
    sudo mv /tmp/kubectl /usr/local/bin/kubectl
    sudo chmod +x /usr/local/bin/kubectl
fi

if ! command -v helm >/dev/null 2>&1; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
