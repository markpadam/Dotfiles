# VS Code

`settings.json` and `keybindings.json`, symlinked to
`~/Library/Application Support/Code/User/` by an explicit block in
`bootstrap.sh` (VS Code's config isn't under `~/.config`, and the generic
`config/` loop would put it in the wrong place).

**VS Code rewrites both files on every GUI settings change**, so they will show
up dirty in `git status` — that's expected. Commit the changes you meant to
make; `git checkout` the ones you didn't.

Extensions are not here — that's `packages/vscode-extensions.txt`, restored by
`install/vscode.sh` (a `code --install-extension` loop) which `bootstrap.sh`
runs.

## Notable settings

- **Frameless-ish window** — `window.titleBarStyle = "custom"` +
  `window.customTitleBarVisibility = "never"` + `window.commandCenter = false`.
  No native title bar; the traffic lights only fade in on hover. This is about
  as close to the Omarchy no-decorations look as macOS allows for VS Code (see
  the Hammerspoon/AeroSpace notes — arbitrary apps can't be de-framed).
- **Theme** — Catppuccin Mocha, `CaskaydiaCove Nerd Font`, no minimap, vscode-icons.
- YAML formatter + tab/indent overrides for Azure Pipelines / docker-compose /
  GitHub Actions; `yaml.disableSchemaDetection` for CI workflow files.
- `keybindings.json` — one binding: `Shift+Enter` in the integrated terminal
  sends `ESC CR` (for multi-line prompts in TUI agents).
