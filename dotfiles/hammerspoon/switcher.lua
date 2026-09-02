-- switcher.lua — a themed Cmd+Tab, drawn to match the Opt+Space menu.
--
-- A vertical hs.canvas list (not hs.window.switcher — its styling can't be made
-- to match): the same panel, 2px accent border, rounded corners, Hack Nerd Font
-- Mono and accent-tinted selection as menu.lua. One row per app, MRU order,
-- real app icon + name. No thumbnails. (⌘` still cycles windows within an app.)
--
-- macOS reserves Cmd+Tab at the Carbon level, so a Karabiner rule remaps it to
-- Cmd+F18 / Cmd+F19 (Cmd still held) and this binds those. Hold Cmd, tap Tab to
-- advance (Shift+Tab / arrows to go back), release Cmd to focus, Esc to cancel.
-- See snapshots/karabiner/README.md.
--
--   require("switcher").start()

local theme = require("theme")

local M = {}
local et = hs.eventtap.event.types

-- geometry mirrors menu.lua (300 = the menu's default width)
local WIDTH, ROW_H, HEADER_H, PAD, BORDER_W, RADIUS, GLYPH_W = 300, 38, 40, 16, 2, 10, 26
local MAX_ROWS = 12
local FONT = "Hack Nerd Font Mono"

local wf, canvas, flagsTap, keyTap
local wins, sel, active, scroll, iconCache

-- ── windows ───────────────────────────────────────────────────────────────
local function ensureFilter()
  if wf then return end
  wf = hs.window.filter.new(nil)
    :setDefaultFilter({ allowRoles = "AXStandardWindow" })
    :setCurrentSpace(nil)
end

local function iconFor(w)
  iconCache = iconCache or {}
  local app = w:application()
  local bid = app and app:bundleID()
  if not bid then return nil end
  if iconCache[bid] == nil then iconCache[bid] = hs.image.imageFromAppBundle(bid) or false end
  return iconCache[bid] or nil
end

-- one entry per app, most-recently-used first; the stored window is that app's
-- MRU window, so focusing it raises the app on the window you last had.
local function refresh()
  local seen = {}
  wins = {}
  for _, w in ipairs(wf:getWindows(hs.window.filter.sortByFocused)) do
    local app = w:application()
    local bid = app and app:bundleID()
    if bid and not seen[bid] then
      seen[bid] = true
      wins[#wins + 1] = w
    end
  end
end

-- ── draw (matches menu.lua) ───────────────────────────────────────────────
local function txt(str, size, hex)
  return { type = "text", text = str, textFont = FONT, textSize = size,
           textColor = { hex = hex } }
end

local function draw()
  local c = theme.current()
  local n = math.min(#wins, MAX_ROWS)
  if sel <= scroll then scroll = sel - 1 end
  if sel > scroll + MAX_ROWS then scroll = sel - MAX_ROWS end
  if scroll < 0 then scroll = 0 end

  local h = HEADER_H + n * ROW_H + PAD
  local scr = hs.screen.mainScreen():frame()
  if not canvas then
    canvas = hs.canvas.new({ x = 0, y = 0, w = WIDTH, h = h })
    canvas:level(hs.canvas.windowLevels.popUpMenu)
    canvas:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
  end
  canvas:frame({
    x = scr.x + math.floor((scr.w - WIDTH) / 2),
    y = scr.y + math.floor(scr.h * 0.22),
    w = WIDTH, h = h,
  })

  local rr = { xRadius = RADIUS, yRadius = RADIUS }
  local els = {
    { type = "rectangle", action = "fill", fillColor = { hex = c.base, alpha = 0.96 }, roundedRectRadii = rr },
    { type = "rectangle", action = "stroke", strokeColor = { hex = c.accent }, strokeWidth = BORDER_W,
      roundedRectRadii = rr, frame = { x = 1, y = 1, w = WIDTH - 2, h = h - 2 } },
  }
  local p = txt(("App  %d/%d"):format(sel, #wins), 13, c.overlay)
  p.frame = { x = PAD, y = 13, w = WIDTH - 2 * PAD, h = 18 }
  els[#els + 1] = p
  els[#els + 1] = { type = "segments", strokeColor = { hex = c.overlay }, strokeWidth = 1,
    coordinates = { { x = PAD, y = HEADER_H - 2 }, { x = WIDTH - PAD, y = HEADER_H - 2 } } }

  for row = 1, n do
    local i = scroll + row
    local w = wins[i]
    if not w then break end
    local ry = HEADER_H + (row - 1) * ROW_H
    local on = (i == sel)
    if on then
      els[#els + 1] = { type = "rectangle", action = "fill",
        fillColor = { hex = c.accent, alpha = 0.15 },
        frame = { x = 4, y = ry, w = WIDTH - 8, h = ROW_H } }
    end
    local img = iconFor(w)
    if img then
      els[#els + 1] = { type = "image", image = img, imageScaling = "scaleProportionally",
        frame = { x = PAD, y = ry + (ROW_H - 18) / 2, w = 18, h = 18 } }
    end
    local app = w:application()
    local l = txt((app and app:name()) or "?", 14, on and c.accent or c.text)
    l.frame = { x = PAD + GLYPH_W, y = ry + (ROW_H - 18) / 2, w = WIDTH - PAD - GLYPH_W - PAD, h = 18 }
    l.textLineBreak = "truncateTail"
    els[#els + 1] = l
  end
  canvas:replaceElements(els)
  canvas:show()
end

-- ── lifecycle ─────────────────────────────────────────────────────────────
local function open(startAtEnd)
  refresh()
  if #wins < 2 then return end
  sel, scroll, active = startAtEnd and #wins or 2, 0, true
  draw()
  flagsTap:start(); keyTap:start()
end

local function close(focusSel)
  active = false
  flagsTap:stop(); keyTap:stop()
  if canvas then canvas:hide(0.06) end
  if focusSel and wins and wins[sel] then wins[sel]:focus() end
end

function M.next()
  if not active then open(false)
  else sel = sel % #wins + 1; draw() end
end

function M.previous()
  if not active then open(true)
  else sel = (sel - 2) % #wins + 1; draw() end
end

local function onFlags(e)
  if active and not e:getFlags().cmd then close(true) end
  return false
end

local function onKey(e)
  if not active then return false end
  local kc = e:getKeyCode()
  if kc == 53 then close(false); return true end          -- Esc
  if kc == 123 then M.previous(); return true end          -- ←
  if kc == 124 then M.next(); return true end              -- →
  return false
end

function M.start()
  M.stop()
  ensureFilter()
  refresh()
  theme.onChange(function() if active then draw() end end)
  flagsTap = hs.eventtap.new({ et.flagsChanged }, onFlags)
  keyTap   = hs.eventtap.new({ et.keyDown }, onKey)
  M.hk1 = hs.hotkey.bind({ "cmd" }, "f18", function() M.next() end)      -- Karabiner: Cmd+Tab
  M.hk2 = hs.hotkey.bind({ "cmd" }, "f19", function() M.previous() end)  -- Karabiner: Cmd+Shift+Tab
end

function M.stop()
  for _, t in ipairs({ flagsTap, keyTap }) do if t then t:stop() end end
  flagsTap, keyTap = nil, nil
  if M.hk1 then M.hk1:delete(); M.hk1 = nil end
  if M.hk2 then M.hk2:delete(); M.hk2 = nil end
  if canvas then canvas:delete(); canvas = nil end
  active = false
end

return M
