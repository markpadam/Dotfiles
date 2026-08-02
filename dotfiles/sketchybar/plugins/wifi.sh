#!/usr/bin/env bash
# `airport -I` was removed in Sonoma; `ipconfig getsummary` is the current way
# to read the SSID without extra permissions.
#
# Click toggles between SSID and local IP.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

SSID=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2}' | head -1)
IP=$(ipconfig getifaddr en0 2>/dev/null)

if [ "$1" = "toggle_detail" ]; then
	CURRENT=$(sketchybar --query "$NAME" | jq -r '.label.value')
	if [ "$CURRENT" = "$SSID" ] && [ -n "$IP" ]; then
		sketchybar --set "$NAME" label="$IP"
	else
		sketchybar --set "$NAME" label="${SSID:-Offline}"
	fi
	exit 0
fi

if [ -n "$SSID" ]; then
	sketchybar --set "$NAME" icon="$ICON_WIFI" icon.color="$ACCENT_SYSTEM" label="$SSID"
elif [ -n "$IP" ]; then
	sketchybar --set "$NAME" icon="$ICON_ETHERNET" icon.color="$BLUE" label="Wired"
else
	sketchybar --set "$NAME" icon="$ICON_WIFI_OFF" icon.color="$RED" label="Offline"
fi
