-- OctoScanner
-- Core.lua - chat capture, storage, filters, whisper templates, slash commands.

OCS = OCS or {}

-- Vanilla ADDON_LOADED identifies the addon by its installed folder name.
local ADDON_NAME = "OctoScanner"

-- One axis decides the tab: what the sender wants. Every section has the same
-- three tabs. What the line is about, such as arena or profession services, is
-- kept on the row as row.kind and is a filter, not a tab.
OCS.BUCKETS = {
	"PVE_LFM", "PVE_LFG", "PVE_UNSURE",
	"PVP_LFM", "PVP_LFG", "PVP_UNSURE",
	"TRADE_WTS", "TRADE_WTB", "TRADE_UNSURE",
	-- Guild recruitment has one list and no intent split: a guild that
	-- recruits and a player who wants a guild are looking for each other.
	"GUILD_ALL",
}

OCS.SECTIONS = {
	{ id = "PVE", label = "PvE", buckets = { "PVE_LFM", "PVE_LFG", "PVE_UNSURE" } },
	{ id = "PVP", label = "PvP", buckets = { "PVP_LFM", "PVP_LFG", "PVP_UNSURE" } },
	{ id = "TRADE", label = "Trade", buckets = { "TRADE_WTS", "TRADE_WTB", "TRADE_UNSURE" } },
	{ id = "GUILD", label = "Guild", buckets = { "GUILD_ALL" } },
}
OCS.BUCKET_SECTION = {}
OCS.BUCKET_LABEL = {
	PVE_LFM = "LFM", PVE_LFG = "LFG", PVE_UNSURE = "Unsure",
	PVP_LFM = "LFM", PVP_LFG = "LFG", PVP_UNSURE = "Unsure",
	TRADE_WTS = "WTS", TRADE_WTB = "WTB", TRADE_UNSURE = "Unsure",
	GUILD_ALL = "Guild",
}

-- One whisper line per section and intent. Unsure shares the line of the LFM
-- side of its section, because an unsure row is most often a recruit post.
OCS.WHISPER_SLOTS = {
	{ key = "pveLfm", label = "PvE LFM and Unsure - they lead a group, you ask for a spot" },
	{ key = "pveLfg", label = "PvE LFG - they look for a group, you offer a spot" },
	{ key = "pvpLfm", label = "PvP LFM and Unsure - they lead an arena, battleground or world PvP group" },
	{ key = "pvpLfg", label = "PvP LFG - they look for PvP, you offer a spot" },
	{ key = "tradeWts", label = "Trade WTS and Unsure - they sell or offer, you buy" },
	{ key = "tradeWtb", label = "Trade WTB - they buy or want, you sell" },
	{ key = "guild", label = "Guild - recruitment posts, you ask about joining" },
}

OCS.WHISPER_BUCKET_SLOT = {
	PVE_LFM = "pveLfm", PVE_UNSURE = "pveLfm", PVE_LFG = "pveLfg",
	PVP_LFM = "pvpLfm", PVP_UNSURE = "pvpLfm", PVP_LFG = "pvpLfg",
	TRADE_WTS = "tradeWts", TRADE_UNSURE = "tradeWts", TRADE_WTB = "tradeWtb",
	GUILD_ALL = "guild",
}

OCS.KIND_LABEL = {
	ARENA = "Arena", BG = "Battleground",
	PVP_OTHER = "Other PvP", GUILD = "Guild",
	PROF = "Profession",
	TRADE_OTHER = "Other Trade", OTHER = "Other",

	TRANSMOG = "Transmog", MOUNT = "Mount", RECIPE = "Recipe",
	 CONSUM = "Consumable", GEAR = "Gear",

}
-- Filled at ingest, so a pack activity shows its short name in the filter.
OCS.KIND_NAMES = {}

function OCS.KindName(kind)
	if not kind then
		return "?"
	end
	return OCS.KIND_LABEL[kind] or OCS.KIND_NAMES[kind] or kind
end

-- The tab that holds a given intent inside a given section.
function OCS.BucketFor(section, intent)
	if section == "TRADE" then
		if intent == "WTS" or intent == "LFM" then
			return "TRADE_WTS"
		end
		if intent == "WTB" or intent == "WTT" or intent == "LFG" then
			return "TRADE_WTB"
		end
		return "TRADE_UNSURE"
	end
	-- One list, whatever the intent says.
	if section == "GUILD" then
		return "GUILD_ALL"
	end
	local prefix = (section == "PVP") and "PVP_" or "PVE_"
	if intent == "LFM" or intent == "LFG" then
		return prefix .. intent
	end
	return prefix .. "UNSURE"
end

-- LFM, LFG, UNSURE, WTS or WTB, without the section prefix.
function OCS.IntentOf(bucket)
	local b = tostring(bucket or "")
	return OCS.Match(b, "_(%u+)$") or b
end

-- Content types present in the rows of one section, for the filter panel.
function OCS.KindList(section)
	local seen, out = {}, {}
	for i = 1, OCS.Len(OCS.SECTIONS) do
		local s = OCS.SECTIONS[i]
		if s.id == section then
			for j = 1, OCS.Len(s.buckets) do
				local list = (OCS_DB and OCS_DB.rows and OCS_DB.rows[s.buckets[j]]) or {}
				for k = 1, OCS.Len(list) do
					local kind = list[k].kind
					if kind and not seen[kind] then
						seen[kind] = true
						table.insert(out, kind)
					end
				end
			end
		end
	end
	table.sort(out)
	return out
end

-- Content types in one section with a row count each, most common first.
-- Every activity a section can hold, whether or not a row is in the list.
OCS.BASE_KINDS = {
	PVP = { "BG", "PVP_OTHER" },
	TRADE = { "PROF", "MOUNT", "RECIPE", "CONSUM", "GEAR", "TRADE_OTHER" },
	PVE = { "OTHER" },
}

OCS.KIND_CATEGORIES = {
	{ id = "CAT_DGN", label = "Dungeon", targetKind = "DGN",
	  kinds = { DGN = true } },
	{ id = "CAT_RAID", label = "Raid", targetKind = "RAID",
	  kinds = { RAID = true } },
	{ id = "CAT_WB", label = "World Boss", targetKind = "WB",
	  kinds = { WB = true } },
}

OCS.KIND_CATEGORY = {}
for i = 1, OCS.Len(OCS.KIND_CATEGORIES) do
	OCS.KIND_CATEGORY[OCS.KIND_CATEGORIES[i].id] = OCS.KIND_CATEGORIES[i]
end

-- The category one activity id belongs to, nil when it stands alone.
function OCS.CategoryForKind(kind)
	for i = 1, OCS.Len(OCS.KIND_CATEGORIES) do
		if kind and OCS.KIND_CATEGORIES[i].kinds[kind] then
			return OCS.KIND_CATEGORIES[i]
		end
	end
	return nil
end

function OCS.KindFilterText(f)
	f = f or (OCS_DB and OCS_DB.filter)
	local kind = (f and f.kind) or "ALL"
	if kind == "ALL" then
		return "All activities"
	end
	local cat = OCS.KIND_CATEGORY[kind]
	if not cat then
		return OCS.KindName(kind)
	end
	local target = (f and f.target) or "ALL"
	if target == "ALL" then
		return cat.label
	end
	if cat.lead then
		for i = 1, OCS.Len(cat.lead) do
			if cat.lead[i].value == target then
				return cat.label .. ": " .. cat.lead[i].label
			end
		end
	end
	return cat.label .. ": " .. target
end

-- A count is there to tell you what is in the list you are looking at, so it
-- is taken from the open tab alone. On PvE LFG the Raid count is the number of
-- raid posts in LFG, not in the whole section.
local function countedBucket(id)
	local mode = OCS.GetMode and OCS.GetMode()
	if mode then
		return id == mode
	end
	return string.find(id, "_UNSURE$") == nil
end

