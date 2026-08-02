#!/usr/bin/env bash
# memory_pressure reports free percentage; we show used.

source "$CONFIG_DIR/colors.sh"

FREE=$(memory_pressure | awk -F': ' '/System-wide memory free percentage/ {gsub(/%/, "", $2); print $2}')

if [ -z "$FREE" ]; then
	exit 0
fi

USED=$((100 - FREE))

if [ "$USED" -gt 85 ]; then
	COLOR="$RED"
elif [ "$USED" -gt 70 ]; then
	COLOR="$PEACH"
else
	COLOR="$LAVENDER"
fi

sketchybar --set "$NAME" icon.color="$COLOR" label="${USED}%"
