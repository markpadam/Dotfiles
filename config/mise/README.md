# mise

Per-project runtime version manager (the `asdf` successor). Shims Node, Python,
Go and Rust onto `PATH` at the version each project asks for.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew install mise
```

## Config

`config/mise/config.toml` here, symlinked to `~/.config/mise/` by the generic
`config/` loop in `bootstrap.sh`.

```toml
[tools]
node   = "lts"
python = "3.12"
go     = "latest"
rust   = "stable"

[settings]
experimental = true
```

These are the global defaults. A project's own `.mise.toml` (or `.tool-versions`)
overrides them inside that directory.

## Activation

The version shims only take effect once mise hooks the shell:

```sh
eval "$(mise activate zsh)"
```

That line lives in `dotfiles/.zshrc`, just after the `profile.d` loop, guarded
on `command -v mise` so the same `.zshrc` still works on hosts without mise.

## Everyday commands

```sh
mise install          # install everything config.toml asks for
mise use node@22      # pin a version for the current directory
mise ls               # what is installed / active
```
