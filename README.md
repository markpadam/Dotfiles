# Dotfiles

Personal dotfiles and bootstrap scripts for macOS, Ubuntu, and WSL.

## Repo structure

- `bootstrap.sh` - clone/update and bootstrap the repo
- `install/common.sh` - common installer for Linux deps + Kubernetes tooling (kubectl, helm, k9s, kubectx)
- `install/ubuntu.sh` - Ubuntu-specific setup (own Docker daemon)
- `install/wsl.sh` - WSL-specific setup (Docker Desktop backend)
- `install/macos.sh` - macOS-specific setup (Homebrew)
- `dotfiles/` - symlinked dotfiles
- `config/nvim/` - LazyVim config, symlinked to `~/.config/nvim`
- `profile.d/` - shell helpers and environment helpers

## Quick start

Run the one-liner from a fresh shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/markpadam/Dotfiles/main/bootstrap.sh)"
```

Then reload your shell:

```bash
exec $SHELL
```

## Supported platforms

- Ubuntu
- Windows Subsystem for Linux (WSL)
- macOS

## Included dotfiles

- `.bashrc` (Linux: multipass VM, WSL)
- `.zshrc` (macOS default shell — sources the same shared helpers as bash)
- `.bash_aliases`
- `.bash_exports`
- `.bash_functions`
- `.tmux.conf`
- `.vimrc` (classic vim fallback)

Git config is the one exception that is **not** symlinked: `~/.gitconfig` is a
real per-machine file (created by `bootstrap.sh`) that `[include]`s the tracked
`dotfiles/gitconfig.shared` plus `~/.gitconfig.local` (identity). This keeps
git's own runtime writes (`safe.directory`, git-lfs filters) out of the tracked
repo, so they can't dirty the tree and block `git pull`.

Neovim/LazyVim is the default editor (`EDITOR=nvim`, `v` → `nvim`); classic
`vim` stays installed as a fallback. The LazyVim config is **not** a home
dotfile — it lives in `config/nvim/` and is symlinked to `~/.config/nvim` by
`bootstrap.sh`. `config/nvim/lazy-lock.json` pins plugin versions so the Mac
and the multipass VM resolve the same plugins. `node` is installed too, since
LazyVim's npm-based LSPs (e.g. `yaml-language-server` for k8s manifests) and
Copilot need it.

Git identity is **not** stored here. Create `~/.gitconfig.local` per machine:

```ini
[user]
    name = Mark Adam
    email = markpadam@hotmail.com
```

## Profile helpers

- `profile.d/kubernetes.sh`
- `profile.d/docker.sh`
- `profile.d/helm.sh`
- `profile.d/tools.sh`

## Kubernetes / exam ergonomics

- `k` alias with kubectl tab-completion (bash + zsh)
- `kn <ns>` to switch namespace, `kctx`, plus `kubectx`/`kubens`
- `$do` = `--dry-run=client -o yaml`, `$now` = `--force --grace-period=0`
- vim auto-indents YAML at 2 spaces and shows tabs/trailing whitespace
- k9s installed on all platforms
- neovim + LazyVim installed on all platforms (same config Mac ⇄ multipass VM)

## Notes

- `bootstrap.sh` clones or updates the repo into `~/.dotfiles`
- dotfiles are symlinked into `~` (existing real files are backed up to `*.bak`)
- `config/nvim` is symlinked to `~/.config/nvim` (existing real dir backed up to `nvim.bak`)
- `.bashrc` and `.zshrc` source `profile.d/*.sh` directly
- first `nvim` launch on a new machine bootstraps LazyVim plugins from `lazy-lock.json`

## Customization

Edit files in `dotfiles/` and `profile.d/` to fit your workflow.
