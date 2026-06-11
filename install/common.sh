#!/usr/bin/env bash
set -euo pipefail

# Common dependencies for Ubuntu and WSL.
# Docker differs per platform and is handled by the environment-specific installer.

sudo apt update
sudo apt install -y \
    git curl wget tmux vim fzf ripgrep jq unzip \
    ca-certificates gnupg lsb-release \
    build-essential \
    software-properties-common

# Map dpkg arch -> the names used by k8s / k9s release artifacts.
case "$(dpkg --print-architecture)" in
    amd64) ARCH=amd64 ;;
    arm64) ARCH=arm64 ;;
    *)     ARCH=amd64 ;;
esac

# kubectl — reinstall if missing OR not runnable (e.g. a stale x86 binary on an
# arm VM, which `command -v` alone would not catch).
if ! kubectl version --client >/dev/null 2>&1; then
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

# neovim (for LazyVim). Distro packages lag behind what LazyVim needs, so use
# the official release tarball — matches the recent nvim used on the Mac.
case "$ARCH" in
    arm64) NVARCH=arm64 ;;
    *)     NVARCH=x86_64 ;;
esac
if ! command -v nvim >/dev/null 2>&1; then
    echo "[*] Installing neovim ($NVARCH)..."
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVARCH}.tar.gz" -o /tmp/nvim.tar.gz
    sudo rm -rf "/opt/nvim-linux-${NVARCH}"
    sudo tar -C /opt -xzf /tmp/nvim.tar.gz
    sudo ln -sfn "/opt/nvim-linux-${NVARCH}/bin/nvim" /usr/local/bin/nvim
    rm -f /tmp/nvim.tar.gz
fi

# node (for LazyVim's npm-based LSPs — yaml-language-server etc. — and Copilot).
# Use NodeSource's single nodejs package, not Ubuntu's bloated node-* set which
# pulls ~100 helper packages and is easy to run a small VM disk out of space on.
if ! command -v node >/dev/null 2>&1; then
    echo "[*] Installing node (NodeSource)..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
