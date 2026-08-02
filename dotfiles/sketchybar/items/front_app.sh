#!/usr/bin/env bash
# Focused application: glyph from sketchybar-app-font + app name.

sketchybar --add item front_app left \
	--set front_app \
	icon.font="$APP_FONT:Regular:16.0" \
	icon.color="$ACCENT_APP" \
	icon.padding_left=10 \
	icon.padding_right=6 \
	label.font="$FONT:Bold:12.0" \
	label.color="$TEXT" \
	label.padding_right=10 \
	script="$PLUGIN_DIR/front_app.sh" \
	click_script="open -a 'Mission Control'" \
	--subscribe front_app front_app_switched

sketchybar --add bracket app_island front_app \
	--set app_island \
	background.color="$ISLAND_COLOR" \
	background.corner_radius=10 \
	background.height=26 \
	background.border_width=1 \
	background.border_color="$ISLAND_BORDER"
