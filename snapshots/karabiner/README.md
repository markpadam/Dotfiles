# Karabiner-Elements

Was kept only to declare the keyboard as ANSI after the Caps Lock hyper key was
retired (2026-08-30). Now also carries **one complex modification**: it remaps
`Cmd+Tab` → `Cmd+F18` and `Cmd+Shift+Tab` → `Cmd+F19` (Cmd still held) so the
themed Hammerspoon window switcher (`dotfiles/hammerspoon/switcher.lua`) can
bind it — macOS reserves `Cmd+Tab` itself at the Carbon level and neither
`hs.hotkey` nor a session eventtap can take it.

## Snapshot, not symlink

`karabiner.json` here is **copied** into `~/.config/karabiner/` by
`bootstrap.sh`, never symlinked — Karabiner rewrites its own config constantly
(device ids, UI state), which a symlink into a public repo would commit. The
copy only happens when no live config exists, so it never clobbers a working
setup; re-apply a repo change by hand:

```sh
cp ~/.dotfiles/snapshots/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
```

Karabiner watches the file and reloads on save.

## First-run setup (manual, GUI)

The DriverKit virtual-HID extension needs a human click — `bootstrap.sh` can't:

1. `brew reinstall --cask karabiner-elements` if the app bundle is broken
   (`/Applications/Karabiner-Elements.app/Contents/MacOS/` empty). Needs `sudo`.
2. Open **Karabiner-Elements.app**.
3. **System Settings → Privacy & Security** (and **Login Items & Extensions →
   Driver Extensions** on macOS 26) → allow *"System software from Karabiner-
   Elements"* / enable the driver extension. Reboot if it asks.
4. Karabiner adds its own login items once the driver is live; confirm
   `pgrep -fl karabiner_grabber` returns a process.
5. In Karabiner-Elements → **Complex Modifications**, the *"Omachy: Cmd+Tab →
   Cmd+F18"* rule loads from `karabiner.json` automatically; check it's listed.

Check it works: `Cmd+Tab` should raise the Hammerspoon switcher, not the macOS
one. If the macOS switcher still shows, the driver isn't approved.
