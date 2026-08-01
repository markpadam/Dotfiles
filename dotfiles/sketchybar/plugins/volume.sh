#!/usr/bin/env bash
# On a volume_change event $INFO carries the new volume; otherwise ask
# CoreAudio via osascript.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

VOLUME="$INFO"
if [ -z "$VOLUME" ]; then
	VOLUME=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)
fi

MUTED=$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)

if [ "$MUTED" = "true" ] || [ "$VOLUME" = "0" ]; then
	sketchybar --set "$NAME" icon="$ICON_VOLUME_LOW" icon.color="$OVERLAY1" label="Muted"
	exit 0
fi

case "$VOLUME" in
[6-9][0-9] | 100) ICON="$ICON_VOLUME_HIGH" ;;
[3-5][0-9]) ICON="$ICON_VOLUME_MID" ;;
*) ICON="$ICON_VOLUME_LOW" ;;
esac

sketchybar --set "$NAME" icon="$ICON" icon.color="$SKY" label="${VOLUME}%"
