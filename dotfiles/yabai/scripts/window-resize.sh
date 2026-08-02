#!/usr/bin/env bash
# Grow or shrink the focused window along $1 (west|east|north|south).
#
# Direction means "which way the edge travels", so east always widens to the
# right and west always pulls that edge back, on both float and bsp spaces.
#
# On a bsp space yabai resizes by moving one edge of the window; which edge
# exists depends on where the window sits in the split tree, so each case tries
# one edge and falls back to the opposite one. On a float space the window is
# resized from its bottom-right corner (and its top-left for the inverse
# directions) so it grows in place rather than drifting.
set -uo pipefail

direction="${1:?usage: window-resize.sh <west|east|north|south>}"
step="${YABAI_RESIZE_STEP:-60}"

layout=$(yabai -m query --spaces --space | jq -r '.type')
floating=$(yabai -m query --windows --window | jq -r '."is-floating"')

if [ "$layout" = "bsp" ] && [ "$floating" = "false" ]; then
	case "$direction" in
	west) yabai -m window --resize "left:-$step:0" || yabai -m window --resize "right:-$step:0" ;;
	east) yabai -m window --resize "right:$step:0" || yabai -m window --resize "left:$step:0" ;;
	north) yabai -m window --resize "top:0:-$step" || yabai -m window --resize "bottom:0:-$step" ;;
	south) yabai -m window --resize "bottom:0:$step" || yabai -m window --resize "top:0:$step" ;;
	*)
		echo "unknown direction: $direction" >&2
		exit 1
		;;
	esac
	exit 0
fi

case "$direction" in
west) yabai -m window --resize "bottom_right:-$step:0" ;;
east) yabai -m window --resize "bottom_right:$step:0" ;;
north) yabai -m window --resize "bottom_right:0:-$step" ;;
south) yabai -m window --resize "bottom_right:0:$step" ;;
*)
	echo "unknown direction: $direction" >&2
	exit 1
	;;
esac
