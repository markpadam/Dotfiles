-- webapp.lua — Omarchy's web2app: run a website as its own chrome-less window
-- with its own profile, launchable from the Opt+Space menu.
--
-- Registry: ~/.local/share/omachy/webapps.json  (not tracked)
-- Profiles: ~/.local/share/omachy/webapp-profiles/<slug>
--
--   Opt+Space -> Install -> Add web app…   (prompts for name + URL)

local M = {}
local HOME  = os.getenv("HOME")
local DIR   = HOME .. "/.local/share/omachy"
local STORE = DIR .. "/webapps.json"

-- Chromium-family browser for --app mode; Safari is the no-app-mode fallback.
local BROWSERS = {
  { bid = "com.brave.Browser",  name = "Brave Browser" },
  { bid = "com.google.Chrome",  name = "Google Chrome" },
  { bid = "com.microsoft.edgemac", name = "Microsoft Edge" },
}

local function browser()
  for _, b in ipairs(BROWSERS) do
    if hs.application.pathForBundleID(b.bid) then return b end
  end
end

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

local function slugify(s)
  return (s:lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", ""))
end

function M.launch(app)
  local b = browser()
  if b then
    local profile = ("%s/webapp-profiles/%s"):format(DIR, app.slug)
    hs.execute(("mkdir -p %q"):format(profile))
    hs.task.new("/usr/bin/open", nil, {
      "-na", b.name, "--args",
      "--app=" .. app.url,
      "--user-data-dir=" .. profile,
      "--no-first-run",
    }):start()
  else
    hs.execute("open " .. ("%q"):format(app.url))   -- Safari, plain tab
  end
end

function M.add()
  local ok1, name = hs.dialog.textPrompt("New web app", "Name", "", "Next", "Cancel")
  if ok1 ~= "Next" or name == "" then return end
  local ok2, url = hs.dialog.textPrompt("New web app", "URL for " .. name,
    "https://", "Add", "Cancel")
  if ok2 ~= "Add" or not url:match("^https?://") then
    if ok2 == "Add" then hs.alert.show("web app: URL must start with http(s)://") end
    return
  end
  local list = load()
  list[#list + 1] = { name = name, url = url, slug = slugify(name) }
  save(list)
  hs.alert.show("\u{f0ac}  Added " .. name)
end

function M.remove(slug)
  local list, out = load(), {}
  for _, a in ipairs(list) do if a.slug ~= slug then out[#out + 1] = a end end
  save(out)
end

function M.menu()
  local list = load()
  local items = {}
  for _, a in ipairs(list) do
    items[#items + 1] = { name = a.name, g = "\u{f0ac}", action = function() M.launch(a) end }
  end
  if #list > 0 then items[#items + 1] = { header = "" } end
  items[#items + 1] = { name = "Add web app…", g = "\u{f0fe}", action = M.add }
  if #list > 0 then
    local rm = {}
    for _, a in ipairs(list) do
      rm[#rm + 1] = { name = a.name, action = function()
        M.remove(a.slug); hs.alert.show("Removed " .. a.name)
      end }
    end
    items[#items + 1] = { name = "Remove web app", g = "\u{f014}", menu = { title = "Remove", items = rm } }
  end
  return { title = "Web Apps", items = items }
end

return M
