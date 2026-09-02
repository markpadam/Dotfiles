# Ghostty

The terminal emulator for the Omachy setup — one of Omarchy's four supported
terminals. Replaced iTerm2 + WezTerm on 2026-09-01 (single terminal now).

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install --cask ghostty
```

## Config

`config` here, symlinked to `~/.config/ghostty/` by the generic `config/` loop
in `bootstrap.sh`. Ghostty also reads `~/Library/Application Support/
com.mitchellh.ghostty/config` and it wins over the XDG path — so on a machine
that had a real file there, move it aside (there is a `config.bak-premigration`
on this Mac).

Reload a running Ghostty with **`Cmd + Shift + ,`**.

### Appearance

JetBrains Mono 13, Catppuccin Mocha, 95% opacity, `macos-titlebar-style =
hidden` (no title bar, no traffic lights — the point of the Omachy setup).
No tabs or splits config: AeroSpace tiles windows, tmux (`dotfiles/.tmux.conf`)
multiplexes inside them.

### Colours

Two optional includes, later ones win, so `theme = Catppuccin Mocha` is just
the fallback:

- `?theme.conf` — written by the Hammerspoon theme switcher
  (`dotfiles/hammerspoon/theme.lua`); this is the live source of truth. It's the
  **last** `config-file` line, so the switcher always wins.
- `?wallust.conf` — older wallpaper-derived palette from `config/wallust/`.

Both are `.gitignore`d (they land in this dir via the symlink). After a theme
switch the switcher triggers Ghostty's **Reload Configuration** itself; new
windows pick it up regardless.

## Named windows — `./launch`

`launch <name>` opens a Ghostty window with a locked title, a working
directory and a startup command — the replacement for iTerm's dynamic
profiles:

| name | title | does |
| --- | --- | --- |
| `aks-lab` | `AKS Lab` | `cd` homelab repo, `./aks-lab tmux` |
| `ide` | `IDE` | `~/.local/bin/ide` (LazyVim) in `~/Documents/gitRepos` |
| `exam` | `K8s Exam` | `~/.exam-motd.sh` then a shell |
| `pwsh` | `PowerShell 7` | `pwsh -l` |
| `ubuntu` | `Ubuntu` | `multipass shell primary` |

Wired into the Hammerspoon menu (**Opt+Space → Terminal**). macOS Ghostty has
no "new window into the running instance" from the CLI, so each is `open -na` =
a fresh Ghostty instance — fine for on-demand tools.

The **`AKS Lab`** title is load-bearing: `dotfiles/aerospace/aerospace.toml`
routes `com.mitchellh.ghostty` windows titled `aks.?lab` to the `aks-lab`
workspace and every other Ghostty window to `terminal` (AeroSpace can't tell
two windows of one app apart otherwise). Ghostty's `--title` ignores title
escape sequences, so tmux/zsh can't clobber it.

## Exec bit

`launch` is executable; `core.fileMode = false` in this repo, so it was added
with `git update-index --chmod=+x`.
