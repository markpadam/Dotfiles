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

The `[mode.*]` tables follow the [Omachy guide](https://omachy.org/guide.html)
— `alt`-prefixed, no Karabiner remap. That means AeroSpace's stock defaults
plus: `alt-f` (`macos-native-fullscreen`), `alt-shift-space` (float/tile),
`alt-q` (close), `alt-r` → a `resize` mode (`h`/`l` width, `j`/`k` height),
`alt-enter` (new Ghostty window), and `cmd-h` / `cmd-alt-h` bound to `[]` so
the macOS hide shortcuts can't drop a tiled window out of the grid. The one
deviation from the guide is the workspace block: `alt-1`..`alt-5` (and
`alt-shift-1`..`5`) target the five named workspaces below instead of the
guide's `1`..`9`. The Caps Lock → Ctrl+Option hyper key that drove the first
iteration was retired on 2026-08-30 (`f5e684a`). Keep custom bindings *above*
the mode tables so a future `default-config.toml` diff stays readable.

### Workspaces

Five, named, on `alt-1`..`alt-5` (positional):

| key | workspace | for |
|-----|-----------|-----|
| `alt-1` | `desktop`  | nothing pinned — a clear space (also where Vial lands) |
| `alt-2` | `terminal` | Ghostty |
| `alt-3` | `browser`  | Safari |
| `alt-4` | `comms`    | Mail, WhatsApp |
| `alt-5` | `coding`   | unrouted — put coding windows here with `alt-shift-5` |

`persistent-workspaces` (top of the file) keeps all five alive when empty so
the keys and the SketchyBar pills always land somewhere. `alt-shift-<n>` moves
the focused window. SketchyBar draws a pill per workspace (icon + label — the
label is the workspace name with its `alt`-key number in brackets, e.g.
`terminal (2)`, `coding (5)`); a click runs `aerospace workspace <name>`. The
bracketed number is cosmetic — `ws_label` in `sketchybarrc`, not the AeroSpace
workspace identifier.

### Session persistence

There is no snapshot/restore — instead the layout is *rebuilt* on each login
from two halves:

- **`after-startup-command`** `open -a`s the workspace apps (Ghostty, Safari,
  Mail, WhatsApp, Vial). How many windows each brings back is the app's own
  restore setting plus the macOS "reopen windows when logging back in" box —
  for Safari, Settings → General → *"Safari opens with: All windows from last
  session"*.
- **`on-window-detected` "Workspace routing"** rules pin each app to a
  workspace as its windows appear: Ghostty → `terminal`, Safari → `browser`,
  Mail / WhatsApp → `comms`, Vial → `desktop`.

Caveats: one app routes to one workspace. Split ratios and left/right ordering
within a workspace are not restored; AeroSpace re-tiles fresh. `desktop` and
`coding` are deliberately unrouted — clear scratch spaces. To send a named
Ghostty window somewhere other than `terminal`, give it a distinct locked
title (`config/ghostty/launch`) and add a `window-title-regex-substring` rule
*above* the catch-all Ghostty rule.

### Startup command

`after-startup-command` also launches `sketchybar`. **Do not add a
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

`[[on-window-detected]]` rules with `run = 'layout floating'` — Activity
Monitor, App Store, Archive Utility, Calculator, Calendar, CleanMyMac, Finder,
Home, Messages, Music, Notes, Reminders, Screens Connect, System Settings,
Weather, and the Windows App (Microsoft Remote Desktop). Alphabetised, one
commented block each. The rule only fires when a window **opens**, so reopen an
app after adding it. Get an app id with `aerospace list-apps`.

One more, kept with the Ghostty routing rules rather than here (it matches by
title, and must precede them): the **Hammerspoon scratchpad** — a Ghostty
window titled `scratchpad` is floated and **not** routed to a workspace, so the
`Ctrl+\`` drop-down terminal (`dotfiles/hammerspoon/scratchpad.lua`) follows the
workspace you're on. Hammerspoon owns its size/position and minimises it to
hide.

## Reload

```sh
aerospace reload-config
```

Or `alt + Shift + ; ` then `Esc` (service mode).
