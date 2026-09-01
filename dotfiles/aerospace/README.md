# AeroSpace

The tiling window manager — the centre of the Omachy setup. Windows arrange
themselves into a grid; focus, moves, workspaces and resize are all keyboard.

The Apple Notes wiki holds the overview and the chord list. This file is the
config reference.

## Install

```sh
brew install --cask nikitabobko/tap/aerospace
```

Needs an **Accessibility** grant by hand the first time (System Settings →
Privacy & Security → Accessibility) — `bootstrap.sh` cannot click it.

## Config

`aerospace.toml` here, symlinked to `~/.config/aerospace/` by the hardcoded
`borders aerospace sketchybar` loop in `bootstrap.sh` (not the generic
`config/` loop — that is where this Mac's existing symlink already points).

### Bindings

Everything under the `[mode.*]` tables is **AeroSpace's bundled
`default-config.toml`, verbatim** — `alt`-prefixed, no Karabiner remap. The
Caps Lock → Ctrl+Option hyper key that drove the first iteration was retired
on 2026-08-30 (`f5e684a`). Keep custom bindings *above* the mode tables so a
future `default-config.toml` diff stays readable.

### Workspaces

Numbered `1`-`9` and lettered `A`-`Z`, straight from the defaults. **No naming
and no app-to-workspace routing are configured** — the `term`/`web`/`lab`/
`notes`/`comms` idea is habit, not config. SketchyBar draws pills for `1`-`9`
only. `dotfiles/sketchybar/sketchybarrc-named` is a prepared alternative that
labels lettered workspaces; nothing routes windows to them yet.

### Startup

`after-startup-command` launches `sketchybar` and nothing else. **Do not add a
`borders active_color=…` line here** — it runs after login and overrides
`~/.config/borders/bordersrc`, which is the single source of truth for the
border (see `dotfiles/borders/README.md`).

### Gaps

`[gaps]` is Hyprland-style breathing room: 8pt inner and outer, except
`outer.top`, which is **per-monitor**:

```toml
outer.top = [{ monitor.'built-in' = 8 }, 34]
```

The built-in's notch safe area (28pt) already clears the SketchyBar, so 8 is
enough there. Every external display reserves nothing at the top, so the gap
itself has to clear the ~26pt bar plus the ~3pt JankyBorders overhang — 34
lands window tops ~5pt below the bar. Verified docked to the DELL, 2026-08-30.
Re-check this if the bar height or the border width changes.

### SketchyBar hook

`exec-on-workspace-change` fires a `sketchybar --trigger
aerospace_workspace_change` so the workspace pills follow AeroSpace directly,
not native macOS Spaces (which this setup collapses to one desktop per
display).

### Floating apps

`[[on-window-detected]]` rules with `run = 'layout floating'` — Finder, System
Settings, Calculator, Messages, Music, Weather, Activity Monitor, App Store,
Archive Utility, Screens Connect, Notes. Alphabetised, one commented block
each. The rule only fires when a window **opens**, so reopen an app after
adding it. Get an app id with `aerospace list-apps`.

## Reload

```sh
aerospace reload-config
```

Or `alt + Shift + ; ` then `Esc` (service mode).
