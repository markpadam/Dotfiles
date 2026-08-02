#!/usr/bin/env bash
# Clock + date island, far right.

sketchybar --add item clock right \
	--set clock \
	update_freq=15 \
	icon="$ICON_CLOCK" \
	icon.color="$ACCENT_CLOCK" \
	icon.padding_left=10 \
	icon.padding_right=6 \
	label.color="$TEXT" \
	label.padding_right=10 \
	script="$PLUGIN_DIR/clock.sh" \
	click_script="open -a 'Calendar'"

sketchybar --add bracket clock_island clock \
	--set clock_island \
	background.color="$ISLAND_COLOR" \
	background.corner_radius=10 \
	background.height=26 \
	background.border_width=1 \
	background.border_color="$ISLAND_BORDER"
