#!/usr/bin/env bash
# Highlights the active Mission Control space. $SELECTED is supplied by the
# `space` component itself — no window manager needed.

source "$CONFIG_DIR/colors.sh"

# label.color tracks the icon: the app icons sit inside the same pill, so they
# have to invert to dark when the mauve highlight is painted behind them.
if [ "$SELECTED" = "true" ]; then
	sketchybar --set "$NAME" \
		background.drawing=on \
		background.color="$ACCENT_SPACES" \
		icon.color="$BASE" \
		label.color="$BASE"
else
	sketchybar --set "$NAME" \
		background.drawing=off \
		icon.color="$OVERLAY0" \
		label.color="$SUBTEXT0"
fi
