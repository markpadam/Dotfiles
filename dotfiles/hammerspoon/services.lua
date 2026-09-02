-- services.lua — small always-on background helpers that feed SketchyBar and
-- add Omarchy-style polish:
--
--   • brew update count           -> hsq.updates   (poll every 3h + on wake)
--   • now playing (Spotify/Music) -> hsq.media     (poll every 5s)
--   • screen recording control    -> hsq.rec       (screencapture -v, tracked)
--   • window-spawn flash          -> accent outline that fades on new windows
--   • wallpaper rotation on unlock (opt-in: services.wallpaperRotate = true)

local theme = require("theme")

local M = {}
local HOME = os.getenv("HOME")
local SB   = "/opt/homebrew/bin/sketchybar"
local BREW = "/opt/homebrew/bin/brew"

M.wallpaperRotate = false   -- rotate to a random wallpaper on unlock
M.windowFlash     = false   -- accent outline that fades in on every new window

local upTimer, mediaTimer, wake, wf, recTask, startedAt

local function sbSet(item, ...)
  local a = { "--set", item }
  for _, v in ipairs({ ... }) do a[#a + 1] = v end
  hs.task.new(SB, nil, a):start()
end

-- ── brew updates ───────────────────────────────────────────────────────────
local function checkUpdates()
  hs.task.new("/bin/sh", function(_, out)
    local n = tonumber((out or ""):match("%d+")) or 0
    sbSet("hsq.updates", "icon=\u{f0ed}", "label=" .. n, "drawing=" .. (n > 0 and "on" or "off"))
  end, { "-c", BREW .. " outdated --quiet | wc -l | tr -d ' '" }):start()
end
M.checkUpdates = checkUpdates

function M.runUpgrade()
  hs.task.new("/usr/bin/open", nil, {
    "-na", "Ghostty", "--args", "--title=brew upgrade",
    "-e", "zsh", "-lc", "brew upgrade; brew cleanup; echo; echo done; exec zsh -l",
  }):start()
end

-- ── now playing ────────────────────────────────────────────────────────────
local function nowPlaying()
  local label
  local function try(mod, st)
    if not (mod.isRunning and mod.isRunning()) then return end
    local ok, state = pcall(mod.getPlaybackState)
    if not ok or state ~= st then return end
    local t = select(2, pcall(mod.getCurrentTrack))
    local a = select(2, pcall(mod.getCurrentArtist))
    if t then label = a and (a .. " – " .. t) or t end
  end
  try(hs.spotify, hs.spotify.state_playing)
  if not label then try(hs.itunes, hs.itunes.state_playing) end
  if label then
    if #label > 48 then label = label:sub(1, 47) .. "…" end
    sbSet("hsq.media", "icon=\u{f001}", "label=" .. label, "drawing=on")
  else
    sbSet("hsq.media", "drawing=off")
  end
end

-- ── screen recording ───────────────────────────────────────────────────────
function M.recording() return recTask ~= nil and recTask:isRunning() end

function M.startRecording()
  if M.recording() then return end
  local out = ("%s/Desktop/Recording %s.mov"):format(HOME, os.date("%Y-%m-%d at %H.%M.%S"))
  recTask = hs.task.new("/usr/sbin/screencapture", function()
    recTask = nil
    sbSet("hsq.rec", "drawing=off")
  end, { "-v", out })
  recTask:start()
  sbSet("hsq.rec", "icon=\u{f111}", "drawing=on")
  hs.alert.show("\u{f111}  Recording — pick Stop recording to finish")
end

function M.stopRecording()
  if not M.recording() then return end
  hs.execute("/bin/kill -INT " .. recTask:pid())   -- SIGINT finalises the file
end

function M.toggleRecording()
  if M.recording() then M.stopRecording() else M.startRecording() end
end

-- ── window-spawn flash ─────────────────────────────────────────────────────
local function flash(win)
  if not (M.windowFlash and win and startedAt and (hs.timer.secondsSinceEpoch() - startedAt) > 8) then return end
  local ok, f = pcall(function() return win:frame() end)
  if not ok or not f or f.w < 40 then return end
  local c = theme.current()
  local cv = hs.canvas.new(f)
  cv:level(hs.canvas.windowLevels.overlay)
  cv:behaviorAsLabels({ "canJoinAllSpaces" })
  cv[1] = {
    type = "rectangle", action = "stroke", strokeColor = { hex = c.accent }, strokeWidth = 3,
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    frame = { x = 2, y = 2, w = f.w - 4, h = f.h - 4 },
  }
  cv:alpha(0.85):show()
  local a = 0.85
  local step
  step = hs.timer.doEvery(0.03, function()
    a = a - 0.11
    if a <= 0 then step:stop(); cv:delete() else cv:alpha(a) end
  end)
  hs.timer.doAfter(0.4, function() if step then step:stop() end; if cv then cv:delete() end end)
end

-- ── wallpaper rotation ─────────────────────────────────────────────────────
local function rotateWallpaper()
  if not M.wallpaperRotate then return end
  local dir = HOME .. "/Pictures/Wallpapers"
  local pics = {}
  local ok, iter, d = pcall(hs.fs.dir, dir)
  if ok then
    for f in iter, d do
      if f:match("%.[jJ][pP][eE]?[gG]$") or f:match("%.[pP][nN][gG]$") then
        pics[#pics + 1] = dir .. "/" .. f
      end
    end
  end
  if #pics == 0 then return end
  local pick = pics[math.random(#pics)]
  hs.osascript.applescript(
    ('tell application "System Events" to tell every desktop to set picture to %q'):format(pick))
end

-- ── lifecycle ──────────────────────────────────────────────────────────────
function M.start()
  M.stop()
  startedAt = hs.timer.secondsSinceEpoch()
  math.randomseed(os.time())

  checkUpdates()
  upTimer = hs.timer.new(3 * 60 * 60, checkUpdates, true):start()

  nowPlaying()
  mediaTimer = hs.timer.new(5, nowPlaying, true):start()

  wake = hs.caffeinate.watcher.new(function(ev)
    if ev == hs.caffeinate.watcher.screensDidWake then checkUpdates() end
    if ev == hs.caffeinate.watcher.screensDidUnlock then rotateWallpaper() end
  end)
  wake:start()

  if M.windowFlash then
    wf = hs.window.filter.new(true):setOverrideFilter({ visible = true })
    wf:subscribe(hs.window.filter.windowCreated, function(w) flash(w) end)
  end
end

function M.stop()
  for _, t in ipairs({ upTimer, mediaTimer }) do if t then t:stop() end end
  if wake then wake:stop(); wake = nil end
  if wf then wf:unsubscribeAll(); wf = nil end
  upTimer, mediaTimer = nil, nil
end

return M
