# macOS defaults, shortcuts and desktops

What `macos/` does, and the details you need when changing it. The Apple Notes
wiki holds the human-facing shortcut list; this file is the reference for how it
is stored and applied.

```
defaults.sh      Dock, Finder, appearance, screenshots, keyboard shortcuts
seed-spaces.sh   Names the Mission Control desktops via DesktopRenamer
```

Apply with `bash macos/defaults.sh`. It is idempotent.

## The keyboard shortcut store

Everything lives in `com.apple.symbolichotkeys`, keyed by numeric id:

```
118-127   Desktop 1-10
 79-82    Space navigation (Ctrl+Left/Right and friends)
    61    Select next source in Input menu  (Ctrl+Opt+Space)
    64    Show Spotlight search             (Cmd+Space)
    65    Show Finder search window         (Opt+Cmd+Space)
```

An entry recorded as just `{ enabled = 1; }` with no parameters uses Apple's
built-in key combination. An entry with a `parameters` triple has an explicit
binding of `(ascii, keycode, modifiers)`:

```
262144  Ctrl        524288  Opt
1048576 Cmd         131072  Shift
```

The `hotkey()` helper in `defaults.sh` wraps the `-dict-add` plist fragment.

**Writing the plist is not enough.** The window server only re-reads it when
`activateSettings -u` runs, so a change appears to have silently failed until the
next login. `defaults.sh` calls it at the end of the section:

```sh
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
```

### Notable bindings

- **Ctrl+1..0 → Desktop 1..10** are wired up for all ten even though only five
  desktops exist, so adding a sixth needs no shortcut work. With no hotkey daemon
  in the setup these **are** the desktop-switching keys, not a convenience layer
  on top of one — turn them off and you are left with Ctrl+arrows and Mission
  Control. (They were also what SketchyBar's space pills synthesised when
  clicked, before the bar was removed on 2026-08-04.)
- **Cmd+Space (id 64) is enabled — Spotlight, and now uncontested.** Raycast used
  to own this chord and id 64 was disabled for it; that was reversed on 2026-08-03,
  and Raycast itself was removed on 2026-08-05. The old caveat about clearing
  Raycast's own global hotkey in its settings no longer applies.
- **Ctrl+Opt+Space (id 61) is disabled.** It was unbound because it collided with
  skhd's float toggle. skhd went on 2026-08-03 and yabai on 2026-08-05, so nothing
  claims the chord now — but 61 is still deliberately left disabled, because
  flipping it back changes *input* behaviour rather than window behaviour. It is a
  standing choice, not a leftover from the window-manager teardown. With one input
  source installed it is a no-op either way.
- **Opt+Cmd+Space (id 65) is untouched** — still the Finder search window.

### Unverified shortcuts

An earlier version of the wiki listed `Ctrl+Shift+arrows` for moving a window
between desktops and `Ctrl+Opt+Cmd+arrows` for moving between displays. Neither
could be confirmed on this machine — the display one has no entry in
`com.apple.symbolichotkeys` at all. Treat both as unverified.

## Mission Control desktops

Five desktops, named by DesktopRenamer:

```
1  Term    iTerm2, dotfiles
2  Web     Safari
3  Lab     k8s homelab, Vault
4  Notes   Apple Notes wiki, docs
5  Comms   mail, calendar, chat
```

Seed with `bash macos/seed-spaces.sh` — dry run by default, `--apply` to commit,
idempotent. Edit the `NAMES` array to change them.

**Desktops cannot be created from a script while SIP is on**, so add them by hand
first: enter Mission Control, hover the top of the screen until the Spaces bar
expands, click `+`. New desktops always append, so they land on the next ordinal.

### Why it keys by ordinal, not space ID

macOS regenerates a space's ID whenever a desktop is deleted and recreated, so an
ID pinned in a repo goes stale the first time the layout is rebuilt. The IDs here
came back `1, 4, 3, 153, 154` — non-sequential, with Desktop 2 holding ID 4.

Ordinals are only stable with `mru-spaces` disabled, which `defaults.sh` sets. With
Mission Control's recency reordering left on, the ordinals shuffle and the seed
script renames the wrong desktops.

### DesktopRenamer install

```sh
brew tap gitmichaelqiu/tap
brew trust --cask gitmichaelqiu/tap/desktoprenamer
brew install --cask desktoprenamer
```

Trust the single cask, **not the whole tap** — the tap has an unrelated broken
cask (`vtplayer.rb`) that errors on every `brew` operation.

Needs two grants by hand, both GUI-only: right-click the app in `/Applications` →
Open to clear Gatekeeper, then Accessibility under System Settings → Privacy &
Security. It reads and renames nothing until the second one is given.

### DesktopRenamer gotchas

**Its AppleScript dictionary documents the wrong format.** The bundled sdef says
`get all spaces` returns `ID~Name~DisplayID~Num`. Version 1.13.2 actually emits
**six** fields — an undocumented trailing `0` and an empty field — and field 3 is a
display *name* ("Built-in Retina Display"), not an ID. With `IFS='~'` and four
`read` variables, bash assigns the whole remainder to the last one, so `num`
arrives as `1~0~` and any arithmetic on it aborts the script. Read five and let the
last absorb the tail.

**Automation permission is granted per calling binary, so a brew-managed daemon
cannot use AppleScript here.** Found via SketchyBar (removed 2026-08-04), but the
rule is general: the identical `osascript` call returned the name from a terminal
and returned empty when the daemon ran it — silently, no error, because a
background service never reliably gets the consent prompt. Don't call AppleScript
from one.

**Read the plist instead.** `~/Library/Preferences/com.michaelqiu.DesktopRenamer.plist`,
key `com.michaelqiu.desktoprenamer.indexcache` — a base64 JSON blob keyed
`<displayUUID>|Desktop|<ordinal>` → name. No TCC grant, ~15ms rather than an
AppleEvent round trip, and it still works with the app quit. Escape the dots or
`plutil -extract` reads them as a nested key path and finds nothing:

```sh
plutil -extract 'com\.michaelqiu\.desktoprenamer\.indexcache' raw -o - "$PLIST" | base64 -d | jq .
```

It is an undocumented internal key, so treat it as best-effort and always give any
consumer a fallback.

**It parks a window on every desktop** (its on-desktop label windows), so anything
enumerating windows per space sees a phantom entry on every one, including empty
desktops. This bit SketchyBar's per-space app icons and needed an explicit ignore
list; worth knowing before writing any other per-space window query.

### Useful AppleScript

```sh
osascript -e 'tell application "DesktopRenamer" to get all spaces'
osascript -e 'tell application "DesktopRenamer" to get current space name'
osascript -e 'tell application "DesktopRenamer" to rename space "<id>" to "<name>"'
```

The dictionary also exposes `move window to space` and `move specific window` —
worth a look if moving windows between desktops ever becomes worth scripting,
since there is no reliable stock keyboard shortcut for it.

## Keyboard layout

Mark types on the **`British-PC`** layout, not `British`. The two differ in where
`` ` ``, `~`, `\` and `|` sit, so never swap them casually. The unused `British`
layout was removed.
