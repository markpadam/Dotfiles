# Dotfiles

A backup of this Mac's setup — shell, editor, packages and system preferences —
captured so the machine can be rebuilt from scratch.

Snapshot taken: **2 August 2026**, from `Mark's MacBook Pro` (Apple Silicon,
Homebrew at `/opt/homebrew`).

> This repo is **public**. Nothing here contains credentials — see
> [What is deliberately not here](#what-is-deliberately-not-here).

## Restore a machine

```bash
git clone https://github.com/markpadam/Dotfiles.git ~/.dotfiles
bash ~/.dotfiles/bootstrap.sh
```

`bootstrap.sh` is safe to re-run. It installs Homebrew if missing, restores
packages, sets up the shell, links configs, and backs up any real file it would
otherwise overwrite to `<name>.bak`.

System preferences are **not** applied automatically, because doing so restarts
Dock and Finder and flips the machine to dark mode. Apply them deliberately:

```bash
bash ~/.dotfiles/macos/defaults.sh
```

## Layout

| Path | What it is |
|---|---|
| `bootstrap.sh` | Entry point — clone/update, install, link |
| `Brewfile` | 10 taps, 43 formulae, 14 casks, 2 npm globals |
| `install/macos.sh` | `brew bundle install` wrapper |
| `install/shell.sh` | oh-my-zsh + zsh plugins (prompt is Starship) |
| `install/vscode.sh` | Reinstalls VS Code extensions |
| `macos/defaults.sh` | System preferences that differ from stock |
| `dotfiles/` | Files symlinked into `~` |
| `config/` | Directories symlinked into `~/.config` |
| `snapshots/` | Configs restored by **copy**, never symlinked |
| `profile.d/` | Shared shell helpers, sourced by `.zshrc`/`.bashrc` |
| `packages/` | VS Code extension list |

### `dotfiles/` → `~`

`.zshrc` `.bashrc` `.bash_aliases` `.bash_exports` `.bash_functions` `.vimrc`
`.tmux.conf` `gitconfig.shared`

`borders/`, `aerospace/` and `sketchybar/` also live here (rather than under
`config/`) and are linked to `~/.config/` — that is where this Mac's existing
symlinks already point, and moving them would break a working machine.

## Window management

**Omarchy-style keyboard-driven tiling**, added back on 28 August 2026 after
an earlier stock-macOS period (4-5 August 2026, when SketchyBar, yabai and
Raycast were all torn out — see git history around `554451c` if that state
is ever wanted back). The current stack:

Each tool below has a `README.md` next to its config with the settings and
gotchas; these bullets are just the map.

- **AeroSpace** (`dotfiles/aerospace/`) — tiling window manager on its stock
  `alt`-prefixed bindings. Five named workspaces on `alt-1`..`alt-5` —
  `desktop` / `terminal` / `browser` / `comms` / `man` — shown as SketchyBar
  pills; a list of always-floating apps; `alt--` / `alt-=` resize (no
  mouse-drag resize, by design). On login the workspace apps are relaunched
  (`after-startup-command`) and `on-window-detected` rules route each back to
  its workspace — see the AeroSpace README's "Session persistence".
- **SketchyBar** (`dotfiles/sketchybar/`) — status bar at the macOS menu-bar
  height; workspace pills follow AeroSpace's `exec-on-workspace-change` hook,
  not native macOS Spaces. Splits into two islands around the notch on the
  built-in.
- **JankyBorders** (`dotfiles/borders/`) — mauve "glow" border on the focused
  window.
- **AutoRaise** (`config/AutoRaise/`) — focus-follows-mouse, with raise. Hold
  Control to suspend it.
- **Hammerspoon** (`dotfiles/hammerspoon/init.lua`) — auto-hides the menu bar
  when a wired external display is connected. Nothing else. Linked to
  `~/.hammerspoon/init.lua` by an explicit line in `bootstrap.sh` (Hammerspoon
  does not read `~/.config`).
- **Raycast** (`raycast/scripts/`) — launcher; Script Commands only, restored
  from git history (`a12c1ef`).
- **Karabiner-Elements** (`snapshots/karabiner/`) — now only declares the
  keyboard as ANSI. The Caps Lock → Ctrl+Option hyper key it used to provide
  was retired on 30 August 2026 (`f5e684a`) when AeroSpace moved to its native
  `alt` bindings. A candidate for removal.

Raycast's hotkey and the Accessibility grants (AeroSpace, AutoRaise,
Hammerspoon) are manual GUI steps that `bootstrap.sh` cannot do — macOS
requires a human click for each.

## Terminal, toolchains, theming

Added 29-30 August 2026 (phase F), rounding out the rest of the Omarchy-style
setup that phases A-E didn't cover:

Each has a `README.md` next to its config.

