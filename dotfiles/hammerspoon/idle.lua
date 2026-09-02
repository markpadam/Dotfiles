-- idle.lua — Hyprland's hypridle progression: dim the screen after a while,
-- lock a bit later. Any input restores brightness; "Keep awake" (toggles.lua)
-- suspends the whole thing.
--
--   require("idle").start()
--   require("idle").config({ dimAfter = 240, lockAfter = 480, dimLevel = 12 })

local M = {}
-- lockAfter = 0 disables auto-lock (leave it to macOS). Fullscreen windows and
-- "Keep awake" (toggles.lua) both inhibit the whole progression.
local cfg = { dimAfter = 300, lockAfter = 600, dimLevel = 12, poll = 15 }

local timer, wake
local dimmed, locked, savedBright = false, false, nil

local function idleSeconds(cb)
  if type(hs.host.idleTime) == "function" then cb(hs.host.idleTime()); return end
  hs.task.new("/usr/sbin/ioreg", function(_, out)
    local ns = tonumber((out or ""):match('"HIDIdleTime" = (%d+)'))
    cb(ns and ns / 1e9 or 0)
  end, { "-c", "IOHIDSystem" }):start()
end

local function restore()
  if savedBright then hs.brightness.set(math.floor(savedBright + 0.5)) end
  dimmed, locked, savedBright = false, false, nil
end

local function inhibited()
  local ok, toggles = pcall(require, "toggles")
  if ok and toggles.state().caffeine then return true end
  local w = hs.window.focusedWindow()
  return w ~= nil and w:isFullScreen()
end

local function tick()
  if inhibited() then return end
  idleSeconds(function(s)
    if s < 5 then
      if dimmed then restore() end
      return
    end
    if cfg.lockAfter > 0 and s >= cfg.lockAfter and not locked then
      locked = true
      hs.caffeinate.lockScreen()
    elseif s >= cfg.dimAfter and not dimmed then
      local b = hs.brightness.get()
      if b and b > cfg.dimLevel then
        savedBright = b
        hs.brightness.set(cfg.dimLevel)
      end
      dimmed = true
    end
  end)
end

function M.config(t) for k, v in pairs(t or {}) do cfg[k] = v end end

function M.start()
  M.stop()
  timer = hs.timer.new(cfg.poll, tick, true):start()
  wake = hs.caffeinate.watcher.new(function(ev)
    if ev == hs.caffeinate.watcher.screensDidWake
      or ev == hs.caffeinate.watcher.screensDidUnlock then restore() end
  end)
  wake:start()
end

function M.stop()
  if timer then timer:stop(); timer = nil end
  if wake then wake:stop(); wake = nil end
end

return M
