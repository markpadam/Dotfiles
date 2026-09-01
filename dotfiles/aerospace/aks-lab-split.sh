#!/usr/bin/env bash
# aks-lab workspace: pin a 60/40 terminal:browser width split.
#
# AeroSpace has no persistent split ratio — a workspace re-tiles 50/50 every
# login — so this runs once from after-startup-command. It waits for both the
# Ghostty (terminal) and Safari (browser) windows to land on `aks-lab`, then
# sets the browser to 40% of the usable width; AeroSpace hands the remaining
# 60% to the terminal.
#
# Width is derived from the *main* display each run, so it adapts to
# docked/undocked. Absolute `resize width`, so re-running it doesn't drift.

set -uo pipefail

ws=aks-lab
browser_share=0.40
gap=8   # matches [gaps] outer.left / outer.right / inner.horizontal in aerospace.toml

win_id() {   # $1 = app-bundle-id  ->  first matching window id on $ws (may be empty)
    aerospace list-windows --workspace "$ws" --format '%{window-id}|%{app-bundle-id}' \
        | awk -F'|' -v a="$1" '$2 == a { print $1; exit }'
}

# Wait up to ~30s for both windows to be routed onto the workspace.
for _ in $(seq 1 30); do
    term=$(win_id com.mitchellh.ghostty)
    browser=$(win_id com.apple.Safari)
    [ -n "$term" ] && [ -n "$browser" ] && break
    sleep 1
done
[ -n "${term:-}" ] && [ -n "${browser:-}" ] || exit 0

# Usable width = main display width - the three 8pt gaps around the split.
main_w=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' \
    | awk -F', ' '{ print $3 + 0 }')
[ "${main_w:-0}" -gt 0 ] || exit 0
usable=$((main_w - gap * 3))
browser_w=$(awk -v u="$usable" -v s="$browser_share" 'BEGIN { printf "%d", u * s }')

aerospace resize --window-id "$browser" width "$browser_w"
