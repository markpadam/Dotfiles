-- Omachy command menu — a keyboard-driven modal on Option+Space, styled after
-- Omarchy 4's `omarchy-menu` (walker --dmenu): a sharp-cornered panel, 2px
-- border, monospace throughout, Nerd Font glyph per row, single-line rows,
-- the current menu name as the "<name>…" prompt.
--
-- On the first screen, typing runs a Raycast-style search across every
-- installed app, every System Settings pane, every menu action, and (a beat
-- later) files by name. Enter to pick, Esc to close, Backspace / ← to go up a
-- level, ↑/↓ to move.
--
-- Drawn with hs.canvas + a keyboard eventtap rather than hs.chooser, so the
-- theme is fully ours and there is no "which window has focus" problem — the
-- eventtap owns the keyboard while the menu is up.
--
-- Wired up from init.lua:  require("menu").bind({"alt"}, "space")

local M = {}
local HOME = os.getenv("HOME")

-- Omachy sibling modules (see init.lua). No cycles: none of these require menu.
local toggles   = require("toggles")
local clipboard = require("clipboard")
local pickers   = require("pickers")
local webapp    = require("webapp")
local emoji     = require("emoji")

-- ── action helpers ─────────────────────────────────────────────────────────
local function focus(app)     return function() hs.application.launchOrFocus(app) end end
local function focusID(bid)    return function() hs.application.launchOrFocusByBundleID(bid) end end
local function openURL(url)    return function() hs.execute("open " .. ("%q"):format(url)) end end
local function openPath(path)  return function() hs.execute("open " .. ("%q"):format(path)) end end
local function shell(cmd)      return function() hs.execute(cmd, true) end end
local function osa(src)        return function() hs.osascript.applescript(src) end end
local function keys(mods, k)   return function() hs.eventtap.keyStroke(mods, k, 0) end end

-- run fn a beat after the menu has closed (screen capture needs it gone)
local function deferred(fn) return function() hs.timer.doAfter(0.2, fn) end end

local function shotPath()
  return string.format("%s/Desktop/Screenshot %s.png", HOME, os.date("%Y-%m-%d at %H.%M.%S"))
