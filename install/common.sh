#!/usr/bin/env bash
set -euo pipefail

# Common dependencies for Ubuntu and WSL.
# Docker differs per platform and is handled by the environment-specific installer.

sudo apt update
sudo apt install -y \
    git curl wget tmux vim fzf ripgrep jq \
    ca-certificates gnupg lsb-release \
    build-essential \
    software-properties-common

# Map dpkg arch -> the names used by k8s / k9s release artifacts.
case "$(dpkg --print-architecture)" in
    amd64) ARCH=amd64 ;;
    arm64) ARCH=arm64 ;;
    *)     ARCH=amd64 ;;
esac

# kubectl
if ! command -v kubectl >/dev/null 2>&1; then
    echo "[*] Installing kubectl ($ARCH)..."
    KVER="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
    curl -fsSL "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl" -o /tmp/kubectl
    sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
fi

# helm
if ! command -v helm >/dev/null 2>&1; then
    echo "[*] Installing helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# k9s
if ! command -v k9s >/dev/null 2>&1; then
    echo "[*] Installing k9s ($ARCH)..."
    curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz" -o /tmp/k9s.tar.gz
    tar -xzf /tmp/k9s.tar.gz -C /tmp k9s
    sudo install -m 0755 /tmp/k9s /usr/local/bin/k9s
    rm -f /tmp/k9s.tar.gz /tmp/k9s
fi

# kubectx + kubens (fast context/namespace switching)
if ! command -v kubectx >/dev/null 2>&1; then
    echo "[*] Installing kubectx/kubens..."
    sudo curl -fsSL https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o /usr/local/bin/kubectx
    sudo curl -fsSL https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens  -o /usr/local/bin/kubens
    sudo chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens
fi
