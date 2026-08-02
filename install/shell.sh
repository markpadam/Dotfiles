#!/usr/bin/env bash
set -euo pipefail

# oh-my-zsh, the powerlevel10k theme and the two zsh plugins referenced by
# .zshrc. These live outside Homebrew (they are plain git clones under
# ~/.oh-my-zsh/custom), so without this step a fresh machine gets a .zshrc that
# silently falls back to the bare `user@host:~$` prompt.

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

clone_if_missing https://github.com/romkatv/powerlevel10k.git \
    "$CUSTOM/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
    "$CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting \
    "$CUSTOM/plugins/zsh-syntax-highlighting"

# The prompt itself is configured by the tracked ~/.p10k.zsh (a Catppuccin
# Mocha p10k config), which bootstrap symlinks into place — no `p10k configure`
# run is needed on a restored machine.

echo "[*] Shell environment ready."
