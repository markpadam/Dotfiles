#!/usr/bin/env bash
set -euo pipefail

# Common dependencies for Ubuntu and WSL.
# Additional platform-specific tooling is installed by the environment-specific installer.

sudo apt update
sudo apt install -y \
    git curl wget tmux vim fzf ripgrep jq \
    ca-certificates gnupg lsb-release \
    build-essential \
    software-properties-common