function OCS.TargetCounts(section, category)
	local out = {}
	for i = 1, OCS.Len(OCS.SECTIONS) do
		local s = OCS.SECTIONS[i]
		if s.id == section then
			for j = 1, OCS.Len(s.buckets) do
				local list = (countedBucket(s.buckets[j]) and OCS_DB and OCS_DB.rows
					and OCS_DB.rows[s.buckets[j]]) or {}
				for k = 1, OCS.Len(list) do
					local row = list[k]
					local name = row.target
					local fits = true
					if category then
						fits = ((row.kind and category.kinds[row.kind])
							or (row.activity and category.kinds[row.activity]))
							and true or false
					end
					if name and name ~= "" and fits then
						out[name] = (out[name] or 0) + 1
					end
				end
			end
		end
	end
	return out
end

function OCS.KindCounts(section)
	local seen, out = {}, {}
	local function seed(kind)
		if kind and not seen[kind] then
			seen[kind] = { kind = kind, count = 0 }
			table.insert(out, seen[kind])
		end
	end
	local base = OCS.BASE_KINDS[section]
	if base then
		for i = 1, OCS.Len(base) do
			seed(base[i])
		end
	end
	if section == "PVE" and OCS.ActivePack then
		local pack = OCS.ActivePack()
		if pack and pack.activities then
			for i = 1, OCS.Len(pack.activities) do
				local act = pack.activities[i]
				if act.id ~= "GUILD" then seed(act.id) end
				-- Seed the caption too, so an activity nobody has posted yet is
				-- still readable instead of showing its id, such as "DGN".
				OCS.KIND_NAMES[act.id] = act.name or act.short or act.id
			end
		end
	end
	for i = 1, OCS.Len(OCS.SECTIONS) do
		local s = OCS.SECTIONS[i]
		if s.id == section then
			for j = 1, OCS.Len(s.buckets) do
				local list = (countedBucket(s.buckets[j]) and OCS_DB and OCS_DB.rows
					and OCS_DB.rows[s.buckets[j]]) or {}
				for k = 1, OCS.Len(list) do
					local kind = list[k].kind
					if kind then
						if not seen[kind] then
							seen[kind] = { kind = kind, count = 0 }
							table.insert(out, seen[kind])
						end
						seen[kind].count = seen[kind].count + 1
					end
				end
			end
		end
	end
	for i = 1, OCS.Len(out) do
		out[i].label = OCS.KindName(out[i].kind)
	end
	table.sort(out, function(a, b)
		if a.count == b.count then
			return a.label < b.label
		end
		return a.count > b.count
	end)
	return out
end

-- A short line for the row counter, so an empty table is never a mystery.
function OCS.FilterSummary()
	local f = OCS_DB and OCS_DB.filter
	if not f then
		return ""
	end
	local parts = {}
	if (f.kind or "ALL") ~= "ALL" then
		table.insert(parts, OCS.KindFilterText(f))
	end

	if (f.class or "ALL") ~= "ALL" then
		table.insert(parts, f.class)
	end
	for role, on in pairs(f.roles or {}) do
		if on then
			table.insert(parts, OCS.RoleLabel(role))
		end
	end

	if (f.minLevel or 0) > 0 or (f.maxLevel or 0) > 0 then
		table.insert(parts, "Level " .. (f.minLevel or 0) .. " to " .. (f.maxLevel or 0))
	end
	if f.word and f.word ~= "" then
		table.insert(parts, "Text " .. f.word)
	end
	if OCS.Len(parts) == 0 then
		return ""
	end
	return " - filter: " .. table.concat(parts, ", ")
end

for i = 1, OCS.Len(OCS.SECTIONS) do
	local s = OCS.SECTIONS[i]
	for j = 1, OCS.Len(s.buckets) do
		OCS.BUCKET_SECTION[s.buckets[j]] = s.id
	end
end
OCS.stats = { events = 0, gated = 0, stored = 0, errors = 0, comm = 0 }

local DEFAULTS = {
	mode = "PVE_LFM",
	section = "PVE",
	style = "vanilla",
	stale = 300,
	showOwn = false,
	debug = false,
	sortKey = "time",
	sortAsc = false,
	-- Which columns each section draws. Set with the Rows button, kept per
	-- section and saved between sessions. A true value means the column is
	-- switched off. Starting sets are seeded once below, never from here:
	-- a default reapplied at every login
	-- would undo a column the player switched back on.
	cols = { PVE = {}, PVP = {}, TRADE = {}, GUILD = {} },
	-- Content pack. auto picks one from the realm name, see Packs.lua.
	pack = "auto",
	minimap = { show = true, angle = 205 },
	window = { shown = false, x = 0, y = 0, w = 780, h = 460, hasPos = false, scale = 100 },
	-- Mini feed. mode records which window the switch button last chose, the
	-- rest is placement.
	mini = { mode = false, shown = false, hasPos = false, point = nil, rel = nil,
		x = 0, y = 0, w = 320, h = 200 },
	filter = {
		intent = "BOTH",
		-- Content type, ALL, a category such as CAT_DGN, or a row kind such
		-- as ARENA.
		kind = "ALL",
		-- The named place inside that category, ALL for all of them.
		target = "ALL",
		-- Character class, ALL or one class name. Only reachable on a realm
		-- whose pack has classes.
		class = "ALL",

		roles = { tank = false, heal = false, damage = false },

		minLevel = 0,
		maxLevel = 0,
		word = "",
	},
	alert = { enabled = false, sound = true, chat = false, popup = true, mode = "ANY",
		scope = "SECTION",
		pos = { hasPos = false, x = 0, y = 0 } },
	-- One line per tab, sent only when you click the W cell in a row.
	whisper = {
		pveLfm = "Hi! Level {mylevel} {myclass} here.",
		pveLfg = "Hi! Still looking for a group?",
		pvpLfm = "Hi! Level {mylevel} {myclass} here.",
		pvpLfg = "Hi! Still looking for a PvP group?",
		tradeWts = "Hi! Is this still available?",
		tradeWtb = "Hi! Are you still looking?",
		guild = "Hi! I saw your guild post. Could you tell me more?",
	},
	rows = { PVE_LFM = {}, PVE_LFG = {}, PVE_UNSURE = {},
		PVP_LFM = {}, PVP_LFG = {}, PVP_UNSURE = {},
		TRADE_WTS = {}, TRADE_WTB = {}, TRADE_UNSURE = {},
		GUILD_ALL = {} },
}

local LEGACY_WHISPERS = {
	pveLfm = "Hi {name}, lvl {mylevel} room in your group?",
	pveLfg = "Hi {name}, I have a group going, want an invite?",
	pvpLfm = "Hi {name}, lvl {mylevel}, room in your PvP group?",
	pvpLfg = "Hi {name}, I have a PvP group going, want an invite?",
	tradeWts = "Hi {name}, still selling? What is your price?",
	tradeWtb = "Hi {name}, still buying? I have it.",
	guild = "Hi {name}, is your guild still recruiting? Lvl {mylevel} here.",
}

local LEGACY_EXTENDED_WHISPERS = {
	pveLfm = "Hi! Level {mylevel} {myclass} here. Still need more?",
	pveLfg = "Hi! Still looking for a group? Want to team up?",
	pvpLfm = "Hi! Level {mylevel} {myclass} here. Still need more for PvP?",
	pvpLfg = "Hi! Still looking for a PvP group? Want to team up?",
}

local function migrateDisplayDefaults()
	for key, old in pairs(LEGACY_WHISPERS) do
		if OCS_DB.whisper[key] == old or OCS_DB.whisper[key] == LEGACY_EXTENDED_WHISPERS[key] then
			OCS_DB.whisper[key] = DEFAULTS.whisper[key]
		end
	end
	if (tonumber(OCS_DB.colsDefaultsVersion) or 0) >= 2 then return end
	local defaults = {
		PVE = { class = true, prog = true, level = true },
		PVP = { role = true, level = true },
	}
	for section, hidden in pairs(defaults) do
		local saved = OCS_DB.cols[section]
		local untouched = next(saved) == nil and not (section == "PVE" and OCS_DB.colsSeeded)
		if section == "PVP" and next(saved) == nil then untouched = true end
		if section == "PVE" and saved.prog == true then
			untouched = true
			for key in pairs(saved) do if key ~= "prog" then untouched = false end end
		end
		if untouched then for key in pairs(hidden) do saved[key] = true end end
	end
	OCS_DB.colsSeeded, OCS_DB.colsDefaultsVersion = true, 2
