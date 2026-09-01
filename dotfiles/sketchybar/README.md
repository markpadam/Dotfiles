# SketchyBar

A scripted status bar that stands in for the macOS menu bar (Hammerspoon
auto-hides the real one when the Mac is docked).

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install felixkratz/formulae/sketchybar
brew install --cask font-sketchybar-app-font   # glyph font
```

The bar also uses **Hack Nerd Font** for its own icons and labels — installed
via the `Brewfile` cask list.

## Config

`sketchybar/` here, symlinked to `~/.config/sketchybar/` by the hardcoded
`borders aerospace sketchybar` loop in `bootstrap.sh`.

```
sketchybarrc          the bar — sourced by the daemon on start / --reload
plugins/*.sh          one script per item, invoked on its own schedule/events
```

Scripts must keep their **exec bit** — the repo sets `core.fileMode = false`,
so add any new plugin with `git update-index --chmod=+x` or the daemon cannot
run it.

### Layout

`sketchybarrc` is Catppuccin Mocha, Hack Nerd Font, 24pt tall (the macOS
menu-bar height), rounded and blurred.

```
LEFT    workspace pills (desktop terminal browser comms man)  ->  front_app
RIGHT   clock  battery  volume  cpu  memory
```

One pill per AeroSpace workspace, `icon + name` (Nerd Font glyph from the
Material Design range — the Font Awesome range is missing from Hack Nerd Font
Bold, which the labels render in; glyphs are stored as `$'\xNN'` byte escapes
so a file rewrite can't strip the private-use codepoints). Pills subscribe to
the `aerospace_workspace_change` event and colour the focused one; each pill's
`click_script` is `aerospace workspace <name>`, so a click switches workspace
through the AeroSpace CLI directly — **no osascript, no Automation grant.**
`plugins/aerospace.sh` takes `<name> <accent-color>` and reads
`$FOCUSED_WORKSPACE` from the trigger.

### Notch islands

On the notched built-in the bar splits into two pills (`left_island` /
`right_island` brackets) straddling the notch; on an external display it is one
continuous bar. `plugins/notch_islands.sh` decides which, keyed on
`NSScreen.screens[0].safeAreaInsets.top` (`>0` ⇒ built-in), and an invisible
`notch_islands` worker item re-runs it on `display_change` and `system_woke`.

`notch_width` in `--bar` is **not** the mechanism — it only reserves centre
space for `center`-anchored items (there are none here) and does not split the
bar background.

## Reload

```sh
sketchybar --reload
```

`brew services restart sketchybar` also works; AeroSpace re-launches it at
login via `after-startup-command`.
