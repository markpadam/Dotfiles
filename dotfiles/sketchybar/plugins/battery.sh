#!/usr/bin/env bash
# Battery percentage with a charge-level icon, colored by state.

PERCENTAGE="$(pmset -g batt | grep -Eo '\d+%' | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

[ -z "$PERCENTAGE" ] && exit 0

if [ -n "$CHARGING" ]; then
    ICON=""
    COLOR=0xffa6e3a1   # green while charging
else
    case "${PERCENTAGE}" in
        9[0-9]|100) ICON="" COLOR=0xffa6e3a1 ;;
        [6-8][0-9]) ICON="" COLOR=0xffcdd6f4 ;;
        [3-5][0-9]) ICON="" COLOR=0xfff9e2af ;;
        [1-2][0-9]) ICON="" COLOR=0xfff9e2af ;;
        *)          ICON="" COLOR=0xfff38ba8 ;;  # low = red
    esac
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
