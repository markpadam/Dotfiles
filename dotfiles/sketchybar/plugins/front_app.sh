#!/usr/bin/env bash
# Shows the name of the currently focused application.
# Triggered by the built-in front_app_switched event.

if [ "$SENDER" = "front_app_switched" ]; then
    sketchybar --set "$NAME" label="$INFO"
fi
