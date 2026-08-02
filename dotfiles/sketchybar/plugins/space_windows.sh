#!/usr/bin/env bash
# Draws the apps living on a space as icons next to its number.
#
# Driven by sketchybar's native `space_windows_change` event — no window
# manager involved. $INFO arrives as:
#
#   { "space": 2, "apps": { "iTerm2": 1, "Safari": 3 } }
#
# i.e. only the space that actually changed, with a window count per app that
# we ignore (one icon per app, however many windows it has).
#
# App names are turned into sketchybar-app-font ligatures (":iterm:" and
# friends) by __icon_map; the label has to be rendered in that font for the
# ligature to resolve, otherwise you get the literal colon-wrapped name.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icon_map.sh"

sid="$(jq -r '.space' <<<"$INFO")"
[ -z "$sid" ] || [ "$sid" = "null" ] && exit 0

# keys[] is sorted and de-duplicated, so icon order stays stable as windows
# come and go rather than jumping around on every event.
icon_strip=""
while read -r app; do
	[ -z "$app" ] && continue
	__icon_map "$app"
	icon_strip+="${icon_strip:+ }${icon_result}"
done <<<"$(jq -r '.apps | keys[]' <<<"$INFO")"

if [ -n "$icon_strip" ]; then
	# Tighten the gap between number and icons, and give the strip its own
	# right padding.
	sketchybar --set "space.$sid" \
		label="$icon_strip" \
		label.drawing=on \
		icon.padding_right=4
else
	# Empty space: drop the label entirely so unused spaces stay a compact
	# square around just the number.
	sketchybar --set "space.$sid" \
		label="" \
		label.drawing=off \
		icon.padding_right=8
fi
