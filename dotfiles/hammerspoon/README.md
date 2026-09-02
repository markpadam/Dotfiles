# Hammerspoon

A Lua bridge to the macOS APIs. In the Omachy setup it does the jobs a launcher
app, an OSD daemon, a theme manager and a handful of Hyprland niceties would do
on Linux.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install --cask hammerspoon
```

Needs an **Accessibility** grant by hand (System Settings → Privacy & Security
→ Accessibility). Runs as a plain launched app — there is no LaunchAgent, so
add it to Login Items, and after a reboot check it with `pgrep -fl Hammerspoon`.

Also used by the theme switcher / pickers:

```sh
brew install btop blueutil switchaudio-osx smudge/smudge/nightlight
```

## Config

Everything is `*.lua` here, symlinked into `~/.hammerspoon/` by an explicit
block in `bootstrap.sh` (Hammerspoon reads `~/.hammerspoon`, not `~/.config`).
`~/.hammerspoon/Spoons/` and Hammerspoon's own state stay out of the repo.

```
init.lua        menu-bar autohide + wires every module below, binds the keys
menu.lua        the Opt+Space command menu (hs.canvas + eventtap)
theme.lua       one command re-skins the whole desktop
palettes.lua    the theme catalogue (8 themes) — edit this to add one
ui.lua          shared panel styling for osd / whichkey (reads theme.lua)
osd.lua         volume / brightness / mute / caps on-screen display
scratchpad.lua  Quake-style drop-down Ghostty (Ctrl+`)
toggles.lua     bar / borders / DND / Night Shift / keep-awake / Zen mode
clipboard.lua   clipboard history (Ctrl+Alt+V)
idle.lua        dim-then-lock idle progression (hypridle)
services.lua    brew-update count, now-playing, screen recording, window flash
whichkey.lua    hold ⌥ → live cheatsheet of AeroSpace + Hammerspoon keys
pickers.lua     audio / Bluetooth / Wi-Fi device pickers for the menu
webapp.lua      run a website as its own app window (web2app)
emoji.lua       emoji + Nerd-Font-glyph picker
```

Reload: `hs -c 'hs.reload()'`. **`hs -c` hangs on canvas/eventtap code** — use
`hs -t 5 -c '…'` when poking at menu / osd / whichkey.

## Keys

| Key | Does |
| --- | --- |
| `⌥ Space` | Command menu |
| `⌃⌥ Space` | Next theme |
| `⌃\`` / `⌃⌥ T` | Toggle the scratchpad terminal |
| `⌃⌥ V` | Clipboard history |
| `⌃⌥ K` | Toggle keep-awake |
| `⌃⌥ Z` | Toggle Zen mode |
| `⌃⌥ N` | Toggle Night Shift |
| `⌃⌥ R` | Start / stop screen recording |
| hold `⌥` | which-key cheatsheet |

`⌃⌥` (Ctrl+Alt) is used everywhere so nothing clashes with AeroSpace's `alt-`
bindings.

## The theme switcher (`theme.lua` + `palettes.lua`)

Picking a theme rewrites config for, and reloads where it can:

| Target | How | Reloads live? |
| --- | --- | --- |
| Hammerspoon UI (menu/osd/whichkey), `hs.alert` | in-process | yes |
| JankyBorders | `borders active_color=…` + `~/.config/borders/theme.sh` | yes |
| SketchyBar | `~/.config/sketchybar/theme.sh` + `--reload` | yes |
| Ghostty | `~/.config/ghostty/theme.conf` (last `config-file`) + Reload Config | yes |
| Wallpaper, macOS light/dark | `System Events` | yes (skipped on a plain reload) |
| bat | `~/.config/bat/config` (validated against `bat --list-themes`) | new shell |
| btop | `~/.config/btop/themes/omachy.theme` + `btop.conf` | restart btop |
| k9s | `~/.config/k9s/skins/omachy.yaml` + `config.yaml` | restart k9s |
| Neovim | `~/.config/nvim/omachy-theme.txt` (read by a LazyVim plugin spec) | restart nvim |
| Starship | palette-config: flip `palette =`; minimal config: regenerate | new shell |

All the generated files are `.gitignore`d. The choice is remembered in
`hs.settings` (`omachy.theme`) and re-asserted 1.5s after login — "soft", so a
plain reload doesn't move your wallpaper or flip light/dark.

**Add a theme:** copy a block in `palettes.lua`, fill the eight semantic
colours + four meter colours, and point `ghostty` / `bat` / `starship` / `nvim`
at a theme each tool ships (see the notes in that file). For a non-Catppuccin
`starship` name, add a `[palettes.<name>]` block to `config/starship.toml`.

Bundled: Catppuccin Mocha (default) · Catppuccin Latte · Tokyo Night ·
Everforest · Gruvbox · Nord · Rosé Pine · Kanagawa.

### wallust

`config/wallust/` predates this and only ever fed Ghostty. The theme switcher
supersedes it — Ghostty's `theme.conf` is the last include and wins. wallust is
kept for the odd manual `wallust run <image>`; nothing calls it automatically.

## SketchyBar state items

`sketchybarrc` adds hidden `hsq.*` items that Hammerspoon turns on:
`hsq.media` (now playing), `hsq.updates` (`brew outdated` count),
`hsq.rec` (recording), `hsq.caffeine` / `hsq.dnd` / `hsq.zen` /
`hsq.nightshift` / `hsq.borders` (toggle state). The glyph is set from Lua so
Nerd Font codepoints stay out of the shell file.

## The command menu (`menu.lua`)

Unchanged engine (sharp `hs.canvas` panel, eventtap owns the keyboard, titled
sections, root Raycast-style search). New branches:

- **Style ▸ Theme** — the 8 themes, ✓ on the active one. **Style ▸ Next theme.**
- **Toggle** — Zen / keep-awake / DND / Night Shift / bar / borders.
- **Clipboard** — history, newest first, paste on pick (also `⌃⌥ V`).
- **Insert** — Emoji, Glyphs (typed into the focused field).
- **Setup** — Audio output/input, Bluetooth, Wi-Fi device pickers (live lists).
- **Install ▸ Web Apps** — add / launch / remove `--app` browser windows.
- **Capture ▸ Start / stop recording** — `screencapture -v`, tracked, `hsq.rec`.
- **System ▸ Packages** — check for updates, `brew upgrade` in a Ghostty window.

Deep entry points still work: `require("menu").openAt("Clipboard")`,
`.openWith("brave")`, `.run("Capture", "Selection → clipboard")`.

## Do Not Disturb

macOS has no supported CLI toggle. `toggles.dnd()` runs
`shortcuts run "Toggle Do Not Disturb"` — create that Shortcut once (Shortcuts
app → single action **Set Focus → Do Not Disturb → Toggle**). Without it the
toggle is a silent no-op; everything else in Zen mode still works.

## Idle (`idle.lua`)

Dims the screen at 5 min idle, locks at 10 min. Fullscreen windows and
keep-awake both suspend it; any input restores brightness. Turn off auto-lock
with `require("idle").config({ lockAfter = 0 })` in `init.lua`.

## Opt-in extras (`services.lua`)

Off by default — flip in `init.lua`:

```lua
require("services").windowFlash     = true   -- accent outline on new windows
require("services").wallpaperRotate = true   -- random wallpaper on unlock
```

## What init.lua does

- `hs.ipc` — `hs -c` from a shell.
- Menu-bar autohide via `com.apple.controlcenter` `AutoHideMenuBarOption` on
  every `hs.screen.watcher` change (0 = hide when a wired external display is
  in, 3 = never). AirPlay screens excluded.
- `require`s every module, binds the keys (registering each with `whichkey`),
  starts `osd` / `clipboard` / `whichkey` / `services` / `idle`, and re-asserts
  the saved theme.