end

local function copyDefaults(src, dst)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then
				dst[k] = {}
			end
			copyDefaults(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

-- Every line the addon writes to chat passes through here, so the style is set
-- in one place: capital first letter, no full stop at the end of a single
-- sentence. A line that holds more than one sentence keeps its punctuation.
local function styleMessage(msg)
	local text = tostring(msg)
	local head = OCS.Match(text, "^(|c%x%x%x%x%x%x%x%x)")
	local rest = head and string.sub(text, string.len(head) + 1) or text
	head = head or ""
	rest = string.gsub(rest, "^%s+", "")
	local first = string.sub(rest, 1, 1)
	if first ~= "" then
		rest = string.upper(first) .. string.sub(rest, 2)
	end
	local _, dots = string.gsub(rest, "%.", "")
	if dots == 1 and string.sub(rest, -1) == "." then
		rest = string.sub(rest, 1, -2)
	end
	return head .. rest
end

function OCS.Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffOctoScanner|r: "
			.. styleMessage(msg))
	end
end

-- Debug prints the posts the addon accepts, one line each. Everything it
-- skips is counted instead and shown by /ocs probe, because a busy channel
-- would otherwise bury the accepted posts.
local function debugPrint(msg)
	if OCS_DB and OCS_DB.debug then
		OCS.Print("|cffaaaaaa" .. tostring(msg) .. "|r")
	end
end

local EVENTS = {
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
}
OCS.EVENTS = EVENTS

-- Mode and sorting ----------------------------------------------------------

function OCS.GetMode()
	return (OCS_DB and OCS_DB.mode) or "PVE_LFM"
end

function OCS.SetMode(mode)
	for i = 1, OCS.Len(OCS.BUCKETS) do
		if OCS.BUCKETS[i] == mode then
			local target = OCS.BUCKET_SECTION[mode] or OCS_DB.section
			OCS.SwitchSectionFilter(target)
			OCS_DB.mode = mode
			OCS_DB.section = target
			if OCS.Refresh then
				OCS.Refresh()
			end
			return
		end
	end
end

local FILTER_KEYS = { "intent", "kind", "target", "class",
	 "minLevel", "maxLevel", "word", "maxOnly",
	}

OCS.FILTER_BLANK = {
	intent = "BOTH", kind = "ALL", target = "ALL", class = "ALL",

	minLevel = 0, maxLevel = 0, word = "",
	maxOnly = false,
	roles = { tank = false, heal = false, damage = false },
}

-- A detached copy, so the stored set does not move when the live one does.
function OCS.CopyFilter(f)
	local out = { roles = {} }
	for i = 1, OCS.Len(FILTER_KEYS) do
		out[FILTER_KEYS[i]] = f[FILTER_KEYS[i]]
	end
	for k, v in pairs(f.roles or {}) do
		out.roles[k] = v
	end
	return out
end

-- Writes a stored set back onto the live filter. Nil means a blank set.
function OCS.ApplyFilter(f)
	f = f or OCS.FILTER_BLANK
	for i = 1, OCS.Len(FILTER_KEYS) do
		local key = FILTER_KEYS[i]
		local v = f[key]
		if v == nil then
			v = OCS.FILTER_BLANK[key]
		end
		OCS_DB.filter[key] = v
	end
	OCS_DB.filter.roles = OCS_DB.filter.roles or {}
	for _, role in ipairs({ "tank", "heal", "damage" }) do
		OCS_DB.filter.roles[role] = (f.roles and f.roles[role]) or false
	end
end

-- The set that belongs to a section. The open section is the live filter, the
-- other two are the sets parked when you left them.
function OCS.FilterFor(section)
	if section == OCS.GetSection() then
		return OCS_DB.filter
	end
	local by = OCS_DB.filter and OCS_DB.filter.bySection
	return (by and by[section]) or OCS.FILTER_BLANK
end

-- Each section keeps its own filter set. Switching sections stores the
-- old choice and restores what that section had.
function OCS.SwitchSectionFilter(newSection)
	if not OCS_DB or not OCS_DB.filter then
		return
	end
	local old = OCS_DB.section or "PVE"
	if old == newSection then
		return
	end
	OCS_DB.filter.bySection = OCS_DB.filter.bySection or {}
	OCS_DB.filter.bySection[old] = OCS.CopyFilter(OCS_DB.filter)
	OCS.ApplyFilter(OCS_DB.filter.bySection[newSection])
	if OCS.RefreshFilterPanel then
		OCS.RefreshFilterPanel()
	end
end

function OCS.GetSection()
	return (OCS_DB and OCS_DB.section) or "PVE"
end

function OCS.SetSection(id)
	for i = 1, OCS.Len(OCS.SECTIONS) do
		local s = OCS.SECTIONS[i]
		if s.id == id then
			OCS.SwitchSectionFilter(id)
			OCS_DB.section = id
			local current = OCS.GetMode()
			if OCS.BUCKET_SECTION[current] ~= id then
				OCS_DB.mode = s.buckets[1]
			end
			if OCS.Refresh then
				OCS.Refresh()
			end
			return
		end
	end
end

-- Which side of the board you are on. Looking for a group means you want to
-- read recruit posts, looking for players means you want to read offers.
function OCS.SetFilterIntent(intent)
	OCS_DB.filter.intent = intent
	if intent == "GROUP" then
		OCS_DB.alert.mode = "LFM"
		OCS.SetMode(OCS.BucketFor(OCS.GetSection(), "LFM"))
	elseif intent == "PLAYERS" then
		OCS_DB.alert.mode = "LFG"
		OCS.SetMode(OCS.BucketFor(OCS.GetSection(), "LFG"))
	else
		OCS_DB.alert.mode = "ANY"
	end
	if OCS.Refresh then
		OCS.Refresh()
	end
end

-- Storage -------------------------------------------------------------------

local function findRow(bucket, name)
	local list = OCS_DB.rows[bucket]
	if not list then
		return nil
	end
	for i = 1, OCS.Len(list) do
		if list[i].name == name then
			return list[i], i
		end
	end
	return nil
end

-- A name lives in one tab at a time, so a repeat post only has to be cleared
-- from the tab it was last seen in. The hint is dropped whenever a row is
-- moved, removed or cleared, and a miss falls back to the full sweep.
local lastBucketOf = {}

-- With a bucket, the hint is dropped only when it still points at that
-- bucket, so removing one row cannot blank the hint of a live row.
function OCS.ForgetName(name, bucket)
	if bucket and lastBucketOf[name] ~= bucket then
		return
	end
	lastBucketOf[name] = nil
end

function OCS.ForgetAllNames()
	for k in pairs(lastBucketOf) do
		lastBucketOf[k] = nil
	end
end

local function removeFromOtherBuckets(bucket, name)
	local hint = lastBucketOf[name]
	if hint == bucket then
		return
	end
	if hint and OCS_DB.rows[hint] then
		local list = OCS_DB.rows[hint]
		local previous
		for j = OCS.Len(list), 1, -1 do
			if list[j].name == name then
				previous = table.remove(list, j)
			end
		end
		if previous then
			return previous
		end
	end
	local previous
	for i = 1, OCS.Len(OCS.BUCKETS) do
		local b = OCS.BUCKETS[i]
		if b ~= bucket then
			local list = OCS_DB.rows[b]
			for j = OCS.Len(list), 1, -1 do
				if list[j].name == name then
					previous = table.remove(list, j)
				end
			end
		end
	end
	return previous
end

function OCS.RemoveRow(bucket, name)
	OCS.ForgetName(name)
	local list = OCS_DB.rows[bucket]
	for i = OCS.Len(list), 1, -1 do
		if list[i].name == name then
			table.remove(list, i)
		end
	end
	if OCS.MiniRemove then OCS.MiniRemove(name, bucket) end
	if OCS.Refresh then
		OCS.Refresh()
	end
end

