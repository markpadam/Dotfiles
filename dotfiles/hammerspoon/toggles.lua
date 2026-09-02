-- toggles.lua — Omarchy's "Toggle" menu: quick switches for the bar, borders,
-- Night Shift, Do Not Disturb, keep-awake, and a one-key Zen mode that stacks
-- them for demos / screen-shares.
--
-- Active toggles show as glyphs in SketchyBar (the `hsq.*` items added in
-- sketchybarrc). State is Hammerspoon-side only — we can't read the real DND
-- state back — so drive everything through here, not System Settings.
--
--   require("toggles").zen()          -- Ctrl+Alt+Z
--   require("toggles").caffeine()     -- Ctrl+Alt+K
--   require("toggles").menu()         -- subtree for the Opt+Space menu

local theme = require("theme")

local M = {}
local SB   = "/opt/homebrew/bin/sketchybar"
local NL   = "/opt/homebrew/bin/nightlight"
local BORDER_W = "6.0"

local state = { bar = true, borders = true, caffeine = false, dnd = false,
                nightshift = false, zen = false }
local zenSaved

local GLYPH = {
  caffeine = "\u{f0f4}", dnd = "\u{f1f6}", zen = "\u{f06c}",
  nightshift = "\u{f186}", bar = "\u{f2d1}", borders = "\u{f2d0}",
}

local function sh(cmd)
  hs.task.new("/bin/sh", nil, { "-c", "export PATH=/opt/homebrew/bin:/usr/bin:/bin:$PATH; " .. cmd }):start()
end
local function sbSet(item, ...)
  local a = { "--set", item }
  for _, v in ipairs({ ... }) do a[#a + 1] = v end
  hs.task.new(SB, nil, a):start()
end
local function glyphItem(name, on)
  sbSet("hsq." .. name, "icon=" .. (GLYPH[name] or "?"), "drawing=" .. (on and "on" or "off"))
end

-- ── individual toggles ─────────────────────────────────────────────────────
function M.bar(force)
  state.bar = (force == nil) and not state.bar or force
  sh(("%s --bar hidden=%s"):format(SB, state.bar and "off" or "on"))
  return state.bar
end

function M.borders(force)
  state.borders = (force == nil) and not state.borders or force
  sh(("borders width=%s"):format(state.borders and BORDER_W or "0.0"))
  glyphItem("borders", not state.borders)
  return state.borders
end

function M.caffeine(force)
  state.caffeine = (force == nil) and not state.caffeine or force
  hs.caffeinate.set("displayIdle", state.caffeine, true)
  glyphItem("caffeine", state.caffeine)
  hs.alert.show(GLYPH.caffeine .. (state.caffeine and "  keeping awake" or "  sleep allowed"))
  return state.caffeine
end

function M.dnd(force)
  state.dnd = (force == nil) and not state.dnd or force
  -- needs a user Shortcut named "Toggle Do Not Disturb" (Turn Focus > toggle);
  -- see the hammerspoon README. No-op-safe if it's missing.
  hs.task.new("/usr/bin/shortcuts", nil, { "run", "Toggle Do Not Disturb" }):start()
  glyphItem("dnd", state.dnd)
  return state.dnd
end

function M.nightShift(force)
  state.nightshift = (force == nil) and not state.nightshift or force
  hs.task.new(NL, nil, { state.nightshift and "on" or "off" }):start()
  glyphItem("nightshift", state.nightshift)
  return state.nightshift
end

-- ── zen mode ───────────────────────────────────────────────────────────────
function M.zen(force)
  local want = (force == nil) and not state.zen or force
  if want == state.zen then return state.zen end
  state.zen = want
  if want then
    zenSaved = { bar = state.bar, borders = state.borders,
                 caffeine = state.caffeine, dnd = state.dnd }
    M.bar(false); M.borders(false); M.caffeine(true)
    if not state.dnd then M.dnd(true) end
    hs.alert.show(GLYPH.zen .. "  Zen mode on")
  else
    M.bar(zenSaved.bar); M.borders(zenSaved.borders); M.caffeine(zenSaved.caffeine)
    if state.dnd ~= zenSaved.dnd then M.dnd(zenSaved.dnd) end
    hs.alert.show(GLYPH.zen .. "  Zen mode off")
  end
  glyphItem("zen", state.zen)
  return state.zen
end

-- ── menu subtree ───────────────────────────────────────────────────────────
function M.menu()
  return { title = "Toggle", items = {
    { name = "Zen mode",          g = GLYPH.zen,        action = function() M.zen() end },
    { name = "Keep awake",        g = GLYPH.caffeine,   action = function() M.caffeine() end },
    { name = "Do Not Disturb",    g = GLYPH.dnd,        action = function() M.dnd() end },
    { name = "Night Shift",       g = GLYPH.nightshift, action = function() M.nightShift() end },
    { name = "Status bar",        g = GLYPH.bar,        action = function() M.bar() end },
    { name = "Window borders",    g = GLYPH.borders,    action = function() M.borders() end },
  } }
end

function M.state() return state end

return M
