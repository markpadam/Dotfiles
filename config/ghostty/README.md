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

`config-file = ?wallust.conf` optionally pulls in a wallpaper-derived palette
from `config/wallust/` (the `?` = no error if it hasn't been generated). Those
`background` / `palette` keys override `theme = Catppuccin Mocha`.
`wallust.conf` is `.gitignore`d — it lands in this dir via the symlink.

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
