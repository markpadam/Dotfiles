#!/usr/bin/env bash
# On a volume_change event $INFO carries the new volume; the mute state has to
# be asked for either way.
#
# One `get volume settings` call returns every field at once, so both values
# come from a single AppleEvent. Two separate osascript calls measured 298ms
# against 154ms for one — and this runs on every press of the volume key, where
# that lag is the difference between the bar keeping up and visibly trailing.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

# output volume:33, input volume:100, alert volume:100, output muted:false
SETTINGS=$(osascript -e 'get volume settings' 2>/dev/null)

# $INFO is preferred when present: it is the value the event actually carried,
# so it cannot be a step behind the way a fresh query can.
VOLUME="$INFO"
if [ -z "$VOLUME" ]; then
	VOLUME=$(sed -n 's/.*output volume:\([0-9]*\).*/\1/p' <<<"$SETTINGS")
fi

MUTED=$(sed -n 's/.*output muted:\([a-z]*\).*/\1/p' <<<"$SETTINGS")

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
