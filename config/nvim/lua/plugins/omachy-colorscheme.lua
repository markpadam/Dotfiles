-- omachy-colorscheme.lua — Neovim's half of the desktop theme switcher.
--
-- The Hammerspoon switcher (dotfiles/hammerspoon/theme.lua) writes a colorscheme
-- name to ~/.config/nvim/omachy-theme.txt; this reads it and points LazyVim at
-- it. lazy.nvim lazy-loads whichever colour plugin provides that scheme, so
-- carrying all of them here is cheap. Restart nvim (or `:colorscheme <name>`)
-- after switching themes.

local function scheme()
  local f = io.open(vim.fn.expand("~/.config/nvim/omachy-theme.txt"), "r")
  if not f then return "tokyonight" end
  local s = (f:read("*l") or ""):gsub("%s+", "")
  f:close()
  return s ~= "" and s or "tokyonight"
end

return {
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "folke/tokyonight.nvim", lazy = true },
  { "sainnhe/everforest", lazy = true, init = function() vim.g.everforest_background = "hard" end },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "gbprod/nord.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },

  { "LazyVim/LazyVim", opts = { colorscheme = scheme() } },
}
