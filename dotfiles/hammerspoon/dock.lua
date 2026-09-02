-- dock.lua — a themed dock, since the macOS one can't be re-coloured.
--
-- An hs.canvas strip on the left edge (matching the `orientation left` the
-- native Dock was set to): pinned apps + anything else running, each with a
-- running dot, click to launch or focus. Auto-hides; slide the mouse to the
-- left edge — or hold Ctrl — to bring it back. Colours come from theme.lua and
-- re-skin on a theme change. The native Dock is parked while this runs.
--
--   require("dock").start()
--   require("dock").edge = "bottom"   -- before start(), if you prefer

local theme = require("theme")

local M = {}
M.edge           = "left"      -- "left" | "bottom"
M.iconSize       = 48
M.hideNativeDock  = true
M.pinned = {
  "com.apple.finder",
  "com.apple.Safari",
  "com.mitchellh.ghostty",
  "com.microsoft.VSCode",
  "com.anthropic.claudefordesktop",
  "com.apple.mail",
  "net.whatsapp.WhatsApp",
  "com.apple.iCal",
  "com.apple.Notes",
  "com.apple.systempreferences",
}

local GAP, PAD, DOT, RADIUS, MARGIN = 8, 8, 5, 12, 6
local canvas, poll, appWatcher, screenWatcher, hideTimer
local flagsTap, ctrlKeyTap, ctrlArmTimer
local shown, list, iconCache, dockParked, ctrlHold

-- ── app list ──────────────────────────────────────────────────────────────
local function icon(bid)
  iconCache = iconCache or {}
  if iconCache[bid] == nil then iconCache[bid] = hs.image.imageFromAppBundle(bid) or false end
  return iconCache[bid] or nil
end

