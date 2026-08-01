#!/usr/bin/env bash
# System status island. Items added to `right` stack right-to-left, so the
# first one added sits furthest right. Clock is sourced before this file, so
# it stays pinned to the far right and this island sits to its left.
#
# Visual order, left to right: cpu | memory | wifi | volume | brightness | battery

sketchybar --add item battery right \
	--set battery \
	update_freq=60 \
	icon.color="$GREEN" \
	icon.padding_left=8 \
	label.padding_right=10 \
	script="$PLUGIN_DIR/battery.sh" \
	click_script="open -b com.apple.systempreferences /System/Library/PreferencePanes/Battery.prefPane" \
	--subscribe battery power_source_change system_woke

sketchybar --add item brightness right \
	--set brightness \
	update_freq=30 \
	icon="$ICON_BRIGHTNESS" \
	icon.color="$YELLOW" \
	script="$PLUGIN_DIR/brightness.sh" \
	--subscribe brightness brightness_change

sketchybar --add item volume right \
	--set volume \
	icon.color="$SKY" \
	script="$PLUGIN_DIR/volume.sh" \
	click_script="osascript -e 'set volume output muted not (output muted of (get volume settings))'" \
	--subscribe volume volume_change

sketchybar --add item wifi right \
	--set wifi \
	update_freq=30 \
	icon="$ICON_WIFI" \
	icon.color="$ACCENT_SYSTEM" \
	script="$PLUGIN_DIR/wifi.sh" \
	click_script="$PLUGIN_DIR/wifi.sh toggle_detail" \
	--subscribe wifi wifi_change system_woke

sketchybar --add item memory right \
	--set memory \
	update_freq=5 \
	icon="$ICON_MEMORY" \
	icon.color="$LAVENDER" \
	script="$PLUGIN_DIR/memory.sh" \
	click_script="open -a 'Activity Monitor'"

sketchybar --add item cpu right \
	--set cpu \
	update_freq=3 \
	icon="$ICON_CPU" \
	icon.color="$MAUVE" \
	icon.padding_left=10 \
	script="$PLUGIN_DIR/cpu.sh" \
	click_script="open -a 'Activity Monitor'"

sketchybar --add bracket system_island cpu memory wifi volume brightness battery \
	--set system_island \
	background.color="$ISLAND_COLOR" \
	background.corner_radius=10 \
	background.height=26 \
	background.border_width=1 \
	background.border_color="$ISLAND_BORDER"