-- Moves every row of a player from one tab to another, for the cases where
-- the wording is genuinely ambiguous.
-- Buckets are stored as ids such as PVE_LFM. Anything the player reads
-- has to use the section and tab captions instead.
-- The bucket, label and section tables are written out by hand. When they
-- drift the symptom is a blank caption or a stale colour, which is easy to
-- miss, so they are checked at login.
function OCS.CheckTables()
	local problems = {}
	for i = 1, OCS.Len(OCS.BUCKETS) do
		local b = OCS.BUCKETS[i]
		if not OCS.BUCKET_LABEL[b] then
			table.insert(problems, "no label for " .. b)
		end
		if not OCS.BUCKET_SECTION[b] then
			table.insert(problems, "no section for " .. b)
		end
		if not OCS_DB.rows[b] then
			table.insert(problems, "no store for " .. b)
		end
	end
	return problems
end

function OCS.BucketName(bucket)
	local label = OCS.BUCKET_LABEL and OCS.BUCKET_LABEL[bucket]
	local sectionId = OCS.BUCKET_SECTION and OCS.BUCKET_SECTION[bucket]
	local sectionLabel
	for i = 1, OCS.Len(OCS.SECTIONS) do
		if OCS.SECTIONS[i].id == sectionId then
			sectionLabel = OCS.SECTIONS[i].label
		end
	end
	if sectionLabel and label then
		return sectionLabel .. " " .. label
	end
	return label or tostring(bucket)
end

function OCS.MoveRow(bucket, name, target)
	OCS.ForgetName(name)
	if bucket == target then
		return
	end
	local from = OCS_DB.rows[bucket]
	local to = OCS_DB.rows[target]
	if not from or not to then
		return
	end
	local moved = 0
	for i = OCS.Len(from), 1, -1 do
		if from[i].name == name then
			local row = table.remove(from, i)
			for j = OCS.Len(to), 1, -1 do
				if to[j].name == name then
					table.remove(to, j)
				end
			end
			table.insert(to, row)
			moved = moved + 1
		end
	end
	if moved > 0 then
		if OCS.MiniRemove then OCS.MiniRemove(name, bucket) end
		OCS.Print(name .. " moved to " .. OCS.BucketName(target))
		if OCS.Refresh then
			OCS.Refresh()
		end
	end
end

function OCS.ClearBucket(bucket)
	OCS_DB.rows[bucket] = {}
	OCS.ForgetAllNames()
	if OCS.MiniRemove then OCS.MiniRemove(nil, bucket) end
	if OCS.Refresh then
		OCS.Refresh()
	end
end

function OCS.CountAll()
	local n = 0
	for i = 1, OCS.Len(OCS.BUCKETS) do
		n = n + OCS.Len(OCS_DB.rows[OCS.BUCKETS[i]])
	end
	return n
end

-- Only used on load/logout, including /reload. During play, history has no
-- age/cap cleanup; a player's new advert or a manual action changes it.
function OCS.TrimHistory(now)
	now = now or time()
	local cutoff, removed = now - 3600, 0
	for i = 1, OCS.Len(OCS.BUCKETS) do
		local list = OCS_DB.rows[OCS.BUCKETS[i]]
		for j = OCS.Len(list), 1, -1 do
			local stamp = tonumber(list[j].time)
			if not stamp or stamp <= cutoff or stamp > now then
				table.remove(list, j)
				removed = removed + 1
			end
		end
	end
	return removed
end

-- Filters -------------------------------------------------------------------

function OCS.AnyRoleFilter()
	local f = OCS_DB.filter
	return f.roles.tank or f.roles.heal or f.roles.damage
end

-- Rows in one tab that pass the current filter, plus the raw total.
function OCS.FilterCount(bucket)
	local source = (OCS_DB and OCS_DB.rows and OCS_DB.rows[bucket]) or {}
	local shown = 0
	for i = 1, OCS.Len(source) do
		if OCS.PassesFilter(source[i]) then
			shown = shown + 1
		end
	end
	return shown, OCS.Len(source)
end

-- True when anything at all is narrowing the view.
function OCS.FilterActive()
	local f = OCS_DB and OCS_DB.filter
	if not f then
		return false
	end
	if (f.kind or "ALL") ~= "ALL" then
		return true
	end

	if (f.class or "ALL") ~= "ALL" then
		return true
	end

	if (f.word or "") ~= "" then
		return true
	end
	if (f.minLevel or 0) > 0 or (f.maxLevel or 0) > 0 then
		return true
	end
	if f.maxOnly then
		return true
	end

	if (f.intent or "BOTH") ~= "BOTH" then
		return true
	end
	if OCS.AnyRoleFilter and OCS.AnyRoleFilter() then
		return true
	end
	return false
end

function OCS.PassesFilter(row)
	return OCS.PassesFilterWith(row, OCS_DB.filter)
end

-- Which single setting is keeping a row out of the list. Each setting is
-- relaxed on its own copy of the filter and the row is tested again, so this
-- needs no second copy of the filter rules and can never drift from them.
local REASON_FIELDS = {
	{ key = "kind", blank = "ALL", label = "Activity" },
	{ key = "target", blank = "ALL", label = "the named place" },
	{ key = "class", blank = "ALL", label = "Class" },
	{ key = "maxOnly", blank = false, label = "Level 60 only" },
	{ key = "minLevel", blank = 0, label = "Level from" },
	{ key = "maxLevel", blank = 0, label = "Level to" },
	{ key = "word", blank = "", label = "Message contains" },
}

function OCS.FilterReasons(row, f)
	f = f or OCS_DB.filter
	if OCS.PassesFilterWith(row, f) then
		return nil
	end
	local out = {}
	for i = 1, OCS.Len(REASON_FIELDS) do
		local field = REASON_FIELDS[i]
		local test = OCS.CopyFilter(f)
		test[field.key] = field.blank
		if OCS.PassesFilterWith(row, test) then
			local label = field.label
			if field.key == "maxOnly" then
				label = "Level " .. (OCS.LEVEL_CAP or 60) .. " only"
			end
			table.insert(out, label)
		end
	end
	if OCS.Len(out) == 0 then
		local test = OCS.CopyFilter(f)
		for i = 1, OCS.Len(OCS.ROLE_ORDER) do
			test.roles[OCS.ROLE_ORDER[i]] = false
		end
		if OCS.PassesFilterWith(row, test) then
			table.insert(out, "Role")
		end
	end
	return out
end

-- /ocs hidden. Prints what the filter is dropping and why, so a rule that hides
-- too much can be pointed at instead of guessed at.
-- What the filter is keeping out, counted per setting instead of one line per
-- row. Twenty hidden guild adverts are one line saying so, with a couple of
-- examples under it, which is what you need to see to know whether a setting is
-- doing what you meant.
function OCS.HiddenReport(limit)
	limit = tonumber(limit) or 2
	local f = OCS_DB.filter
	local groups, order, total = {}, {}, 0
	for bucket, list in pairs((OCS_DB and OCS_DB.rows) or {}) do
		for i = 1, OCS.Len(list) do
			local row = list[i]
			if not OCS.PassesFilterWith(row, f) then
				total = total + 1
				local reasons = OCS.FilterReasons(row, f)
				local why = (reasons and OCS.Len(reasons) > 0)
					and table.concat(reasons, " + ")
					or "two or more settings together"
				local g = groups[why]
				if not g then
					g = { why = why, count = 0, samples = {} }
					groups[why] = g
					table.insert(order, g)
				end
				g.count = g.count + 1
				if OCS.Len(g.samples) < limit then
					local msg = row.message or ""
					if OCS.Len(msg) > 70 then
						msg = string.sub(msg, 1, 68) .. ".."
					end
					table.insert(g.samples, (row.name or "?")
						.. ": " .. msg)
				end
			end
		end
	end
	if total == 0 then
		OCS.Print("Nothing is hidden by the filter.")
		return
	end
	table.sort(order, function(a, b)
		if a.count == b.count then
			return a.why < b.why
		end
		return a.count > b.count
	end)
	OCS.Print("Filter hides " .. total .. " rows. By setting:")
	for i = 1, OCS.Len(order) do
		local g = order[i]
		OCS.Print("  " .. g.count .. "x " .. g.why)
		for j = 1, OCS.Len(g.samples) do
			OCS.Print("      " .. g.samples[j])
		end
	end
	OCS.Print("  /ocs hidden <n> shows n examples per setting.")
