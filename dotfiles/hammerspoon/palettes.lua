-- palettes.lua — the theme catalogue for the Omachy setup.
--
-- One table per theme. `theme.lua` reads this, converts the hex values into
-- whatever each target wants (SketchyBar `0xAARRGGBB`, JankyBorders `glow(...)`,
-- Ghostty / bat / starship / nvim theme *names*) and applies the lot.
--
-- To add a theme: copy a block, fill in the eight semantic colours + the four
-- meter colours, and point `ghostty` / `bat` / `starship` / `nvim` at a theme
-- that ships with each tool (see the notes by each field). `starship` must name
-- a `[palettes.*]` block in config/starship.toml — add one if it's missing.
--
--   base     window / bar background        red     \
--   mantle   slightly darker (islands)      green    |  meter + diagnostic
--   crust    darkest       (borders bg)     yellow   |  colours, nothing else
--   surface  inactive border, pill fill     blue    /
--   overlay  dim text, hairlines
--   subtext  secondary text
--   text     primary text
--   accent   the ONE accent — border glow, active pill, selection, OSD bar

return {
  {
    name = "catppuccin-mocha", label = "Catppuccin Mocha", dark = true,
    base = "#1e1e2e", mantle = "#181825", crust = "#11111b",
    surface = "#313244", overlay = "#6c7086", subtext = "#a6adc8", text = "#cdd6f4",
    accent = "#cba6f7",
    red = "#f38ba8", green = "#a6e3a1", yellow = "#f9e2af", blue = "#89b4fa",
    ghostty = "Catppuccin Mocha", bat = "Catppuccin Mocha",
    starship = "catppuccin_mocha", nvim = "catppuccin-mocha",
    wallpaper = "dominik-mayer-18.png",
  },
  {
    name = "catppuccin-latte", label = "Catppuccin Latte", dark = false,
    base = "#eff1f5", mantle = "#e6e9ef", crust = "#dce0e8",
    surface = "#ccd0da", overlay = "#9ca0b0", subtext = "#6c6f85", text = "#4c4f69",
    accent = "#8839ef",
    red = "#d20f39", green = "#40a02b", yellow = "#df8e1d", blue = "#1e66f5",
    ghostty = "Catppuccin Latte", bat = "Catppuccin Latte",
    starship = "catppuccin_latte", nvim = "catppuccin-latte",
    wallpaper = "laundry.jpg",
  },
  {
    name = "tokyo-night", label = "Tokyo Night", dark = true,
    base = "#1a1b26", mantle = "#16161e", crust = "#13131a",
    surface = "#292e42", overlay = "#565f89", subtext = "#a9b1d6", text = "#c0caf5",
    accent = "#7aa2f7",
    red = "#f7768e", green = "#9ece6a", yellow = "#e0af68", blue = "#7aa2f7",
    ghostty = "TokyoNight Night", bat = "base16",
    starship = "tokyo_night", nvim = "tokyonight-night",
    wallpaper = "city-horizon.jpg",
  },
  {
    name = "everforest", label = "Everforest Dark", dark = true,
    base = "#272e33", mantle = "#232a2e", crust = "#1e2326",
    surface = "#2e383c", overlay = "#859289", subtext = "#9da9a0", text = "#d3c6aa",
    accent = "#a7c080",
    red = "#e67e80", green = "#a7c080", yellow = "#dbbc7f", blue = "#7fbbb3",
    ghostty = "Everforest Dark Hard", bat = "base16",
    starship = "everforest", nvim = "everforest",
    wallpaper = "grandfather-tree.jpg",
  },
  {
    name = "gruvbox", label = "Gruvbox Dark", dark = true,
    base = "#282828", mantle = "#1d2021", crust = "#1d2021",
    surface = "#3c3836", overlay = "#928374", subtext = "#a89984", text = "#ebdbb2",
    accent = "#fabd2f",
    red = "#fb4934", green = "#b8bb26", yellow = "#fabd2f", blue = "#83a598",
    ghostty = "Gruvbox Dark", bat = "gruvbox-dark",
    starship = "gruvbox", nvim = "gruvbox",
    wallpaper = "railroad-2.jpg",
  },
  {
    name = "nord", label = "Nord", dark = true,
    base = "#2e3440", mantle = "#2a2f3a", crust = "#242933",
    surface = "#3b4252", overlay = "#4c566a", subtext = "#d8dee9", text = "#eceff4",
    accent = "#88c0d0",
    red = "#bf616a", green = "#a3be8c", yellow = "#ebcb8b", blue = "#81a1c1",
    ghostty = "Nord", bat = "Nord",
    starship = "nord", nvim = "nord",
    wallpaper = "clouds-3.png",
  },
  {
    name = "rose-pine", label = "Rosé Pine", dark = true,
    base = "#191724", mantle = "#1f1d2e", crust = "#16141f",
    surface = "#26233a", overlay = "#6e6a86", subtext = "#908caa", text = "#e0def4",
    accent = "#c4a7e7",
    red = "#eb6f92", green = "#9ccfd8", yellow = "#f6c177", blue = "#31748f",
    ghostty = "Rose Pine", bat = "base16",
    starship = "rose_pine", nvim = "rose-pine",
    wallpaper = "koi.jpg",
  },
  {
    name = "kanagawa", label = "Kanagawa Wave", dark = true,
    base = "#1f1f28", mantle = "#16161d", crust = "#16161d",
    surface = "#2a2a37", overlay = "#727169", subtext = "#a6a69c", text = "#dcd7ba",
    accent = "#7e9cd8",
    red = "#e82424", green = "#98bb6c", yellow = "#e6c384", blue = "#7e9cd8",
    ghostty = "Kanagawa Wave", bat = "base16",
    starship = "kanagawa", nvim = "kanagawa-wave",
    wallpaper = "aesthetic.jpg",
  },
}
