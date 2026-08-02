#!/usr/bin/env bash
# $INFO holds the newly focused app's name on a front_app_switched event.

if [ "$SENDER" != "front_app_switched" ]; then
	exit 0
fi

icon=":default:"
if [ -f "$CONFIG_DIR/icon_map.sh" ]; then
	source "$CONFIG_DIR/icon_map.sh"
	__icon_map "$INFO"
	icon="$icon_result"
fi

sketchybar --set "$NAME" icon="$icon" label="$INFO"
