#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Space Layout
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🪟
# @raycast.packageName Window Management

# Documentation:
# @raycast.description Flip the current desktop between float (macOS behaves normally) and bsp (yabai auto-tiles). Same as Ctrl+Alt+T.
# @raycast.author Mark Adam

# Raycast runs script commands with a minimal environment that does not include
# Homebrew, so every binary used here has to be reachable explicitly.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# yabai-msg and sketchybar-msg both abort with "'env USER' not set!" if USER
# is missing, which a stripped environment will not provide.
export USER="${USER:-$(id -un)}"
set -euo pipefail

if ! pgrep -xq yabai; then
	echo "yabai is not running"
	exit 1
fi

~/.config/yabai/scripts/toggle-layout.sh
echo "Space is now $(yabai -m query --spaces --space | jq -r '.type')"
