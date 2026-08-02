#!/usr/bin/env bash
set -euo pipefail

# Package restore for macOS. Everything this Mac has installed is pinned in the
# Brewfile at the repo root, so this stays a thin wrapper around `brew bundle`.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

if ! command -v brew >/dev/null 2>&1; then
    echo "[*] Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "[*] Restoring Homebrew packages from Brewfile..."
# `brew bundle install` is additive: it installs what's missing and leaves
# already-present formulae at their current version, so re-running bootstrap
# never turns into a surprise system-wide upgrade.
brew bundle install --file="$DOTFILES/Brewfile" --no-upgrade

echo "[*] Homebrew restore complete."
