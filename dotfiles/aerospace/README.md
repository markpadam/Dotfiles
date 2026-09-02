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
`aks-lab-split.sh` sits alongside it (same symlinked dir) and is invoked from
`after-startup-command` — keep its exec bit (`git update-index --chmod=+x`;
the repo sets `core.fileMode = false`).

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
| `alt-5` | `aks-lab`  | Kubernetes homelab — Ghostty (the `AKS Lab` window) + Safari on the cluster dashboard, 60/40 width split |

`persistent-workspaces` (top of the file) keeps all five alive when empty so
the keys and the SketchyBar pills always land somewhere. `alt-shift-<n>` moves
the focused window. SketchyBar draws a pill per workspace (icon + label — the
label is the workspace name with its `alt`-key number in brackets, e.g.
`terminal (2)`, and `aks-lab` reads "AKS Lab (5)"); a click runs `aerospace
workspace <name>`. The bracketed number is cosmetic — `ws_label` in
`sketchybarrc`, not the AeroSpace workspace identifier.

### Session persistence

There is no snapshot/restore — instead the layout is *rebuilt* on each login
from two halves:

- **`after-startup-command`** `open -a`s the workspace apps (Ghostty, Safari,
  Mail, WhatsApp, Vial). How many windows each brings back is the app's own
  restore setting plus the macOS "reopen windows when logging back in" box —
  for Safari, Settings → General → *"Safari opens with: All windows from last
  session"*. Two extra lines open the `aks-lab` pair: a dedicated Ghostty
  instance whose title is locked to **AKS Lab** (running `./aks-lab tmux`),
  and a *new* Safari window
  (`make new document`, so it is a window and not a tab in the restored
  `browser` one) on `http://localhost:9997`. A third line runs
  **`aks-lab-split.sh`**, which waits for both windows and then sets a 60/40
  terminal:browser width split — AeroSpace has no persistent split ratio, so
  a workspace otherwise re-tiles 50/50 every login. The script derives the
  width from the main display each run (adapts to docked/undocked) and uses an
  absolute `resize width`, so it is safe to re-run; `alt--` / `alt-=` nudge it
  afterwards.
- **`on-window-detected` "Workspace routing"** rules pin each app to a
  workspace as its windows appear: Ghostty → `terminal`, Safari → `browser`
  (or `aks-lab` if the title matches `localhost:9997` — first match wins, so
  that rule is listed first), Mail / WhatsApp → `comms`, Vial → `desktop`, the
  Ghostty window titled **AKS Lab** → `aks-lab` and every other Ghostty window
  → `terminal` (AeroSpace can't tell two windows of one app apart, so the
  cockpit's locked title is the discriminator).

Caveats: one app routes to one workspace (the Safari `localhost:9997` rule is
a best-effort regex on the title *at detection time* — a window still loading
its page lands on `browser`; move it with `alt-shift-5`).
Split ratios and left/right ordering within a workspace are not restored;
AeroSpace re-tiles fresh. `desktop` is deliberately unrouted — a clear scratch
space. To send another named Ghostty window somewhere other than `terminal`,
give it a distinct locked title (`config/ghostty/launch`) and add a
`window-title-regex-substring` rule *above* the catch-all Ghostty rule.

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
