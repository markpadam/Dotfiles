#!/usr/bin/env bash
# Show battery percentage with a Nerd Font icon.
PERCENTAGE=$(pmset -g batt | grep -Eo '[0-9]+%' | tr -d '%')
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
    sketchybar --set "$NAME" icon="󱉝" label="?"
    exit 0
fi

if [ -n "$CHARGING" ]; then
    ICON="󰂄" COLOR=0xffcba6f7   # charging — mauve accent
elif [ "$PERCENTAGE" -ge 80 ]; then
    ICON="󰁹" COLOR=0xffa6adc8   # full
elif [ "$PERCENTAGE" -ge 60 ]; then
    ICON="󰂁" COLOR=0xffa6adc8
elif [ "$PERCENTAGE" -ge 40 ]; then
    ICON="󰁾" COLOR=0xffa6adc8
elif [ "$PERCENTAGE" -ge 20 ]; then
    ICON="󰁼" COLOR=0xfff9e2af   # yellow — getting low
else
    ICON="󰁺" COLOR=0xfff38ba8   # red — critical
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
