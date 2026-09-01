require("hs.ipc") -- enables `hs -c '...'` from the terminal for reload/debugging

-- Directional window focus used to live here as a Ctrl-b hjkl tmux-style
-- modal. Removed once AeroSpace took over tiling — its own alt-hjkl bindings
-- replace it natively. Reload this file with `hs -c 'hs.reload()'` from a shell.

-- Auto-hide menu bar only when an external display is connected.
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
