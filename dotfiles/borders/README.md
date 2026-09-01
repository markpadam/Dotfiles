# JankyBorders

Draws a coloured border around the focused window so it is obvious which one has
keyboard focus — the visual half of the AeroSpace tiling setup (AutoRaise moves
focus with the pointer, this shows you where it landed).

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install FelixKratz/formulae/borders
```

## Config

`bordersrc` here, symlinked to `~/.config/borders/`. It is the **single source
of truth** for border appearance — the `borders` daemon (started by
`brew services`) executes it on launch. AeroSpace does **not** set colours
imperatively; a `borders active_color=...` line in `aerospace.toml`'s
`after-startup-command` runs after login and silently overrides this file, so
there isn't one.

Executable — it is run, not sourced, so it needs the exec bit
(`git update-index --chmod=+x`; this repo sets `core.fileMode = false`).

Current settings, Catppuccin Mocha:

```sh
style=round
width=6.0
hidpi=on
active_color="glow(0xffcba6f7)"   # mauve glow — focused window
inactive_color=0xff313244          # surface0   — unfocused windows
```

`glow(...)` gives the focused window a soft outer bloom rather than a flat
stroke — the "purple glow" the Omarchy look calls for.

## Width is centred on the window frame

The stroke straddles the frame edge, so it reaches about **half** its width
outward — at `width=6.0`, roughly 3pt beyond the window. AeroSpace's
`[gaps] outer.top` (34 on external displays) is tuned around that overhang so
the border clears the SketchyBar; changing the width here means re-checking
that gap.

Worth remembering whenever a border looks like it is touching something it
should not be: it is usually the border reaching outward, not the other element
being mispositioned. Adjusting the *other* thing's offset never helped, because
the borders just swallowed the gain.

## Run / restart

```sh
brew services start borders
brew services restart borders   # after editing bordersrc
```
