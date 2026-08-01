#!/usr/bin/env bash
# Native Mission Control spaces. No window manager involved — the `space`
# component talks to macOS directly and only draws spaces that actually exist,
# so creating 10 up front is safe.
#
# Clicking a space sends Ctrl+<n>. That only works if the matching
# "Switch to Desktop n" shortcut is enabled under
# System Settings → Keyboard → Keyboard Shortcuts → Mission Control,
# and sketchybar has Accessibility permission. Harmless if not.

sketchybar --add item apple_logo left \
	--set apple_logo \
	icon="$ICON_APPLE" \
	icon.font="$FONT:Bold:15.0" \
	icon.color="$ACCENT_SPACES" \
	icon.padding_left=10 \
	icon.padding_right=6 \
	label.drawing=off \
	click_script="open -a 'System Settings'"

for sid in $(seq 1 10); do
	# Ctrl+1..9 are key codes 18-25,26; Ctrl+0 is key code 29.
	case "$sid" in
	1) keycode=18 ;; 2) keycode=19 ;; 3) keycode=20 ;; 4) keycode=21 ;;
	5) keycode=23 ;; 6) keycode=22 ;; 7) keycode=26 ;; 8) keycode=28 ;;
	9) keycode=25 ;; 10) keycode=29 ;;
	esac

	sketchybar --add space "space.$sid" left \
		--set "space.$sid" \
		space="$sid" \
		icon="$sid" \
		icon.font="$FONT:Bold:12.0" \
		icon.color="$OVERLAY0" \
		icon.padding_left=8 \
		icon.padding_right=8 \
		label.drawing=off \
		background.color="$SURFACE1" \
		background.corner_radius=7 \
		background.height=20 \
		background.drawing=off \
		script="$PLUGIN_DIR/space.sh" \
		click_script="osascript -e 'tell application \"System Events\" to key code $keycode using control down'"
done

sketchybar --add bracket spaces_island apple_logo '/space\..*/' \
	--set spaces_island \
	background.color="$ISLAND_COLOR" \
	background.corner_radius=10 \
	background.height=26 \
	background.border_width=1 \
	background.border_color="$ISLAND_BORDER"
