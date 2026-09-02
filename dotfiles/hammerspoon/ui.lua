-- ui.lua — shared look for every Hammerspoon panel (OSD, which-key, clipboard).
--
-- Matches menu.lua's Omarchy styling: sharp corners, 2px accent border,
-- Hack Nerd Font Mono, colours pulled live from theme.lua so a theme switch
-- restyles these panels too.

local theme = require("theme")

local M = {}
M.FONT = "Hack Nerd Font Mono"

function M.c() return theme.current() end

function M.txt(str, size, hex, opts)
  local e = {
    type = "text", text = str, textFont = M.FONT,
    textSize = size, textColor = { hex = hex },
  }
  for k, v in pairs(opts or {}) do e[k] = v end
  return e
end

-- sharp panel: opaque-ish fill + 2px accent stroke inset by 1px
function M.panel(w, h, c)
  c = c or M.c()
  return {
    { type = "rectangle", action = "fill", fillColor = { hex = c.base, alpha = 0.97 } },
    {
      type = "rectangle", action = "stroke",
      strokeColor = { hex = c.accent }, strokeWidth = 2,
      frame = { x = 1, y = 1, w = w - 2, h = h - 2 },
    },
  }
end

-- a horizontal progress bar (used by the OSD): track + fill, 0..1
function M.meter(x, y, w, h, frac, c)
  c = c or M.c()
  frac = math.max(0, math.min(1, frac))
  return {
    {
      type = "rectangle", action = "fill", fillColor = { hex = c.surface },
      frame = { x = x, y = y, w = w, h = h },
    },
    {
      type = "rectangle", action = "fill", fillColor = { hex = c.accent },
      frame = { x = x, y = y, w = math.max(h, w * frac), h = h },
    },
  }
end

-- centred canvas on the main screen at a vertical fraction (0 = top, 1 = bottom)
function M.centred(w, h, vfrac)
  local f = hs.screen.mainScreen():frame()
  local cv = hs.canvas.new({
    x = f.x + (f.w - w) / 2,
    y = f.y + (f.h - h) * (vfrac or 0.5),
    w = w, h = h,
  })
  cv:level(hs.canvas.windowLevels.overlay)
  cv:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
  return cv
end

return M
