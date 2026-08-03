# SketchyBar

Scriptable replacement for the macOS menu bar. This config draws Catppuccin Mocha
"floating islands" — one rounded pill per group of items — with the real menu bar
set to auto-hide behind it.

The Apple Notes wiki holds the overview and day-to-day usage. This file is the
config reference: the things you need when editing, not when using.

## Install

```sh
brew install FelixKratz/formulae/sketchybar
brew install --cask font-sketchybar-app-font   # glyphs for the focused-app item
```

Status icons come from Hack Nerd Font, installed separately.

## Files

Everything lives here and is symlinked to `~/.config/sketchybar/`.

| File | Purpose |
| --- | --- |
| `sketchybarrc` | Bar geometry and item defaults; sources everything else. Executed, so it must be executable. |
| `colors.sh` | Catppuccin Mocha palette plus semantic roles. Sourced. |
| `icons.sh` | Nerd Font glyphs, stored as ASCII escapes (see below). Sourced. |
| `icon_map.sh` | App name to glyph map, from the sketchybar-app-font release. Sourced. |
| `items/` | spaces, front_app, system, clock — one bracket per island. Sourced. |
| `plugins/` | One script per item, run on a timer or an event. Executed. |

## Layout

- **Left** — show-desktop button, Mission Control space pills, focused app.
- **Right** — cpu, memory, wifi, volume, brightness, battery, then a clock island.
- **Centre is deliberately empty.** That is where the notch sits, and SketchyBar
  has no notch-aware layout, so leaving it empty is the only reliable defence.
  `notch_width` is *not* a bar property in 2.24.0 — it is accepted silently and
  ignored, so it looks like it worked.

## Bar geometry

`height=28`, `y_offset=0`, `margin=10`, 26pt brackets, transparent bar.

**28 is `NSScreen safeAreaInsets.top` on the built-in display — and that
protection is undocked-only.** Undocked, the notch reserves 28pt that no window
may occupy, so a 28pt bar at `y_offset=0` sits inside the reserved strip and can
never overlap.

Docked to the external display it is a different story (measured 2026-08-03):

```
docked     DELL U4025QW  safeAreaTop=0   reservedTop=0
           Built-in      safeAreaTop=0   reservedTop=0
undocked   Built-in      safeAreaTop=28  reservedTop=28
```

The DELL has no notch, and the built-in *drops its own inset* when it switches to
its docked 1728x1080 scaled mode. With the menu bar auto-hidden nothing reserves
the strip on either screen, so anything tiled to the top edge lands under the bar.
This is the root cause of every "the bar overlaps my windows" report while docked.

Do **not** try to fix overlap by nudging `y_offset` — that was tried and the gain
was swallowed by the window borders.

Two other numbers look like the menu bar height and are not: `NSStatusBar.thickness`
reports 22 (the legacy status-*item* height), and the Accessibility API reports 29
(includes a 1pt bottom edge).

### What does and does not reserve space

- **The menu bar only reserves space on the main display.** With auto-hide off and
  both screens attached, the DELL (main) reported `reservedTop=31` and the built-in
  `reservedTop=0` — and that survived a `killall SystemUIServer`. Turning auto-hide
  off is therefore only ever a partial fix.
- **macOS native tiling** (green button, drag-to-edge, Fn+Ctrl+arrows) uses
  `visibleFrame`, so it reserves nothing when the menu bar is hidden. With
  `com.apple.WindowManager EnableTiledWindowMargins = 1` a native right-half lands
  at `x=1284 y=8 w=1268 h=1064` on the DELL — 8pt from the top, under the bar.

### Hiding the real menu bar

```sh
defaults write NSGlobalDomain _HIHideMenuBar -bool true
```

This **did** apply live on 2026-08-03 — flipping it moved the main display's
`reservedTop` between 0 and 31 within ~2s, no re-login. An earlier note claimed it
needed a re-login on macOS 26; trust the measurement, but if it ever looks inert:

```sh
osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
```

## Space pills

Each pill shows its desktop number, and beside it an app-font icon for every app
with a window on that desktop. Driven by SketchyBar's own `space_windows_change`
event, so no window manager is involved. Empty desktops drop the icons and stay
compact squares around just the number.

The active pill swaps its number for the desktop's name, read from DesktopRenamer
(see `macos/README.md`). Only the active one — names are far wider than digits, and
with the notch ruling out the centre position this island already shares the strip
with the focused app and the system islands.

Two things that are easy to lose here:

- **`updates=on` on the hidden driver item is load-bearing.** The global default is
  `updates=when_shown`, and a `drawing=off` item is never shown, so the script would
  silently never run.
- **The name lookup reads DesktopRenamer's preferences rather than calling its
  AppleScript.** Automation consent is granted per calling binary, and a
  brew-managed daemon never reliably gets the prompt.

Clicking a pill sends Ctrl and a number, so it depends on the "Switch to Desktop N"
shortcuts being enabled plus Accessibility permission. See `macos/README.md`.

## Gotchas

- **Nerd Font glyphs are private-use-area codepoints and get silently stripped**
  when files are rewritten by tooling, landing as empty strings. `icons.sh` stores
  them as ASCII `$'\xNN'` escapes instead, which always survive. Verify with
  `xxd -p`, never by eye.
- **Hack Nerd Font has no U+F538** (Font Awesome 5 memory) — it renders as tofu.
  Memory uses U+F035B. Check any glyph first:
  `fc-query --format='%{charset}' ~/Library/Fonts/HackNerdFont-Regular.ttf`
- **`position` only accepts `top` and `bottom`** in 2.24.0. `left` and `right` are
  accepted with exit code 0 and then silently ignored, leaving the bar at `top`.
  A vertical bar is not possible.
- **`topmost=window` and `topmost=on` both report as `"on"`** from
  `sketchybar --query bar`. A config saying `window` next to a query saying `on` is
  not a mismatch — only `off` reports distinctly.
- **Space pills for desktops that do not exist are parked off-screen**
  automatically, so declaring 10 is safe regardless of how many exist.
- **Exec bits.** This repo sets `core.fileMode = false`, so git records scripts as
  644 whatever they are on disk. Anything SketchyBar executes — `sketchybarrc` and
  every script under `plugins/` — must be added with `git update-index --chmod=+x`,
  or a fresh clone gets a bar that never starts. Sourced files correctly stay 644.
- **TCC Accessibility grants pin the resolved Cellar path**
  (`/opt/homebrew/Cellar/sketchybar/<version>/bin/sketchybar`), not the `opt/`
  symlink. A version bump will silently break space-clicking — re-grant in
  Settings → Privacy & Security → Accessibility when that happens.

## Plugin cost

Measured per invocation, 2026-08-02:

```
clock 27ms · memory 28ms · wifi 35ms · battery 38ms · cpu 41ms · brightness 46ms · volume 156ms
```

Anything calling `osascript` dominates — batch AppleScript into **one** call
(`get volume settings` returns every field) rather than one per value.
`ps -A -o %cpu` on macOS is a recent-window figure, not a lifetime average, so
summing it is a legitimate CPU gauge (verified 59% against top's 59.6% under load).

## Run / restart

```sh
brew services start sketchybar     # background service
sketchybar --reload                # after editing config
tail -f /opt/homebrew/var/log/sketchybar/sketchybar.out.log
```

Logs: `/opt/homebrew/var/log/sketchybar/sketchybar.{out,err}.log`