end

function OCS.PassesFilterWith(row, f)
	f = f or OCS.FILTER_BLANK
	local anyRole = false
	for i = 1, OCS.Len(OCS.ROLE_ORDER) do
		if f.roles and f.roles[OCS.ROLE_ORDER[i]] then
			anyRole = true
		end
	end
	if anyRole then
		local ok = false
		for i = 1, OCS.Len(OCS.ROLE_ORDER) do
			local role = OCS.ROLE_ORDER[i]
			if f.roles[role] and row.roleSet and row.roleSet[role] then
				ok = true
			end
		end
		if not ok then
			return false
		end
	end
	-- Content type. Cuts across the tabs, so it lives in the filter panel. A
	-- category passes every activity id inside it, and the named place picked
	-- on the second level narrows that to one dungeon, raid or boss.
	local kind = f.kind or "ALL"
	if kind ~= "ALL" then
		local cat = OCS.KIND_CATEGORY[kind]
		if cat then
			-- The kind answers first, the activity is the fallback. A row stored
			-- by a build that overwrote its kind still lands in the category its
			-- activity names.
			if not (cat.kinds[row.kind]
				or (row.activity and cat.kinds[row.activity])) then
				return false
			end
			local target = f.target or "ALL"
			if target ~= "ALL" then
				local lead = false
				if cat.lead then
					for i = 1, OCS.Len(cat.lead) do
						if cat.lead[i].value == target then
							lead = true
						end
					end
				end
				if lead then
					-- LFT is an activity, so it matches on the row kind. A row whose kind
					-- was overwritten by an older build answers on its
					-- activity instead.
					if row.kind ~= target and row.activity ~= target then
						return false
					end
				elseif row.target ~= target then
					return false
				end
			end
		elseif row.kind ~= kind then
			return false
		end
	end

	-- Character class. A post that names no class never passes a class
	-- filter, because guessing one would be worse than leaving it out.
	if f.class and f.class ~= "ALL" then
		if not (row.classSet and row.classSet[f.class]) then
			return false
		end
	end
	if (f.minLevel or 0) > 0 then
		if not row.level or row.level < f.minLevel then
			return false
		end
	end
	if (f.maxLevel or 0) > 0 then
		if not row.level or row.level > f.maxLevel then
			return false
		end
	end
	if f.maxOnly then
		local cap = OCS.LEVEL_CAP or 60
		if row.level and row.level < cap then
			return false
		end
		-- A character at the cap earns no experience, so a post that sells it
		-- is levelling traffic whatever level it names, or names none.
		if row.levelling then
			return false
		end
	end
	if f.word and f.word ~= "" then
		local needle = string.lower(f.word)
		if not string.find(string.lower(row.message or ""), needle, 1, true) then
			return false
		end
	end
	return true
end

local SORTERS = {
	time = function(a, b) return (a.time or 0) < (b.time or 0) end,
	name = function(a, b) return (a.name or "") < (b.name or "") end,
	role = function(a, b) return (a.roleText or "") < (b.roleText or "") end,

	level = function(a, b) return (a.level or 0) < (b.level or 0) end,
	-- Pack columns.
	act = function(a, b)
		local ta = (a.activityShort or "") .. " " .. (a.target or "")
		local tb = (b.activityShort or "") .. " " .. (b.target or "")
		return ta < tb
	end,

	prog = function(a, b) return (a.prog or "") < (b.prog or "") end,
	message = function(a, b) return (a.message or "") < (b.message or "") end,
}

function OCS.GetSortedRows(bucket, key, ascending)
	local source = OCS_DB.rows[bucket] or {}
	local list = {}
	for i = 1, OCS.Len(source) do
		if OCS.PassesFilter(source[i]) then
			table.insert(list, source[i])
		end
	end
	local sorter = SORTERS[key] or SORTERS.time
	table.sort(list, function(a, b)
		if ascending then
			return sorter(a, b)
		end
		return sorter(b, a)
	end)
	return list
end

-- Alerts --------------------------------------------------------------------

-- The popup, the sound, the chat line and the mini feed all ask this one
-- question, so a feed row can never disagree with an alert.
function OCS.AlertMatch(bucket, row)
	local a = OCS_DB.alert
	local intent = OCS.IntentOf(bucket)
	if intent == "UNSURE" then
		return false
	end
	if a.mode ~= "ANY" and a.mode ~= intent then
		return false
	end
	local section = OCS.BUCKET_SECTION[bucket] or "PVE"
	-- scope SECTION: only the tab you are looking at can alert, so sitting on
	-- PvE LFG keeps PvE LFM quiet.
	-- scope ALL: any tab can, each judged by its own section filter set.
	if (a.scope or "SECTION") == "SECTION" and bucket ~= OCS.GetMode() then
		return false
	end
	return OCS.PassesFilterWith(row, OCS.FilterFor(section))
end

-- Alerts proper. The feed ignores this switch, see below.
local function alertWanted(bucket, row)
	if not OCS_DB.alert.enabled then
		return false
	end
	return OCS.AlertMatch(bucket, row)
end

-- Message handling ----------------------------------------------------------

local function channelLabel(event, arg4, arg9)
	if event == "CHAT_MSG_CHANNEL" then
		return (arg9 and arg9 ~= "" and arg9) or (arg4 and arg4 ~= "" and arg4) or "channel"
	end
	local short = string.gsub(event, "^CHAT_MSG_", "")
	return string.gsub(string.lower(short), "_", " ")
end

local lastSeen = {}

-- Without this the dedupe cache grows for the whole session, one entry per
-- unique line seen. The housekeeping ticker calls it every five seconds.
function OCS.PurgeSeen()
	local now = time()
	for key, seen in pairs(lastSeen) do
		if now - seen >= 3 then
			lastSeen[key] = nil
		end
	end
end

-- Debug output is public through /ocs debug, so it must not carry raw chat
-- escapes or internal ids. A failure strips the escape character rather than
-- passing the raw line through.
local function safeText(s)
	local ok, clean = pcall(OCS.DisplayText, s)
	if ok and type(clean) == "string" and clean ~= "" then
		return clean
	end
	return (string.gsub(tostring(s), "|", ""))
end

OCS.ROW_SCHEMA = 5

-- Guild recruitment used to sit in the PvE and PvP tabs. It has its own section
-- now, so stored guild rows are carried across once instead of being stranded
-- in a tab that no longer shows them.
local function moveGuildRows()
	local target = OCS_DB.rows.GUILD_ALL
	if not target then
		target = {}
		OCS_DB.rows.GUILD_ALL = target
	end
	local moved = 0
	for i = 1, OCS.Len(OCS.BUCKETS) do
		local id = OCS.BUCKETS[i]
		if id ~= "GUILD_ALL" then
			local list = OCS_DB.rows[id]
			if list then
				-- Backwards, because rows are taken out of the list while it
				-- is being walked.
				for k = OCS.Len(list), 1, -1 do
					if list[k].kind == "GUILD" then
						table.insert(target, table.remove(list, k))
						moved = moved + 1
					end
				end
			end
		end
	end
	return moved
end

function OCS.MigrateRows()
	if not OCS_DB or not OCS_DB.rows then
		return 0
	end
	local done = moveGuildRows()
	for i = 1, OCS.Len(OCS.BUCKETS) do
		local list = OCS_DB.rows[OCS.BUCKETS[i]] or {}
		for j = 1, OCS.Len(list) do
			local row = list[j]
			if row.schema ~= OCS.ROW_SCHEMA then
				local text = row.rawMessage or row.message
				local parsed
				if text then
					local ok, out = pcall(OCS.Parse, text)
					if ok and type(out) == "table" then
						parsed = out
					end
				end
				if parsed then
					local locked = row.locked or {}

					row.target = row.target or parsed.target

					if row.levelling == nil then
						row.levelling = parsed.levelling
					end
					row.activity = row.activity or parsed.activity
					row.activityName = row.activityName or parsed.activityName
					row.activityShort = row.activityShort or parsed.activityShort
					if not locked.role and parsed.roleSet then
						row.roleSet = parsed.roleSet
						row.roleText = parsed.roleText
					end
					row.orig = row.orig or {}

					done = done + 1
				end
				row.schema = OCS.ROW_SCHEMA
			end
		end
	end
	return done
