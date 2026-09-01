# omachy

Scripts that glue the Omachy setup together. Currently one: the `dev` project
workspace builder.

`config/omachy/` here, symlinked to `~/.config/omachy/` by the generic
`config/` loop in `bootstrap.sh`.

## dev-session.sh

```sh
dev [path]     # defaults to the current directory
```

`dev` is a shell function in the "Omachy managed" block of `dotfiles/.zshrc`:

```sh
dev() { sh ~/.config/omachy/dev-session.sh "$@"; }
```

It attaches an existing tmux session named after the directory, or builds a
fresh one with five windows:

```
nvim       nvim .        (selected on attach)
opencode   opencode
git        lazygit
server     empty
scratch    empty
```

The session name is `basename` with `.` and `:` replaced by `-` (tmux rejects
both in session names).

Needs `tmux`, `nvim` and `lazygit` (all in the `Brewfile`) plus `opencode`
(installed via Homebrew but **not yet recorded in the `Brewfile`** — add it).
Keep the exec bit (`git update-index --chmod=+x`; the repo sets
`core.fileMode = false`).
