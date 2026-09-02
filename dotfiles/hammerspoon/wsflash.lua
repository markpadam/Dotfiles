-- wsflash.lua — reacts to an AeroSpace workspace switch:
--   • a brief centre overlay with the workspace name (Hyprland-style)
--   • a per-workspace wallpaper from ~/Pictures/Wallpapers
-- AeroSpace's exec-on-workspace-change writes the name to
-- ~/.cache/omachy/workspace; we pathwatch that file.
--
--   require("wsflash").start()
--
-- Per-workspace wallpaper: each workspace gets a fixed image from
-- ~/Pictures/Wallpapers (by name hash, so it's stable), or set M.wallpaperMap
-- = { coding = "koi.jpg", … } to pin specific ones. Turn OFF macOS's own
-- wallpaper auto-rotate or it'll cycle out from under this. M.wallpaper = false
-- to disable.

local ui    = require("ui")
local theme = require("theme")

local M = {}
M.wallpaper     = true
M.wallpaperMap  = {}      -- { <workspace> = "<file in ~/Pictures/Wallpapers>" }

local HOME = os.getenv("HOME")
local FILE = HOME .. "/.cache/omachy/workspace"
local WPDIR = HOME .. "/Pictures/Wallpapers"

local GLYPH = {
  desktop  = "\u{f108}", terminal = "\u{f120}", browser = "\u{f0ac}",
  comms    = "\u{f086}", coding   = "\u{f121}",
}

local canvas, watcher, hideTimer, last, wpList

-- ── per-workspace wallpaper ───────────────────────────────────────────────
local function wallpapers()
  if wpList then return wpList end
  wpList = {}
  local ok, iter, d = pcall(hs.fs.dir, WPDIR)
  if ok then
    for f in iter, d do
      if f:match("%.[jJ][pP][eE]?[gG]$") or f:match("%.[pP][nN][gG]$") or f:match("%.[hH][eE][iI][cC]$") then
        wpList[#wpList + 1] = WPDIR .. "/" .. f
      end
    end
  end
  table.sort(wpList)
  return wpList
end

local function wallpaperFor(name)
  local m = M.wallpaperMap[name]
  if m then return WPDIR .. "/" .. m end
  local list = wallpapers()
  if #list == 0 then return nil end
  local h = 5381
  for i = 1, #name do h = (h * 33 + name:byte(i)) % 2147483647 end
  return list[(h % #list) + 1]
end

local function setWallpaper(name)
  if not M.wallpaper then return end
  local p = wallpaperFor(name)
  if p and hs.fs.attributes(p) then
    hs.osascript.applescript(
      ('tell application "System Events" to tell every desktop to set picture to %q'):format(p))
  end
end

local function flash(name)
  local c = theme.current()
  local W, H = 260, 116
  canvas = canvas or ui.centred(W, H, 0.42)
  local scr = hs.screen.mainScreen():frame()
  canvas:frame({ x = scr.x + (scr.w - W) / 2, y = scr.y + (scr.h - H) * 0.42, w = W, h = H })

  local els = {
    { type = "rectangle", action = "fill", fillColor = { hex = c.base, alpha = 0.96 },
      roundedRectRadii = { xRadius = 12, yRadius = 12 } },
    { type = "rectangle", action = "stroke", strokeColor = { hex = c.accent }, strokeWidth = 2,
      roundedRectRadii = { xRadius = 12, yRadius = 12 }, frame = { x = 1, y = 1, w = W - 2, h = H - 2 } },
    ui.txt(GLYPH[name] or "\u{f2d0}", 40, c.accent,
      { frame = { x = 0, y = 20, w = W, h = 44 }, textAlignment = "center" }),
    ui.txt(name:gsub("^%l", string.upper), 17, c.text,
      { frame = { x = 0, y = 70, w = W, h = 22 }, textAlignment = "center" }),
  }
  canvas:replaceElements(els)
  canvas:show(0.08)
  if hideTimer then hideTimer:stop() end
  hideTimer = hs.timer.doAfter(0.75, function() if canvas then canvas:hide(0.25) end end)
end

local function onChange()
  local f = io.open(FILE, "r"); if not f then return end
  local name = (f:read("*l") or ""):gsub("%s+", ""); f:close()
  if name ~= "" and name ~= last then
    last = name
    flash(name)
    setWallpaper(name)
  end
end

function M.start()
  M.stop()
  hs.execute(("mkdir -p %q"):format(HOME .. "/.cache/omachy"))
  local f = io.open(FILE, "r")           -- seed `last` so we don't flash on load
  if f then last = (f:read("*l") or ""):gsub("%s+", ""); f:close() end
  watcher = hs.pathwatcher.new(FILE, onChange)
  watcher:start()
end

function M.stop()
  if watcher then watcher:stop(); watcher = nil end
  if hideTimer then hideTimer:stop(); hideTimer = nil end
  if canvas then canvas:delete(); canvas = nil end
end

return M
