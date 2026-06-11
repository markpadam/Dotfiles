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
    # --autostash so per-machine tweaks (e.g. a custom PS1 in .zshrc) don't
    # block the pull: git stashes them, rebases, then reapplies.
    git -C "$DOTFILES" pull --rebase --autostash
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

# Per-machine git identity lives in ~/.gitconfig.local (not synced).
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

# ~/.gitconfig is a REAL per-machine file (NOT a symlink), so git's own runtime
# writes (safe.directory, git-lfs filters) stay out of the tracked repo. It just
# includes the shared config + this machine's identity.
GITCONFIG="$HOME/.gitconfig"
GITSHARED="$DOTFILES/dotfiles/gitconfig.shared"
if [ -L "$GITCONFIG" ]; then
    # Migrate from the old symlinked-.gitconfig setup.
    echo "[*] Replacing symlinked ~/.gitconfig with a real include file"
    rm -f "$GITCONFIG"
fi
if [ ! -e "$GITCONFIG" ]; then
    printf '[include]\n\tpath = %s\n[include]\n\tpath = %s\n' \
        "$GITSHARED" "$GITLOCAL" > "$GITCONFIG"
elif ! grep -qF "$GITSHARED" "$GITCONFIG"; then
    # Real file already there (hand-made) — just prepend our include once,
    # leaving any runtime settings git appended below it untouched.
    echo "[*] Adding shared-config include to existing ~/.gitconfig"
    printf '[include]\n\tpath = %s\n' "$GITSHARED" | cat - "$GITCONFIG" > "$GITCONFIG.tmp"
    mv "$GITCONFIG.tmp" "$GITCONFIG"
fi
# Re-register the git-lfs filters in the new ~/.gitconfig if git-lfs is present.
command -v git-lfs >/dev/null 2>&1 && git lfs install >/dev/null 2>&1 || true

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

# Neovim / LazyVim config lives under ~/.config/nvim (not a dotfile in ~), so
# it is symlinked separately. Same source of truth on Mac, multipass VM, WSL.
NVIM_SRC="$DOTFILES/config/nvim"
NVIM_DST="$HOME/.config/nvim"
if [ -d "$NVIM_SRC" ]; then
    mkdir -p "$HOME/.config"
    # If a real dir (not our symlink) is in the way, back it up once.
    if [ -e "$NVIM_DST" ] && [ ! -L "$NVIM_DST" ]; then
        echo "[*] Backing up existing ~/.config/nvim -> nvim.bak"
        rm -rf "$NVIM_DST.bak"
        mv "$NVIM_DST" "$NVIM_DST.bak"
    fi
    ln -sfn "$NVIM_SRC" "$NVIM_DST"
fi

# Our .bashrc and .zshrc already source profile.d, so nothing else to wire up.
echo "[*] Done. Reload your shell."
