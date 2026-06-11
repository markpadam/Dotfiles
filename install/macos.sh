#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
    echo "[*] Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew update

# Install only what's missing — don't upgrade tools the machine already has.
# (`brew install <formula>` would upgrade outdated formulae; we avoid that so
# bootstrap stays a setup step, not a surprise system-wide upgrade.)
FORMULAE=(git tmux vim neovim node fzf ripgrep jq kubectl helm k9s kubectx)
missing=()
for f in "${FORMULAE[@]}"; do
    brew list --formula "$f" >/dev/null 2>&1 || missing+=("$f")
done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "[*] Installing: ${missing[*]}"
    brew install "${missing[@]}"
else
    echo "[*] All formulae already installed — nothing to do."
fi

# Docker Desktop (cask). Skip if already present so we don't reinstall/upgrade.
brew list --cask docker >/dev/null 2>&1 || brew install --cask docker || true
