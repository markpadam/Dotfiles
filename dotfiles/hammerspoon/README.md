# Hammerspoon

A Lua bridge to the macOS APIs. In the Omachy setup it does two jobs:

1. **Auto-hide the menu bar when a wired external display is connected**
   (`init.lua`).
2. **The Omachy command menu** — a keyboard-driven `hs.canvas` modal on
   `Opt+Space` with a small curated tree of actions (`menu.lua`), in place of
   a launcher app.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install --cask hammerspoon
```

Needs an **Accessibility** grant by hand (System Settings → Privacy & Security
→ Accessibility). Runs as a plain launched app — there is no LaunchAgent, so
add it to Login Items, and after a reboot check it with `pgrep -fl Hammerspoon`.

## Config

`init.lua` and `menu.lua` here. Hammerspoon reads from `~/.hammerspoon/`,
**not** `~/.config`, so it does not fit either symlink loop in `bootstrap.sh`
— an explicit block next to `borders / aerospace / sketchybar` links every
`*.lua` in this dir:

```sh
for f in "$DOTFILES/dotfiles/hammerspoon"/*.lua; do
    link "$f" "$HOME/.hammerspoon/$(basename "$f")"
done
```

`~/.hammerspoon/Spoons/` and Hammerspoon's own state stay out of the repo.

### What init.lua does

- `hs.ipc` — enables `hs -c '...'` from a shell (used to reload).
- A `hs.screen.watcher` that, on every display change, sets
  `com.apple.controlcenter`'s `AutoHideMenuBarOption` (0 = always hide when an
  external display is wired in, 3 = never) and `killall ControlCenter` to
  apply it live. AirPlay screens are excluded so a TV used as a wireless
  display does not count as docked.
- `require("menu").bind({"alt"}, "space")` — wires the command menu to
  `Opt+Space` (the slot Raycast used).

The old `NSGlobalDomain _HIHideMenuBar` key is a mirror macOS overwrites on
its own schedule — writing it directly does not stick on macOS 26.

Directional window focus (`Ctrl-b` `h/j/k/l`) used to live here; it moved to
AeroSpace's `alt` bindings and was removed.

### The command menu (`menu.lua`)

Drawn with `hs.canvas` + a keyboard eventtap (not `hs.chooser`), styled after
**Omarchy 4's `omarchy-menu`** (walker `--dmenu`): a sharp-cornered panel, 2px
mauve border, `Hack Nerd Font Mono` throughout, one Nerd Font glyph per row,
single-line rows, the current menu name as the `<name>…` prompt, and a subtle
mauve-tinted selection (the row text also goes accent). No focus fragility —
the eventtap owns the keyboard while the menu is up.

- Every list is split into **titled sections** (dim caps + a hairline). In the
  tree, drop a `section("NAME")` between items. Section rows aren't selectable
  — `↑/↓` skips them — and an empty section is pruned automatically.

- **Enter** to pick, **Esc** to close, **Backspace** / **←** to go up a level,
  **↑/↓** to move (wraps). Click outside to dismiss. `Back` is the first row of
  any submenu.

- **On the first screen, typing runs a Raycast-style search** across every
  installed `.app`, every System Settings pane (the `SETTINGS` table), every
  menu action, and — a beat later, via `mdfind` — files by name. Results are
  grouped **COMMANDS / APPLICATIONS / SETTINGS / FILES**, the group with the
  best match first. Inside a submenu, typing just filters that level.

- **Apps** — a curated favourites split into **Custom Apps** and **Builtin
  Apps**, each row the real app icon. Everything not on the favourites list is
  one keystroke away via root search, so keep these short.
- **Terminal** — **Open Terminal** (blank Ghostty) plus the named launchers
  (`config/ghostty/launch`: AKS-Lab, IDE, K8s Exam, PowerShell 7, Ubuntu).
- **Capture** — `screencapture` (selection → clipboard or file, window, whole
  screen), the `⌘⇧5` recording toolbar, Digital Color Meter.
- **Style** — Dark / Light appearance (via System Events), a **Wallpaper**
  submenu built live from `~/Pictures/Wallpapers/`, and the Wallpaper pane.
- **Setup** — opens the Wi-Fi / Bluetooth / Sound / Displays / Keyboard panes
  (`x-apple.systempreferences:` URLs), plus a `networksetup` Wi-Fi toggle.
- **Shortcuts** — Omarchy's `Learn ▸ Keybindings` idea: display-only rows in
  the `CHORD  →  action` style, grouped into sections. **Tiling** is parsed
  live from `aerospace.toml` (all `[mode.*]` blocks) so it never drifts, and
  bucketed by command into LAYOUT / FOCUS & MOVE / RESIZE / WORKSPACES /
  WINDOW (+ one section per non-main mode); **TMUX**, **Ghostty** and
  **NeoVim** are static (`TMUX` / `GHOSTTY` / `NEOVIM` tables) mirroring
  `~/.tmux.conf`, Ghostty's stock keybinds (no `keybind` lines in its config)
  and LazyVim. These sub-lists set `width = 460` so the arrow layout fits.
- **System** — lock, sleep, log out / restart / shut down (System Events),
  reload Hammerspoon / AeroSpace / SketchyBar.

The whole tree is plain Lua tables near the top of the file — add a row as
`{ name = "...", action = fn }` or `{ name = "...", menu = <subtable> }`, with
an optional `g = NF.<name>` glyph (the `NF` table holds `\u{}` escapes, all
present in Hack Nerd Font Mono) or `app = "bundle.id"` (drawn with that app's
real icon). Colours are the `C` block; panel geometry is `WIDTH` / `ROW_H` /
`PAD` / `RADIUS` / `BORDER_W` / `FONT`; a node can override `width`. To swap
the trigger key, change the `bind(...)` call in `init.lua`.

Helpers for binding deeper entry points:
`require("menu").openWith("brave")` opens with a search pre-filled,
`require("menu").openAt("Apps", "Builtin Apps")` opens straight to a submenu,
`require("menu").run("Capture", "Selection → clipboard")` fires one leaf with
no UI.

## Reload

```sh
hs -c 'hs.reload()'
```

Or `killall Hammerspoon; open -a Hammerspoon`.
