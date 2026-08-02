#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

BATT=$(pmset -g batt)
PERCENT=$(echo "$BATT" | grep -Eo '[0-9]+%' | head -1 | cut -d% -f1)
CHARGING=$(echo "$BATT" | grep -c 'AC Power')

if [ -z "$PERCENT" ]; then
	exit 0
fi

if [ "$CHARGING" -ne 0 ]; then
	ICON="$ICON_BATTERY_CHARGING"
	COLOR="$GREEN"
else
	case "$PERCENT" in
	9[0-9] | 100) ICON="$ICON_BATTERY_100" ;;
	[6-8][0-9]) ICON="$ICON_BATTERY_75" ;;
	[3-5][0-9]) ICON="$ICON_BATTERY_50" ;;
	[1-2][0-9]) ICON="$ICON_BATTERY_25" ;;
	*) ICON="$ICON_BATTERY_0" ;;
	esac

	if [ "$PERCENT" -gt 60 ]; then
		COLOR="$GREEN"
	elif [ "$PERCENT" -gt 30 ]; then
		COLOR="$YELLOW"
	elif [ "$PERCENT" -gt 15 ]; then
		COLOR="$PEACH"
	else
		COLOR="$RED"
	fi
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENT}%"
