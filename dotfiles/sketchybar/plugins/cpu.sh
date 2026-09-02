#!/usr/bin/env bash
# Show CPU usage percentage with color-coded Nerd Font icon.

CPU=$(top -l 1 -n 0 | awk '/CPU usage/ {gsub(/%/,""); print int($3 + $5)}')

if [ "$CPU" -ge 80 ]; then
    COLOR=0xfff38ba8   # red — under load
elif [ "$CPU" -ge 50 ]; then
    COLOR=0xfff9e2af   # yellow — busy
else
    COLOR=0xffa6adc8   # subtext — idle (matches the menu)
fi

sketchybar --set "$NAME" icon.color="$COLOR" label="${CPU}%"
