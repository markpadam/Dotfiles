#!/usr/bin/env bash
# Highlights the active Mission Control space. $SELECTED is supplied by the
# `space` component itself — no window manager needed.

source "$CONFIG_DIR/colors.sh"

if [ "$SELECTED" = "true" ]; then
	sketchybar --set "$NAME" \
		background.drawing=on \
		background.color="$ACCENT_SPACES" \
		icon.color="$BASE"
else
	sketchybar --set "$NAME" \
		background.drawing=off \
		icon.color="$OVERLAY0"
fi
