# Dotfiles

Personal dotfiles and bootstrap scripts for macOS, Ubuntu, and WSL.

## Repo structure

- `bootstrap.sh` - clone/update and bootstrap the repo
- `install/common.sh` - common installer for Linux deps + Kubernetes tooling (kubectl, helm, k9s, kubectx)
- `install/ubuntu.sh` - Ubuntu-specific setup (own Docker daemon)
- `install/wsl.sh` - WSL-specific setup (Docker Desktop backend)
- `install/macos.sh` - macOS-specific setup (Homebrew)
- `dotfiles/` - symlinked dotfiles
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
- `.vimrc`
- `.gitconfig`

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

## Notes

- `bootstrap.sh` clones or updates the repo into `~/.dotfiles`
- dotfiles are symlinked into `~` (existing real files are backed up to `*.bak`)
- `.bashrc` and `.zshrc` source `profile.d/*.sh` directly

## Customization

Edit files in `dotfiles/` and `profile.d/` to fit your workflow.
