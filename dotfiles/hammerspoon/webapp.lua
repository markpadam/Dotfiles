-- webapp.lua — websites as quick-launch entries in Opt+Space -> Web Apps.
--
-- Opens frameless via Brave's `--app=<url>` (no tab strip, no toolbar). It runs
-- in Brave's DEFAULT profile — deliberately, no `--user-data-dir` — so your
-- Brave logins, autofill and built-in password manager all work. Falls back to
-- `open <url>` in the default browser if Brave isn't installed.
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
local function domain(url) return (url:match("^https?://([^/]+)") or url) end

-- ── favicons ──────────────────────────────────────────────────────────────
-- prefer the dashboard's curated icon (homarr dashboard-icons), else the site's
-- favicon via Google's service.
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
function M.launch(app)
  if hs.application.pathForBundleID("com.brave.Browser") then
    hs.task.new("/usr/bin/open", nil,
      { "-na", "Brave Browser", "--args", "--app=" .. app.url }):start()
  else
    hs.execute("open " .. ("%q"):format(app.url))
  end
end

function M.add()
  local ok1, name = hs.dialog.textPrompt("New web app", "Name", "", "Next", "Cancel")
  if ok1 ~= "Next" or name == "" then return end
  local ok2, url = hs.dialog.textPrompt("New web app", "URL for " .. name, "https://", "Add", "Cancel")
  if ok2 ~= "Add" or not url:match("^https?://") then
    if ok2 == "Add" then hs.alert.show("web app: URL must start with http(s)://") end
    return
  end
  local slug = slugify(name)
  local list = load()
  list[#list + 1] = { name = name, url = url, slug = slug }
  save(list); fetchIcon(slug, url)
  hs.alert.show("\u{f0ac}  Added " .. name)
end

function M.remove(slug)
  local out = {}
  for _, a in ipairs(load()) do if a.slug ~= slug then out[#out + 1] = a end end
  save(out); iconCache[slug] = nil
end

-- ── sync from the home dashboard ──────────────────────────────────────────
-- Read homepage's /api/services (gethomepage.dev) and keep the
-- `source = "homepage"` entries in step with it — add new services, drop ones
-- that have gone. Hand-added entries are never touched.
function M.syncHomepage(cb)
  hs.task.new("/usr/bin/curl", function(_, body)
    local ok, groups = pcall(hs.json.decode, body or "")
    if not ok or type(groups) ~= "table" then if cb then cb(false, 0) end; return end

    local svc, order = {}, {}         -- url -> { name, icon }
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
      else changed = true end                          -- gone from the dashboard
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
  return { name = a.name, image = img, g = img and nil or "\u{f0ac}",
           action = function() M.launch(a) end }
end

function M.menu()
  local list = load()
  local mine, homepage, dash = {}, {}, nil
  for _, a in ipairs(list) do
    if a.slug == "home-dashboard" then dash = a
    elseif a.source == "homepage" then homepage[#homepage + 1] = a
    else mine[#mine + 1] = a end
  end

  local items = {
    { name = "Add web app…",        g = "\u{f0fe}", action = M.add },
    { name = "Sync home dashboard",  g = "\u{f021}", action = function()
      M.syncHomepage(function(ch, n) hs.alert.show(("Home dashboard: %d services%s")
        :format(n, ch and ", updated" or "")) end)
    end },
  }

  -- Home dashboard + its synced services, tucked in one submenu
  if dash or #homepage > 0 then
    local sub = {}
    if dash then sub[#sub + 1] = row(dash); sub[#sub + 1] = { header = "SERVICES" } end
    for _, a in ipairs(homepage) do sub[#sub + 1] = row(a) end
    items[#items + 1] = { name = "Home Dashboard", image = dash and iconFor(dash.slug) or nil,
      g = "\u{f0ac}", menu = { title = "Home Dashboard", items = sub } }
  end

  if #mine > 0 then items[#items + 1] = { header = "" } end
  for _, a in ipairs(mine) do items[#items + 1] = row(a) end

  if #list > 0 then
    local rm = {}
    for _, a in ipairs(list) do
      rm[#rm + 1] = { name = a.name .. (a.source == "homepage" and "  (auto)" or ""),
        action = function() M.remove(a.slug); hs.alert.show("Removed " .. a.name) end }
    end
    items[#items + 1] = { header = "" }
    items[#items + 1] = { name = "Remove web app", g = "\u{f014}", menu = { title = "Remove", items = rm } }
  end
  return { title = "Web Apps", items = items }
end

-- ── seed + periodic sync ──────────────────────────────────────────────────
function M.start()
  local list, have = load(), {}
  for _, a in ipairs(list) do have[a.slug] = true end
  for _, seed in ipairs({
    { name = "Messenger",      url = "https://www.messenger.com/", slug = "messenger" },
    { name = "Home Dashboard", url = HOMEPAGE,                     slug = "home-dashboard" },
  }) do
    if not have[seed.slug] then
      list[#list + 1] = seed
      fetchIcon(seed.slug, seed.url)
    end
  end
  save(list)
  M.syncHomepage()
  M._timer = hs.timer.new(6 * 60 * 60, function() M.syncHomepage() end, true):start()
end

return M
