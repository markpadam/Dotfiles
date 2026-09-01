# Hammerspoon

A Lua bridge to the macOS APIs. In the Omachy setup it does exactly one job:
**auto-hide the menu bar when a wired external display is connected.**

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install --cask hammerspoon
```

Needs an **Accessibility** grant by hand (System Settings → Privacy & Security
→ Accessibility). Runs as a plain launched app — there is no LaunchAgent, so
add it to Login Items, and after a reboot check it with `pgrep -fl Hammerspoon`.

## Config

`init.lua` here. Hammerspoon reads from `~/.hammerspoon/`, **not** `~/.config`,
so it does not fit either symlink loop in `bootstrap.sh` — there is an explicit
line for it next to the `borders / aerospace / sketchybar` block:

```sh
link "$DOTFILES/dotfiles/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
```

`~/.hammerspoon/Spoons/` and Hammerspoon's own state stay out of the repo.

### What init.lua does

- `hs.ipc` — enables `hs -c '...'` from a shell (used to reload).
- A `hs.screen.watcher` that, on every display change, sets
  `com.apple.controlcenter`'s `AutoHideMenuBarOption` (0 = always hide when an
  external display is wired in, 3 = never) and `killall ControlCenter` to
  apply it live.
- AirPlay screens are excluded from "external connected" so a TV used as a
  wireless display does not count as docked.

The old `NSGlobalDomain _HIHideMenuBar` key is a mirror macOS overwrites on
its own schedule — writing it directly does not stick on macOS 26.

Directional window focus (`Ctrl-b` `h/j/k/l`) used to live here; it moved to
AeroSpace's `alt` bindings and was removed.

## Reload

```sh
hs -c 'hs.reload()'
```

Or `killall Hammerspoon; open -a Hammerspoon`.
