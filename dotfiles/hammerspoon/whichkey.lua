-- whichkey.lua — hold Option (alt) for ~0.7s with nothing else pressed and a
-- cheatsheet fades in: three columns of the keys worth remembering — macOS +
-- Hammerspoon, AeroSpace (parsed live from aerospace.toml), Neovim + Terminal.
-- Once up it stays; let go of Option, then a single tap of Option (or Esc)
-- closes it.
--
-- This is the quick-glance view — the common stuff only. The full reference is
-- Opt+Space -> Shortcuts.
--
--   require("whichkey").register("⌃⌥ Space", "Cycle theme")
--   require("whichkey").start()

local ui = require("ui")

local M = {}
local HOME = os.getenv("HOME")
local et   = hs.eventtap.event.types

local HOLD = 0.7               -- seconds to hold Option before the sheet opens

local registered = {}          -- { {chord, desc}, ... } from init.lua
local canvas, flagsTap, armKeyTap, escTap, armTimer, armed, shown, releasedSinceShow

-- ── curated static sections ────────────────────────────────────────────────
local TERMINAL = {
  { "⌃B", "tmux prefix" },
  { "⌃B  V / X", "Split right / down" },
  { "⌃B  H J K L", "Focus pane" },
  { "⌃B  Z", "Zoom pane" },
  { "⌃B  C", "New window" },
  { "⌃B  1–9", "Go to window N" },
  { "⌃B  D", "Detach session" },
  { "⌘ K", "Ghostty clear" },
  { "dev", "tmux project session" },
}

local MACOS = {
  { "⌘ Space", "Spotlight" },
  { "⌃⌘ Space", "Emoji & symbols" },
  { "⌘ Tab", "Switch apps" },
  { "⌘ `", "Windows in app" },
  { "⌘⇧ 4", "Screenshot region" },
  { "⌘⇧ 5", "Screenshot / record" },
  { "⌘⌥ Esc", "Force quit" },
  { "⌃⌘ Q", "Lock screen" },
  { "⌘ ,", "App settings" },
  { "⌘ M", "Minimise window" },
  { "⌘⇧ .", "Toggle hidden files" },
  { "⌘ ⌫", "Move to Trash" },
  { "Right ⌘ ×2", "Dictation" },
}

local NEOVIM = {
  { "Space", "Leader" },
  { "Space Space", "Find files" },
  { "Space /", "Grep project" },
  { "Space e", "File explorer" },
  { "Space ,", "Switch buffer" },
  { "⇧H / ⇧L", "Prev / next buffer" },
  { "Space b d", "Close buffer" },
  { "g d / g r", "Definition / refs" },
  { "K", "Hover docs" },
  { "Space c a", "Code action" },
  { "Space c r", "Rename symbol" },
  { "] d / [ d", "Next / prev diagnostic" },
  { "Space x x", "Diagnostics list" },
  { "Space g g", "Lazygit" },
  { "Space s k", "Search keymaps" },
  { "Space q q", "Quit all" },
}

