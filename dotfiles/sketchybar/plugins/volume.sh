#!/usr/bin/env bash
# System volume with a Nerd Font speaker icon.
#
# On a `volume_change` event SketchyBar hands us the new level in $INFO — the
# reliable source. AppleScript's `output volume of (get volume settings)`
# returns "missing value" whenever the active output can't report a level
# (AirPlay, some Bluetooth headsets, a conferencing virtual device), which is
# why the old plugin showed "missing value%". Use $INFO first, fall back to
# AppleScript, and show a neutral "–" rather than a bogus number when neither
# works — a volume-key press then fills in the real value via $INFO.

MUTE=0xff6c7086   # Catppuccin overlay
FG=0xffcdd6f4     # text

VOLUME=""
MUTED="false"
[[ "$INFO" =~ ^[0-9]+$ ]] && VOLUME="$INFO"

read -r AS_VOL AS_MUTED <<<"$(osascript \
    -e 'set s to (get volume settings)' \
    -e 'set v to output volume of s' \
    -e 'set m to output muted of s' \
    -e 'if v is missing value then set v to -1' \
    -e 'if m is missing value then set m to false' \
    -e 'return (v as integer as string) & " " & (m as string)' 2>/dev/null)"

[[ -z "$VOLUME" && "$AS_VOL" =~ ^[0-9]+$ ]] && VOLUME="$AS_VOL"
[[ "$AS_MUTED" == "true" ]] && MUTED="true"

if [ "$MUTED" = "true" ]; then
    ICON="󰝟"; COLOR=$MUTE
    LABEL="${VOLUME:-–}%"; [ -z "$VOLUME" ] && LABEL="muted"
elif [[ "$VOLUME" =~ ^[0-9]+$ ]]; then
    LABEL="${VOLUME}%"
    COLOR=$FG
    if   [ "$VOLUME" -eq 0 ];   then ICON="󰝟"; COLOR=$MUTE
    elif [ "$VOLUME" -lt 34 ];  then ICON="󰕿"
    elif [ "$VOLUME" -lt 67 ];  then ICON="󰖀"
    else                             ICON="󰕾"
    fi
else
    ICON="󰖀"; COLOR=$MUTE; LABEL="–"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