end

function OCS.HandleMessage(event, message, sender, arg4, arg9, source, language)
	OCS.stats.events = OCS.stats.events + 1
	if not message or message == "" or not sender or sender == "" then
		return
	end

	sender = OCS.Match(sender, "^[^-]+") or sender
	-- Ignore transport channels before deduping: rejected addon traffic must
	-- not suppress the same text subsequently posted to a human channel.
	if OCS.IsAddonTraffic and OCS.IsAddonTraffic(message, channelLabel(event, arg4, arg9), language) then
		OCS.stats.comm = (OCS.stats.comm or 0) + 1
		return
	end

	-- Both capture paths can deliver the same line, so drop instant repeats.
	local key = sender .. "\001" .. message
	local now = time()
	if lastSeen[key] and now - lastSeen[key] < 3 then
		return
	end
	lastSeen[key] = now

	if not OCS_DB.showOwn and sender == UnitName("player") then
		return
	end

	local parsed = OCS.Parse(message)
	if not parsed then
		return
	end
	OCS.stats.gated = OCS.stats.gated + 1

	local section = parsed.route or "PVE"
	local bucket
	if section == "TRADE" then
		bucket = OCS.BucketFor("TRADE", parsed.tradeIntent or "UNSURE")
	else
		bucket = OCS.BucketFor(section, parsed.intent or "UNSURE")
	end
	local channel = channelLabel(event, arg4, arg9)
	debugPrint(OCS.BucketName(bucket) .. " <- " .. sender .. " [" .. channel .. "] "
		.. safeText(message))

	local previous = removeFromOtherBuckets(bucket, sender)
	lastBucketOf[sender] = bucket
	local row = findRow(bucket, sender)
	local isNew = false

	if not row then
		-- A new intent moves the same record, including manual cell locks.
		row = previous or { name = sender, locked = {} }
		table.insert(OCS_DB.rows[bucket], row)
		isNew = true
		OCS.stats.stored = OCS.stats.stored + 1
	end

	row.time = now
	-- The raw chat string is kept for a whisper and for a copy, the table
	-- shows the clean text.
	row.rawMessage = message
	-- A failure here must not leave the row without a message.
	local okClean, clean = pcall(OCS.DisplayText, message)
	if not okClean or type(clean) ~= "string" or clean == "" then
		clean = message
		OCS.stats.errors = OCS.stats.errors + 1
	end
	row.message = clean
	row.kind = parsed.kind or "OTHER"
	if parsed.kind and parsed.activityShort then
		-- The menu shows the full name, the table cell shows the short one.
		OCS.KIND_NAMES[parsed.kind] = parsed.activityName or parsed.activityShort
	end
	row.channel = channel
	if not row.locked then
		row.locked = {}
	end
	if not row.locked.role then
		row.roleSet = parsed.roleSet
		row.roleText = parsed.roleText
	end

	if not row.locked.level then
		row.level = parsed.level
		row.bracket = parsed.bracket
	end

	-- Kept so a hand edit can be stepped back to what the message itself said.
	-- Always refreshed from the parse, even where a cell is locked by an edit.
	row.orig = row.orig or {}
	row.orig.roleText = parsed.roleText
	row.orig.level = parsed.level
	row.orig.bracket = parsed.bracket

	row.orig.prog = parsed.prog

	-- Straight from the current post. An older post must not leave a stale
	-- number behind when the sender writes again without one.
	row.size = parsed.size
	row.wanted = parsed.wanted

	-- Pack fields. Which of these the table shows is decided by the pack.
	row.activity = parsed.activity
	row.activityName = parsed.activityName
	row.activityShort = parsed.activityShort

	-- True when the post sells experience, which no level 60 group does.
	row.levelling = parsed.levelling
	row.class = parsed.class
	row.classSet = parsed.classSet
	row.profession = parsed.profession
	row.profMode = parsed.profMode
	row.target = parsed.target

	if not row.locked.prog then
		row.prog = parsed.prog
	end

	-- The mini feed collects whatever matches the alert rules, even with
	-- alerts switched off, and even while the window is closed.
	if OCS.MiniPush and OCS.AlertMatch(bucket, row) then
		OCS.MiniPush(row, bucket)
	elseif OCS.MiniRemove then
		OCS.MiniRemove(sender)
	end

	if isNew and alertWanted(bucket, row) then
		local a = OCS_DB.alert
		if a.chat then
			OCS.Print("|cffffd100" .. OCS.BucketName(bucket) .. "|r " .. sender .. ": " .. (row.message or ""))
		end
		if a.sound then
			PlaySound("RaidWarning")
		end
		if a.popup and OCS.ShowAlert then
			OCS.ShowAlert(row, bucket)
		end
	end

	OCS.RefreshSoon()
end

-- A busy channel delivers several lines in the same frame. Repainting once per
-- frame instead of once per line keeps the cost flat on a full trade channel.
local refreshDriver = CreateFrame("Frame")
refreshDriver:Hide()
OCS.SetScript(refreshDriver, "OnUpdate", function(self)
	self:Hide()
	if OCS.Refresh then
		OCS.Refresh()
	end
end)

function OCS.RefreshSoon()
	refreshDriver:Show()
end

-- Every capture path funnels through here so one error cannot kill the addon.
function OCS.Ingest(event, message, sender, arg4, arg9, source, language)
	if not OCS_DB then
		return
	end
	local ok, err = pcall(OCS.HandleMessage, event, message, sender, arg4, arg9, source, language)
	if not ok then
		OCS.stats.errors = OCS.stats.errors + 1
		OCS.lastError = tostring(err)
		if OCS_DB.debug then
			OCS.Print("|cffff5555error|r " .. OCS.lastError)
		end
	end
end

-- Capture path 1: registered chat events.
local driver = CreateFrame("Frame", "OCS_Driver", UIParent)
driver:RegisterEvent("ADDON_LOADED")

