-- whichkey.lua — hold Option (alt) for ~0.4s with nothing else pressed and a
-- cheatsheet fades in: the AeroSpace alt-bindings (parsed live from
-- aerospace.toml) plus the Hammerspoon global keys registered from init.lua.
-- Release Option, or press any key, to dismiss. The live counterpart to the
-- Opt+Space -> Shortcuts submenu.
--
--   require("whichkey").register("⌃⌥ Space", "Cycle theme")
--   require("whichkey").start()

local ui = require("ui")

local M = {}
local HOME = os.getenv("HOME")
local et   = hs.eventtap.event.types

local registered = {}          -- { {chord, desc}, ... } from init.lua
local canvas, flagsTap, keyTap, armTimer, armed, sawKey

-- ── parse alt- bindings from aerospace.toml ────────────────────────────────
local DESC = {
  ["layout tiles horizontal vertical"] = "Tile layout",
  ["layout accordion horizontal vertical"] = "Accordion layout",
  ["layout floating tiling"] = "Float / tile",
  ["macos-native-fullscreen"] = "Fullscreen",
  ["focus left"] = "Focus ←", ["focus down"] = "Focus ↓",
  ["focus up"] = "Focus ↑", ["focus right"] = "Focus →",
  ["move left"] = "Move ←", ["move down"] = "Move ↓",
  ["move up"] = "Move ↑", ["move right"] = "Move →",
  ["resize smart -50"] = "Shrink", ["resize smart +50"] = "Grow",
  ["mode resize"] = "Resize mode", ["mode service"] = "Service mode",
  ["workspace-back-and-forth"] = "Last workspace",
  ["move-workspace-to-monitor --wrap-around next"] = "Move to next monitor",
  ["close"] = "Close window",
}
local SYM = { alt = "⌥", cmd = "⌘", ctrl = "⌃", shift = "⇧" }

local function fmtChord(k)
  local mods, key = {}, ""
  for p in k:gmatch("[^-]+") do
    if SYM[p] then mods[#mods + 1] = SYM[p] else key = p end
  end
  key = ({ slash = "/", minus = "−", equal = "=", comma = ",", tab = "⇥",
           enter = "⏎", semicolon = ";", space = "Space" })[key] or key:upper()
  return table.concat(mods) .. " " .. key
end

local function describe(cmd)
  if DESC[cmd] then return DESC[cmd] end
  local w = cmd:match("^workspace (.+)$");                 if w then return "→ " .. w end
  local m = cmd:match("^move%-node%-to%-workspace (.+)$"); if m then return "Send → " .. m end
  if cmd:find("new window") then return "New terminal" end
  return (cmd:gsub("%-", " "):gsub("^%l", string.upper))
end

local function aeroBindings()
  local out, inMain = {}, false
  local f = io.open(HOME .. "/.config/aerospace/aerospace.toml", "r")
  if not f then return out end
  for line in f:lines() do
    local hdr = line:match("^%s*%[(.-)%]")
    if hdr then inMain = (hdr == "mode.main.binding") end
    if inMain then
      local k, v = line:match("^%s*(alt%-[%w%-]+)%s*=%s*(.+)$")
      if k and v then
        local cmd = v:match("^'([^']*)'") or v:match("^%[%s*'([^']*)'")
        if cmd and not k:match("^alt%-shift%-[1-5]$") then
          out[#out + 1] = { fmtChord(k), describe(cmd) }
        end
      end
    end
  end
  f:close()
  return out
end

-- ── draw ───────────────────────────────────────────────────────────────────
local function draw()
  local c = ui.c()
  local left  = registered
  local right = aeroBindings()
  local rows  = math.max(#left, #right, 1)
  local COLW, ROWH, PAD, HEAD = 260, 20, 22, 34
  local W = COLW * 2 + PAD * 3
  local H = HEAD + rows * ROWH + PAD

  canvas = canvas or ui.centred(W, H, 0.5)
  canvas:frame({
    x = hs.screen.mainScreen():frame().x + (hs.screen.mainScreen():frame().w - W) / 2,
    y = hs.screen.mainScreen():frame().y + (hs.screen.mainScreen():frame().h - H) / 2,
    w = W, h = H,
  })
  local els = ui.panel(W, H, c)
  els[#els + 1] = ui.txt("Hammerspoon", 10, c.overlay, { frame = { x = PAD, y = 12, w = COLW, h = 12 } })
  els[#els + 1] = ui.txt("AeroSpace", 10, c.overlay, { frame = { x = PAD * 2 + COLW, y = 12, w = COLW, h = 12 } })

  local function column(list, x0)
    for i, b in ipairs(list) do
      local y = HEAD + (i - 1) * ROWH
      els[#els + 1] = ui.txt(b[1], 12, c.accent,
        { frame = { x = x0, y = y, w = 96, h = 15 } })
      els[#els + 1] = ui.txt(b[2], 12, c.text,
        { frame = { x = x0 + 100, y = y, w = COLW - 100, h = 15 }, textLineBreak = "truncateTail" })
    end
  end
  column(left, PAD)
  column(right, PAD * 2 + COLW)
  canvas:replaceElements(els)
  canvas:show(0.1)
end

function M.show() if not canvas or not canvas:isShowing() then draw() end end
function M.hide()
  if armTimer then armTimer:stop(); armTimer = nil end
  if canvas then canvas:hide(0.12) end
  if keyTap then keyTap:stop() end
  armed = false
end

function M.register(chord, desc) registered[#registered + 1] = { chord, desc } end

-- ── hold detection ─────────────────────────────────────────────────────────
local function onFlags(e)
  local f = e:getFlags()
  local onlyAlt = f.alt and not (f.cmd or f.ctrl or f.shift)
  if onlyAlt and not armed then
    armed, sawKey = true, false
    keyTap:start()
    armTimer = hs.timer.doAfter(0.4, function() if armed and not sawKey then M.show() end end)
  elseif not onlyAlt and armed then
    M.hide()
  end
  return false
end

local function onKey()
  sawKey = true
  M.hide()
  return false
end

function M.start()
  M.stop()
  flagsTap = hs.eventtap.new({ et.flagsChanged }, onFlags)
  keyTap   = hs.eventtap.new({ et.keyDown }, onKey)
  flagsTap:start()
end

function M.stop()
  if flagsTap then flagsTap:stop(); flagsTap = nil end
  if keyTap then keyTap:stop(); keyTap = nil end
  if canvas then canvas:delete(); canvas = nil end
end

return M
