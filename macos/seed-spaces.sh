#!/usr/bin/env bash
set -euo pipefail

# Name the Mission Control desktops via DesktopRenamer.
#
# Dry run by default -- it prints what it would rename and changes nothing.
# Pass --apply to actually rename:
#
#   bash macos/seed-spaces.sh            # show the plan
#   bash macos/seed-spaces.sh --apply    # do it
#
# Desktops are keyed by *ordinal* (the Num field), not by space ID. macOS
# regenerates the ID whenever a desktop is deleted and recreated, so IDs are
# useless as a durable key in a repo; the ordinal survives. That is only true
# with `mru-spaces = false`, which macos/defaults.sh sets -- with Mission
# Control's recency reordering left on, the ordinals shuffle and this script
# would rename the wrong desktops.
#
# This does NOT create desktops. macOS exposes no scriptable way to add one.
# The only tool that could was yabai's scripting addition, which needs SIP
# partially disabled; yabai was removed on 2026-08-05 and SIP stays fully on
# either way. Add desktops by hand in Mission Control first; any name here with
# no matching desktop is simply skipped.

NAMES=(Term Web Lab Notes Comms)

APPLY=false
[ "${1:-}" = "--apply" ] && APPLY=true

if ! pgrep -xq DesktopRenamer; then
	echo "DesktopRenamer is not running -- start it first (open -a DesktopRenamer)." >&2
	exit 1
fi

# `get all spaces` returns one record per line. The bundled sdef documents the
# format as ID~Name~DisplayID~Num, but 1.13.2 actually emits six fields:
#
#   1~Desktop 1~Built-in Retina Display~1~0~
#   ^ ^         ^                       ^ ^
#   | name      display *name*, not an  | undocumented, always 0 here;
#   ID         ID as the sdef claims    ordinal   then a trailing empty field
#
# So the read below takes five variables and lets `rest` absorb the tail. With
# only four, bash would assign the whole remainder to `num` ("1~0~") and the
# arithmetic below would abort the script. Five keeps it working if the app
# grows further fields, which the sdef drift suggests it might.
spaces=$(osascript -e 'tell application "DesktopRenamer" to get all spaces')

if [ -z "$spaces" ]; then
	echo "DesktopRenamer returned no spaces. Grant it Accessibility permission" >&2
	echo "(System Settings > Privacy & Security > Accessibility) and try again." >&2
	exit 1
fi

# Only touch the display the current desktop is on. On a Mac that has had
# external monitors attached, stale entries for disconnected displays can still
# come back, each with its own Num sequence -- renaming by ordinal alone would
# then hit two desktops per number.
current_id=$(osascript -e 'tell application "DesktopRenamer" to get current space id' | cut -d, -f1)
display=$(awk -F'~' -v id="$current_id" '$1 == id { print $3; exit }' <<<"$spaces")

if [ -z "$display" ]; then
	echo "Could not determine the current display; refusing to rename blind." >&2
	exit 1
fi

planned=0
while IFS='~' read -r id name row_display num rest; do
	[ -n "${num:-}" ] || continue
	[ "$row_display" = "$display" ] || continue

	want=${NAMES[num - 1]:-}
	[ -n "$want" ] || continue
	[ "$name" != "$want" ] || continue

	planned=$((planned + 1))
	if $APPLY; then
		osascript -e "tell application \"DesktopRenamer\" to rename space \"$id\" to \"$want\""
		echo "    desktop $num: ${name:-<unnamed>} -> $want"
	else
		echo "    desktop $num: ${name:-<unnamed>} -> $want (dry run)"
	fi
done <<<"$spaces"

total=$(awk -F'~' -v d="$display" '$3 == d' <<<"$spaces" | grep -c . || true)

if [ "$planned" -eq 0 ]; then
	echo "[*] Nothing to do -- all $total desktops already named."
elif $APPLY; then
	echo "[*] Renamed $planned of $total desktops."
else
	echo "[*] $planned of $total desktops would be renamed. Re-run with --apply."
fi

if [ "$total" -lt "${#NAMES[@]}" ]; then
	echo "[!] Only $total desktops exist but ${#NAMES[@]} names are configured."
	echo "    Add the rest by hand in Mission Control, then re-run."
fi
