#!/usr/bin/env bash
# Summing per-process %CPU and dividing by thread count is cheap and
# instantaneous — `top -l 2` would be more accurate but blocks for a second.

source "$CONFIG_DIR/colors.sh"

THREADS=$(sysctl -n machdep.cpu.thread_count)
LOAD=$(ps -A -o %cpu | awk -v t="$THREADS" '{s += $1} END {printf "%.0f", s / t}')

if [ "$LOAD" -gt 80 ]; then
	COLOR="$RED"
elif [ "$LOAD" -gt 50 ]; then
	COLOR="$PEACH"
elif [ "$LOAD" -gt 25 ]; then
	COLOR="$YELLOW"
else
	COLOR="$MAUVE"
fi

sketchybar --set "$NAME" icon.color="$COLOR" label="${LOAD}%"
