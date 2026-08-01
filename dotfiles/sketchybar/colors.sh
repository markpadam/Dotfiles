#!/usr/bin/env bash
# Catppuccin Mocha. Matches ../borders/bordersrc.
# Format is 0xAARRGGBB — leading byte is alpha.

export ROSEWATER=0xfff5e0dc
export FLAMINGO=0xfff2cdcd
export PINK=0xfff5c2e7
export MAUVE=0xffcba6f7
export RED=0xfff38ba8
export MAROON=0xffeba0ac
export PEACH=0xfffab387
export YELLOW=0xfff9e2af
export GREEN=0xffa6e3a1
export TEAL=0xff94e2d5
export SKY=0xff89dceb
export SAPPHIRE=0xff74c7ec
export BLUE=0xff89b4fa
export LAVENDER=0xffb4befe

export TEXT=0xffcdd6f4
export SUBTEXT1=0xffbac2de
export SUBTEXT0=0xffa6adc8
export OVERLAY2=0xff9399b2
export OVERLAY1=0xff7f849c
export OVERLAY0=0xff6c7086
export SURFACE2=0xff585b70
export SURFACE1=0xff45475a
export SURFACE0=0xff313244
export BASE=0xff1e1e2e
export MANTLE=0xff181825
export CRUST=0xff11111b

export TRANSPARENT=0x00000000

# --- Semantic roles -----------------------------------------------------
# The bar itself is invisible; each bracket paints its own island.
export BAR_COLOR=$TRANSPARENT
export ISLAND_COLOR=0xf0313244    # surface0 @ ~94% — slight see-through
export ISLAND_BORDER=0xff45475a   # surface1
export ITEM_COLOR=$TEXT
export ACCENT_SPACES=$MAUVE
export ACCENT_APP=$BLUE
export ACCENT_SYSTEM=$TEAL
export ACCENT_CLOCK=$PEACH