OCS.SetScript(driver, "OnEvent", function(self, event, a1, a2, a3, a4, a5, a6, a7, a8, a9)
	if event == "ADDON_LOADED" then
		local name = a1
		if name ~= ADDON_NAME then
			return
		end
		if OCS.initDone then
			return
		end
		OCS.initDone = true
		OCS_DB = OCS_DB or {}
		copyDefaults(DEFAULTS, OCS_DB)
		migrateDisplayDefaults()
		-- Remove the old automatic age/cap settings. The first upgrade also
		-- restores newest-first; later explicit header choices stay saved.
		OCS_DB.expiry, OCS_DB.maxRows = nil, nil
		if OCS_DB.manualCleanupVersion ~= 1 then
			OCS_DB.sortKey, OCS_DB.sortAsc = "time", false
			OCS_DB.manualCleanupVersion = 1
		end
		-- Pick the content pack before any message is parsed.
		local override = OCS_DB.pack
		if override == "auto" then
			override = nil
		end
		if OCS.SelectPack then
			OCS.SelectPack(override)
		end
		-- The pack decides the column set, so this runs before the window is
		-- ever built.
		if OCS.ApplyPackColumns then
			OCS.ApplyPackColumns()
		end
		for i = 1, OCS.Len(OCS.BUCKETS) do
			OCS_DB.rows[OCS.BUCKETS[i]] = OCS_DB.rows[OCS.BUCKETS[i]] or {}
		end
		if not OCS.BUCKET_SECTION[OCS_DB.mode or ""] then
			OCS_DB.mode = "PVE_LFM"
		end
		-- Restore only the last hour. Never call this from a play-time ticker.
		OCS.TrimHistory(time())
		-- Bring surviving legacy rows up to date.
		local migrated = OCS.MigrateRows()
		if migrated > 0 and OCS_DB.debug then
			OCS.Print("Brought " .. migrated .. " stored rows up to date.")
		end
		for i = 1, OCS.Len(EVENTS) do
			self:RegisterEvent(EVENTS[i])
		end
		-- The realm name is not always readable while addons load, so the pack
		-- is picked again once the world is up.
		pcall(self.RegisterEvent, self, "PLAYER_ENTERING_WORLD")
		self:RegisterEvent("PLAYER_LOGOUT")
		OCS.filterCount = 0
		local problems = OCS.CheckTables()
		if OCS.Len(problems) > 0 and OCS_DB.debug then
			for i = 1, OCS.Len(problems) do
				OCS.Print("Table check: " .. problems[i])
			end
		end
		OCS.Print("Version " .. OCS.VERSION .. " loaded. Type /ocs to open, /ocs help for commands.")
		if OCS.ActivePack then
			local pack = OCS.ActivePack()
			OCS.Print("Pack: " .. pack.name .. " (realm " .. tostring(OCS.realmName)
				.. ")" .. ((OCS_DB.pack ~= "auto") and " - forced with /ocs pack" or "")
				.. (pack.contentNote and (" - " .. pack.contentNote) or ""))
		end
		return
	end

	if event == "PLAYER_LOGOUT" then
		OCS.TrimHistory(time())
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		-- Only an automatic pack moves. One forced with /ocs pack stays put.
		if (OCS_DB.pack or "auto") == "auto" and OCS.SelectPack then
			local before = OCS.packId
			OCS.SelectPack(nil)
			if OCS.packId ~= before then
				if OCS.ApplyPackColumns then
					OCS.ApplyPackColumns()
				end
				local pack = OCS.ActivePack()
				OCS.Print("Pack: " .. pack.name .. " (realm "
					.. tostring(OCS.realmName) .. ")"
					.. (pack.contentNote and (" - " .. pack.contentNote) or ""))
				if OCS.Refresh then OCS.Refresh() end
				if OCS.RefreshFilterPanel then OCS.RefreshFilterPanel() end
			end
		end
		return
	end

	OCS.Ingest(event, a1, a2, a4, a9, "event", a3)
end)

-- Housekeeping ticker; Vanilla has no C_Timer.
local elapsedSince = 0
OCS.SetScript(driver, "OnUpdate", function(self, elapsed)
	elapsedSince = elapsedSince + (elapsed or 0)
	if elapsedSince < 5 then
		return
	end
	elapsedSince = 0
	OCS.PurgeSeen()
	if OCS.RefreshTimes then
		pcall(OCS.RefreshTimes)
	end
end)

-- Slash commands ------------------------------------------------------------

local function printHelp()
	OCS.Print("Commands:")
	local lines = {
		"/ocs - show or hide the window",
		"/ocs pve | pvp | trade | guild - pick a section",
		"/ocs lfm | lfg | unsure | wts | wtb - pick a tab",
		"/ocs style vanilla | dark | grid | slate | parchment | glass | felfire - same as the Skins button",
		"/ocs clear - clear the current tab, clearall - clear everything",
		"/ocs mini - open or close the mini feed",
		"/ocs mini reset - put the mini feed back in the middle of the screen",
		"/ocs reset - put the main window in the middle at its default size",
		"/ocs position reset - same thing",
		"/ocs minimap - show or hide the minimap button",
		"/ocs alert on | off | sound | chat | popup | mode lfm|lfg|any",
		"/ocs alert scope section | all - same as the Scope button above Alerts",
		"/ocs alert move or unlock - drag the popup, /ocs alert lock - fix it in place",
		"/ocs alert reset - put the popup back in its default spot",
		"/ocs own - include or exclude your own messages",
		"/ocs pack - show the active content pack",
		"/ocs pack octo | turtle | vanilla | auto - switch content profile",
		"/ocs whisper - set the one click whisper line for each tab",
		"/ocs whisper pvelfm | pvelfg | pvplfm | pvplfg | wts | wtb | guild <text> - set one line",
		"/ocs hidden - list what the filter is dropping right now",
		"/ocs probe - print a diagnostic report, useful when reporting a bug",
		"/ocs debug - print one line for every post the addon accepts",
	}
	for i = 1, OCS.Len(lines) do
		DEFAULT_CHAT_FRAME:AddMessage("  " .. lines[i])
	end
end

local function handleAlert(rest)
	local a = OCS_DB.alert
	local cmd, value = OCS.Match(rest, "^(%S*)%s*(.*)$")
	cmd = string.lower(cmd or "")
	if cmd == "on" then
		a.enabled = true
		OCS.Print("Alerts on")
	elseif cmd == "off" then
		a.enabled = false
		OCS.Print("Alerts off")
	elseif cmd == "sound" then
		a.sound = not a.sound
		OCS.Print("Alert sound " .. (a.sound and "on" or "off"))
	elseif cmd == "chat" then
		a.chat = not a.chat
		OCS.Print("Alert chat line " .. (a.chat and "on" or "off"))
	elseif cmd == "popup" then
		a.popup = not a.popup
		OCS.Print("Alert popup " .. (a.popup and "on" or "off"))
	elseif cmd == "move" or cmd == "unlock" then
		if OCS.SetAlertUnlocked then
			OCS.SetAlertUnlocked(true)
		end
	elseif cmd == "lock" then
		if OCS.SetAlertUnlocked then
			OCS.SetAlertUnlocked(false)
		end
	elseif cmd == "reset" then
		if OCS.ResetAlertPosition then
			OCS.ResetAlertPosition()
		end
	elseif cmd == "scope" then
		local sc = string.upper(value or "")
		if sc == "SECTION" or sc == "ALL" then
			a.scope = sc
			OCS.Print("Alert scope " .. (sc == "ALL" and "All" or "Section"))
		else
			OCS.Print("Use /ocs alert scope section | all")
		end
	elseif cmd == "mode" then
		local m = string.upper(value or "")
		if m == "LFM" or m == "LFG" or m == "ANY" then
			a.mode = m
			OCS.Print("Alert mode " .. (m == "ANY" and "any" or m))
		else
			OCS.Print("Use /ocs alert mode lfm | lfg | any")
		end
	else
		OCS.Print("Alerts " .. (a.enabled and "on" or "off")
			.. ", mode " .. ((a.mode == "ANY") and "any" or a.mode)
			.. ", popup " .. (a.popup and "on" or "off")
			.. ", sound " .. (a.sound and "on" or "off")
			.. ", chat " .. (a.chat and "on" or "off"))
	end
	if OCS.RefreshFilterPanel then
		OCS.RefreshFilterPanel()
	end
end

-- Whisper templates ---------------------------------------------------------

-- Accepts either a bucket name or a slot key.
local function slotKey(key)
	local k = tostring(key or "")
	if OCS.WHISPER_BUCKET_SLOT[k] then
		return OCS.WHISPER_BUCKET_SLOT[k]
	end
	for i = 1, OCS.Len(OCS.WHISPER_SLOTS) do
		if OCS.WHISPER_SLOTS[i].key == k then
			return k
		end
	end
	return nil
end

function OCS.WhisperTemplate(key)
	if not OCS_DB or not OCS_DB.whisper then
		return ""
	end
	local slot = slotKey(key)
	if not slot then
		return ""
	end
	return OCS_DB.whisper[slot] or ""
end

-- Puts every line back to the shipped default, used by the panel button.
function OCS.ResetWhisperTemplates()
	if not OCS_DB then
		return
	end
	OCS_DB.whisper = {}
	for i = 1, OCS.Len(OCS.WHISPER_SLOTS) do
		local key = OCS.WHISPER_SLOTS[i].key
		OCS_DB.whisper[key] = DEFAULTS.whisper[key]
	end
	OCS.Print("Whisper lines reset")
end

function OCS.SetWhisperTemplate(key, text)
	if not OCS_DB then
		return
	end
	OCS_DB.whisper = OCS_DB.whisper or {}
	local slot = slotKey(key)
	if not slot then
		return
	end
	OCS_DB.whisper[slot] = text or ""
end

