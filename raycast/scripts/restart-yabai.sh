#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Restart yabai
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ♻️
# @raycast.packageName Window Management

# Documentation:
# @raycast.description Restart the yabai service to pick up yabairc changes. skhd is not restarted — it hot-reloads skhdrc on save by itself.
# @raycast.author Mark Adam

# Raycast runs script commands with a minimal environment that does not include
# Homebrew, so every binary used here has to be reachable explicitly.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# yabai-msg and sketchybar-msg both abort with "'env USER' not set!" if USER
# is missing, which a stripped environment will not provide.
export USER="${USER:-$(id -un)}"
set -euo pipefail

yabai --restart-service

# --restart-service returns before the daemon is back up, so confirm rather
# than reporting success on faith.
for _ in $(seq 1 10); do
	if pgrep -xq yabai; then
		echo "yabai restarted (layout: $(yabai -m config layout 2>/dev/null || echo '?'))"
		exit 0
	fi
	sleep 0.3
done

echo "yabai did not come back up — check: tail /opt/homebrew/var/log/yabai/yabai.err.log"
exit 1
