#!/usr/bin/env bash
# Nerd Font glyphs (Hack Nerd Font).
#
# Written as $'\xNN' UTF-8 escapes rather than literal characters: these are
# private-use-area codepoints, and plenty of tooling silently drops them when
# rewriting a file. Escapes are plain ASCII, so they always survive.

export ICON_DESKTOP=$'\xef\x84\x88'           # U+F108 desktop (show desktop)

export ICON_CPU=$'\xef\x8b\x9b'               # U+F2DB microchip
export ICON_MEMORY=$'\xf3\xb0\x8d\x9b'        # U+F035B md-memory (FA5 U+F538 is absent from Hack Nerd Font)
export ICON_WIFI=$'\xef\x87\xab'              # U+F1EB wifi
export ICON_WIFI_OFF=$'\xef\x81\x9e'          # U+F05E ban
export ICON_ETHERNET=$'\xef\x82\xac'          # U+F0AC globe

export ICON_VOLUME_HIGH=$'\xef\x80\xa8'       # U+F028 volume-up
export ICON_VOLUME_MID=$'\xef\x80\xa7'        # U+F027 volume-down
export ICON_VOLUME_LOW=$'\xef\x80\xa6'        # U+F026 volume-off

export ICON_BRIGHTNESS=$'\xef\x86\x85'        # U+F185 sun
export ICON_BRIGHTNESS_LOW=$'\xef\x86\x86'    # U+F186 moon

export ICON_BATTERY_100=$'\xef\x89\x80'       # U+F240 battery-full
export ICON_BATTERY_75=$'\xef\x89\x81'        # U+F241 battery-three-quarters
export ICON_BATTERY_50=$'\xef\x89\x82'        # U+F242 battery-half
export ICON_BATTERY_25=$'\xef\x89\x83'        # U+F243 battery-quarter
export ICON_BATTERY_0=$'\xef\x89\x84'         # U+F244 battery-empty
export ICON_BATTERY_CHARGING=$'\xef\x83\xa7'  # U+F0E7 bolt

export ICON_CLOCK=$'\xef\x80\x97'             # U+F017 clock
export ICON_CALENDAR=$'\xef\x84\xb3'          # U+F133 calendar
