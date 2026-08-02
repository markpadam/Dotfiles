#!/usr/bin/env bash
set -euo pipefail

# Reinstall the VS Code extensions recorded in packages/vscode-extensions.txt.
# Skipped silently when VS Code isn't installed, so this is safe to call from
# bootstrap on a headless or minimal machine.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
LIST="$DOTFILES/packages/vscode-extensions.txt"

# The `code` shim isn't on PATH until VS Code installs it, so fall back to the
# binary inside the app bundle.
CODE_BIN=""
if command -v code >/dev/null 2>&1; then
    CODE_BIN="code"
elif [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
    CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
else
    echo "[*] VS Code not found — skipping extension restore."
    exit 0
fi

[ -f "$LIST" ] || { echo "[!] $LIST missing — skipping."; exit 0; }

echo "[*] Restoring VS Code extensions..."
while IFS= read -r ext; do
    # Tolerate blank lines and comments in the list.
    case "$ext" in ''|\#*) continue ;; esac
    "$CODE_BIN" --install-extension "$ext" --force || echo "[!] failed: $ext"
done < "$LIST"

echo "[*] VS Code extensions restored."
