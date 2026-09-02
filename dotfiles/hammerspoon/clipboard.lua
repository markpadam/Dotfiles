-- clipboard.lua — a small clipboard history (Omarchy ships clipse).
--
-- Watches the pasteboard, keeps the last 60 text entries in
-- ~/.cache/omachy/clipboard.json (survives a reload), and exposes them as menu
-- rows. Picking one copies it and pastes into the frontmost app.
--
-- Surfaced as Opt+Space -> Clipboard, or straight there on Ctrl+Alt+V
-- (require("menu").openAt("Clipboard")).

local M = {}
local HOME  = os.getenv("HOME")
local STORE = HOME .. "/.cache/omachy/clipboard.json"
local MAX   = 60

local hist = {}
local watcher, poll, lastCount

local function save()
  hs.execute(("mkdir -p %q"):format(HOME .. "/.cache/omachy"))
  local f = io.open(STORE, "w")
  if f then f:write(hs.json.encode(hist)); f:close() end
end

local function load()
  local f = io.open(STORE, "r")
  if not f then return end
  local ok, data = pcall(hs.json.decode, f:read("*a"))
  f:close()
  if ok and type(data) == "table" then hist = data end
end

local function record(t)
  if not t or type(t) ~= "string" or t:match("^%s*$") or #t > 20000 then return end
  for i, v in ipairs(hist) do if v == t then table.remove(hist, i) break end end
  table.insert(hist, 1, t)
  while #hist > MAX do table.remove(hist) end
  save()
end

local function check()
  local c = hs.pasteboard.changeCount()
  if c == lastCount then return end
  lastCount = c
  record(hs.pasteboard.getContents())
end

function M.start()
  load()
  lastCount = hs.pasteboard.changeCount()
  if hs.pasteboard.watcher then
    watcher = hs.pasteboard.watcher.new(function(t) record(t); lastCount = hs.pasteboard.changeCount() end)
    watcher:start()
  else
    poll = hs.timer.new(0.8, check, true):start()
  end
end

function M.stop()
  if watcher then watcher:stop(); watcher = nil end
  if poll then poll:stop(); poll = nil end
end

-- menu rows: newest first, first line shown, paste on pick
function M.rows()
  local out = {}
  for _, t in ipairs(hist) do
    local label = (t:match("[^\n]*") or t):gsub("%s+$", "")
    if label == "" then label = "⏎ " .. (t:gsub("%s+", " "):sub(1, 48)) end
    if #label > 62 then label = label:sub(1, 61) .. "…" end
    out[#out + 1] = {
      name = label,
      action = function()
        hs.pasteboard.setContents(t)
        lastCount = hs.pasteboard.changeCount()
        hs.timer.doAfter(0.12, function() hs.eventtap.keyStroke({ "cmd" }, "v", 0) end)
      end,
    }
  end
  if #out == 0 then out[1] = { name = "Clipboard history empty", action = function() end } end
  return out
end

function M.clear() hist = {}; save(); hs.alert.show("Clipboard history cleared") end

return M