function OCS.BuildWhisper(row, bucket)
	if not row then
		return nil
	end
	local text = OCS.WhisperTemplate(bucket or OCS.GetMode())
	if not text or text == "" then
		return nil
	end
	local values = {
		name = row.name or "",
		role = OCS.RoleDisplay(row.roleText),
		level = row.level and tostring(row.level) or "?",
		size = row.size and tostring(row.size) or "?",
		prof = row.profession or "?",
		profmode = row.profMode or "?",
		myname = UnitName("player") or "",
		mylevel = tostring(UnitLevel("player") or 0),
		myclass = UnitClass("player") or "",
	}
	text = string.gsub(text, "{(%a+)}", function(key)
		local value = values[string.lower(key)]
		if value == nil then
			return "{" .. key .. "}"
		end
		return value
	end)
	return text
end

function OCS.SendWhisper(row, bucket)
	if not row or not row.name or row.name == "" then
		return false
	end
	local text = OCS.BuildWhisper(row, bucket)
	if not text or text == "" then
		OCS.Print("No whisper line set for this tab. Press the Whisp Templates button in the window, or use /ocs whisper pvelfm <text>")
		return false
	end
	if string.len(text) > 250 then
		text = string.sub(text, 1, 250)
	end
	SendChatMessage(text, "WHISPER", nil, row.name)
	row.whispered = time()
	if OCS.Refresh then
		OCS.Refresh()
	end
	return true
end

local WHISPER_CMD = {
	lfm = "pveLfm", pvelfm = "pveLfm",
	lfg = "pveLfg", pvelfg = "pveLfg",
	pvplfm = "pvpLfm", pvplfg = "pvpLfg",
	wts = "tradeWts", wtb = "tradeWtb",
	guild = "guild",
}

local function handleWhisper(rest)
	local sub, text = OCS.Match(rest, "^(%S*)%s*(.*)$")
	sub = string.lower(sub or "")
	if sub == "" then
		if OCS.ShowWhisperSetup then
			OCS.ShowWhisperSetup()
		end
		return
	end
	local slot = WHISPER_CMD[sub]
	if not slot then
		OCS.Print("Use /ocs whisper to open the setup, or /ocs whisper pvelfm | pvelfg | pvplfm | pvplfg | wts | wtb | guild <text>")
		return
	end
	if text == "" then
		OCS.Print(sub .. " line: " .. (OCS.WhisperTemplate(slot) or ""))
	else
		OCS.SetWhisperTemplate(slot, text)
		OCS.Print(sub .. " line saved: " .. text)
	end
end

SLASH_OCTOCS1 = "/ocs"
SlashCmdList["OCTOCS"] = function(msg)
	msg = msg or ""
	local cmd, rest = OCS.Match(msg, "^(%S*)%s*(.*)$")
	cmd = string.lower(cmd or "")
	rest = rest or ""

	if cmd == "" then
		if OCS.Toggle then OCS.Toggle() end
	elseif cmd == "pve" or cmd == "pvp" or cmd == "trade"
		or cmd == "guild" then
		OCS.SetSection(string.upper(cmd))
	elseif cmd == "lfm" or cmd == "lfg" or cmd == "unsure"
		or cmd == "wts" or cmd == "wtb" then
		-- A tab is an intent inside the section you are in.
		OCS.SetMode(OCS.BucketFor(OCS.GetSection(), string.upper(cmd)))
		if OCS.Show then OCS.Show() end
	elseif cmd == "style" then
		local style = string.lower(rest)
		local names = {}
		if OCS.SKIN_ORDER then
			for i = 1, OCS.Len(OCS.SKIN_ORDER) do
				table.insert(names, OCS.SKIN_ORDER[i].id)
			end
		end
		local found = false
		for i = 1, OCS.Len(names) do
			if names[i] == style then
				found = true
			end
		end
		if found then
			OCS_DB.style = style
			if OCS.ApplyStyle then OCS.ApplyStyle() end
			OCS.Print("Skin set to " .. style .. ".")
		else
			OCS.Print("Use the Skins button, or /ocs style "
				.. table.concat(names, " | "))
		end
	elseif cmd == "clear" then
		OCS.ClearBucket(OCS.GetMode())
		OCS.Print("Cleared " .. OCS.BucketName(OCS.GetMode()) .. ".")
	elseif cmd == "clearall" then
		for i = 1, OCS.Len(OCS.BUCKETS) do
			OCS_DB.rows[OCS.BUCKETS[i]] = {}
		end
		if OCS.MiniClear then OCS.MiniClear() end
		if OCS.Refresh then OCS.Refresh() end
		OCS.ForgetAllNames()
		OCS.Print("Cleared every tab.")
	elseif cmd == "reset" or (cmd == "position" and string.lower(rest) == "reset") then
		if OCS.ResetWindow and OCS.ResetWindow() then
			OCS.Print("Window back in the middle of the screen at 780 by 460.")
		else
			OCS.Print("The window is not built yet, open it with /ocs first.")
		end
	elseif cmd == "mini" then
		if string.lower(rest) == "reset" then
			if OCS.MiniResetPosition then
				OCS.MiniResetPosition()
			end
		elseif OCS.MiniToggleMode then
			OCS.MiniToggleMode()
			OCS.Print("Mini feed " .. (OCS.MiniIsShown() and "on" or "off"))
		else
			OCS.Print("The mini feed is not loaded, Mini.lua is missing or failed")
		end
	elseif cmd == "minimap" then
		OCS_DB.minimap.show = not OCS_DB.minimap.show
		if OCS.UpdateMinimapButton then OCS.UpdateMinimapButton() end
		OCS.Print("Minimap button " .. (OCS_DB.minimap.show and "shown" or "hidden"))
	elseif cmd == "alert" then
		handleAlert(rest)
	elseif cmd == "whisper" then
		handleWhisper(rest)
	elseif cmd == "pack" then
		local want = string.lower(rest)
		if want == "" then
			local pack = OCS.ActivePack()
			OCS.Print("Pack " .. pack.name .. " on realm " .. tostring(OCS.realmName)
				.. ", setting is " .. tostring(OCS_DB.pack))
			local names = {}
			for id in pairs(OCS.PACKS) do
				table.insert(names, id)
			end
			table.sort(names)
			OCS.Print("Available: auto, " .. table.concat(names, ", "))
			local acts = {}
			for i = 1, OCS.Len(pack.activities) do
				table.insert(acts, pack.activities[i].name)
			end
			OCS.Print("This pack finds: " .. table.concat(acts, ", "))
		elseif want == "auto" or OCS.PACKS[want] then
			OCS_DB.pack = want
			OCS.SelectPack(want ~= "auto" and want or nil)
			OCS.Print("Pack set to " .. OCS.ActivePack().name
				.. ". Rows already listed keep the old reading, run /ocs clearall"
				.. " to drop them. New posts use the new pack.")
			if OCS.ApplyPackColumns then
				OCS.ApplyPackColumns()
			end
			if OCS.RefreshFilterPanel then OCS.RefreshFilterPanel() end
			if OCS.Refresh then OCS.Refresh() end
		else
			OCS.Print("Unknown pack. Use /ocs pack to list them.")
		end
	elseif cmd == "expiry" then
		OCS.Print("Rows stay during play. Every load, including /reload, restores only the last hour. Use Clear Tab, Clear All or remove a row.")
	elseif cmd == "own" then
		OCS_DB.showOwn = not OCS_DB.showOwn
		OCS.Print("Own messages " .. (OCS_DB.showOwn and "included" or "ignored"))
	elseif cmd == "hidden" then
		OCS.HiddenReport(rest)
	elseif cmd == "probe" then
		if OCS.Probe then
			OCS.Probe()
		else
			OCS.Print("Diagnostics are not available.")
		end
	elseif cmd == "debug" then
		OCS_DB.debug = not OCS_DB.debug
		OCS.Print("Debug output " .. (OCS_DB.debug and "on" or "off")
			.. ". Accepted posts only, run /ocs probe for the counters.")
	elseif cmd == "help" then
		printHelp()
	else
		printHelp()
	end
end
