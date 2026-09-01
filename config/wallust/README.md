# wallust

Generates a 16-colour terminal palette from the current wallpaper and writes
it out through a template. Feeds WezTerm; nothing else, yet.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install chenrui333/tap/wallust
```

**Not in Homebrew core.** The formula is `chenrui333/tap/wallust`, marked
`trusted: true` in the `Brewfile` (Homebrew 6 tap-trust model).

## Config

`config/wallust/` here, symlinked to `~/.config/wallust/` by the generic
`config/` loop in `bootstrap.sh`.

```
wallust.toml               backend = full, color_space = lab, palette = dark16
templates/wezterm.template WezTerm colour-scheme TOML, {{placeholder}} tokens
```

`wallust.toml` maps the template to its target:

```toml
[templates]
wezterm = { template = "wezterm.template", target = "~/.config/wezterm/colors/wallust.toml" }
```

## Run

```sh
wallust run <path-to-wallpaper>
```

That writes `~/.config/wezterm/colors/wallust.toml`; WezTerm picks it up on
next launch (see `config/wezterm/README.md`).

## Status: unproven

Not smoke-tested against the installed wallust version. Before relying on it:

1. Run it once and confirm the target file actually appears.
2. If the palette looks wrong, the `{{...}}` placeholder names in
   `templates/wezterm.template` are the likely cause — check `wallust --help`
   / its docs for the current token list and fix them **there**, not in
   `wezterm.lua`, which only reads whatever this produces.

It reaches WezTerm only. SketchyBar and JankyBorders still carry their own
static Catppuccin Mocha values — wiring wallust through to them is a natural
next step, not done.
