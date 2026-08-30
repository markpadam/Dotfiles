#!/usr/bin/env bash
# `airport -I` was removed in Sonoma; `ipconfig getsummary` is the current way
# to read the SSID without extra permissions.
#
# Click toggles between SSID and local IP.
#
# The interface is whichever one currently carries the default route, not a
# hardcoded en0. en0 is the *Wi-Fi* card on this Mac and the Ethernet adapters
# come up as en4/en5/en6, so asking en0 for a wired address could never
# succeed — on Ethernet with Wi-Fi off this reported "Offline" rather than
# "Wired". Following the default route also picks the link actually in use when
# both are up.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

IFACE=$(route -n get default 2>/dev/null | awk '/interface: / {print $2}')

# getsummary only reports an SSID for a Wi-Fi interface, so an empty result
# here is what distinguishes wired from wireless below.
SSID=$(ipconfig getsummary "${IFACE:-en0}" 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2}' | head -1)
IP=$(ipconfig getifaddr "${IFACE:-en0}" 2>/dev/null)

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
