#!/usr/bin/env bash
# notch_islands.sh
#
# One continuous bar on an external display; two pills straddling the notch
# on the built-in. SketchyBar's bar follows the primary (menu-bar) display,
# so we key off that display's top safe-area inset: > 0 means the notched
# built-in, 0 means anything else.
#
# Fires on: display_change, system_woke, and once directly from sketchybarrc.

sleep 0.3   # let macOS settle the display arrangement after a dock/undock

top_inset=$(osascript -l JavaScript -e \
    'ObjC.import("AppKit"); $.NSScreen.screens.objectAtIndex(0).safeAreaInsets.top' \
    2>/dev/null)
top_inset=${top_inset%%.*}   # integer part only ("28.000000" -> "28")

case "$top_inset" in
    '' | *[!0-9]* | 0) notched=0 ;;   # empty / non-numeric / zero -> external
    *)                 notched=1 ;;
esac

if [ "$notched" = 1 ]; then
    # Built-in: dissolve the bar's own background, raise the two island pills
    sketchybar --bar   color=0x00000000 border_width=0 \
               --set   left_island  background.drawing=on \
               --set   right_island background.drawing=on
else
    # External display: a single continuous bar
    sketchybar --bar   color=0xcc1e1e2e border_width=1 \
               --set   left_island  background.drawing=off \
               --set   right_island background.drawing=off
fi
