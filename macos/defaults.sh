#!/usr/bin/env bash
set -euo pipefail

# macOS system preferences captured from this Mac.
#
# Only settings that actually differ from Apple's defaults are recorded here.
# Everything else on the machine was left at stock, and writing stock values
# back would just add noise that's impossible to review later.
#
# Re-runnable: every line is an idempotent `defaults write`.

echo "[*] Applying macOS defaults..."

# --- Dock -------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock tilesize -int 35
# Minimise windows into their app icon rather than a separate Dock tile.
defaults write com.apple.dock minimize-to-application -bool true
# Stop Mission Control reordering desktops by recency. Ctrl+1..9 and the
# sketchybar space islands are both *positional*, so with reordering on the
# numbers drift apart from the desktops and silently stop meaning anything.
defaults write com.apple.dock mru-spaces -bool false

# --- Finder -----------------------------------------------------------------
# icnv = icon view. Others: Nlsv (list), clmv (column), glyv (gallery).
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"

# --- Global / appearance ----------------------------------------------------
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
# Natural scrolling OFF (scroll direction follows the content, not the finger).
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# --- Screenshots ------------------------------------------------------------
defaults write com.apple.screencapture location -string "$HOME/Documents"

# --- Keyboard shortcuts -----------------------------------------------------
# com.apple.symbolichotkeys stores every system shortcut by numeric id. The
# parameter triple is (ascii, keycode, modifier mask); 262144 = control,
# 524288 = option, 1048576 = command.
#
# Writing these is not enough on its own -- the window server only re-reads the
# plist when activateSettings is run, which happens at the end of this section.
hotkey() { # hotkey <id> <enabled true|false> <ascii> <keycode> <modifiers>
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" "
      <dict><key>enabled</key><$2/>
      <key>value</key><dict>
        <key>parameters</key><array>
          <integer>$3</integer><integer>$4</integer><integer>$5</integer>
        </array>
        <key>type</key><string>standard</string>
      </dict></dict>"
}

# Ctrl+1..0 switch to Desktop 1..10 (ids 118-127). Off by default beyond the
# first few. These are load-bearing for the SketchyBar space pills: clicking one
# synthesises the matching Ctrl+n, so without these the islands do nothing.
# Note the keycodes are not sequential -- 5 and 6 are swapped, as are 7 and 8.
hotkey 118 true 49 18 262144   # Desktop 1
hotkey 119 true 50 19 262144   # Desktop 2
hotkey 120 true 51 20 262144   # Desktop 3
hotkey 121 true 52 21 262144   # Desktop 4
hotkey 122 true 53 23 262144   # Desktop 5
hotkey 123 true 54 22 262144   # Desktop 6
hotkey 124 true 55 26 262144   # Desktop 7
hotkey 125 true 56 28 262144   # Desktop 8
hotkey 126 true 57 25 262144   # Desktop 9
hotkey 127 true 48 29 262144   # Desktop 10

# Ctrl+Opt+Space, "Select next source in Input menu". Disabled because it
# collides with skhd's float toggle on the same chord.
hotkey 61 false 32 49 786432

# Cmd+Space, Spotlight. Enabled. Raycast used to own this chord; its own hotkey
# has to be cleared or moved in Raycast's own settings, because a Raycast global
# hotkey wins over the system one while Raycast is running. Note Opt+Cmd+Space
# (id 65, Finder search window) is deliberately left alone.
hotkey 64 true 32 49 1048576

# --- Apply ------------------------------------------------------------------
# Dock and Finder only re-read their prefs on restart. AppleInterfaceStyle needs
# a logout (or an SP restart) to take effect everywhere, so it may look unapplied
# until the next login.
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

# Makes the window server re-read com.apple.symbolichotkeys. Without this the
# shortcuts above are written but inert until the next login.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u >/dev/null 2>&1 || true

echo "[*] macOS defaults applied. Log out and back in for appearance changes."