local function buildList()
  local out, seen = {}, {}
  for _, bid in ipairs(M.pinned) do
    out[#out + 1] = { bid = bid, pinned = true }
    seen[bid] = true
  end
  for _, app in ipairs(hs.application.runningApplications()) do
    local bid = app:bundleID()
    if bid and not seen[bid] and app:kind() == 1 then
      seen[bid] = true
      out[#out + 1] = { bid = bid, pinned = false }
    end
  end
  for _, e in ipairs(out) do
    e.running = hs.application.applicationsForBundleID(e.bid)[1] ~= nil
  end
  list = out
  return out
end

-- ── geometry ──────────────────────────────────────────────────────────────
local function frameFor(n)
  local scr = hs.screen.primaryScreen():frame()
  local S = M.iconSize
  if M.edge == "bottom" then
    local w = n * S + (n - 1) * GAP + 2 * PAD
    local h = S + 2 * PAD
    return { x = scr.x + (scr.w - w) / 2, y = scr.y + scr.h - h - MARGIN, w = w, h = h }, false
  else
    local w = S + 2 * PAD
    local h = n * S + (n - 1) * GAP + 2 * PAD
    return { x = scr.x + MARGIN, y = scr.y + (scr.h - h) / 2, w = w, h = h }, true
  end
end

-- ── draw ──────────────────────────────────────────────────────────────────
local function draw()
  local c = theme.current()
  buildList()
  local f, vertical = frameFor(#list)
  if not canvas then
    canvas = hs.canvas.new(f)
    canvas:level(hs.canvas.windowLevels.floating)
    canvas:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
    canvas:clickActivating(false)
    canvas:canvasMouseEvents(true, true, false, false)
    canvas:mouseCallback(function(_, msg, id)
      if msg == "mouseUp" and type(id) == "string" then
        local i = tonumber(id:match("^app(%d+)$"))
        if i and list[i] then hs.application.launchOrFocusByBundleID(list[i].bid) end
      end
    end)
  end
  canvas:frame(f)

  local rr = { xRadius = RADIUS, yRadius = RADIUS }
  local els = {
    { type = "rectangle", action = "fill", fillColor = { hex = c.mantle, alpha = 0.95 },
      roundedRectRadii = rr },
    { type = "rectangle", action = "stroke", strokeColor = { hex = c.accent }, strokeWidth = 2,
      roundedRectRadii = rr, frame = { x = 1, y = 1, w = f.w - 2, h = f.h - 2 } },
  }
  for i, e in ipairs(list) do
    local ix = vertical and PAD or (PAD + (i - 1) * (M.iconSize + GAP))
    local iy = vertical and (PAD + (i - 1) * (M.iconSize + GAP)) or PAD
    local img = icon(e.bid)
    if img then
      els[#els + 1] = {
        type = "image", image = img, imageScaling = "scaleProportionally",
        frame = { x = ix, y = iy, w = M.iconSize, h = M.iconSize },
        trackMouseUp = true, id = "app" .. i,
      }
    end
    if e.running then
      local cx = vertical and (f.w - DOT) or (ix + M.iconSize / 2)
      local cy = vertical and (iy + M.iconSize / 2) or (f.h - DOT)
      els[#els + 1] = {
        type = "circle", action = "fill", fillColor = { hex = c.accent },
        center = { x = cx, y = cy }, radius = DOT / 2,
      }
    end
  end
  canvas:replaceElements(els)
end

-- ── show / hide ───────────────────────────────────────────────────────────
function M.reveal()
  if hideTimer then hideTimer:stop(); hideTimer = nil end
  if shown then return end
  draw()
  canvas:show(0.12)
  shown = true
end

function M.hide()
  if not shown then return end
  if canvas then canvas:hide(0.15) end
  shown = false
end

local function scheduleHide()
  if hideTimer or not shown then return end
  hideTimer = hs.timer.doAfter(0.4, function() hideTimer = nil; M.hide() end)
end

local function tick()
  local m = hs.mouse.absolutePosition()
  local f = frameFor(#(list or buildList()))
  local pad = 24
  local nearEdge
  if M.edge == "bottom" then
    nearEdge = m.y >= f.y + f.h - 1 and m.x >= f.x - pad and m.x <= f.x + f.w + pad
  else
    nearEdge = m.x <= 2 and m.y >= f.y - pad and m.y <= f.y + f.h + pad
  end
  local overPanel = shown and m.x >= f.x - 4 and m.x <= f.x + f.w + 4
    and m.y >= f.y - 4 and m.y <= f.y + f.h + 4
  if (nearEdge or overPanel or ctrlHold) then M.reveal()
  elseif shown then scheduleHide() end
end

-- ── hold Ctrl to show ─────────────────────────────────────────────────────
-- A key pressed within the arm window is "Ctrl + <key>", so cancel.
local function onCtrlKey()
  if ctrlArmTimer then ctrlArmTimer:stop(); ctrlArmTimer = nil end
  if ctrlKeyTap then ctrlKeyTap:stop() end
  return false
end

local function onFlags(e)
  local f = e:getFlags()
  local onlyCtrl = f.ctrl and not (f.cmd or f.alt or f.shift)
  if onlyCtrl then
    if not ctrlHold and not ctrlArmTimer then
      ctrlKeyTap:start()
      ctrlArmTimer = hs.timer.doAfter(0.3, function()
        ctrlArmTimer = nil
        if ctrlKeyTap then ctrlKeyTap:stop() end
        if hs.eventtap.checkKeyboardModifiers().ctrl then
          ctrlHold = true
          M.reveal()
        end
      end)
    end
  else
    if ctrlArmTimer then ctrlArmTimer:stop(); ctrlArmTimer = nil end
    if ctrlKeyTap then ctrlKeyTap:stop() end
    if ctrlHold then ctrlHold = false; scheduleHide() end
  end
  return false
end

-- ── native Dock ───────────────────────────────────────────────────────────
local function parkNativeDock(park)
  if park and not dockParked then
    dockParked = true
    hs.execute("defaults write com.apple.dock autohide-delay -float 1000 && killall Dock", true)
  elseif not park and dockParked then
    dockParked = false
    hs.execute("defaults delete com.apple.dock autohide-delay; killall Dock", true)
  end
end

-- ── lifecycle ─────────────────────────────────────────────────────────────
function M.start()
  M.stop()
  if M.hideNativeDock then
    parkNativeDock(true)
    -- put the native Dock back if Hammerspoon quits (also fires on reload —
    -- a brief Dock flash, then the fresh load re-parks it)
    local prev = hs.shutdownCallback
    hs.shutdownCallback = function()
      parkNativeDock(false)
      if prev then pcall(prev) end
    end
  end
  buildList()
  theme.onChange(function() if shown then draw() end end)

  local redraw = hs.timer.delayed.new(0.5, function() if shown then draw() end end)
  appWatcher = hs.application.watcher.new(function(_, ev)
    if ev == hs.application.watcher.launched or ev == hs.application.watcher.terminated then
      redraw:start()
    end
  end)
  appWatcher:start()

  screenWatcher = hs.screen.watcher.new(function() if shown then draw() end end)
  screenWatcher:start()

  flagsTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, onFlags)
  ctrlKeyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, onCtrlKey)
  flagsTap:start()

  poll = hs.timer.new(0.2, tick, true):start()
end

function M.stop()
  for _, t in ipairs({ poll, flagsTap, ctrlKeyTap }) do if t then t:stop() end end
  if appWatcher then appWatcher:stop(); appWatcher = nil end
  if screenWatcher then screenWatcher:stop(); screenWatcher = nil end
  if hideTimer then hideTimer:stop(); hideTimer = nil end
  if ctrlArmTimer then ctrlArmTimer:stop(); ctrlArmTimer = nil end
  poll, flagsTap, ctrlKeyTap = nil, nil, nil
  if canvas then canvas:delete(); canvas = nil end
  shown, ctrlHold = false, false
  parkNativeDock(false)
end

return M
