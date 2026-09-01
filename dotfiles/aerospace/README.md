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

The `[mode.*]` tables are **AeroSpace's bundled `default-config.toml`,
verbatim** — `alt`-prefixed, no Karabiner remap — *except* the workspace
block: `alt-1`..`alt-5` (and `alt-shift-1`..`5` to move a window) target the
five named workspaces below instead of `1`..`9` / `A`..`Z`. The Caps Lock →
Ctrl+Option hyper key that drove the first iteration was retired on
2026-08-30 (`f5e684a`). Keep custom bindings *above* the mode tables so a
future `default-config.toml` diff stays readable.

### Workspaces

Five, named, on `alt-1`..`alt-5` (positional):

| key | workspace | for |
|-----|-----------|-----|
| `alt-1` | `desktop`  | nothing pinned — a clear space |
| `alt-2` | `terminal` | Ghostty / WezTerm |
| `alt-3` | `browser`  | Safari, RDP |
| `alt-4` | `comms`    | Mail, WhatsApp, Messages |
| `alt-5` | `man`      | manuals, scratch, everything else |

`persistent-workspaces` (top of the file) keeps all five alive when empty so
the keys and the SketchyBar pills always land somewhere. `alt-shift-<n>` moves
the focused window. There is still **no automatic app-to-workspace routing** —
the "for" column is habit, not config. SketchyBar draws a pill per workspace
(icon + name); a click runs `aerospace workspace <name>`.

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
