#!/usr/bin/env bash
set -euo pipefail

# Restore this Mac's setup from the repo. Safe to re-run: every step is
# idempotent, installs are additive, and any real file already in the way is
# backed up to <name>.bak before a symlink replaces it.

REPO="https://github.com/markpadam/Dotfiles.git"
DOTFILES="$HOME/.dotfiles"
export DOTFILES

echo "[*] Bootstrapping Dotfiles..."

if [ ! -d "$DOTFILES" ]; then
    echo "[*] Cloning Dotfiles repo..."
    git clone "$REPO" "$DOTFILES"
else
    echo "[*] Updating Dotfiles repo..."
    # --autostash so per-machine tweaks don't block the pull: git stashes them,
    # rebases, then reapplies.
    git -C "$DOTFILES" pull --rebase --autostash
fi

if [ "$(uname)" != "Darwin" ]; then
    echo "[!] This repo is a macOS backup; package restore is macOS-only."
    echo "[!] Continuing with symlinks only."
    MACOS=0
else
    MACOS=1
fi

# --- packages ---------------------------------------------------------------
if [ "$MACOS" = "1" ]; then
    bash "$DOTFILES/install/macos.sh"
    bash "$DOTFILES/install/shell.sh"
fi

# --- git identity -----------------------------------------------------------
# Per-machine identity lives in ~/.gitconfig.local and is deliberately NOT
# tracked, so a work machine can differ without dirtying the repo.
GITLOCAL="$HOME/.gitconfig.local"
if [ ! -f "$GITLOCAL" ]; then
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
    echo "[*] Replacing symlinked ~/.gitconfig with a real include file"
    rm -f "$GITCONFIG"
fi
if [ ! -e "$GITCONFIG" ]; then
    printf '[include]\n\tpath = %s\n[include]\n\tpath = %s\n' \
        "$GITSHARED" "$GITLOCAL" > "$GITCONFIG"
elif ! grep -qF "$GITSHARED" "$GITCONFIG"; then
    echo "[*] Adding shared-config include to existing ~/.gitconfig"
    printf '[include]\n\tpath = %s\n' "$GITSHARED" | cat - "$GITCONFIG" > "$GITCONFIG.tmp"
    mv "$GITCONFIG.tmp" "$GITCONFIG"
fi
command -v git-lfs >/dev/null 2>&1 && git lfs install >/dev/null 2>&1 || true

# --- symlink helper ---------------------------------------------------------
# Backs up a pre-existing real file/dir once, then points target at source.
link() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "[*] Backing up existing $(basename "$dst") -> $(basename "$dst").bak"
        rm -rf "$dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sfn "$src" "$dst"
}

# --- home dotfiles ----------------------------------------------------------
echo "[*] Linking dotfiles into \$HOME..."
for file in "$DOTFILES/dotfiles"/.*; do
    base=$(basename "$file")
    [[ "$base" == "." || "$base" == ".." ]] && continue
    link "$file" "$HOME/$base"
done

# --- ~/.config --------------------------------------------------------------
mkdir -p "$HOME/.config"

echo "[*] Linking ~/.config entries..."
# borders, aerospace and sketchybar live under dotfiles/ (not config/)
# because that is where the existing symlink on this Mac already points.
for name in borders aerospace sketchybar; do
    [ -e "$DOTFILES/dotfiles/$name" ] && link "$DOTFILES/dotfiles/$name" "$HOME/.config/$name"
done

for src in "$DOTFILES/config"/*; do
    [ -e "$src" ] || continue
    link "$src" "$HOME/.config/$(basename "$src")"
done

# --- snapshot-only configs --------------------------------------------------
# These apps rewrite their own config at runtime, so they are copied rather than
# symlinked — a symlink would let the app commit its runtime state (and, for gh,
# potentially an auth token) straight into this public repo.
echo "[*] Restoring snapshot configs (copy, not symlink)..."
for src in "$DOTFILES/snapshots"/*; do
    [ -d "$src" ] || continue
    name=$(basename "$src")
    dst="$HOME/.config/$name"
    if [ -e "$dst" ]; then
        echo "    skipping $name (already present — not overwriting live config)"
    else
        cp -R "$src" "$dst"
        echo "    restored $name"
    fi
done

# --- VS Code ----------------------------------------------------------------
[ "$MACOS" = "1" ] && bash "$DOTFILES/install/vscode.sh"

# --- macOS defaults ---------------------------------------------------------
# Not run automatically: it restarts Dock/Finder and changes system appearance,
# which is rude to do behind someone's back on an already-configured machine.
if [ "$MACOS" = "1" ]; then
    echo
    echo "[*] To apply macOS system preferences, run:"
    echo "      bash $DOTFILES/macos/defaults.sh"
fi

echo "[*] Done. Reload your shell."
