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

# Run installer. common.sh is Linux-only (apt); macOS uses Homebrew in macos.sh.
if [ "$ENV" != "macos" ]; then
    bash "$DOTFILES/install/common.sh"
fi
bash "$DOTFILES/install/$ENV.sh"

# Preserve the existing git identity before our .gitconfig symlink replaces it.
# Our tracked .gitconfig includes ~/.gitconfig.local for per-machine identity.
GITLOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GITLOCAL" ]; then
    # Keep an existing identity if one is set; otherwise fall back to the
    # personal default. Edit ~/.gitconfig.local on the work machine if needed.
    GIT_NAME=$(git config --global user.name || true)
    GIT_EMAIL=$(git config --global user.email || true)
    [ -n "$GIT_NAME" ]  || GIT_NAME="Mark Adam"
    [ -n "$GIT_EMAIL" ] || GIT_EMAIL="markpadam@hotmail.com"
    echo "[*] Creating $GITLOCAL ($GIT_NAME <$GIT_EMAIL>)"
    {
        echo "[user]"
        printf '\tname = %s\n'  "$GIT_NAME"
        printf '\temail = %s\n' "$GIT_EMAIL"
    } > "$GITLOCAL"
fi

# Symlink dotfiles, backing up any pre-existing real files first.
echo "[*] Linking dotfiles..."
for file in "$DOTFILES/dotfiles"/.*; do
    base=$(basename "$file")
    [[ "$base" == "." || "$base" == ".." ]] && continue
    target="$HOME/$base"
    # If a real file/dir (not our symlink) is in the way, back it up once.
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "[*] Backing up existing $base -> $base.bak"
        mv "$target" "$target.bak"
    fi
    ln -sf "$file" "$target"
done

# Our .bashrc and .zshrc already source profile.d, so nothing else to wire up.
echo "[*] Done. Reload your shell."
