# Dotfiles

Personal dotfiles and bootstrap scripts for macOS, Ubuntu, and WSL.

## Repo structure

- `bootstrap.sh` - clone/update and bootstrap the repo
- `install/common.sh` - common installer for Linux dependencies
- `install/ubuntu.sh` - Ubuntu-specific setup
- `install/wsl.sh` - WSL-specific setup
- `install/macos.sh` - macOS-specific setup
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

- `.bashrc`
- `.bash_aliases`
- `.bash_exports`
- `.bash_functions`
- `.tmux.conf`
- `.vimrc`
- `.gitconfig`

## Profile helpers

- `profile.d/kubernetes.sh`
- `profile.d/docker.sh`
- `profile.d/helm.sh`
- `profile.d/tools.sh`

## Notes

- `bootstrap.sh` clones or updates the repo into `~/.dotfiles`
- dotfiles are symlinked into `~`
- `~/.bashrc` is updated once to source `profile.d/*.sh`

## Customization

Edit files in `dotfiles/` and `profile.d/` to fit your workflow.
