#!/usr/bin/env bash
# No CLI reads display brightness on Apple Silicon, but the backlight driver
# publishes it in IORegistry as a value/max pair under IODisplayParameters.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

PARAMS=$(ioreg -c AppleARMBacklight -r -d 1 2>/dev/null | grep -o '"brightness"={[^}]*}' | head -1)
VALUE=$(echo "$PARAMS" | grep -o '"value"=[0-9]*' | cut -d= -f2)
MAX=$(echo "$PARAMS" | grep -o '"max"=[0-9]*' | cut -d= -f2)

if [ -z "$VALUE" ] || [ -z "$MAX" ] || [ "$MAX" -eq 0 ]; then
	sketchybar --set "$NAME" drawing=off
	exit 0
fi

PERCENT=$((VALUE * 100 / MAX))

if [ "$PERCENT" -lt 25 ]; then
	ICON="$ICON_BRIGHTNESS_LOW"
else
	ICON="$ICON_BRIGHTNESS"
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color="$YELLOW" label="${PERCENT}%"
