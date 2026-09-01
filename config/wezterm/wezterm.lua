-- ~/.config/wezterm/wezterm.lua
--
-- Deliberately minimal: AeroSpace tiles windows and tmux (prefix C-b, see
-- dotfiles/.tmux.conf) multiplexes panes/sessions inside them. WezTerm does
-- NOT get its own leader/split keybindings here -- a WezTerm leader on the
-- same chord would swallow tmux's prefix before tmux ever saw it. If wallust has been
-- run, it drops a generated palette at colors/wallust.toml; fall back to the
-- static Catppuccin Mocha scheme (matching borders/sketchybar) until then.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- NOTE: wezterm.color.load_scheme's exact signature hasn't been verified
-- against the installed WezTerm version yet -- check `wezterm show-config`
-- or the WezTerm changelog if this branch errors on startup.
local wallust_colors = wezterm.config_dir .. "/colors/wallust.toml"
local wallust_file = io.open(wallust_colors, "r")
if wallust_file then
  wallust_file:close()
  config.color_scheme = "wallust"
  config.color_schemes = {
    wallust = wezterm.color.load_scheme(wallust_colors),
  }
else
  config.color_scheme = "Catppuccin Mocha"
end

config.font = wezterm.font("Hack Nerd Font", { weight = "Regular" })
config.font_size = 13.5
config.window_background_opacity = 0.94
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

-- One pane per window is the norm here -- AeroSpace tiles windows, tmux
-- multiplexes inside them -- so keep tab/pane chrome out of the way.
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Non-conflicting keys only: nothing on C-b (tmux's prefix) or any alt-*
-- combo (AeroSpace's global modifier, which never reaches WezTerm anyway).
config.keys = {
  { key = "=", mods = "CMD", action = wezterm.action.IncreaseFontSize },
  { key = "-", mods = "CMD", action = wezterm.action.DecreaseFontSize },
  { key = "n", mods = "CMD", action = wezterm.action.SpawnWindow },
}

return config
