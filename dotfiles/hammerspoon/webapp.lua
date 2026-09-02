-- webapp.lua — websites as quick-launch entries in Opt+Space -> Web Apps.
--
-- An entry launches its matching **Safari "Add to Dock" web app** if one exists
-- (~/Applications/*.app, com.apple.Safari.WebApp.* — frameless, and it uses
-- iCloud Keychain autofill). If not, it just opens in Safari — from there,
-- File ▸ Add to Dock makes it a real app. A "·" in the menu row means "no
-- dedicated app yet, opens as a tab".
--
-- Registry: ~/.local/share/omachy/webapps.json   (not tracked)
-- Favicons: ~/.local/share/omachy/webapp-icons/<slug>.png
--
-- Each entry: { name, url, slug, source }. source = "homepage" marks one
-- auto-synced from the home dashboard's /api/services (gethomepage.dev — see
-- M.syncHomepage, runs on start + every 6h); nil = added by hand.

local M = {}
local HOME  = os.getenv("HOME")
local DIR   = HOME .. "/.local/share/omachy"
local STORE = DIR .. "/webapps.json"
local ICONS = DIR .. "/webapp-icons"
local HOMEPAGE = "https://homepage.theadamsfamily.uk/"

-- ── store ─────────────────────────────────────────────────────────────────
local function load()
  local f = io.open(STORE, "r")
  if not f then return {} end
  local ok, d = pcall(hs.json.decode, f:read("*a")); f:close()
  return (ok and type(d) == "table") and d or {}
end

local function save(list)
  hs.execute(("mkdir -p %q"):format(DIR))
  local f = io.open(STORE, "w")
  if f then f:write(hs.json.encode(list)); f:close() end
end

local function slugify(s) return (s:lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")) end
local function domain(url) return ((url or ""):match("^https?://([^/]+)") or (url or "")):gsub("^www%.", "") end

-- ── Safari "Add to Dock" web apps ─────────────────────────────────────────
local safariCache, safariAt
function M.safariApps()
  local now = hs.timer.secondsSinceEpoch()
  if safariCache and now - safariAt < 30 then return safariCache end
  local out = {}
  local dir = HOME .. "/Applications"
  local ok, iter, d = pcall(hs.fs.dir, dir)
  if ok then
    for f in iter, d do
      if f:sub(-4) == ".app" then
        local pl = select(2, pcall(hs.plist.read, dir .. "/" .. f .. "/Contents/Info.plist"))
        local bid = type(pl) == "table" and pl.CFBundleIdentifier
        if type(bid) == "string" and bid:find("com.apple.Safari.WebApp", 1, true) == 1 then
          out[#out + 1] = {
            name = pl.CFBundleName or f:sub(1, -5),
            url  = pl.Manifest and pl.Manifest.start_url,
            path = dir .. "/" .. f,
          }
        end
      end
    end
  end
  safariCache, safariAt = out, now
  return out
end

-- strip a "(5) " unread count and a " | Site" / " - Site" tail
local function cleanName(s)
  s = (s or ""):gsub("^%s*%(%d+%)%s*", ""):gsub("%s*[|%-–—][^|%-–—]*$", "")
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function safariAppFor(entry)
  local en, ed = entry.name:lower(), domain(entry.url)
  for _, s in ipairs(M.safariApps()) do
    local sn = cleanName(s.name):lower()
    if en == sn or en:find(sn, 1, true) or sn:find(en, 1, true) or ed == domain(s.url) then
      return s
    end
  end
end

-- ── favicons ──────────────────────────────────────────────────────────────
local function iconUrl(url, hp)
  if type(hp) == "string" and hp ~= "" then
    if hp:match("^https?://") then return hp end
    local png = hp:match("^(.+)%.svg$") and (hp:match("^(.+)%.svg$") .. ".png") or hp
    if png:match("%.png$") then
      return "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/" .. png
    end
  end
  return ("https://www.google.com/s2/favicons?sz=64&domain=%s"):format(domain(url))
end

local function fetchIcon(slug, url, hp)
  hs.execute(("mkdir -p %q"):format(ICONS))
  hs.task.new("/usr/bin/curl", nil, {
    "-sL", "--max-time", "8", "-o", ("%s/%s.png"):format(ICONS, slug), iconUrl(url, hp),
  }):start()
end

local iconCache = {}
local function iconFor(slug)
  if iconCache[slug] == nil then
    local p = ("%s/%s.png"):format(ICONS, slug)
    iconCache[slug] = (hs.fs.attributes(p) and hs.image.imageFromPath(p)) or false
  end
  return iconCache[slug] or nil
end

-- ── launch / add / remove ─────────────────────────────────────────────────
local function openInSafari(url)
  hs.osascript.applescript(
    ('tell application "Safari"\nactivate\nmake new document with properties {URL:%q}\nend tell'):format(url))
end

function M.launch(app)
  local s = safariAppFor(app)
  if s then hs.task.new("/usr/bin/open", nil, { s.path }):start()
  else openInSafari(app.url) end
end

-- ── sync from the home dashboard ──────────────────────────────────────────
function M.syncHomepage(cb)
  hs.task.new("/usr/bin/curl", function(_, body)
    local ok, groups = pcall(hs.json.decode, body or "")
    if not ok or type(groups) ~= "table" then if cb then cb(false, 0) end; return end

    local svc, order = {}, {}
    for _, grp in ipairs(groups) do
      for _, s in ipairs(grp.services or {}) do
        local url = s.href
        if type(url) == "string" and url:match("^https?://") and not svc[url] then
          svc[url] = { name = s.name or domain(url), icon = s.icon }
          order[#order + 1] = url
        end
      end
    end

    local list, kept, changed = load(), {}, false
    for _, a in ipairs(list) do
      if a.source ~= "homepage" then kept[#kept + 1] = a
      elseif svc[a.url] then kept[#kept + 1] = a; svc[a.url] = nil
      else changed = true end
    end
    for _, url in ipairs(order) do
      local s = svc[url]
      if s then
        local slug = "hp-" .. slugify(s.name)
        kept[#kept + 1] = { name = s.name, url = url, slug = slug, source = "homepage" }
        fetchIcon(slug, url, s.icon)
        changed = true
      end
    end
    if changed then save(kept) end
    if cb then cb(changed, #order) end
  end, { "-sL", "--max-time", "12", HOMEPAGE .. "api/services" }):start()
end

-- ── menu ──────────────────────────────────────────────────────────────────
local function row(a)
  local img = iconFor(a.slug)
  if not img then fetchIcon(a.slug, a.url) end
  return {
    name = a.name .. (safariAppFor(a) and "" or "  ·"),   -- trailing dot = no dedicated Safari app, opens as a tab
    image = img, g = img and nil or "\u{f0ac}",
    action = function() M.launch(a) end,
  }
end

-- Just a launcher — web apps are made / removed by hand in Safari ▸ File ▸
-- Add to Dock. The home dashboard's services are auto-synced (open as a Safari
-- app if you've made one, else a Safari tab).
function M.menu()
  local homepage, dash = {}, nil
  for _, a in ipairs(load()) do
    if a.slug == "home-dashboard" then dash = a
    elseif a.source == "homepage" then homepage[#homepage + 1] = a end
  end

  local items = {}

  if dash or #homepage > 0 then
    local sub = {}
    if dash then sub[#sub + 1] = row(dash) end
    sub[#sub + 1] = { name = "Sync now", g = "\u{f021}", action = function()
      M.syncHomepage(function(ch, n) hs.alert.show(("Home dashboard: %d services%s")
        :format(n, ch and ", updated" or "")) end)
    end }
    if #homepage > 0 then sub[#sub + 1] = { header = "SERVICES" } end
    for _, a in ipairs(homepage) do sub[#sub + 1] = row(a) end
    items[#items + 1] = { name = "Home Dashboard", image = dash and iconFor(dash.slug) or nil,
      g = "\u{f0ac}", menu = { title = "Home Dashboard", items = sub } }
    items[#items + 1] = { header = "SAFARI WEB APPS" }
  end

  for _, s in ipairs(M.safariApps()) do
    items[#items + 1] = {
      name = cleanName(s.name), image = hs.image.imageFromPath(s.path),
      action = function() hs.task.new("/usr/bin/open", nil, { s.path }):start() end,
    }
  end
  if #items == 0 then
    items[1] = { name = "No Safari web apps — Safari ▸ File ▸ Add to Dock", action = function() end }
  end
  return { title = "Web Apps", items = items }
end

-- ── seed + periodic sync ──────────────────────────────────────────────────
function M.start()
  local list, have = load(), {}
  for _, a in ipairs(list) do have[a.slug] = true end
  if not have["home-dashboard"] then
    list[#list + 1] = { name = "Home Dashboard", url = HOMEPAGE, slug = "home-dashboard" }
    fetchIcon("home-dashboard", HOMEPAGE)
    save(list)
  end
  M.syncHomepage()
  M._timer = hs.timer.new(6 * 60 * 60, function() M.syncHomepage() end, true):start()
end

return M
