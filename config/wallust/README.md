# wallust

Generates a 16-colour terminal palette from the current wallpaper and writes
it out through a template. Feeds Ghostty; nothing else.

> **Superseded.** The Hammerspoon theme switcher
> (`dotfiles/hammerspoon/theme.lua`) is the theming system now — it re-skins
> Ghostty, SketchyBar, JankyBorders, the prompt, bat, btop, k9s and Neovim
> together from a curated palette. Ghostty's `theme.conf` (written by the
> switcher) is the last `config-file` include and wins over `wallust.conf`.
> wallust is kept only for the occasional manual `wallust run <image>`; nothing
> calls it automatically.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install chenrui333/tap/wallust
```

**Not in Homebrew core.** The formula is `chenrui333/tap/wallust`, marked
`trusted: true` in the `Brewfile`.

## Config

`config/wallust/` here, symlinked to `~/.config/wallust/` by the generic
`config/` loop in `bootstrap.sh`.

```
wallust.toml               backend = full, color_space = lab, palette = dark16
templates/ghostty.template Ghostty colour keys, {{placeholder}} tokens
```

`wallust.toml` maps the template to its target:

```toml
[templates]
ghostty = { template = "ghostty.template", target = "~/.config/ghostty/wallust.conf" }
```

## Run

```sh
wallust run <path-to-wallpaper>
```

That writes `~/.config/ghostty/wallust.conf`, which `config/ghostty/config`
pulls in with `config-file = ?wallust.conf` — the `?` makes it optional, so
Ghostty is fine before the first run. `wallust.conf` is `.gitignore`d (it lands
in the repo dir via the symlink).

## Status: unproven

Not smoke-tested against the installed wallust version. Before relying on it:

1. Run it once and confirm `~/.config/ghostty/wallust.conf` appears.
2. If the palette looks wrong, the `{{...}}` token names in
   `templates/ghostty.template` are the likely cause — check `wallust --help`
   for the current list and fix them **there**.
3. Reload Ghostty (`Cmd + Shift + ,`) to pick it up.

It reaches Ghostty only. SketchyBar and JankyBorders still carry their own
static Catppuccin Mocha values — wiring wallust through to them is a natural
next step, not done.
