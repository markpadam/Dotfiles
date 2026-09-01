# WezTerm

The terminal emulator for the Omachy setup.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install --cask wezterm
```

Needs **Hack Nerd Font** (in the `Brewfile`).

## Config

`wezterm.lua` here, symlinked to `~/.config/wezterm/` by the generic `config/`
loop in `bootstrap.sh` — no special-case needed.

### Deliberately minimal

No leader key, no split or pane bindings. AeroSpace tiles the windows and
tmux (`dotfiles/.tmux.conf`, prefix `C-b`) multiplexes inside them, so a
WezTerm leader on the same chord would swallow tmux's prefix before tmux saw
it. The only bindings are:

```
Cmd + =   font size up
Cmd + -   font size down
Cmd + n   new window
```

### Appearance

Hack Nerd Font 13.5, 94% opacity with a 20px background blur, `RESIZE` window
decorations (no title bar), 8px padding, tab bar hidden when there is one tab.

### Colours

If `~/.config/wezterm/colors/wallust.toml` exists it is loaded as the
`wallust` scheme; otherwise the built-in `Catppuccin Mocha` scheme is used.
See `config/wallust/README.md`.

> `wezterm.color.load_scheme`'s signature has **not** been checked against the
> installed WezTerm version. If WezTerm errors on startup, that call is the
> first suspect — `wezterm show-config` or the changelog.

## Reload

WezTerm watches the file and reloads automatically on save
(`automatically_reload_config` defaults on). `Cmd + Shift + R` forces it.
