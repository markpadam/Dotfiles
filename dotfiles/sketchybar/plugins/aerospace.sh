#!/usr/bin/env bash
# Highlights the focused AeroSpace workspace. $1 = this item's workspace id.
# Triggered by the custom aerospace_workspace_change event (or forced on load).

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

if [ "$1" = "$FOCUSED" ]; then
    sketchybar --set "$NAME" background.drawing=on icon.color=0xff1e1e2e background.color=0xffcba6f7
else
    sketchybar --set "$NAME" background.drawing=off icon.color=0xffcdd6f4
fi
