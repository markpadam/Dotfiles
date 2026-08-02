#!/usr/bin/env bash
# Flip the current space between float (macOS behaves normally) and bsp
# (yabai auto-tiles). This is the opt-in switch the whole float-first setup is
# built around — see ~/.config/yabai/yabairc.
#
# The change is per-space and lasts until you toggle back or log out; it is not
# written to yabairc, so a restart returns every space to float.
set -euo pipefail

if [ "$(yabai -m query --spaces --space | jq -r '.type')" = "bsp" ]; then
	yabai -m space --layout float
else
	yabai -m space --layout bsp
fi
