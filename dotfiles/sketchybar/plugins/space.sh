#!/usr/bin/env bash
# Highlights the active Mission Control space. $SELECTED is supplied by the
# `space` component itself — no window manager needed.
#
# The active space swaps its digit for its DesktopRenamer name (Term, Web, Lab
# …) and swaps back on the way out. Only the active one, deliberately: names are
# far wider than digits, and with the notch ruling out the `center` position the
# spaces island shares a 1496pt strip with front_app and the system islands.
# Five names side by side crowd it; one does not.

source "$CONFIG_DIR/colors.sh"

# space.3 -> 3. The item name is the only place the ordinal is available here,
# since $SELECTED is all the component passes in.
digit="${NAME##*.}"

PLIST="$HOME/Library/Preferences/com.michaelqiu.DesktopRenamer.plist"
# Escaped because plutil treats an unescaped . as a key-path separator, and this
# key is full of them.
INDEX_KEY='com\.michaelqiu\.desktoprenamer\.indexcache'

# Read the name straight out of DesktopRenamer's prefs rather than asking it
# over AppleScript.
#
# The app does expose `get current space name`, but Automation permission is
# granted per *calling* binary, and sketchybar is a brew-managed daemon that
# never reliably gets the consent prompt -- the AppleScript route returned empty
# here while the identical command worked from a terminal. Reading the plist
# needs no TCC grant, costs ~15ms instead of an AppleEvent round trip, and keeps
# working when DesktopRenamer is not running at all.
#
# indexcache is a JSON blob keyed "<displayUUID>|Desktop|<ordinal>". Ordinal,
# not space ID -- which is the durable key anyway, since macOS regenerates IDs
# when a desktop is deleted and recreated. head -1 because a second display
# contributes its own entry per ordinal.
#
# Undocumented internal key, so treat it as best-effort: every failure path here
# falls through to the digit, which is what the bar showed before any of this.
space_name() {
	[ -r "$PLIST" ] || return 1
	plutil -extract "$INDEX_KEY" raw -o - "$PLIST" 2>/dev/null |
		base64 -d 2>/dev/null |
		jq -r --arg n "$digit" \
			'to_entries[] | select(.key | endswith("|Desktop|" + $n)) | .value' \
			2>/dev/null | head -1
}

# label.color tracks the icon: the app icons sit inside the same pill, so they
# have to invert to dark when the mauve highlight is painted behind them.
if [ "$SELECTED" = "true" ]; then
	# Looked up only in this branch, so a space change costs one lookup rather
	# than one per space item on the bar.
	name="$(space_name)"

	sketchybar --set "$NAME" \
		icon="${name:-$digit}" \
		background.drawing=on \
		background.color="$ACCENT_SPACES" \
		icon.color="$BASE" \
		label.color="$BASE"
else
	sketchybar --set "$NAME" \
		icon="$digit" \
		background.drawing=off \
		icon.color="$OVERLAY0" \
		label.color="$SUBTEXT0"
fi
