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
| `Brewfile` | 10 taps, 54 formulae, 14 casks, 2 npm globals |
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
`hammerspoon/` links into `~/.hammerspoon/`, and `vscode/`
(`settings.json` + `keybindings.json`) into `~/Library/Application Support/Code/
User/` — both via explicit `bootstrap.sh` blocks. VS Code rewrites its two
files on every GUI toggle, so expect them dirty; extensions stay in
`packages/vscode-extensions.txt`.

## Window management

**Omarchy-style keyboard-driven tiling**, added back on 28 August 2026 after
an earlier stock-macOS period (4-5 August 2026, when SketchyBar, yabai and
Raycast were all torn out — see git history around `554451c` if that state
is ever wanted back). The current stack:

Each tool below has a `README.md` next to its config with the settings and
gotchas; these bullets are just the map.

- **AeroSpace** (`dotfiles/aerospace/`) — tiling window manager on its stock
  `alt`-prefixed bindings. Five named workspaces on `alt-1`..`alt-5` —
  `desktop` / `terminal` / `browser` / `comms` / `coding` — shown as
  SketchyBar pills; a list of always-floating apps; `alt--` / `alt-=` resize
  (no mouse-drag resize, by design). On login the workspace apps are
  relaunched (`after-startup-command`) and `on-window-detected` rules route
  each back to its workspace — see the AeroSpace README's "Session
  persistence".
- **SketchyBar** (`dotfiles/sketchybar/`) — status bar at the macOS menu-bar
  height; workspace pills follow AeroSpace's `exec-on-workspace-change` hook,
  not native macOS Spaces. Splits into two islands around the notch on the
  built-in.
- **JankyBorders** (`dotfiles/borders/`) — mauve "glow" border on the focused
  window.
- **Hammerspoon** (`dotfiles/hammerspoon/`) — the Linux-desktop glue macOS
  lacks. Auto-hides the menu bar on a wired external display; the **Omachy
  command menu** (`menu.lua`, `hs.canvas` modal on `Opt+Space`); a
  **whole-desktop theme switcher** (`theme.lua` — Ghostty, SketchyBar,
  JankyBorders, prompt, bat, btop, k9s, nvim, wallpaper together, `⌃⌥Space` to
  cycle); a volume/brightness **OSD**; a **Quake terminal** (`⌃\``); **Zen
  mode** and toggles; **clipboard history**; a **which-key** overlay; idle
  dim-then-lock; and SketchyBar state glyphs (updates count, now-playing,
  recording). Its README has the full map. `bootstrap.sh` links every `*.lua`
  in the dir into `~/.hammerspoon/` (Hammerspoon does not read `~/.config`).
- **Karabiner-Elements** (`snapshots/karabiner/`) — now only declares the
  keyboard as ANSI. The Caps Lock → Ctrl+Option hyper key it used to provide
  was retired on 30 August 2026 (`f5e684a`) when AeroSpace moved to its native
  `alt` bindings. A candidate for removal.

The Accessibility grants (AeroSpace, Hammerspoon) are manual GUI steps that
`bootstrap.sh` cannot do — macOS requires a human click for each.

## Terminal, toolchains, theming

Added 29-30 August 2026 (phase F), rounding out the rest of the Omarchy-style
setup that phases A-E didn't cover:

Each has a `README.md` next to its config.

- **Ghostty** (`config/ghostty/`) — the terminal emulator (one of Omarchy's
  four supported). Titlebar hidden, no tabs/splits — AeroSpace tiles windows,
  tmux multiplexes inside them. `theme.conf` (written by the Hammerspoon theme
  switcher) is the last `config-file` include and sets the palette.
  `config/ghostty/launch` opens the named windows (AKS-Lab / IDE / K8s Exam /
  PowerShell / Ubuntu — the old iTerm profiles), wired into the Hammerspoon menu.
- **tmux** (`dotfiles/.tmux.conf`) — prefix `C-b`, TPM plugins, a Dracula
  status bar, `v`/`x` splits, `h/j/k/l` pane moves. `config/omachy/dev-session.sh`
  builds a preset session on top of it.
- **Shell** (`dotfiles/.zshrc`) — zsh + oh-my-zsh (plugins only, no theme).
  The "Omachy managed" block at the end wires **Starship** (prompt,
  `config/starship.toml`, replaced powerlevel10k on 30 August 2026), `fzf`,
  `atuin`, `zoxide` (`cd`), `eza` (`ls`/`ll`/`la`/`lt`), `bat` (`cat`), vi
  mode, `fastfetch`, and the `dev` function (`config/omachy/`).
- **mise** (`config/mise/`) — Node/Python/Go/Rust versions. Needs
  `eval "$(mise activate zsh)"`, which `.zshrc` does after the profile.d loop.
- **Theming** — the Hammerspoon **theme switcher** (`dotfiles/hammerspoon/
  theme.lua`, 8 themes, `⌃⌥Space` to cycle) re-skins Ghostty, SketchyBar,
  JankyBorders, Starship, bat, btop, k9s, Neovim and the wallpaper from one
  curated palette. Generated files (`theme.conf`, `theme.sh`,
  `omachy-theme.txt`) are `.gitignore`d.
- **wallust** (`config/wallust/`) — superseded by the theme switcher; kept for
  the odd manual `wallust run`. **Not in Homebrew core**
  (`chenrui333/tap/wallust`, `trusted: true`).

### `config/` → `~/.config`

`nvim/` (LazyVim) · `fish/` · `powershell/` · `git/` · `ghostty/` ·
`wallust/` · `mise/` · `omachy/` · `starship.toml`

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
