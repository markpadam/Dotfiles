# AutoRaise

Focus follows the mouse: hover a window and it takes keyboard focus, then raises.
The one feature worth keeping from the yabai experiment, as a standalone tool —
it needs Accessibility permission only, not a disabled SIP.

The Apple Notes wiki holds the overview. This file is the config reference.

## Install

```sh
brew tap dimentium/autoraise
brew install dimentium/autoraise/autoraise
brew services start dimentium/autoraise/autoraise
```

Not in homebrew/core, so the tap needs its own `Brewfile` line or `brew bundle`
cannot resolve the formula.

## Config

`config` here, symlinked to `~/.config/AutoRaise/` by the `config/` loop in
`bootstrap.sh`. Not executable — AutoRaise parses it, so no exec bit is needed.

Current settings, all of which match the built-in defaults:

```sh
pollMillis=50          # mouse poll interval, min 20
delay=1                # raise delay in units of pollMillis; 0 = focus only
requireMouseStop=true  # wait for the mouse to settle before acting
disableKey=control     # hold to suspend while held
```

`delay=0` drops the raise and leaves focus-only — yabai's `autofocus` behaviour.
`ignoreApps="A,B"` excludes apps that misbehave. The `focusDelay` option needs a
rebuild with `--with-dexperimental_focus_first`; it is not compiled in here.

## Accessibility is pinned to the versioned Cellar path

macOS recorded the grant against `Cellar/autoraise/5.6/bin/AutoRaise`, not the
stable `opt/autoraise/bin/AutoRaise` symlink. **A `brew upgrade` moves the binary
to a new versioned path and the permission silently stops applying** — AutoRaise
keeps running and does nothing at all.

After any upgrade, re-add it in System Settings → Privacy & Security →
Accessibility (`+`, then Cmd+Shift+G and paste the new path) and remove the stale
entry. The same trap applies to `borders`.

The same thing catches a fresh install for a different reason: the command-line
build runs headless under `launchd`, so it never triggers a permission prompt.
Nothing looks wrong — hovering simply does nothing.

## Run / restart

```sh
brew services start dimentium/autoraise/autoraise
brew services restart dimentium/autoraise/autoraise   # after editing config
```

Logs go to `~/Library/Logs/AutoRaise.log`, but only when `verbose=true` is set.