end
local function screencap(flags, toFile)
  return deferred(function()
    local args = hs.fnutils.copy(flags)
    if toFile then args[#args + 1] = shotPath() end
    hs.task.new("/usr/sbin/screencapture", nil, args):start()
  end)
end

local function toggleWifi()
  local on = hs.execute("networksetup -getairportpower en0"):match(": On")
  hs.execute("networksetup -setairportpower en0 " .. (on and "off" or "on"))
  hs.alert.show("Wi-Fi " .. (on and "off" or "on"))
end

local function setAppearance(dark)
  return osa(('tell application "System Events" to tell appearance preferences '
    .. 'to set dark mode to %s'):format(tostring(dark)))
end

-- ── Nerd Font glyphs (stored as \u{} escapes so no PUA bytes hit the file;
--    every codepoint below is present in Hack Nerd Font Mono) ───────────────
local NF = {
  apps = "\u{f00a}", custom = "\u{f0ac}", builtin = "\u{f179}",
  terminal = "\u{f489}", termprompt = "\u{f120}", plus = "\u{f0fe}",
  capture = "\u{f030}", video = "\u{f03d}", eyedropper = "\u{f1fb}",
  style = "\u{f1fc}", moon = "\u{f186}", sun = "\u{f185}", image = "\u{f03e}",
  setup = "\u{f013}", cog = "\u{f013}", wifi = "\u{f1eb}", bt = "\u{f293}",
  sound = "\u{f028}", display = "\u{f108}", keyboard = "\u{f11c}",
  system = "\u{f011}", lock = "\u{f023}", logout = "\u{f08b}",
  refresh = "\u{f021}", power = "\u{f011}", back = "\u{f053}",
  shortcuts = "\u{f11c}", window = "\u{f2d0}", tmux = "\u{ebc8}", vim = "\u{e62b}",
  search = "\u{f002}", folder = "\u{f07b}", apple = "\u{f179}", ssh = "\u{f120}",
  toggle = "\u{f205}", insert = "\u{f040}", web = "\u{f0ac}",
  clipboard = "\u{f0ea}", record = "\u{f111}", emoji = "\u{f118}", palette = "\u{f1fc}",
}

-- built fresh each time it's opened, so new files show up
local function wallpaperMenu()
  local dir = HOME .. "/Pictures/Wallpapers"
  local items = {}
  local ok, iter, dirobj = pcall(hs.fs.dir, dir)
  if ok then
    for file in iter, dirobj do
      if file:match("%.[jJ][pP][eE]?[gG]$") or file:match("%.[pP][nN][gG]$")
        or file:match("%.[hH][eE][iI][cC]$") then
        local path = dir .. "/" .. file
        items[#items + 1] = {
          name = (file:gsub("%.%w+$", "")), g = NF.image,
          action = osa(('tell application "System Events" to tell every desktop '
            .. 'to set picture to %q'):format(path)),
        }
      end
    end
  end
  table.sort(items, function(a, b) return a.name:lower() < b.name:lower() end)
  if #items == 0 then
    items[1] = { name = "No images in ~/Pictures/Wallpapers", g = NF.image, action = function() end }
  end
  return { title = "Wallpaper", g = NF.image, items = items }
end

-- ── the tree ───────────────────────────────────────────────────────────────
-- item = { name, action = fn }                        leaf
--        { name, menu = <subtree | fn returning one> }  submenu
--        { name, app = "bundle.id", action = fn }      leaf drawn with an app icon
--        optional `g = "<glyph>"` overrides the inherited category glyph

local CUSTOM_APPS = { title = "Custom Apps", g = NF.custom, items = {
  { name = "Claude",         app = "com.anthropic.claudefordesktop",  action = focusID("com.anthropic.claudefordesktop") },
  { name = "VS Code",        app = "com.microsoft.VSCode",            action = focusID("com.microsoft.VSCode") },
  { name = "Ghostty",        app = "com.mitchellh.ghostty",           action = focusID("com.mitchellh.ghostty") },
  { name = "Brave Browser",  app = "com.brave.Browser",               action = focusID("com.brave.Browser") },
  { name = "GitHub Desktop", app = "com.github.GitHubClient",         action = focusID("com.github.GitHubClient") },
  { name = "Postman",        app = "com.postmanlabs.mac",             action = focusID("com.postmanlabs.mac") },
  { name = "Freelens",       app = "app.freelens.Freelens",           action = focusID("app.freelens.Freelens") },
  { name = "NordVPN",        app = "com.nordvpn.macos",               action = focusID("com.nordvpn.macos") },
  { name = "Screens",        app = "com.edovia.screens.5",            action = focusID("com.edovia.screens.5") },
  { name = "Windows App",    app = "com.microsoft.rdc.macos",         action = focusID("com.microsoft.rdc.macos") },
  { name = "WhatsApp",       app = "net.whatsapp.WhatsApp",           action = focusID("net.whatsapp.WhatsApp") },
  { name = "Zoom",           app = "us.zoom.xos",                     action = focusID("us.zoom.xos") },
  { name = "Vial",           app = "today.vial",                      action = focusID("today.vial") },
} }

local BUILTIN_APPS = { title = "Builtin Apps", g = NF.builtin, items = {
  { name = "Safari",           app = "com.apple.Safari",           action = focus("Safari") },
  { name = "Mail",             app = "com.apple.mail",             action = focus("Mail") },
  { name = "Calendar",         app = "com.apple.iCal",             action = focus("Calendar") },
  { name = "Reminders",        app = "com.apple.reminders",        action = focus("Reminders") },
  { name = "Notes",            app = "com.apple.Notes",            action = focus("Notes") },
  { name = "Music",            app = "com.apple.Music",            action = focus("Music") },
  { name = "Home",             app = "com.apple.Home",             action = focus("Home") },
  { name = "Activity Monitor", app = "com.apple.ActivityMonitor",  action = focus("Activity Monitor") },
  { name = "System Settings",  app = "com.apple.systempreferences", action = focus("System Settings") },
} }

local APPS = { title = "Apps", g = NF.apps, items = {
  { name = "Custom Apps",  menu = CUSTOM_APPS },
  { name = "Builtin Apps", menu = BUILTIN_APPS },
} }

-- Named Ghostty windows — the replacement for the old iTerm dynamic profiles.
-- Each is a locked title + working dir + command; see config/ghostty/launch.
-- open a TUI in its own Ghostty window
local function tui(name, cmd)
  return function()
    hs.task.new("/usr/bin/open", nil, { "-na", "Ghostty", "--args",
      "--title=" .. name, "-e", "zsh", "-lc", cmd .. "; exec zsh -l" }):start()
  end
end

local TUIS = { title = "TUIs", g = NF.terminal, items = {
  { name = "btop  ·  system",     g = NF.termprompt, action = tui("btop", "btop") },
  { name = "lazygit  ·  git",     g = NF.termprompt, action = tui("lazygit", "lazygit") },
  { name = "lazydocker  ·  docker", g = NF.termprompt, action = tui("lazydocker", "lazydocker") },
  { name = "k9s  ·  kubernetes",  g = NF.termprompt, action = tui("k9s", "k9s") },
  { name = "mactop  ·  power (sudo)", g = NF.termprompt, action = tui("mactop", "sudo mactop") },
} }

local TERMINAL = { title = "Terminal", g = NF.terminal, items = {
  { name = "Open Terminal", g = NF.plus, action = shell("open -na Ghostty") },
  { name = "SSH",   g = NF.termprompt, menu = pickers.sshMenu() },
  { name = "TUIs",  g = NF.terminal,   menu = TUIS },
  { header = "NAMED WINDOWS" },
  { name = "AKS-Lab (tmux cockpit)", g = NF.termprompt, action = shell("~/.config/ghostty/launch aks-lab") },
  { name = "IDE (LazyVim)",          g = NF.termprompt, action = shell("~/.config/ghostty/launch ide") },
  { name = "K8s Exam",               g = NF.termprompt, action = shell("~/.config/ghostty/launch exam") },
  { name = "PowerShell 7",           g = NF.termprompt, action = shell("~/.config/ghostty/launch pwsh") },
  { name = "Ubuntu (Multipass)",     g = NF.termprompt, action = shell("~/.config/ghostty/launch ubuntu") },
} }

local CAPTURE = { title = "Capture", g = NF.capture, items = {
  { name = "Selection → clipboard", action = screencap({ "-i", "-c" }, false) },
  { name = "Selection → file",      action = screencap({ "-i" }, true) },
  { name = "Window → file",         action = screencap({ "-iW" }, true) },
  { name = "Whole screen → file",   action = screencap({ "-x" }, true) },
  { name = "Start / stop recording", g = NF.record,
    action = function() require("services").toggleRecording() end },
  { name = "Recording toolbar (⌘⇧5)", g = NF.video, action = deferred(keys({ "cmd", "shift" }, "5")) },
  { name = "Digital Color Meter",   g = NF.eyedropper, action = focus("Digital Color Meter") },
} }

local SETUP = { title = "Setup", g = NF.setup, items = {
  { name = "Audio output",       g = NF.sound, menu = pickers.audioMenu("output") },
  { name = "Audio input",        g = NF.sound, menu = pickers.audioMenu("input") },
  { name = "Bluetooth devices",  g = NF.bt,   menu = pickers.bluetoothMenu() },
  { name = "Wi-Fi networks",     g = NF.wifi, menu = pickers.wifiMenu() },
  { name = "Toggle Wi-Fi",       g = NF.wifi, action = toggleWifi },
  { header = "SETTINGS PANES" },
  { name = "Wi-Fi settings",     g = NF.wifi,
    action = openURL("x-apple.systempreferences:com.apple.wifi-settings-extension") },
  { name = "Bluetooth settings", g = NF.bt,
    action = openURL("x-apple.systempreferences:com.apple.BluetoothSettings") },
  { name = "Sound settings",     g = NF.sound,
    action = openURL("x-apple.systempreferences:com.apple.Sound-Settings.extension") },
  { name = "Display settings",   g = NF.display,
    action = openURL("x-apple.systempreferences:com.apple.Displays-Settings.extension") },
  { name = "Keyboard settings",  g = NF.keyboard,
    action = openURL("x-apple.systempreferences:com.apple.Keyboard-Settings.extension") },
} }

local INSERT = { title = "Insert", g = NF.insert, items = {
  { name = "Emoji",  g = NF.emoji,   menu = emoji.menu },
  { name = "Glyphs", g = NF.palette, menu = emoji.glyphMenu },
} }

local function clipboardMenu() return { title = "Clipboard", items = clipboard.rows() } end

local SYSTEM = { title = "System", g = NF.system, items = {
  { header = "POWER" },
  { name = "Lock screen",        g = NF.lock,    action = function() hs.caffeinate.lockScreen() end },
  { name = "Sleep",              g = NF.moon,    action = function() hs.caffeinate.systemSleep() end },
  { name = "Log out…",           g = NF.logout,  action = osa('tell application "System Events" to log out') },
  { name = "Restart…",           g = NF.refresh, action = osa('tell application "System Events" to restart') },
  { name = "Shut down…",         g = NF.power,   action = osa('tell application "System Events" to shut down') },
  { header = "RELOAD" },
  { name = "Reload Hammerspoon", g = NF.refresh, action = function() hs.reload() end },
  { name = "Reload AeroSpace",   g = NF.refresh, action = shell("aerospace reload-config") },
  { name = "Reload SketchyBar",  g = NF.refresh, action = shell("sketchybar --reload") },
  { header = "PACKAGES" },
  { name = "Check for updates",  g = NF.refresh,
    action = function() require("services").checkUpdates(); hs.alert.show("Checking for updates…") end },
  { name = "Update everything",  g = NF.refresh,
    action = function() require("services").updateAll() end },
} }

-- System Settings panes, for root search. `open`ing a stale pane id just lands
-- on the last-used pane rather than erroring, so an odd macOS rename degrades.
local SETTINGS = {
  { name = "Wi-Fi",              url = "x-apple.systempreferences:com.apple.wifi-settings-extension" },
  { name = "Bluetooth",          url = "x-apple.systempreferences:com.apple.BluetoothSettings" },
  { name = "Network",            url = "x-apple.systempreferences:com.apple.Network-Settings.extension" },
  { name = "Sound",              url = "x-apple.systempreferences:com.apple.Sound-Settings.extension" },
  { name = "Displays",           url = "x-apple.systempreferences:com.apple.Displays-Settings.extension" },
  { name = "Keyboard",           url = "x-apple.systempreferences:com.apple.Keyboard-Settings.extension" },
  { name = "Trackpad",           url = "x-apple.systempreferences:com.apple.Trackpad-Settings.extension" },
  { name = "Mouse",              url = "x-apple.systempreferences:com.apple.Mouse-Settings.extension" },
  { name = "Appearance",         url = "x-apple.systempreferences:com.apple.Appearance-Settings.extension" },
  { name = "Wallpaper",          url = "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension" },
  { name = "Desktop & Dock",     url = "x-apple.systempreferences:com.apple.Desktop-Settings.extension" },
  { name = "Control Center",     url = "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension" },
  { name = "Notifications",      url = "x-apple.systempreferences:com.apple.Notifications-Settings.extension" },
  { name = "Focus",              url = "x-apple.systempreferences:com.apple.Focus-Settings.extension" },
  { name = "Battery",            url = "x-apple.systempreferences:com.apple.Battery-Settings.extension" },
  { name = "General",            url = "x-apple.systempreferences:com.apple.systempreferences.GeneralSettings" },
  { name = "Software Update",    url = "x-apple.systempreferences:com.apple.Software-Update-Settings.extension" },
  { name = "Privacy & Security", url = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension" },
  { name = "Accessibility",      url = "x-apple.systempreferences:com.apple.Accessibility-Settings.extension" },
  { name = "Users & Groups",     url = "x-apple.systempreferences:com.apple.Users-Groups-Settings.extension" },
  { name = "Date & Time",        url = "x-apple.systempreferences:com.apple.Date-Time-Settings.extension" },
  { name = "Sharing",            url = "x-apple.systempreferences:com.apple.Sharing-Settings.extension" },
  { name = "Time Machine",       url = "x-apple.systempreferences:com.apple.Time-Machine-Settings.extension" },
  { name = "Screen Time",        url = "x-apple.systempreferences:com.apple.Screen-Time-Settings.extension" },
  { name = "Lock Screen",        url = "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension" },
  { name = "Siri & Spotlight",   url = "x-apple.systempreferences:com.apple.Siri-Settings.extension" },
}

-- ── keyboard-shortcut reference (Omarchy's "Learn ▸ Keybindings") ──────────
-- Display-only rows in Omarchy's `%-35s → %s` style: chord, an arrow, the
-- action. Tiling is parsed live from aerospace.toml so it can't drift; TMUX /
-- NeoVim mirror ~/.tmux.conf and LazyVim.

local MODSYM = { alt = "⌥", cmd = "⌘", ctrl = "⌃", shift = "⇧" }
local KEYSYM = {
  slash = "/", minus = "−", equal = "=", comma = ",", period = ".",
  semicolon = ";", enter = "↩", tab = "⇥", space = "Space",
  backspace = "⌫", esc = "⎋", up = "↑", down = "↓", left = "←", right = "→",
}
local function fmtKey(chord)
  local mods, key = {}, ""
  for part in chord:gmatch("[^-]+") do
    if MODSYM[part] then mods[#mods + 1] = MODSYM[part] else key = part end
  end
  key = KEYSYM[key] or (#key == 1 and key:upper() or key)
  return table.concat(mods) .. (#mods > 0 and " " or "") .. key
end

local AERO_DESC = {
  ["layout tiles horizontal vertical"]     = "Tiles layout",
  ["layout accordion horizontal vertical"] = "Accordion layout",
  ["layout floating tiling"]               = "Toggle float / tile",
  ["macos-native-fullscreen"]              = "Fullscreen",
  ["focus left"] = "Focus left", ["focus down"] = "Focus down",
  ["focus up"] = "Focus up", ["focus right"] = "Focus right",
  ["move left"] = "Move window left", ["move down"] = "Move window down",
  ["move up"] = "Move window up", ["move right"] = "Move window right",
  ["resize smart -50"] = "Shrink", ["resize smart +50"] = "Grow",
  ["mode resize"] = "Resize mode", ["mode service"] = "Service mode",
  ["mode main"] = "Back to normal",
  ["workspace-back-and-forth"] = "Last workspace",
  ["move-workspace-to-monitor --wrap-around next"] = "Workspace → next monitor",
  ["close"] = "Close window", ["flatten-workspace-tree"] = "Reset layout",
  ["close-all-windows-but-current"] = "Close others", ["reload-config"] = "Reload config",
  ["resize width -50"] = "Narrower", ["resize width +50"] = "Wider",
  ["resize height -50"] = "Shorter", ["resize height +50"] = "Taller",
}
local function aeroDesc(cmd)
  if AERO_DESC[cmd] then return AERO_DESC[cmd] end
  local w = cmd:match("^workspace (.+)$");                 if w then return "Workspace: " .. w end
  local m = cmd:match("^move%-node%-to%-workspace (.+)$"); if m then return "Send to: " .. m end
  local j = cmd:match("^join%-with (%a+)$");               if j then return "Join " .. j end
  if cmd:find("Ghostty") and cmd:find("new window") then return "New terminal window" end
  return (cmd:gsub("%-", " "):gsub("^%l", string.upper))
end

local function shortcut(key, desc)
  return { name = key .. "  " .. desc, chord = key, act = desc, info = true }
end
local function section(name) return { header = name } end

-- which titled section a main-mode AeroSpace command belongs to
local function aeroSection(cmd)
  if cmd:match("^layout") or cmd == "macos-native-fullscreen" then return "LAYOUT" end
  if cmd:match("^focus ") or cmd:match("^move ") then return "FOCUS & MOVE" end
  if cmd:match("^resize ") then return "RESIZE" end
  if cmd:match("workspace") then return "WORKSPACES" end
  return "WINDOW"
end

-- parsed fresh each open, so a rebind shows up next time the menu is used
local function tilingMenu()
  local main, other, mode = {}, {}, nil   -- main[section] = {rows}; other = {mode -> {rows}}
  local mainOrder = { "LAYOUT", "FOCUS & MOVE", "RESIZE", "WORKSPACES", "WINDOW" }
  local otherOrder = {}
  local f = io.open(HOME .. "/.config/aerospace/aerospace.toml", "r")
  if f then
    for line in f:lines() do
      local hdr = line:match("^%s*%[(.-)%]")
      if hdr then mode = hdr:match("^mode%.([%w_]+)%.binding$") end
      if mode then
        local key, val = line:match("^%s*([%w%-]+)%s*=%s*(.+)$")
        if key and val then
          val = val:gsub("%s*#.*$", "")
          local cmd = val ~= "[]"
            and (val:match("^'([^']*)'") or val:match("^%[%s*'([^']*)'") or val:match('^"([^"]*)"'))
          if cmd then
            local row = shortcut(fmtKey(key), aeroDesc(cmd))
            if mode == "main" then
              local s = aeroSection(cmd)
              main[s] = main[s] or {}
              table.insert(main[s], row)
            else
              if not other[mode] then other[mode] = {}; otherOrder[#otherOrder + 1] = mode end
              table.insert(other[mode], row)
            end
          end
        end
      end
    end
    f:close()
  end
  local items = {}
  for _, s in ipairs(mainOrder) do
    if main[s] then
      items[#items + 1] = section(s)
      for _, r in ipairs(main[s]) do items[#items + 1] = r end
    end
  end
  for _, m in ipairs(otherOrder) do
    items[#items + 1] = section(m:upper() .. " MODE")
    for _, r in ipairs(other[m]) do items[#items + 1] = r end
  end
  if #items == 0 then
    items[1] = { name = "aerospace.toml not found", chord = "—",
      act = "~/.config/aerospace/aerospace.toml", info = true }
  end
  return { title = "Tiling", g = NF.window, width = 460, items = items }
end

local TMUX = { title = "TMUX", g = NF.tmux, width = 460, items = {
  section("GENERAL"),
  shortcut("⌃ B",          "Prefix key"),
  shortcut("⌃B  R",        "Reload ~/.tmux.conf"),
  section("PANES"),
  shortcut("⌃B  V",        "Split pane right"),
  shortcut("⌃B  X",        "Split pane down"),
  shortcut("⌃B  H J K L",  "Focus pane (vim dirs)"),
  shortcut("⌃B  ⇧HJKL",    "Resize pane (repeatable)"),
  shortcut("⌃B  Z",        "Zoom / unzoom pane"),
  section("WINDOWS"),
  shortcut("⌃B  C",        "New window"),
  shortcut("⌃B  1 – 9",    "Go to window N"),
  shortcut("⌃B  W",        "Window picker"),
  section("SESSION & COPY"),
  shortcut("⌃B  D",        "Detach session"),
  shortcut("⌃B  [",        "Copy mode (vi keys)"),
  shortcut("copy:  V  Y",  "Select · yank to pasteboard"),
} }

-- Ghostty runs on its stock keybinds (no `keybind` lines in config/ghostty/
-- config). `super` = ⌘. copy-on-select is on, and ⌘W doesn't prompt
-- (confirm-close-surface = false).
local GHOSTTY = { title = "Ghostty", g = NF.terminal, width = 460, items = {
  section("WINDOWS & TABS"),
  shortcut("⌘ N",        "New window"),
  shortcut("⌘ T",        "New tab"),
  shortcut("⌘ W",        "Close split / tab"),
  shortcut("⌘⇧ W",       "Close window"),
  shortcut("⌘ 1 – 9",    "Go to tab N"),
  shortcut("⌘⇧ [  /  ]", "Prev / next tab"),
  shortcut("⌘ ⏎",        "Toggle fullscreen"),
  section("SPLITS"),
  shortcut("⌘ D",        "Split right"),
  shortcut("⌘⇧ D",       "Split down"),
  shortcut("⌘ [  /  ]",  "Focus prev / next split"),
  shortcut("⌘⌥ ← ↑ → ↓", "Focus split by direction"),
  shortcut("⌘⌃ ← ↑ → ↓", "Resize split"),
  shortcut("⌘⌃ =",       "Equalise splits"),
  shortcut("⌘⇧ ⏎",       "Zoom / unzoom split"),
  section("FONT"),
  shortcut("⌘ =  /  −",  "Font bigger / smaller"),
  shortcut("⌘ 0",        "Reset font size"),
  section("SEARCH & SCROLLBACK"),
  shortcut("⌘ F",        "Search"),
  shortcut("⌘ E",        "Search selection"),
  shortcut("⌘ G  /  ⌘⇧ G", "Next / prev match"),
  shortcut("⌘⇧ ↑  /  ↓", "Jump to prev / next prompt"),
  shortcut("⌘ Home / End", "Scroll to top / bottom"),
  shortcut("⌘ K",        "Clear screen"),
  section("GENERAL"),
  shortcut("⌘⇧ P",       "Command palette"),
  shortcut("⌘ ,  /  ⌘⇧ ,", "Open / reload config"),
  shortcut("⌘⌥ I",       "Terminal inspector"),
  shortcut("⌘ C  /  V",  "Copy / paste"),
  shortcut("⌘ Q",        "Quit"),
} }

local NEOVIM = { title = "NeoVim", g = NF.vim, width = 460, items = {
  section("GENERAL"),
  shortcut("Space",         "Leader key"),
  shortcut("Space  l",      "Lazy (plugins)"),
  shortcut("Space  s k",    "Search keymaps"),
  shortcut("Space  q q",    "Quit all"),
  section("FILES"),
  shortcut("Space  Space",  "Find files"),
  shortcut("Space  /",      "Grep (live, project root)"),
  shortcut("Space  e",      "File explorer (Neo-tree)"),
  shortcut("Space  f n",    "New file"),
  section("BUFFERS & WINDOWS"),
  shortcut("Space  ,",      "Switch buffer"),
  shortcut("⇧H  /  ⇧L",     "Prev / next buffer"),
  shortcut("Space  b d",    "Delete buffer"),
  shortcut("⌃ H J K L",     "Move between windows"),
  section("CODE"),
  shortcut("g d  /  g r",   "Definition / references"),
  shortcut("K",             "Hover docs"),
  shortcut("Space  c a",    "Code action"),
  shortcut("Space  c r",    "Rename symbol"),
  shortcut("] d  /  [ d",   "Next / prev diagnostic"),
  shortcut("Space  x x",    "Diagnostics (Trouble)"),
  shortcut("Space  g g",    "Lazygit"),
} }

local MACOS = { title = "macOS", g = NF.apple, width = 460, items = {
  section("SYSTEM"),
  shortcut("⌘ Space",        "Spotlight"),
  shortcut("⌃⌘ Space",       "Emoji & symbols"),
  shortcut("⌃⌘ Q",           "Lock screen"),
  shortcut("⌘⌥ Esc",         "Force quit"),
  shortcut("⌘ ,",            "App settings"),
  shortcut("Fn Fn",          "Dictation"),
  section("SCREENSHOTS"),
  shortcut("⌘⇧ 3",           "Whole screen"),
  shortcut("⌘⇧ 4",           "Selected region"),
  shortcut("⌘⇧ 4  Space",    "A window"),
  shortcut("⌘⇧ 5",           "Screenshot / record toolbar"),
  shortcut("+ ⌃",            "…to clipboard instead of a file"),
  section("WINDOWS & APPS"),
  shortcut("⌘ Tab",          "Switch app (themed switcher)"),
  shortcut("⌘ `",            "Cycle windows in the app"),
  shortcut("⌘ M  /  ⌘ H",    "Minimise  ·  hide (⌘H is off in AeroSpace)"),
  shortcut("⌘ W  /  ⌘ Q",    "Close window  ·  quit app"),
  shortcut("⌃ ↑",            "Mission Control"),
  section("FINDER"),
  shortcut("⌘⇧ .",           "Toggle hidden files"),
  shortcut("⌘⇧ G",           "Go to folder…"),
  shortcut("⌘ ⌫",            "Move to Trash"),
  shortcut("⌘⇧ ⌫",           "Empty Trash"),
  shortcut("Space",          "Quick Look"),
  section("TEXT"),
  shortcut("⌥ ← / →",        "Move by word"),
  shortcut("⌘ ← / →",        "Line start / end"),
  shortcut("⌥ ⌫",            "Delete word"),
  shortcut("⌘ ⌫",            "Delete to line start"),
} }

local SHORTCUTS = { title = "Shortcuts", g = NF.shortcuts, items = {
  { name = "macOS",   g = NF.apple,    menu = MACOS },
  { name = "Tiling",  g = NF.window,   menu = tilingMenu },
  { name = "TMUX",    g = NF.tmux,     menu = TMUX },
  { name = "Ghostty", g = NF.terminal, menu = GHOSTTY },
  { name = "NeoVim",  g = NF.vim,      menu = NEOVIM },
} }

local ROOT = { title = "Go", items = {
  section("LAUNCH"),
  { name = "Apps",      g = NF.apps,      menu = APPS },
  { name = "Terminal",  g = NF.terminal,  menu = TERMINAL },
  { name = "Web Apps",  g = NF.web,       menu = webapp.menu },
  section("DESKTOP"),
  { name = "Capture",   g = NF.capture,   menu = CAPTURE },
  { name = "Toggle",    g = NF.toggle,    menu = toggles.menu },
  { name = "Clipboard", g = NF.clipboard, menu = clipboardMenu },
  { name = "Insert",    g = NF.insert,    menu = INSERT },
  { name = "Setup",     g = NF.setup,     menu = SETUP },
  section("SYSTEM"),
  { name = "Shortcuts", g = NF.shortcuts, menu = SHORTCUTS },
  { name = "System",    g = NF.system,    menu = SYSTEM },
} }

-- ── theme (Catppuccin Mocha) ───────────────────────────────────────────────
local C = {
  base     = "#1e1e2e",
  text     = "#cdd6f4",
  subtext  = "#a6adc8",
  overlay  = "#6c7086",
  accent   = "#cba6f7",   -- mauve; also the JankyBorders active colour
}

-- ── geometry (Omarchy: --width 295, 2px border, 20px padding, no radius) ────
local WIDTH    = 300
local BORDER_W = 2
local RADIUS   = 10
local HEADER_H = 42
local ROW_H    = 38
local PAD      = 16
local GLYPH_W  = 22
local MAX_ROWS = 10          -- floor; the real cap is screen-relative (bodyBudget)
local FONT     = "Hack Nerd Font Mono"
local TOP_FRAC = 0.16        -- panel top as a fraction of screen height
local BOT_FRAC = 0.94        -- keep the panel bottom above this fraction

-- Vertical space the row list may use: everything between the panel top and
-- BOT_FRAC of screen height, but never less than the old 10-row budget. The
-- root menu then fits without scrolling on any display, while long submenus
-- (Tiling, search results) still scroll.
local function bodyBudget()
  local h = hs.screen.mainScreen():frame().h
  return math.max(MAX_ROWS * ROW_H,
    math.floor(h * BOT_FRAC) - math.floor(h * TOP_FRAC) - HEADER_H - PAD)
end

-- ── icons for the app / file rows (Omarchy's launcher uses real icons) ─────
local iconCache = {}
local function appIcon(bundleID)
  local k = "a:" .. bundleID
  if iconCache[k] == nil then iconCache[k] = hs.image.imageFromAppBundle(bundleID) or false end
  return iconCache[k] or nil
end
local function fileIcon(path)
  local k = "f:" .. path
  if iconCache[k] == nil then iconCache[k] = hs.image.iconForFile(path) or false end
  return iconCache[k] or nil
end

-- ── root search index ──────────────────────────────────────────────────────
local APP_DIRS = {
  "/Applications", "/Applications/Utilities",
  "/System/Applications", "/System/Applications/Utilities",
  HOME .. "/Applications",
}
local appList, flatCache

local function scanApps()
  local seen, out = {}, {}
  for _, dir in ipairs(APP_DIRS) do
    local ok, iter, d = pcall(hs.fs.dir, dir)
    if ok then
      for f in iter, d do
        if f:sub(-4) == ".app" and not seen[f] then
          seen[f] = true
          out[#out + 1] = { name = f:sub(1, -5), path = dir .. "/" .. f }
        end
      end
    end
  end
  table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
  appList = out
end

local function flatActions()
  if flatCache then return flatCache end
  local out = {}
  local function walk(node, crumb)
    for _, it in ipairs(node.items) do
      if type(it.menu) == "table" then
        walk(it.menu, (crumb ~= "" and crumb .. " ▸ " or "") .. it.name)
      elseif it.action and not it.app then
        out[#out + 1] = { name = it.name, crumb = crumb, action = it.action,
                          g = it.g or node.g }
      end
    end
  end
  walk(ROOT, "")
  flatCache = out
  return out
end

local function score(name, q)
  local n = name:lower()
  if n == q then return 0 end
  if n:sub(1, #q) == q then return 1 end
  for w in n:gmatch("%S+") do if w:sub(1, #q) == q then return 2 end end
  if n:find(q, 1, true) then return 3 end
  return nil
end

-- ── driver state ───────────────────────────────────────────────────────────
local canvas, keyTap, mouseTap
local trail  = {}
local rows   = {}
local sel    = 1
local scroll = 0
local filter = ""
local opening = false
local fileHits = {}
local fileToken = 0
local fileTimer

local function resolve(node)
  if type(node) == "function" then return node() end
  return node
end
local function searching() return #trail == 1 and filter ~= "" end
local function curWidth()  return (trail[#trail] and trail[#trail].width) or WIDTH end

local HDR_H = 22
local function rowHeight(r) return (r and r.kind == "header") and HDR_H or ROW_H end
local function selectable(r) return r and r.kind ~= "header" end

-- first non-header row from `from`, walking `dir`
local function nextSel(from, dir)
  local i = from
  while rows[i] and rows[i].kind == "header" do i = i + dir end
  return rows[i] and i or nil
end

-- ── rows ───────────────────────────────────────────────────────────────────
local function clampSel()
  if #rows == 0 then sel, scroll = 1, 0; return end
  if sel > #rows then sel = #rows end
  if sel < 1 then sel = 1 end
  if not selectable(rows[sel]) then
    sel = nextSel(sel, 1) or nextSel(sel, -1) or sel
  end
  if sel <= scroll then scroll = sel - 1 end
  if scroll < 0 then scroll = 0 end
  -- advance scroll until the selected row fits in the height budget
  local budget = bodyBudget()
  while scroll < sel - 1 do
    local y = 0
    for ri = scroll + 1, sel do y = y + rowHeight(rows[ri]) end
    if y <= budget then break end
    scroll = scroll + 1
  end
end

local function searchRows(q)
  q = q:lower()
  local cand = {}
  local function push(label, tag, action, image, glyph, s, grp)
    cand[#cand + 1] = { label = label, tag = tag, kind = "action", grp = grp,
      item = { action = action }, image = image, g = glyph, s = s, key = label:lower() }
  end
  for _, a in ipairs(flatActions()) do
    local s = score(a.name, q)
    if s then push(a.name, a.crumb, a.action, nil, a.g, s, "COMMANDS") end
  end
  for _, ap in ipairs(appList or {}) do
    local s = score(ap.name, q)
    if s then push(ap.name, nil, openPath(ap.path), fileIcon(ap.path), nil, s + 0.1, "APPLICATIONS") end
  end
  for _, st in ipairs(SETTINGS) do
    local s = score(st.name, q)
    if s then push(st.name .. " settings", nil, openURL(st.url), nil, NF.cog, s + 0.2, "SETTINGS") end
  end
  for _, fp in ipairs(fileHits[q] or {}) do
    local base = fp:match("([^/]+)$") or fp
    push(base, (fp:gsub("/[^/]*$", "")):gsub("^" .. HOME, "~"),
      openPath(fp), fileIcon(fp), nil, 4, "FILES")
  end

  -- bucket into titled groups; order groups by their best (lowest) score
  local groups, order = {}, {}
  for _, c in ipairs(cand) do
    local g = c.grp
    if not groups[g] then groups[g] = { best = c.s, rows = {} }; order[#order + 1] = g end
    groups[g].rows[#groups[g].rows + 1] = c
    if c.s < groups[g].best then groups[g].best = c.s end
  end
  table.sort(order, function(a, b) return groups[a].best < groups[b].best end)

  local out, seen, total = {}, {}, 0
  for _, g in ipairs(order) do
    local grp = groups[g]
    table.sort(grp.rows, function(a, b)
      if a.s ~= b.s then return a.s < b.s end
      return a.key < b.key
    end)
    local added = {}
    for _, c in ipairs(grp.rows) do
      if not seen[c.key] and total < 40 then
        seen[c.key] = true
        added[#added + 1] = c
        total = total + 1
      end
    end
    if #added > 0 then
      out[#out + 1] = { kind = "header", label = g }
      for _, c in ipairs(added) do out[#out + 1] = c end
    end
  end
  return out
end

local function buildRows()
  if searching() then
    rows = searchRows(filter)
    clampSel()
    return
  end
  local node = trail[#trail]
  local list = {}
  if #trail > 1 then
    list[#list + 1] = { label = "Back", kind = "back", g = NF.back }
  end
  local f = filter:lower()
  for _, it in ipairs(node.items) do
    if it.header then
      if f == "" then list[#list + 1] = { kind = "header", label = it.header } end
    else
      local hay = (it.name or it.chord or ""):lower()
      if f == "" or hay:find(f, 1, true) then
        list[#list + 1] = {
          label = it.chord or it.name,
          act   = it.act,
          kind  = it.menu and "menu" or (it.info and "info" or "action"),
          item  = it,
          image = it.image or (it.app and appIcon(it.app)) or nil,
          g     = (not it.app and not it.image and not it.info) and (it.g or node.g) or nil,
        }
      end
    end
  end
  -- drop a header with nothing under it (last row, or followed by another header)
  for i = #list, 1, -1 do
    if list[i].kind == "header" and (not list[i + 1] or list[i + 1].kind == "header") then
      table.remove(list, i)
    end
  end
  rows = list
  clampSel()
end

-- ── drawing ────────────────────────────────────────────────────────────────
local function txt(str, size, hex, font)
  return { type = "text", text = str, textFont = font or FONT,
           textSize = size, textColor = { hex = hex } }
end

local function draw()
  local W = curWidth()
  -- visible slice from `scroll`, capped by a pixel budget (rows vary in height)
  local budget = bodyBudget()
  local vis, vy = {}, 0
  for ri = scroll + 1, #rows do
    local rh = rowHeight(rows[ri])
    if vy + rh > budget and #vis > 0 then break end
    vis[#vis + 1] = { ri = ri, y = vy, h = rh }
    vy = vy + rh
  end
  local bodyH = (#rows == 0) and 34 or vy
  local h = HEADER_H + bodyH + PAD
  local scr = hs.screen.mainScreen():frame()
  canvas:frame({
    x = scr.x + math.floor((scr.w - W) / 2),
    y = scr.y + math.floor(scr.h * TOP_FRAC),
    w = W, h = h,
  })

  local els = {}
  local function add(e) els[#els + 1] = e end

  -- rounded panel + 2px border
  local rr = { xRadius = RADIUS, yRadius = RADIUS }
  add({ type = "rectangle", action = "fill", fillColor = { hex = C.base, alpha = 0.96 },
        roundedRectRadii = rr })
  add({ type = "rectangle", action = "stroke", strokeColor = { hex = C.accent },
        strokeWidth = BORDER_W, roundedRectRadii = rr,
        frame = { x = BORDER_W / 2, y = BORDER_W / 2, w = W - BORDER_W, h = h - BORDER_W } })

  -- prompt line: "<menu>…" until you type, then the query
  local prompt = filter ~= "" and filter
    or ((searching() and "Search" or trail[#trail].title) .. "…")
  local p = txt(prompt, 15, filter ~= "" and C.text or C.overlay)
  p.frame = { x = PAD, y = 12, w = W - 2 * PAD, h = 20 }
  add(p)
  add({ type = "segments", strokeColor = { hex = C.overlay }, strokeWidth = 1,
        coordinates = { { x = PAD, y = HEADER_H - 2 }, { x = W - PAD, y = HEADER_H - 2 } } })

  if #rows == 0 then
    local e = txt(searching() and "No Results" or "No matches", 13, C.overlay)
    e.frame = { x = PAD, y = HEADER_H + 12, w = W - 2 * PAD, h = 18 }
    add(e)
  end

  for _, v in ipairs(vis) do
    local r = rows[v.ri]
    local ry, rh = HEADER_H + v.y, v.h

    if r.kind == "header" then
      local hx = txt(r.label, 10, C.overlay)
      hx.frame = { x = PAD, y = ry + rh - 15, w = W - 2 * PAD, h = 12 }
      add(hx)
      add({ type = "segments", strokeColor = { hex = C.overlay, alpha = 0.35 }, strokeWidth = 1,
            coordinates = { { x = PAD, y = ry + rh - 1 }, { x = W - PAD, y = ry + rh - 1 } } })
    else
      local on = (v.ri == sel)
      local fg = on and C.accent or C.text
      if on then
        add({ type = "rectangle", action = "fill", fillColor = { hex = C.accent, alpha = 0.15 },
              frame = { x = 4, y = ry, w = W - 8, h = rh } })
      end

      local tx = PAD
      if r.image then
        add({ type = "image", image = r.image, imageScaling = "scaleProportionally",
              frame = { x = PAD, y = ry + (rh - 16) / 2, w = 16, h = 16 } })
        tx = PAD + GLYPH_W
      elseif r.g then
        local gl = txt(r.g, 14, on and C.accent or C.subtext)
        gl.frame = { x = PAD, y = ry + (rh - 18) / 2, w = GLYPH_W, h = 18 }
        add(gl)
        tx = PAD + GLYPH_W
      end

      if r.kind == "info" then
        local c = txt(r.label, 13, C.accent)
        c.frame = { x = tx, y = ry + (rh - 16) / 2, w = 120, h = 16 }
        add(c)
        local a = txt("→  " .. (r.act or ""), 13, on and C.accent or C.text)
        a.frame = { x = tx + 128, y = ry + (rh - 16) / 2, w = W - tx - 128 - PAD, h = 16 }
        a.textLineBreak = "truncateTail"
        add(a)
      else
        local l = txt(r.label, 14, fg)
        l.frame = { x = tx, y = ry + (rh - 18) / 2, w = W - tx - PAD - (r.tag and 96 or 0), h = 18 }
        l.textLineBreak = "truncateTail"
        add(l)
        if r.tag then
          local t = txt(r.tag, 11, C.overlay)
          t.frame = { x = W - PAD - 92, y = ry + (rh - 14) / 2, w = 92, h = 14 }
          t.textAlignment = "right"
          t.textLineBreak = "truncateHead"
          add(t)
        end
      end
    end
  end

  local shown = vis[#vis] and vis[#vis].ri or 0
  if scroll > 0 or shown < #rows then
    local more = txt(("%d/%d"):format(shown, #rows), 10, C.overlay)
    more.frame = { x = W - PAD - 54, y = 14, w = 54, h = 14 }
    more.textAlignment = "right"
    add(more)
  end

  canvas:replaceElements(els)
  canvas:show()
end

local function refresh() buildRows(); draw() end

local function enterLevel()
  filter, sel, scroll = "", 1, 0
  buildRows()
  local start = (rows[1] and rows[1].kind == "back") and 2 or 1
  sel = nextSel(start, 1) or 1
  clampSel()
  draw()
end

-- ── file search (async, debounced) ─────────────────────────────────────────
local function kickFileSearch()
  local q = filter
  if not searching() or #q < 2 or fileHits[q] then return end
  if fileTimer then fileTimer:stop() end
  fileTimer = hs.timer.doAfter(0.25, function()
    fileToken = fileToken + 1
    local tok = fileToken
    hs.task.new("/usr/bin/mdfind", function(_, out)
      if tok ~= fileToken then return end
      local hits = {}
      for line in (out or ""):gmatch("[^\n]+") do
        if #hits >= 6 then break end
        local noise = line:sub(-4) == ".app"
          or line:find("/%.") or line:find("^/System/")
          or line:find("^/Library/Caches/") or line:find("/Library/Developer/")
          or line:find("^/private/")
        if not noise and hs.fs.attributes(line) then hits[#hits + 1] = line end
      end
      fileHits[q] = hits
      if filter == q and searching() then buildRows(); draw() end
    end, { "-name", q }):start()
  end)
end

-- ── navigation ─────────────────────────────────────────────────────────────
local function goBack()
  if #trail > 1 then table.remove(trail); enterLevel() else M.close() end
end

local function activate()
  local r = rows[sel]
  if not r or r.kind == "header" then return end
  if r.kind == "back" then goBack(); return end
  if r.kind == "info" then M.close(); return end
  if r.kind == "menu" then
    trail[#trail + 1] = resolve(r.item.menu)
    enterLevel()
  elseif r.kind == "action" then
    local fn = r.item.action
    M.close()
    hs.timer.doAfter(0.12, function()
      local ok, err = pcall(fn)
      if not ok then hs.alert.show("menu: " .. tostring(err)) end
    end)
  end
end

local function move(d)
  if #rows == 0 then return end
  local i = sel
  for _ = 1, #rows do
    i = i + d
    if i < 1 then i = #rows elseif i > #rows then i = 1 end
    if selectable(rows[i]) then break end
  end
  sel = i
  refresh()
end

-- ── input ──────────────────────────────────────────────────────────────────
local function onKey(e)
  local ok, handled = pcall(function()
    local kc = e:getKeyCode()
    local fl = e:getFlags()
    if fl.cmd then return false end
    if kc == 53 then M.close(); return true end
    if kc == 36 or kc == 76 then activate(); return true end
    if kc == 126 then move(-1); return true end
    if kc == 125 then move(1); return true end
    if kc == 123 then goBack(); return true end
    if kc == 124 then
      if rows[sel] and rows[sel].kind == "menu" then activate() end
      return true
    end
    if kc == 51 then
      if filter ~= "" then
        filter = filter:sub(1, -2); sel, scroll = 1, 0
        kickFileSearch(); refresh()
      else
        goBack()
      end
      return true
    end
    local ch = e:getCharacters(true)
    if ch and #ch == 1 and ch:match("[%w%p ]") and not fl.ctrl and not fl.alt then
      filter = filter .. ch
      sel, scroll = 1, 0
      kickFileSearch()
      refresh()
      return true
    end
    return true
  end)
  if not ok then M.close(); return true end
  return handled
end

local function onMouseOutside(e)
  if not (canvas and canvas:isShowing()) then return false end
  local p, f = e:location(), canvas:frame()
  if p.x < f.x or p.x > f.x + f.w or p.y < f.y or p.y > f.y + f.h then M.close() end
  return false
end

local function rowAtY(cy)
  local yy = cy - HEADER_H
  if yy < 0 then return nil end
  local acc = 0
  for ri = scroll + 1, #rows do
    local rh = rowHeight(rows[ri])
    if yy >= acc and yy < acc + rh then
      return selectable(rows[ri]) and ri or nil
    end
    acc = acc + rh
  end
  return nil
end

-- ── lifecycle ──────────────────────────────────────────────────────────────
local function ensureCanvas()
  if canvas then return end
  canvas = hs.canvas.new({ x = 0, y = 0, w = WIDTH, h = 200 })
  canvas:level(hs.canvas.windowLevels.popUpMenu)
  canvas:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
  canvas:clickActivating(false)
  canvas:canvasMouseEvents(true, true, false, true)
  canvas:mouseCallback(function(_, ev, _, _, cy)
    local ri = rowAtY(cy)
    if not ri then return end
    if ev == "mouseMove" then
      if ri ~= sel then sel = ri; draw() end
    elseif ev == "mouseUp" then
      sel = ri; activate()
    end
  end)
  keyTap   = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, onKey)
  mouseTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, onMouseOutside)
end

function M.close()
  if keyTap then keyTap:stop() end
  if mouseTap then mouseTap:stop() end
  if fileTimer then fileTimer:stop() end
  if canvas then canvas:hide() end
  trail, filter, sel, scroll, opening = {}, "", 1, 0, false
end

function M.open()
  ensureCanvas()
  if not appList then scanApps() end
  fileHits = {}
  opening = true
  trail, filter, sel, scroll = { ROOT }, "", 1, 0
  -- wait for the Opt+Space chord to lift (ceiling ~1s) so the first keystrokes
  -- don't race the modifier release, then bring it up
  local tries = 0
  local function go()
    if not trail[1] then return end          -- closed before we came up
    local m = hs.eventtap.checkKeyboardModifiers()
    if (m.cmd or m.alt or m.ctrl or m.shift) and tries < 50 then
      tries = tries + 1
      hs.timer.doAfter(0.02, go)
      return
    end
    opening = false
    buildRows(); draw()
    keyTap:start(); mouseTap:start()
  end
  hs.timer.doAfter(0.02, go)
end

function M.toggle()
  if canvas and canvas:isShowing() then M.close()
  elseif not opening then M.open() end
end

function M.bind(mods, key)
  return hs.hotkey.bind(mods, key, M.toggle)
end

-- Fire a leaf action directly by its path, no UI:
--   require("menu").run("Capture", "Selection → clipboard")
function M.run(...)
  local node = ROOT
  for _, name in ipairs({ ... }) do
    local found
    for _, it in ipairs(node.items) do
      if it.name == name then found = it; break end
    end
    if not found then hs.alert.show("menu: no '" .. name .. "'"); return end
    if found.menu then
      node = resolve(found.menu)
    elseif found.action then
      local ok, err = pcall(found.action)
      if not ok then hs.alert.show("menu: " .. tostring(err)) end
      return
    end
  end
end

-- Open with a search query pre-filled:  require("menu").openWith("brave")
function M.openWith(q)
  M.open()
  hs.timer.doAfter(0.28, function()
    if not trail[1] then return end
    filter, sel, scroll = q, 1, 0
    kickFileSearch(); buildRows(); draw()
  end)
end

-- Open straight to a submenu:  require("menu").openAt("Apps", "Builtin Apps")
function M.openAt(...)
  local path = { ... }
  M.open()
  hs.timer.doAfter(0.28, function()
    for _, name in ipairs(path) do
      local node = trail[#trail]
      if not node then return end
      for _, it in ipairs(node.items) do
        if it.name == name and it.menu then
          trail[#trail + 1] = resolve(it.menu)
          break
        end
      end
    end
    enterLevel()
  end)
end

return M
