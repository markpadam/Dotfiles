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

# --- Finder -----------------------------------------------------------------
# icnv = icon view. Others: Nlsv (list), clmv (column), glyv (gallery).
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"

# --- Global / appearance ----------------------------------------------------
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
# Natural scrolling OFF (scroll direction follows the content, not the finger).
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# --- Screenshots ------------------------------------------------------------
defaults write com.apple.screencapture location -string "$HOME/Documents"

# --- Apply ------------------------------------------------------------------
# Dock and Finder only re-read their prefs on restart. AppleInterfaceStyle needs
# a logout (or an SP restart) to take effect everywhere, so it may look unapplied
# until the next login.
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo "[*] macOS defaults applied. Log out and back in for appearance changes."