- **WezTerm** (`config/wezterm/`) — the terminal emulator. Deliberately no
  leader/split keys: AeroSpace tiles windows, tmux multiplexes inside them.
  wallust palette if present, else the built-in Catppuccin Mocha scheme.
- **tmux** (`dotfiles/.tmux.conf`) — prefix `C-b`, TPM plugins, a Dracula
  status bar, `v`/`x` splits, `h/j/k/l` pane moves. `config/omachy/dev-session.sh`
  builds a preset session on top of it.
- **Shell** (`dotfiles/.zshrc`) — zsh + oh-my-zsh (plugins only, no theme).
  The "Omachy managed" block at the end wires **Starship** (prompt,
  `config/starship.toml`, replaced powerlevel10k on 30 August 2026), `fzf`,
  `atuin`, vi mode, `fastfetch`, and the `dev` function (`config/omachy/`).
- **mise** (`config/mise/`) — Node/Python/Go/Rust versions. Needs
  `eval "$(mise activate zsh)"`, which `.zshrc` does after the profile.d loop.
- **wallust** (`config/wallust/`) — generates a palette from the wallpaper.
  **Not in Homebrew core** (`chenrui333/tap/wallust`, `trusted: true`).
  Untested against the installed version — see its README before relying on it.

### `config/` → `~/.config`

`nvim/` (LazyVim) · `fish/` · `powershell/` · `git/` · `AutoRaise/` ·
`wezterm/` · `wallust/` · `mise/` · `omachy/` · `starship.toml`

`AutoRaise` needs an Accessibility grant made by hand the first time (System
Settings → Privacy & Security → Accessibility) before `brew services start`
does anything useful. macOS pins that grant to the **versioned Cellar path**,
so a `brew upgrade` silently revokes it. See `config/AutoRaise/README.md`.

### `snapshots/` → copied, not linked

`gh/` · `qBittorrent/` · `NuGet/` · `karabiner/`

These apps rewrite their own config files at runtime. Symlinking them into a
public git repo would let the app commit its runtime state — and in `gh`'s case
potentially an auth token — straight into version control. `bootstrap.sh` copies
them only when no live config already exists, so it never clobbers a
working setup. `karabiner/karabiner.json` now only declares the keyboard type
(the Caps Lock hyper key was retired on 30 August 2026) — but Karabiner still
rewrites this file constantly (device IDs, UI state), so it belongs here for
the same reason `gh` does.

## The shell

zsh via oh-my-zsh for plugins and completion; the prompt is **Starship**
(`config/starship.toml`, a Catppuccin Mocha config), initialised in the
Omachy-managed block at the end of `.zshrc`. oh-my-zsh loads no theme of its
own (`ZSH_THEME=""`).

Plugins: `git kubectl kubectx helm docker docker-compose terraform azure fluxcd
zsh-autosuggestions zsh-syntax-highlighting`. The last two are loaded by
oh-my-zsh only — the Omachy block does not re-source them.

The Omachy-managed block also initialises `fzf` (`Ctrl-t` file / `Alt-c` cd),
`atuin` (history search on `Ctrl-r`), `mise`, vi mode (`set -o vi`),
`fastfetch` on launch, and the `dev` function (`config/omachy/dev-session.sh`).

`.zshrc` guards the oh-my-zsh load, so the same file still produces a working
shell on hosts without it.

## What is deliberately not here

Machine-local identity and secrets are excluded by design, and `.gitignore`
guards against them being added back by accident:

- `~/.gitconfig.local` — git identity, generated per machine by `bootstrap.sh`
- `~/.gitconfig` — a real file, not a symlink, so git's own runtime writes
  (`safe.directory`, git-lfs filters) stay out of the repo
- `.config/gh/hosts.yml` — GitHub account state; re-run `gh auth login`
- `.config/github-copilot/` — contains `auth.db`, an OAuth token store
- `~/.credentials`, `~/.vault-token`, `~/.env`, `~/.aks-lab-secrets`, `~/.lab-ado`
- Shell history, `.zcompdump*` caches, `.DS_Store`, and `*.bak` leftovers

## Notes

- `brew bundle install --no-upgrade` is additive: re-running bootstrap installs
  what is missing and leaves existing formulae at their current version, so it
  never turns into a surprise system-wide upgrade.
- `freelens`, `headlamp` and `postman` are pinned in the `Brewfile` by hand.
  They are installed on this Mac, but their Homebrew install receipts are out of
  sync with the cask definitions, so `brew bundle dump` silently omits them.
- The `Brewfile` records 41 top-level formulae, not the 178 that `brew list`
  reports — the remainder are dependencies Homebrew resolves on its own.
- This repo previously carried Ubuntu and WSL installers. It is now a macOS
  backup; those scripts remain available in git history.
