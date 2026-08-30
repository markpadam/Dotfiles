#!/usr/bin/env bash
# Highlights the AeroSpace workspace this item represents.
# $FOCUSED_WORKSPACE arrives from aerospace.toml's exec-on-workspace-change
# hook via `sketchybar --trigger aerospace_workspace_change
# FOCUSED_WORKSPACE=...` (or the initial-paint call in items/workspaces.sh).

source "$CONFIG_DIR/colors.sh"

# workspace.web -> web
name="${NAME#workspace.}"

if [ "$name" = "$FOCUSED_WORKSPACE" ]; then
	sketchybar --set "$NAME" \
		background.drawing=on \
		background.color="$ACCENT_SPACES" \
		icon.color="$BASE"
else
	sketchybar --set "$NAME" \
		background.drawing=off \
		icon.color="$OVERLAY0"
fi
