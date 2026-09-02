-- osd.lua — a themed on-screen display for volume / brightness / mute / caps,
-- standing in for macOS's own HUD (SwayOSD in Omarchy terms).
--
-- The media keys are consumed and re-implemented so the stock HUD never shows;
-- brightness keys on an external display (where hs.brightness can't help) are
-- left alone. Panel is bottom-centre, sharp, accent-coloured, auto-hides.
--
--   require("osd").start()      -- wired from init.lua
--   require("osd").stop()

local ui = require("ui")

local M = {}
local STEP = 100 / 16        -- one keypress ≈ 6.25%, like a 16-notch keyboard
local W, H  = 340, 66
local HIDE  = 1.1

local canvas, hideTimer, keyTap, capsTap
local et = hs.eventtap.event.types

local GLYPH = {
  vol  = "\u{f028}", low = "\u{f027}", mute = "\u{f026}",
  bright = "\u{f185}", caps = "\u{f023}",
}

local function output() return hs.audiodevice.defaultOutputDevice() end

local function show(glyph, label, frac)
  local c = ui.c()
  if not canvas then canvas = ui.centred(W, H, 0.86) end
  canvas:frame({ x = hs.screen.mainScreen():frame().x
    + (hs.screen.mainScreen():frame().w - W) / 2,
    y = hs.screen.mainScreen():frame().y
    + hs.screen.mainScreen():frame().h * 0.86, w = W, h = H })

  local els = ui.panel(W, H, c)
  els[#els + 1] = ui.txt(glyph, 20, c.accent,
    { frame = { x = 16, y = (H - 26) / 2, w = 28, h = 26 } })
  els[#els + 1] = ui.txt(label, 12, c.subtext,
    { frame = { x = 52, y = 10, w = W - 68, h = 15 }, textLineBreak = "truncateTail" })
  if frac then
    for _, e in ipairs(ui.meter(52, H - 22, W - 68, 6, frac, c)) do els[#els + 1] = e end
  end
  canvas:replaceElements(els)
  canvas:show(0.08)

  if hideTimer then hideTimer:stop() end
  hideTimer = hs.timer.doAfter(HIDE, function() if canvas then canvas:hide(0.25) end end)
end

local function showVolume()
  local d = output()
  local v = d and d:volume()
  local muted = d and d:muted()
  if not v then return false end        -- device has no software volume
  if muted then
    show(GLYPH.mute, "Muted", 0)
  else
    show(v > 45 and GLYPH.vol or GLYPH.low, ("Volume  %d%%"):format(math.floor(v + 0.5)), v / 100)
  end
  return true
end

local function nudgeVolume(delta)
  local d = output()
  local v = d and d:volume()
  if not v then return false end
  if delta > 0 and d:muted() then d:setMuted(false) end
  d:setVolume(math.max(0, math.min(100, v + delta)))
  -- setVolume is async-ish; read back a beat later for an accurate bar
  hs.timer.doAfter(0.03, showVolume)
  return true
end

local function toggleMute()
  local d = output()
  if not d or d:volume() == nil then return false end
  d:setMuted(not d:muted())
  hs.timer.doAfter(0.03, showVolume)
  return true
end

local function nudgeBrightness(delta)
  local b = hs.brightness.get()
  if not b or b < 0 then return false end        -- external display: let macOS do it
  local n = math.max(0, math.min(100, b + delta))
  hs.brightness.set(math.floor(n + 0.5))
  show(GLYPH.bright, ("Brightness  %d%%"):format(math.floor(n + 0.5)), n / 100)
  return true
end

local function handle(e)
  local k = e:systemKey()
  if not k or not (k.down or k.repeatKey) then return false end
  if k.key == "SOUND_UP"        then return nudgeVolume(STEP) end
  if k.key == "SOUND_DOWN"      then return nudgeVolume(-STEP) end
  if k.key == "MUTE"            then return not k.repeatKey and toggleMute() or true end
  if k.key == "BRIGHTNESS_UP"   then return nudgeBrightness(STEP) end
  if k.key == "BRIGHTNESS_DOWN" then return nudgeBrightness(-STEP) end
  return false
end

-- never let a bug here break the hardware keys: on error, pass the event through
local function onKey(e)
  local ok, consumed = pcall(handle, e)
  return ok and consumed or false
end

local capsWas
local function onCaps(e)
  local on = e:getFlags().capslock
  if on == capsWas then return false end
  capsWas = on
  show(GLYPH.caps, on and "Caps Lock  on" or "Caps Lock  off")
  return false
end

function M.start()
  M.stop()
  keyTap  = hs.eventtap.new({ et.systemDefined }, onKey)
  capsTap = hs.eventtap.new({ et.flagsChanged }, onCaps)
  keyTap:start(); capsTap:start()
  capsWas = hs.eventtap.checkKeyboardModifiers().capslock
end

function M.stop()
  if keyTap then keyTap:stop(); keyTap = nil end
  if capsTap then capsTap:stop(); capsTap = nil end
  if hideTimer then hideTimer:stop(); hideTimer = nil end
  if canvas then canvas:delete(); canvas = nil end
end

return M
