#!/usr/bin/env bash
set -e

REPO="https://github.com/markpadam/Dotfiles.git"
DOTFILES="$HOME/.dotfiles"

echo "[*] Bootstrapping Dotfiles..."

# Clone or update repo
if [ ! -d "$DOTFILES" ]; then
    echo "[*] Cloning Dotfiles repo..."
    git clone "$REPO" "$DOTFILES"
else
    echo "[*] Updating Dotfiles repo..."
    git -C "$DOTFILES" pull --rebase
fi

cd "$DOTFILES"

# Detect environment
if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    ENV="wsl"
elif [ "$(uname)" = "Darwin" ]; then
    ENV="macos"
else
    ENV="ubuntu"
fi

echo "[*] Detected environment: $ENV"

# Run installer
bash "$DOTFILES/install/common.sh"
bash "$DOTFILES/install/$ENV.sh"

# Symlink dotfiles
echo "[*] Linking dotfiles..."
for file in "$DOTFILES/dotfiles"/.*; do
    base=$(basename "$file")
    [[ "$base" == "." || "$base" == ".." ]] && continue
    ln -sf "$file" "$HOME/$base"
done

# Ensure profile.d is loaded
if ! grep -q "profile.d" "$HOME/.bashrc"; then
    echo 'for f in $HOME/.dotfiles/profile.d/*.sh; do [ -r "$f" ] && source "$f"; done' >> "$HOME/.bashrc"
fi

echo "[*] Done. Reload your shell."
