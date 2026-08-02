#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reseed Desktop Names
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🏷️
# @raycast.packageName Window Management

# Documentation:
# @raycast.description Rename the Mission Control desktops back to Term/Web/Lab/Notes/Comms via DesktopRenamer. Idempotent — does nothing if they already match.
# @raycast.author Mark Adam

# Raycast runs script commands with a minimal environment that does not include
# Homebrew, so every binary used here has to be reachable explicitly.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
set -euo pipefail

# fullOutput rather than compact: this one reports per-desktop what it changed,
# and silently swallowing that would hide a partial rename.
exec ~/.dotfiles/macos/seed-spaces.sh --apply
