# SketchyBar

A scripted status bar that stands in for the macOS menu bar (Hammerspoon
auto-hides the real one when the Mac is docked).

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install felixkratz/formulae/sketchybar
brew install --cask font-sketchybar-app-font   # glyph font
```

The bar uses **Hack Nerd Font Mono** for its own icons and labels — installed
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

### Theming

Every colour in `sketchybarrc` is a `BAR_*` shell var with a Catppuccin Mocha
default. The Hammerspoon theme switcher (`dotfiles/hammerspoon/theme.lua`)
writes `$CONFIG_DIR/theme.sh` with overrides for the active theme and runs
`sketchybar --reload`; `plugins/notch_islands.sh` sources it too (for the
external-display bar colour). `theme.sh` is `.gitignore`d.

### Hammerspoon state items

`sketchybarrc` adds hidden `hsq.*` items — `media` (now playing), `updates`
(`brew outdated` count), `rec` (recording), `caffeine` / `dnd` / `zen` /
`nightshift` / `borders` (toggle state). Hammerspoon sets their `icon` +
`drawing` at runtime (`toggles.lua` / `services.lua`), so the Nerd Font
codepoints never touch this shell file.

### Layout

`sketchybarrc` shares the **Opt+Space command menu**'s palette
(`dotfiles/hammerspoon/menu.lua`): Catppuccin Mocha, **Hack Nerd Font Mono**,
24pt tall (the macOS menu-bar height), a **2px mauve (`0xffcba6f7`) border**,
blurred, and mauve as the one accent — everything else is `text` / `subtext`
grey. Warning colours (yellow/red) survive only on the CPU / memory / battery
meters; idle/normal there is `subtext`. Rounded corners (bar 8, pills 6),
**bold labels**, and workspace names capitalised (`Desktop (1)` …) are the
bar's own choices, not the menu's.

```
LEFT    workspace pills (desktop terminal browser comms coding)  ->  front_app
RIGHT   clock  battery  volume  cpu  memory
```

One pill per AeroSpace workspace, `icon + label` (Nerd Font glyph from the
Material Design range; Hack Nerd Font Mono *Regular* carries both the MD and
Font Awesome ranges. Glyphs are stored as `$'\xNN'` byte escapes so a file
rewrite can't strip the private-use codepoints). The label (`ws_label`) is the
workspace name plus its `alt`-key number in brackets — `desktop (1)` … `AKS
Lab (5)` — kept separate from `ws_name`, the AeroSpace identifier used by
`click_script` and `aerospace.sh`. Pills subscribe to the
`aerospace_workspace_change` event; the focused pill takes the menu's
selected-row look (a faint mauve-tinted fill + mauve icon/label), the rest are
`subtext` grey. Each pill's
`click_script` is `aerospace workspace <name>`, so a click switches workspace
through the AeroSpace CLI
directly — **no osascript, no Automation grant.** `plugins/aerospace.sh` takes
`<name> <accent-color>` and reads `$FOCUSED_WORKSPACE` from the trigger.

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