-- ── parse the common alt- bindings from aerospace.toml ─────────────────────
local DESC = {
  ["layout tiles horizontal vertical"] = "Tile / stack",
  ["layout accordion horizontal vertical"] = "Accordion",
  ["layout floating tiling"] = "Float / tile",
  ["macos-native-fullscreen"] = "Fullscreen",
  ["focus left"] = "Focus ←", ["focus down"] = "Focus ↓",
  ["focus up"] = "Focus ↑", ["focus right"] = "Focus →",
  ["move left"] = "Move ←", ["move down"] = "Move ↓",
  ["move up"] = "Move ↑", ["move right"] = "Move →",
  ["resize smart -50"] = "Shrink", ["resize smart +50"] = "Grow",
  ["mode resize"] = "Resize mode", ["mode service"] = "Service mode",
  ["workspace-back-and-forth"] = "Last workspace",
  ["move-workspace-to-monitor --wrap-around next"] = "→ next monitor",
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

-- keep the cheatsheet short: the move-window (alt-shift-hjkl) and
-- send-to-workspace (alt-shift-N) rows just mirror focus / switch one Shift
-- away, so drop them; keep alt-shift-space (float) and the service-mode gate.
local function keepBinding(k, cmd)
  if k:match("^alt%-shift%-[hjkl]$") then return false end
  if k:match("^alt%-shift%-%d$") then return false end
  if k:match("^alt%-shift%-tab$") then return false end
  if cmd:match("^join%-with") then return false end
  return true
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
        if cmd and keepBinding(k, cmd) then
          out[#out + 1] = { fmtChord(k), describe(cmd) }
        end
      end
    end
  end
  f:close()
  return out
end

-- ── draw ───────────────────────────────────────────────────────────────────
-- FS 14 matches the menu.lua row size (Opt+Space -> Shortcuts).
local COLW, ROWH, GAP, PAD, TOP = 322, 23, 24, 24, 18
local CHORDW  = 116      -- chord sub-column; the rest of COLW is the description
local FS      = 14        -- row font size
local HFS     = 12        -- section-header font size
local SECTGAP = 16        -- vertical gap between two sections in one column

local function draw()
  local c = ui.c()
  -- each column is a list of { title, rows } sections, stacked vertically
  local columns = {
    { { "macOS", MACOS }, { "Hammerspoon", registered } },
    { { "AeroSpace", aeroBindings() } },
    { { "Neovim", NEOVIM }, { "Terminal", TERMINAL } },
  }

  -- column height in px = per-section (header 26 + rows) + gaps between sections
  local function colHeight(col)
    local h = 0
    for _, s in ipairs(col) do h = h + 26 + #s[2] * ROWH + SECTGAP end
    return h - SECTGAP
  end
  local bodyH = 0
  for _, col in ipairs(columns) do bodyH = math.max(bodyH, colHeight(col)) end

  local W = PAD * 2 + #columns * COLW + (#columns - 1) * GAP
  local H = TOP + bodyH + PAD

  local scr = hs.screen.mainScreen():frame()
  canvas = canvas or ui.centred(W, H, 0.5)
  canvas:frame({
    x = scr.x + math.floor((scr.w - W) / 2),
    y = scr.y + math.floor((scr.h - H) / 2),
    w = W, h = H,
  })

  local els = ui.panel(W, H, c)
  for i, col in ipairs(columns) do
    local x0 = PAD + (i - 1) * (COLW + GAP)
    local y = TOP
    for _, sec in ipairs(col) do
      els[#els + 1] = ui.txt(sec[1]:upper(), HFS, c.overlay,
        { frame = { x = x0, y = y, w = COLW, h = 16 } })
      els[#els + 1] = {
        type = "segments", strokeColor = { hex = c.overlay, alpha = 0.3 }, strokeWidth = 1,
        coordinates = { { x = x0, y = y + 19 }, { x = x0 + COLW, y = y + 19 } },
      }
      y = y + 26
      for _, b in ipairs(sec[2]) do
        els[#els + 1] = ui.txt(b[1], FS, c.accent,
          { frame = { x = x0, y = y, w = CHORDW, h = 17 }, textLineBreak = "truncateTail" })
        els[#els + 1] = ui.txt(b[2], FS, c.text,
          { frame = { x = x0 + CHORDW + 4, y = y, w = COLW - CHORDW - 4, h = 17 },
            textLineBreak = "truncateTail" })
        y = y + ROWH
      end
      y = y + SECTGAP
    end
  end
  canvas:replaceElements(els)
  canvas:show(0.1)
end

function M.show()
  if shown then return end
  draw()
  shown, armed, releasedSinceShow = true, false, false
  if armKeyTap then armKeyTap:stop() end
  escTap:start()
end

function M.hide()
  if armTimer then armTimer:stop(); armTimer = nil end
  if armKeyTap then armKeyTap:stop() end
  if escTap then escTap:stop() end
  if canvas then canvas:hide(0.12) end
  shown, armed = false, false
end

function M.register(chord, desc) registered[#registered + 1] = { chord, desc } end

-- ── hold to open, tap Option (or Esc) to close ────────────────────────────
-- Hold Option alone for 0.7s -> show. A key pressed during that window is
-- "alt + <key>", so cancel. Once it's up: let go of Option, then a single
-- press of Option closes it again (Esc too).
local function onArmKey()
  armed = false
  if armTimer then armTimer:stop(); armTimer = nil end
  if armKeyTap then armKeyTap:stop() end
  return false
end

local function onEscKey(e)
  if e:getKeyCode() == 53 then M.hide(); return true end   -- 53 = Esc, consume it
  return false
end

local function onFlags(e)
  local f = e:getFlags()
  local onlyAlt = f.alt and not (f.cmd or f.ctrl or f.shift)
  if shown then
    if not f.alt then
      releasedSinceShow = true            -- Option let go — arm the tap-to-close
    elseif f.alt and releasedSinceShow then
      M.hide()                            -- pressed again -> close
    end
  elseif onlyAlt then
    if not armed then
      armed = true
      armKeyTap:start()
      armTimer = hs.timer.doAfter(HOLD, function()
        armTimer = nil
        if armed then M.show() end
      end)
    end
  elseif armed then
    armed = false
    if armTimer then armTimer:stop(); armTimer = nil end
    armKeyTap:stop()
  end
  return false
end

function M.start()
  M.stop()
  flagsTap  = hs.eventtap.new({ et.flagsChanged }, onFlags)
  armKeyTap = hs.eventtap.new({ et.keyDown }, onArmKey)
  escTap    = hs.eventtap.new({ et.keyDown }, onEscKey)
  flagsTap:start()
end

function M.stop()
  for _, t in ipairs({ flagsTap, armKeyTap, escTap }) do if t then t:stop() end end
  flagsTap, armKeyTap, escTap = nil, nil, nil
  if canvas then canvas:delete(); canvas = nil end
end

return M
