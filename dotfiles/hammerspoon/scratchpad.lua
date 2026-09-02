-- scratchpad.lua — a Quake-style drop-down Ghostty on Ctrl+` .
--
-- One dedicated Ghostty instance, title locked to "scratchpad" (Ghostty's
-- --title ignores escape sequences). AeroSpace floats it by title rule (see
-- aerospace.toml). Hidden = minimized: macOS won't let a window sit above the
-- menu bar, AeroSpace re-unhides app:hide()'d apps, and its --window-id doesn't
-- match Hammerspoon's — minimize is the one thing that Just Works, and
-- AeroSpace leaves minimized windows alone.
--
--   require("scratchpad").bind({ "ctrl" }, "`")

local M = {}
local HOME  = os.getenv("HOME")
local TITLE = "scratchpad"
local DROP  = 0.46               -- fraction of screen height
local ANIM  = 0.16

local lastSpawn = 0

local function findWin()
  for _, app in ipairs(hs.application.applicationsForBundleID("com.mitchellh.ghostty")) do
    for _, w in ipairs(app:allWindows()) do
      if (w:title() or ""):lower():find(TITLE, 1, true) then return w end
    end
  end
end

local function onFrame()
  local scr = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  local f, gap = scr:frame(), 8
  return { x = f.x + gap, y = f.y + gap, w = f.w - gap * 2, h = math.floor(f.h * DROP) }
end

local function place(w, animate)
  local on = onFrame()
  if animate then
    w:setFrame({ x = on.x, y = on.y - 24, w = on.w, h = on.h }, 0)
    local prev = hs.window.animationDuration
    hs.window.animationDuration = ANIM
    w:setFrame(on)
    hs.window.animationDuration = prev
  else
    w:setFrame(on, 0)
  end
  w:raise(); w:focus()
  hs.timer.doAfter(0.3, function() if w:isVisible() and not w:isMinimized() then w:setFrame(on, 0) end end)
end

local function reveal(w)
  if w:isMinimized() then
    w:unminimize()
    hs.timer.doAfter(0.05, function() place(w, true) end)
  else
    place(w, false)
  end
end

local function spawn()
  local now = hs.timer.secondsSinceEpoch()
  if now - lastSpawn < 6 then return end        -- debounce double-fires
  lastSpawn = now
  hs.task.new("/usr/bin/open", function() end,
    { "-na", "Ghostty", "--args", "--title=" .. TITLE, "--working-directory=" .. HOME }):start()
  local tries = 0
  local function grab()
    tries = tries + 1
    local w = findWin()
    if w then reveal(w)
    elseif tries < 40 then hs.timer.doAfter(0.1, grab) end
  end
  hs.timer.doAfter(0.3, grab)
end

function M.toggle()
  local w = findWin()
  if not w then spawn(); return end
  if w:isMinimized() then
    reveal(w)
  elseif w:application():isFrontmost() then
    w:minimize()
  else
    w:raise(); w:focus()                         -- shown but behind → surface it
  end
end

function M.bind(mods, key)
  return hs.hotkey.bind(mods, key, M.toggle)
end

return M
