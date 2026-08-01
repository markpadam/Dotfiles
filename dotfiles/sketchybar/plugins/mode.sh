#!/usr/bin/env bash
# Shows "PREFIX" when AeroSpace is in the tmux binding mode, hides it otherwise.
# Triggered by the custom aerospace_mode_change event.

MODE="$(aerospace list-modes --current 2>/dev/null)"

if [ "$MODE" = "tmux" ]; then
    sketchybar --set "$NAME" background.drawing=on
else
    sketchybar --set "$NAME" background.drawing=off
fi
