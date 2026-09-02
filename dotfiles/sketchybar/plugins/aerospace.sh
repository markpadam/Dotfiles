#!/usr/bin/env bash
# $1 = workspace name this item represents
# $2 = the accent colour (mauve, 0xffcba6f7 from sketchybarrc)
# $FOCUSED_WORKSPACE = set by the aerospace_workspace_change trigger
#
# Focused pill = the command menu's selected-row look: a faint accent-tinted
# fill + accent-coloured icon/label. Unfocused = subtext grey.

ACCENT="${2:-0xffcba6f7}"
TINT="0x26${ACCENT#0xff}"      # same hue, ~15% alpha
DIM=0xffa6adc8                 # Catppuccin subtext

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" \
        background.drawing=on     \
        background.color="$TINT" \
        icon.color="$ACCENT"     \
        label.color="$ACCENT"
else
    sketchybar --set "$NAME" \
        background.drawing=off    \
        icon.color="$DIM"        \
        label.color="$DIM"
fi
