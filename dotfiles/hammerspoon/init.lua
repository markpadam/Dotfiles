require("hs.ipc") -- enables `hs -c '...'` from the terminal for reload/debugging

-- Reload this file with `hs -c 'hs.reload()'` from a shell. NOTE: `hs -c`
-- hangs on canvas/eventtap code — use `hs -t 5 -c '...'` when poking at the
-- menu / OSD / which-key modules.

-- ── Auto-hide menu bar only when a wired external display is connected ──────
-- With no external display, menu bar stays visible except in native
-- fullscreen, which macOS already hides it for regardless of this setting.
--
-- macOS 26's actual switch is com.apple.controlcenter's AutoHideMenuBarOption
-- (0 = Always, 3 = Never; confirmed by toggling the System Settings dropdown
-- and reading the value back). The legacy NSGlobalDomain _HIHideMenuBar key
-- is just a mirror macOS derives from this and gets overwritten on its own
-- schedule -- writing it directly does not stick. ControlCenter.app (not
-- SystemUIServer) owns menu bar rendering now, so that's what needs killing
-- to pick up the change live.
local menuBarLastHidden = nil

-- Plain screen-count isn't enough: AirPlay displays (e.g. a TV used as a
-- wireless extended display) show up in hs.screen.allScreens() too, so
-- counting screens alone false-triggers "external connected" with nothing
-- physically plugged in. Exclude the built-in panel and anything AirPlay.
local function hasWiredExternalDisplay()
  for _, screen in ipairs(hs.screen.allScreens()) do
    local name = screen:name() or ""
    if name ~= "Built-in Retina Display" and not name:lower():find("airplay") then
      return true
    end
  end
  return false
end

local function updateMenuBarAutohide()
  local externalConnected = hasWiredExternalDisplay()
  if externalConnected == menuBarLastHidden then return end
  menuBarLastHidden = externalConnected
  hs.execute(string.format(
    "defaults write com.apple.controlcenter AutoHideMenuBarOption -int %s; killall ControlCenter",
    externalConnected and "0" or "3"
  ))
end

screenWatcher = hs.screen.watcher.new(updateMenuBarAutohide)
screenWatcher:start()
updateMenuBarAutohide()

-- ── Omachy modules ────────────────────────────────────────────────────────
-- theme.lua re-skins Ghostty / borders / SketchyBar / prompt / bat / btop /
-- k9s / nvim / wallpaper together; the rest layer on Omarchy behaviours.
local theme     = require("theme")
local menu      = require("menu")
local osd       = require("osd")
local scratchpad = require("scratchpad")
local toggles   = require("toggles")
local clipboard = require("clipboard")
local idle      = require("idle")
local services  = require("services")
local whichkey  = require("whichkey")

-- Command menu on the Raycast slot (Opt+Space). Tree in menu.lua.
menu.bind({ "alt" }, "space")

-- Global keys — Ctrl+Alt so they never clash with AeroSpace's alt- bindings.
local function map(mods, key, fn, desc)
  hs.hotkey.bind(mods, key, fn)
  whichkey.register(
    (mods[1] == "ctrl" and "⌃⌥ " or "⌥ ") .. (key == "`" and "`" or key:upper()), desc)
end

map({ "ctrl", "alt" }, "space", function() theme.cycle(1) end, "Next theme")
map({ "ctrl", "alt" }, "t",     function() scratchpad.toggle() end, "Scratchpad terminal")
scratchpad.bind({ "ctrl" }, "`")   -- Quake-style, second binding
map({ "ctrl", "alt" }, "v",     function() menu.openAt("Clipboard") end, "Clipboard history")
map({ "ctrl", "alt" }, "k",     function() toggles.caffeine() end, "Toggle keep-awake")
map({ "ctrl", "alt" }, "z",     function() toggles.zen() end, "Toggle Zen mode")
map({ "ctrl", "alt" }, "n",     function() toggles.nightShift() end, "Toggle Night Shift")
map({ "ctrl", "alt" }, "r",     function() services.toggleRecording() end, "Toggle screen recording")
whichkey.register("⌥ Space", "Command menu")

-- ── start the background pieces ───────────────────────────────────────────
osd.start()
clipboard.start()
whichkey.start()
services.start()
idle.start()

-- Re-assert the saved theme after login so borders/bar/Ghostty match it. Soft
-- = don't touch wallpaper or light/dark on a plain reload; a manual theme.set()
-- still does the full job.
hs.timer.doAfter(1.5, function() theme.apply(nil, { soft = true }) end)
