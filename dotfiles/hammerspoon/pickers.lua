-- pickers.lua — TUI-style device pickers for the Opt+Space menu: audio output /
-- input (SwitchAudioSource), Bluetooth (blueutil), Wi-Fi (networksetup).
-- Omarchy's wiremix / bluetui / impala, minus the terminal.
--
-- Each returns a function menu.lua resolves fresh on open, so the list and the
-- ✓ are always current. CLIs are queried synchronously — all are sub-100ms.

local M = {}
local SAS = "/opt/homebrew/bin/SwitchAudioSource"
local BU  = "/opt/homebrew/bin/blueutil"
local NS  = "/usr/sbin/networksetup"

local function lines(cmd)
  local out = hs.execute(cmd) or ""
  local t = {}
  for l in out:gmatch("[^\n]+") do t[#t + 1] = l end
  return t
end
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function openURL(u) return function() hs.execute("open " .. ("%q"):format(u)) end end

-- ── audio ──────────────────────────────────────────────────────────────────
function M.audioMenu(kind)   -- "output" | "input"
  return function()
    local cur = trim(hs.execute(("%s -c -t %s"):format(SAS, kind)) or "")
    local items = {}
    for _, name in ipairs(lines(("%s -a -t %s"):format(SAS, kind))) do
      items[#items + 1] = {
        name = name .. (name == cur and "   ✓" or ""),
        action = function() hs.execute(("%s -s %q -t %s"):format(SAS, name, kind)) end,
      }
    end
    if #items == 0 then items[1] = { name = "No devices", action = function() end } end
    return { title = kind == "output" and "Audio Output" or "Audio Input", items = items }
  end
end

-- ── bluetooth ──────────────────────────────────────────────────────────────
function M.bluetoothMenu()
  return function()
    local items = {}
    for _, l in ipairs(lines(BU .. " --paired")) do
      local addr = l:match("address: ([%x:-]+)")
      local name = l:match('name: "([^"]*)"') or addr or "?"
      local connected = l:find(", connected,") ~= nil
      if addr then
        items[#items + 1] = {
          name = (connected and "\u{f293}  " or "   ") .. name,
          g = connected and nil or "\u{f293}",
          action = function()
            hs.execute(("%s --%s %q"):format(BU, connected and "disconnect" or "connect", addr))
          end,
        }
      end
    end
    if #items == 0 then items[1] = { name = "No paired devices", action = function() end } end
    items[#items + 1] = { header = "" }
    items[#items + 1] = { name = "Bluetooth settings", g = "\u{f013}",
      action = openURL("x-apple.systempreferences:com.apple.BluetoothSettings") }
    return { title = "Bluetooth", items = items }
  end
end

-- ── wi-fi ──────────────────────────────────────────────────────────────────
function M.wifiMenu()
  return function()
    local cur = trim((hs.execute(NS .. " -getairportnetwork en0") or ""):match(":%s*(.*)$") or "")
    local items = {
      { name = "Wi-Fi settings", g = "\u{f013}",
        action = openURL("x-apple.systempreferences:com.apple.wifi-settings-extension") },
      { header = "PREFERRED" },
    }
    for _, ssid in ipairs(lines(NS .. " -listpreferredwirelessnetworks en0")) do
      ssid = trim(ssid)
      if ssid ~= "" and not ssid:find("Preferred networks") then
        items[#items + 1] = {
          name = ssid .. (ssid == cur and "   ✓" or ""), g = "\u{f1eb}",
          action = function() hs.execute(("%s -setairportnetwork en0 %q"):format(NS, ssid)) end,
        }
      end
    end
    return { title = "Wi-Fi", items = items }
  end
end

return M
