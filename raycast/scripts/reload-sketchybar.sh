#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reload SketchyBar
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 📊
# @raycast.packageName Window Management

# Documentation:
# @raycast.description Re-read the SketchyBar config after editing it in the dotfiles repo.
# @raycast.author Mark Adam

# Raycast runs script commands with a minimal environment that does not include
# Homebrew, so every binary used here has to be reachable explicitly.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# yabai-msg and sketchybar-msg both abort with "'env USER' not set!" if USER
# is missing, which a stripped environment will not provide.
export USER="${USER:-$(id -un)}"
set -euo pipefail

if ! pgrep -xq sketchybar; then
	echo "SketchyBar is not running — start it with: brew services start sketchybar"
	exit 1
fi

sketchybar --reload
echo "SketchyBar reloaded"
