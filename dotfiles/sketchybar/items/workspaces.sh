#!/usr/bin/env bash
# AeroSpace workspaces — NOT native macOS Spaces. "Displays have separate
# Spaces" is off and Mission Control is collapsed to one Space per display
# (see aerospace.toml's header comment), so there is nothing left for
# sketchybar's native `space` component to talk to. These are plain items,
# driven entirely by AeroSpace's exec-on-workspace-change hook, which fires
# `sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=...`.
#
# Names match aerospace.toml's workspace names directly (term/web/lab/notes/
# comms) — no DesktopRenamer plist lookup needed, unlike the old
# native-Spaces version, since the workspace name already *is* the label.
#
# Known gap vs. the old bar: there is no per-workspace app-icon strip
# (space_windows.sh) any more. That relied on sketchybar's native
# space_windows_change event, which only fires for real macOS Spaces.
# AeroSpace has no equivalent per-workspace window-change push event, only
# `aerospace list-windows --workspace X` on demand — reproducing the old
# always-on icon strip would mean polling every workspace continuously,
# which wasn't worth it for a first pass. Revisit if it's missed.

WORKSPACES=(term web lab notes comms)

# Custom events must be declared before anything can subscribe to or
# trigger them, or sketchybar logs "Event: '...' not found" and silently
# drops it.
sketchybar --add event aerospace_workspace_change

# Clicking sends F11 (native "Show Desktop" Mission Control shortcut).
# Unrelated to the AeroSpace/Spaces change above; harmless if that shortcut
# is disabled under System Settings -> Keyboard -> Keyboard Shortcuts.
sketchybar --add item show_desktop left \
	--set show_desktop \
	icon="$ICON_DESKTOP" \
	icon.font="$FONT:Bold:14.0" \
	icon.color="$ACCENT_SPACES" \
	icon.padding_left=10 \
	icon.padding_right=6 \
	label.drawing=off \
	click_script="osascript -e 'tell application \"System Events\" to key code 103'"

for name in "${WORKSPACES[@]}"; do
	sketchybar --add item "workspace.$name" left \
		--set "workspace.$name" \
		icon="$name" \
		icon.font="$FONT:Bold:12.0" \
		icon.color="$OVERLAY0" \
		icon.padding_left=10 \
		icon.padding_right=10 \
		label.drawing=off \
		background.color="$SURFACE1" \
		background.corner_radius=7 \
		background.height=20 \
		background.drawing=off \
		script="$PLUGIN_DIR/workspace.sh" \
		click_script="aerospace workspace $name" \
		--subscribe "workspace.$name" aerospace_workspace_change
done

sketchybar --add bracket workspaces_island show_desktop '/workspace\..*/' \
	--set workspaces_island \
	background.color="$ISLAND_COLOR" \
	background.corner_radius=10 \
	background.height=26 \
	background.border_width=1 \
	background.border_color="$ISLAND_BORDER"

# Paint initial focus state — no aerospace_workspace_change event has fired
# yet this early in sketchybar's own startup, so without this every item
# would start unhighlighted even though one workspace really is focused.
# Reuses the exact same event path as live updates rather than a separate
# one-off code path.
if command -v aerospace >/dev/null; then
	initial="$(aerospace list-workspaces --focused 2>/dev/null)"
	[ -n "$initial" ] && sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$initial"
fi
