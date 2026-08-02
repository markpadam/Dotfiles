#!/usr/bin/env bash
# Move the focused window in $1 (west|east|north|south).
#
# The action depends on the current space's layout, because this setup is
# float-first. On a bsp space "move" means swap places with the neighbouring
# window; on a float space it means nudge the window by a fixed step. Without
# that split these keys would be dead on every space except the ones you have
# explicitly toggled to bsp — which is most of them.
set -uo pipefail

direction="${1:?usage: window-move.sh <west|east|north|south>}"
step="${YABAI_FLOAT_STEP:-60}"

layout=$(yabai -m query --spaces --space | jq -r '.type')
floating=$(yabai -m query --windows --window | jq -r '."is-floating"')

# A managed window on a bsp space: rearrange the tree. --swap trades places
# with the neighbour; when there is no neighbour that way --warp pushes the
# window across the tree edge instead, so the key still does something.
if [ "$layout" = "bsp" ] && [ "$floating" = "false" ]; then
	yabai -m window --swap "$direction" 2>/dev/null ||
		yabai -m window --warp "$direction" 2>/dev/null ||
		true
	exit 0
fi

case "$direction" in
west) dx=-$step dy=0 ;;
east) dx=$step dy=0 ;;
north) dx=0 dy=-$step ;;
south) dx=0 dy=$step ;;
*)
	echo "unknown direction: $direction" >&2
	exit 1
	;;
esac

yabai -m window --move "rel:$dx:$dy"
