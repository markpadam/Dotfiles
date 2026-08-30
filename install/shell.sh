#!/usr/bin/env bash
set -euo pipefail

# oh-my-zsh and the two zsh plugins referenced by .zshrc. These live outside
# Homebrew (they are plain git clones under ~/.oh-my-zsh/custom), so without
# this step a fresh machine gets a .zshrc with no autosuggestions or syntax
# highlighting. The prompt itself is Starship (installed via Brewfile,
# configured by config/starship.toml) — no oh-my-zsh theme is used.

ZSH_DIR="$HOME/.oh-my-zsh"
CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

if [ ! -d "$ZSH_DIR" ]; then
    echo "[*] Installing oh-my-zsh..."
    # --unattended: don't chsh or launch a subshell, bootstrap continues after.
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended
else
    echo "[*] oh-my-zsh already present."
fi

# repo-url:destination pairs, cloned shallow — we only ever track upstream HEAD.
clone_if_missing() {
    local url="$1" dest="$2"
    if [ -d "$dest" ]; then
        echo "[*] $(basename "$dest") already present."
    else
        echo "[*] Cloning $(basename "$dest")..."
        git clone --depth=1 "$url" "$dest"
    fi
}

clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
    "$CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting \
    "$CUSTOM/plugins/zsh-syntax-highlighting"

echo "[*] Shell environment ready."
