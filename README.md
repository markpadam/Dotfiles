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
| `Brewfile` | 9 taps, 43 formulae, 12 casks, 2 npm globals |
| `install/macos.sh` | `brew bundle install` wrapper |
| `install/shell.sh` | oh-my-zsh, powerlevel10k, zsh plugins |
| `install/vscode.sh` | Reinstalls VS Code extensions |
| `macos/defaults.sh` | System preferences that differ from stock |
| `dotfiles/` | Files symlinked into `~` |
| `config/` | Directories symlinked into `~/.config` |
| `snapshots/` | Configs restored by **copy**, never symlinked |
| `profile.d/` | Shared shell helpers, sourced by `.zshrc`/`.bashrc` |
| `packages/` | VS Code extension list |
| `raycast/scripts/` | Raycast Script Commands — add the directory in Raycast |

### `dotfiles/` → `~`

`.zshrc` `.bashrc` `.bash_aliases` `.bash_exports` `.bash_functions` `.vimrc`
`.tmux.conf` `.p10k.zsh` `gitconfig.shared`

`sketchybar/`, `borders/`, `yabai/` and `skhd/` also live here (rather than
under `config/`) and are linked to `~/.config/` — that is where this Mac's
existing symlinks already point, and moving them would break a working machine.

`yabai` and `skhd` both need Accessibility permission granted by hand the first
time (System Settings → Privacy & Security → Accessibility) before
`brew services start` will do anything useful, so bootstrap installs them but
does not start them.

### `config/` → `~/.config`

`nvim/` (LazyVim) · `fish/` · `powershell/` · `git/` · `starship.toml`

### `snapshots/` → copied, not linked

`gh/` · `qBittorrent/` · `NuGet/`

These apps rewrite their own config files at runtime. Symlinking them into a
public git repo would let the app commit its runtime state — and in `gh`'s case
potentially an auth token — straight into version control. `bootstrap.sh` copies
them only when no live config already exists, so it never clobbers a
working setup.

## The shell

zsh via oh-my-zsh, themed with powerlevel10k. `.p10k.zsh` is a Catppuccin Mocha
prompt config, so a restored machine gets the finished prompt without anyone
running `p10k configure`.

Plugins: `git kubectl kubectx helm docker docker-compose terraform azure fluxcd
zsh-autosuggestions zsh-syntax-highlighting`.

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
