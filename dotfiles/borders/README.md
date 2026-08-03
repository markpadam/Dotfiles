# JankyBorders

Draws a coloured border around the focused window so it is obvious which one has
keyboard focus. Originally installed alongside a tiling window manager and kept
after both of those experiments ended — it is useful with plain macOS window
management too.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install FelixKratz/formulae/borders
```

## Config

`bordersrc` here, symlinked to `~/.config/borders/`. Executable — it is run, not
sourced, so it needs the exec bit (`git update-index --chmod=+x`; this repo sets
`core.fileMode = false`).

Current settings, Catppuccin Mocha:

```sh
style=round
width=4.0
active_color=0xffcba6f7     # mauve   — focused window
inactive_color=0xff45475a   # surface1 — unfocused
```

## Width is centred on the window frame

The stroke straddles the frame edge, so it reaches about **half** its width
outward. At `width=6.0` it stuck out roughly 3pt and met the bottom of the
SketchyBar islands; `4.0` reaches about 1.5pt and leaves a clear gap.

Worth remembering when the bar and the borders look like they are touching — it is
usually the border closing the gap, not the bar. It is also why bar overlap is
never fixed by nudging SketchyBar's `y_offset`: the borders swallow the gain.

## Run / restart

```sh
brew services start borders
brew services restart borders   # after editing bordersrc
```
