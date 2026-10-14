-- OctoScanner
-- Parser.lua - normalisation, token tables, classification. No game API here.
-- What counts as an activity comes from the active pack, see Packs.lua.

OCS = OCS or {}
OCS.VERSION = "1.0.0"

-- CLINK is a readable item-link format used by chat addons on this client.
local function clinkNames(s)
	return (string.gsub(s, "{[Cc][Ll][Ii][Nn][Kk]:%x+:%d+:[^:}]*:[^:}]*:[^:}]*:([^}]+)}", " %1 "))
end

local function trim(s)
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	return s
end

-- 1. Normalisation ----------------------------------------------------------

function OCS.Normalize(raw)
	if not raw then
		return " "
	end
	local t = clinkNames(raw)
	-- Chat faces are punctuation, not the single-letter Damage role.
	t = string.gsub(t, "[:;=][%-%^]?[dD%(%)]", " ")
	t = string.gsub(t, "|c%x%x%x%x%x%x%x%x", "")
	t = string.gsub(t, "|r", "")
	t = string.gsub(t, "|H.-|h", " ")
	t = string.gsub(t, "|h", " ")
	t = string.gsub(t, "|T.-|t", "")
	t = string.lower(t)
	-- Clock times must not become character levels or the ST dungeon alias.
	t = " " .. t .. " "
	for _, zone in ipairs({ "st", "cet", "cest", "est", "edt", "gmt", "utc", "msk" }) do
		t = string.gsub(t, "(%d%d?:%d%d)%s*" .. zone .. "(%W)", " clock %2")
		t = string.gsub(t, "(%d%d%d%d)%s*" .. zone .. "(%W)", " clock %2")
		if zone ~= "st" then
			t = string.gsub(t, "(%W)%d%d?%s*" .. zone .. "(%W)", "%1 clock %2")
		end
	end
	t = string.gsub(t, "%d%d?:%d%d%s*[ap]m", " clock ")
	t = string.gsub(t, "%d%d?:%d%d", " clock ")
	t = string.gsub(t, "%d+%s*[ap]m", " clock ")
	-- Observed typo: "Strath UDneed tank". Keep the Undead wing readable.
	t = string.gsub(t, " udneed ", " ud need ")
	-- Group progress such as 3/3, 8/10 or 14/15 becomes one token, so those
	-- numbers are never mistaken for a level or a wanted count.
	t = string.gsub(t, "(%d)%s*/%s*(%d)", "%1by%2")
	t = string.gsub(t, ">", " gt ")
	t = string.gsub(t, "<", " lt ")
	t = string.gsub(t, "%+%s*(%d)", " plus%1 ")
	t = string.gsub(t, "(%a)%+", "%1 plus ")
	t = string.gsub(t, "%+", " ")
	t = string.gsub(t, "[/\\,%.!%?%(%)%[%]{}:;\"'%*%%=|~#&@`^]", " ")
	t = string.gsub(t, "_", " ")
	t = string.gsub(t, "%-%-(%a)", " %1")
	t = string.gsub(t, "%s+", " ")
	t = string.gsub(t, " clock st ", " clock ")
	return " " .. trim(t) .. " "
end

function OCS.IsAddonTraffic(raw, channel, language)
	if language == "ADDON" then return true end
	if type(channel) == "string" then
		channel = string.lower(trim(channel))
		channel = string.gsub(channel, "^%d+%.%s*", "")
		if channel == "lft" or channel == "ttrp" then return true end
	end
	local s = tostring(raw or "")
	if s == "" then
		return false
	end
	-- TTRP location packets have a name, two coordinates and a version.
	if string.find(s, "^[PM][^~]+~%-?%d+%.?%d*~%-?%d+%.?%d*~%d+%.%d+%.%d+") then return true end
	-- A protocol header at the start, with no space near it.
	local head = string.sub(s, 1, 24)
	if OCS.Match(s, "^[%w]+:[%u%d]+:") and not string.find(head, " ", 1, true) then
		return true
	end
	-- A hyperlink holds a long payload by design, so a line with a link is
	-- left to the display cleaner.
	if string.find(s, "|H", 1, true) or string.find(string.lower(s), "{clink:", 1, true) then
		return false
	end
	-- Slash-separated enchant lists and texture paths can be very long words
	-- inside human adverts. Length alone is only useful for an opaque packet.
	if not string.find(s, " ", 1, true) and string.len(s) >= 24 then
		return true
	end
	return false
end

function OCS.DisplayText(raw)
	local src = tostring(raw or "")
	if src == "" then
		return ""
	end
	local hadLink = string.find(src, "|H", 1, true) ~= nil
	local t = clinkNames(src)
	t = string.gsub(t, "|c%x%x%x%x%x%x%x%x", "")
	t = string.gsub(t, "|r", "")
	t = string.gsub(t, "|T.-|t", "")
	-- A complete link keeps only the text the player reads.
	t = string.gsub(t, "|H.-|h%[(.-)%]|h", " %1 ")
	t = string.gsub(t, "|H.-|h", "")
	t = string.gsub(t, "|h", "")
	t = string.gsub(t, "|n", " ")
	t = string.gsub(t, "|", " ")
	-- Keep this result. If the next step removes too much, we fall back to it.
	local safe = trim((string.gsub(t, "%s+", " ")))
	-- The rest of a link payload is a very long word. Only a line that held a
	-- link can have one, so plain chat text is never touched.
	if hadLink then
		t = string.gsub(t, "%S+", function(w)
			if OCS.Len(w) >= 24 and not string.find(string.lower(w), "^http") and not string.find(string.lower(w), "^www%.") then
				return ""
			end
			return w
		end)
	end
	t = trim((string.gsub(t, "%s+", " ")))
	-- The Message column must never go blank. Show less clean text instead.
	if t == "" then
		t = safe
	end
	if t == "" then
		t = src
	end
	return t
end

local function has(t, token)
	return string.find(t, " " .. token .. " ", 1, true) ~= nil
end
OCS.Has = has

local function hasAny(t, list)
	for i = 1, OCS.Len(list) do
		if has(t, list[i]) then
			return true, list[i]
		end
	end
	return false
end

local function words(t)
	local out = {}
	for w in string.gfind(t, "%S+") do
		table.insert(out, w)
	end
	return out
end

-- Tokens the pack treats as a group object, such as "lf brd".
local function packGroupWord(w)
	local pack = OCS.ActivePack and OCS.ActivePack()
	if not pack or not pack.groupWords then
		return false
	end
	for i = 1, OCS.Len(pack.groupWords) do
		if pack.groupWords[i] == w then
			return true
		end
	end
	return false
end

function OCS.MarkSize(t)
	local size
	local function keep(n)
		local v = tonumber(n)
		if v and v >= 2 and v <= 40 then
			size = size or v
			return true
		end
	end
	local stems = {}
	local pack = OCS.ActivePack and OCS.ActivePack()
	if pack then
		for i = 1, OCS.Len(pack.activities) do
			local list = pack.activities[i].sizeStems
			if list then
				for j = 1, OCS.Len(list) do
					table.insert(stems, list[j])
				end
			end
		end
	end
	for i = 1, OCS.Len(stems) do
		local stem = stems[i]
		t = string.gsub(t, " " .. stem .. "(%d+) ", function(n)
			if not keep(n) then return " " .. stem .. n .. " " end
			return " " .. stem .. " size" .. n .. " "
		end)
		t = string.gsub(t, " " .. stem .. " (%d+) ", function(n)
			if not keep(n) then return " " .. stem .. " " .. n .. " " end
			return " " .. stem .. " size" .. n .. " "
		end)
	end
	t = string.gsub(t, " (%d+) ?man ", function(n)
		keep(n)
		return " size" .. n .. " man "
	end)
	-- Spelled out small groups.
	if string.find(t, " duo ", 1, true) then
		keep(2)
	end
	if string.find(t, " trio ", 1, true) then
		keep(3)
	end
	return t, size
end

-- 3. Roles ------------------------------------------------------------------

local ROLE_WORDS = {
	tank = {
		"tank", "tanks", "tanking", "tanker", "tnk", "mt", "ot", "maintank",
		"offtank", "prot", "protection", "bear", "guardian", "t",
	},
	heal = {
		"heal", "heals", "healz", "healer", "healers", "healor", "healing",
		"healler", "healo", "resto", "rdruid", "rsham", "holy", "hpal",
		"hpala", "hpriest", "disc", "tree", "healadin", "hps", "h",
	},
	damage = {
		"dps", "dd", "damage", "dmg", "rdps", "mdps", "gigadps", "pumper",
		"pumpers", "aoe", "aoes", "ranged", "melee", "caster", "arms",
		"fury", "ret", "feral", "cat", "boomkin", "moonkin", "boomy", "ele",
		"enh", "shadow", "sp", "spriest", "destro", "affli", "affly", "demo",
		"arcane", "fire", "frost", "combat", "sub", "assa", "mm", "bm",
		"surv", "mage", "lock", "warlock", "rogue", "hunter",
		"hunt", "d",
	},
}

local ROLE_WORD_MAP = {}
for role, list in pairs(ROLE_WORDS) do
	for i = 1, OCS.Len(list) do
		ROLE_WORD_MAP[list[i]] = role
	end
end

local ROLE_PHRASES = {
	{ "off tank", "tank" }, { "main tank", "tank" }, { "prot pala", "tank" },
	{ "prot paladin", "tank" }, { "prot warr", "tank" },
	{ "resto druid", "heal" }, { "resto sham", "heal" }, { "holy pala", "heal" },
	{ "holy priest", "heal" }, { "disc priest", "heal" },

	{ "warr dps", "damage" }, { "dps warr", "damage" },
	{ "ranged dps", "damage" }, { "melee dps", "damage" },
	{ "aoe dps", "damage" }, { "dps aoe", "damage" }, { "big aoe", "damage" },
	{ "huge aoe", "damage" }, { "good aoe", "damage" }, { "big pumper", "damage" },

}

-- One line that asks for everything. It fills all three roles, so a tank
-- filter and a healer filter both find the post.
local ANY_ROLE_PHRASES = {
	"lf all", "lfm all", "all roles", "any role", "any roles",
	"all welcome", "anyone welcome", "everyone welcome", "any and all",
	"need all", "need any", "need everyone", "need everything",
	"all classes", "any class welcome", "need rest", "need the rest",
}

local COMPACT = { t = "tank", h = "heal", d = "damage" }
local ROLE_ORDER = { "tank", "heal", "damage" }
OCS.ROLE_ORDER = ROLE_ORDER

-- Captions for anything a player reads. The keys stay lower case.
OCS.ROLE_LABEL = { tank = "Tank", heal = "Healer", damage = "Damage",
	any = "Any" }

function OCS.RoleLabel(role)
	return OCS.ROLE_LABEL[role] or role
end

-- Turns a stored role string such as "tank, damage" into "Tank, Damage".
-- Stored ids stay lower case, this is display only.
function OCS.RoleDisplay(text)
	if not text or text == "" then
		return "?"
	end
	local out = {}
	for word in string.gfind(tostring(text), "[^,%s]+") do
		table.insert(out, OCS.RoleLabel(word))
	end
	if OCS.Len(out) == 0 then
		return "?"
	end
	return table.concat(out, ", ")
end

-- Returns the role a single word stands for, or nil.
local function roleAt(word)
	local role = ROLE_WORD_MAP[word]
	if role then
		return role
	end
	local rest = OCS.Match(word, "^%d+(%a+)$") or OCS.Match(word, "^%d+%-%d+(%a+)$")
	if rest and ROLE_WORD_MAP[rest] then
		return ROLE_WORD_MAP[rest]
	end
	if OCS.Match(word, "^%d[thd]") and string.gsub(word, "%d[thd]", "") == "" then
		return "compact"
	end
	return nil
end

OCS.CLASSES = { "Warrior", "Paladin", "Hunter", "Rogue", "Priest",
	"Shaman", "Mage", "Warlock", "Druid" }

-- Two word spellings are read first, so "holy pala" is a paladin and not a
-- healer with no class.
local CLASS_PHRASES = {
	{ "holy pala", "Paladin" },
	{ "prot pala", "Paladin" }, { "ret pala", "Paladin" },
	{ "prot warr", "Warrior" }, { "arms warr", "Warrior" },
	{ "fury warr", "Warrior" }, { "resto druid", "Druid" },
	{ "feral druid", "Druid" }, { "resto sham", "Shaman" },
	{ "ele sham", "Shaman" }, { "enh sham", "Shaman" },
	{ "shadow priest", "Priest" }, { "holy priest", "Priest" },
	{ "disc priest", "Priest" },
}

-- Single words that name a class and nothing else. "war" is left out because
-- it is a word, and "mag" is left out because it is Magtheridon.
local CLASS_WORDS = {
	warrior = "Warrior", warriors = "Warrior", warr = "Warrior",
	warri = "Warrior", warrs = "Warrior",
	paladin = "Paladin", paladins = "Paladin", pala = "Paladin",
	pally = "Paladin", pallies = "Paladin", hpala = "Paladin",
	hpal = "Paladin", retri = "Paladin",
	hunter = "Hunter", hunters = "Hunter", huntard = "Hunter",
	hntr = "Hunter",
	rogue = "Rogue", rogues = "Rogue", rog = "Rogue", rouge = "Rogue",
	priest = "Priest", priests = "Priest", spriest = "Priest",
	hpriest = "Priest", shadowpriest = "Priest",
	shaman = "Shaman", shamans = "Shaman", sham = "Shaman",
	shammy = "Shaman", rsham = "Shaman",
	mage = "Mage", mages = "Mage",
	warlock = "Warlock", warlocks = "Warlock", lock = "Warlock",
	locks = "Warlock",
	druid = "Druid", druids = "Druid", dudu = "Druid", drood = "Druid",
	rdruid = "Druid", boomkin = "Druid", moonkin = "Druid",
}

-- Returns the text for the cell and the set the class filter reads. A post
-- naming more than two classes is a recruitment list, so the cell says so
-- rather than growing sideways.
function OCS.ParseClass(t)
	local seen, out = {}, {}
	local excluded, negative = {}, false
	local list = words(t)
	for i = 1, OCS.Len(list) do
		local w = list[i]
		if w == "no" or (w == "full" and (list[i + 1] == "on"
			or CLASS_WORDS[list[i + 1]] or list[i + 1] == "war")) then
			negative = true
		elseif negative and CLASS_WORDS[w] then
			excluded[CLASS_WORDS[w]] = true
		elseif negative and w == "war" then
			excluded.Warrior = true
		elseif w ~= "on" and w ~= "and" and w ~= "or" then
			negative = false
		end
	end
	for i = 1, OCS.Len(CLASS_PHRASES) do
		local name = CLASS_PHRASES[i][2]
		if has(t, CLASS_PHRASES[i][1]) and not seen[name] and not excluded[name] then
			seen[name] = true
			table.insert(out, name)
		end
	end
	for _, w in ipairs(words(t)) do
		local name = CLASS_WORDS[w]
		if name and not seen[name] and not excluded[name] then
			seen[name] = true
			table.insert(out, name)
		end
	end
	if OCS.Len(out) == 0 then
		return nil, nil
	end
	if OCS.Len(out) > 2 then
		return "Several", seen
	end
	return table.concat(out, " / "), seen
end

function OCS.ParseRoles(t)
	local set = {}
	for i = 1, OCS.Len(ROLE_PHRASES) do
		if has(t, ROLE_PHRASES[i][1]) then
			set[ROLE_PHRASES[i][2]] = true
		end
	end
	for _, w in ipairs(words(t)) do
		local role = ROLE_WORD_MAP[w]
		if role then
			set[role] = true
		else
			local rest = OCS.Match(w, "^%d+(%a+)$") or OCS.Match(w, "^%d+%-%d+(%a+)$")
			if rest and ROLE_WORD_MAP[rest] then
				set[ROLE_WORD_MAP[rest]] = true
			elseif OCS.Match(w, "^%d[thd]") and string.gsub(w, "%d[thd]", "") == "" then
				for _, letter in string.gfind(w, "(%d)([thd])") do
					set[COMPACT[letter]] = true
				end
			end
		end
	end
	for i = 1, OCS.Len(ANY_ROLE_PHRASES) do
		if has(t, ANY_ROLE_PHRASES[i]) then
			set.tank, set.heal, set.damage = true, true, true
			set.any = true
		end
	end
	return set
end

function OCS.RoleText(set)
	if not set then
		return "?"
	end
	-- Every role at once reads better as one word than as a list of three.
	if set.any then
		return "any"
	end
	local out = {}
	for i = 1, OCS.Len(ROLE_ORDER) do
		if set[ROLE_ORDER[i]] then
			table.insert(out, ROLE_ORDER[i])
		end
	end
	if OCS.Len(out) == 0 then
		return "?"
	end
	return table.concat(out, ", ")
end

-- 4. Intent -----------------------------------------------------------------
-- Word position carries the meaning. A role named after the looking-for token
-- is a role being recruited. A role named before it is the sender describing
-- themselves. "lf dps" recruits, "dps lf" offers.

local NOISE_WORDS = {
	"what", "whats", "why", "how", "when", "where", "who", "which", "idk",
	"should", "anyone know", "does", "do i", "can i get", "is it", "are",
	"wts", "wtb", "selling", "buying", "price", "gz", "grats", "lol",
	"ty", "thanks", "says", "bugged", "broken", "question",
}

-- Wording only a group leader uses.
local LEADER_SIGNS = {
	"pst", "pst me", "pst for inv", "pst info", "pm info", "pm me",
	"pm for info", "pm for inv", "msg me", "message me", "whisper me",
	"w me", "dm me", "invite bot", "inv bot", "priority", "spots",
	"spot", "spot left", "spots left", "join us", "we need", "forming",
	"making group", "making grp", "who wants", "anyone wants", "need more",
	"include in message", "send info", "apply",
	"looking for more", "anyone need",
	"and go", "last spot", "assembling", "gogo",
}

-- Wording only a player looking for a group uses.
local LFG_STRONG = {
	"inv me", "invite me", "inv pls", "inv plz", "inv plox", "pls inv",
	"plz inv", "invite pls", "invite plz", "send invite", "send inv",
	"invite please", "inv please", "can i join", "could i join",
	"looking to join", "want to join", "wanna join", "lf inv", "lfinv",
	"let me join", "let me in", "let me into",
	"lf invite", "need inv", "need invite", "need group", "need grp",
	"need a group", "need party", "want group", "want inv", "inv here",
	"take me", "add me", "count me", "me too", "sign me up", "im free",
	"i am free", "available for", "free for ms", "ready for ms",
}

local LFM_WEAK = {
	"lfm", "lf m", "lfmore", "lf more", "need more", "spot open",
	"spots open", "spot left", "spots left", "forming", "making group",
	"making grp", "who wants", "anyone wants", "join us", "we need",
	"still need", "more needed",
}

local LFG_WEAK = {
	"lfg", "lf g", "lf group", "lf grp", "lf grup", "lf grupe", "lf gruop",
	"looking for group", "lf party", "lf pt", "lf run", "lf raid",
	"lg", "free dps", "free heal",
	"free tank", "any room", "room for me", "plus1", "plus2", "plus3",
	"lf farm", "lf spam", "lf carry", "lf lvling", "lf leveling",
}

local SELF_ADS = {
	"geared", "i have", "i am",
	"im", "my", "free", "ready", "available", "lvling", "leveling",
	"can go", "want to go", "wanna go",
}

local function lfKindOf(w)
	if w == "lfm" or w == "lfmore" or OCS.Match(w, "^lfm%d+$") or OCS.Match(w, "^lf%d+m$") then
		return "lfm"
	end
	if w == "lfg" or w == "lg" or w == "lgf" or OCS.Match(w, "^lfg%d*$") then
		return "lfg"
	end
	if w == "lf" or OCS.Match(w, "^lf%d+$") then
		return "lf"
	end
	if w == "looking" or w == "searching" or w == "seeking" or w == "search" then
		return "lf"
	end
	if w == "need" or w == "needs" or w == "want" or w == "wants" or w == "wanted" then
		return "need"
	end
	return nil
end

function OCS.GroupRequest(t)
	if has(t, "looking for more") then return "lfm" end
	for word in string.gfind(t, "%S+") do
		local kind = lfKindOf(word)
		if kind == "lfm" or kind == "lfg" then return kind end
	end
end

local GUILD_NOUNS = { "guild", "guilds", "guilde", "gilde", "guilda", "gildia" }
local GUILD_ACTIONS = { "recruiting", "recruitment", "recruit", "recruits", "recrute", "recluta", "rekrutuje", "rekrutiert", "sucht", "gesucht", "shucht",
	"recrutement", "buscamos", "join",
	"rebuilding", "join us", "join for", "hledame", "otevira brany",
	"speaking players", "välkomna", "häng med", "te esperamos", "ishet", "nabiraet" }
function OCS.IsGuildAdvert(t, raw)
	-- A word in a guild's name does not make its PUG a guild recruitment post.
	local body = raw and OCS.Normalize((string.gsub(raw, "<[^<>]+>", " "))) or t
	local noun = hasAny(body, GUILD_NOUNS)
	local request = OCS.GroupRequest(body)
	if request and not has(body, "looking for more")
		and not hasAny(body, { "lf guild", "lfg guild", "looking for guild", "looking for a guild", "guild looking", "guild lfm" })
		and not hasAny(body, { "recruiting", "recruitment", "recruit", "recruits", "recrutement", "raid roster", "raiding roster" }) then
		return false
	end
	if hasAny(body, { "for guild", "guild run", "guild runs" }) and not hasAny(body, GUILD_ACTIONS) then return false end
	if noun and hasAny(t, GUILD_ACTIONS) then return true end
	local named = string.find(raw or "", "<[^<>]+>")
	if named and noun and not OCS.GroupRequest(t) then return true end
	if named and hasAny(t, { "needs you", "our two teams", "our raid roster", "our raiding roster", "raid schedule" }) then return true end
	if noun and has(t, "guild events") and has(t, "looking for") then return true end
	if noun and has(t, "any") and string.find(raw or "", "%?") then return true end
	if noun then
		local list = words(t)
		for i = 1, OCS.Len(list) do
			if list[i] == "lf" or list[i] == "lfg" or list[i] == "looking" then
				for j = i + 1, math.min(i + 6, OCS.Len(list)) do
					if hasAny(" " .. list[j] .. " ", GUILD_NOUNS) then return true end
					if roleAt(list[j]) or packGroupWord(list[j]) then break end
				end
			end
		end
	end
	-- A named guild can advertise a roster without spelling out "guild".
	if named then
		return hasAny(t, GUILD_ACTIONS) or hasAny(t, { "lf raiders", "looking for more", "looking for players", "raid times" })
	end
	-- Some roster adverts use a guild name in prose, then recurring raid
	-- nights and a class list. A dated PUG alone does not satisfy this.
	if not OCS.GroupRequest(t) and hasAny(t, { "every thursday", "every wednesday", "every reset" })
		and hasAny(t, { "resto", "casters", "holy", "raiders" }) then return true end
	return false
end

-- What the looking-for token points at. "lf brd" and "lf group" mean the
-- sender wants a group and any role named afterwards describes the sender.
-- "lf dps" and "lf 2 tanks" mean the sender is filling a group. This beats
-- the role-position rule, because "lf brd dps" puts the role after the token
-- while still being an offer.
local GROUP_OBJECTS = {
	["group"] = true, ["grp"] = true, ["grup"] = true, ["gruop"] = true,
	["grupe"] = true, ["gruppe"] = true, ["party"] = true, ["pt"] = true,
	["raid"] = true, ["run"] = true, ["team"] = true, ["farm"] = true,
	["farming"] = true, ["spam"] = true, ["spamm"] = true, ["loop"] = true,
	["push"] = true, ["carry"] = true, ["leveling"] = true,
	["levelling"] = true, ["lvling"] = true, ["lvls"] = true,
	["duo"] = true, ["trio"] = true,
}

-- Words that carry no meaning between the token and its object.
local OBJECT_FILLERS = {
	["a"] = true, ["an"] = true, ["the"] = true, ["for"] = true,
	["some"] = true, ["any"] = true, ["to"] = true, ["in"] = true,
	["on"] = true, ["of"] = true, ["fast"] = true, ["quick"] = true,
	["new"] = true, ["good"] = true, ["big"] = true, ["giga"] = true,
	["chill"] = true, ["active"] = true,
}

local function lfObjectIsGroup(list, at)
	for i = at + 1, math.min(at + 4, OCS.Len(list)) do
		local w = list[i]
		if OCS.Match(w, "^size%d+$") or OBJECT_FILLERS[w] then
			-- Skip and keep reading.
		elseif roleAt(w) then
			return false
		elseif OCS.Match(w, "^%d+$") then
			return false
		elseif GROUP_OBJECTS[w] or packGroupWord(w)  then
			return true
		else
			return false
		end
	end
	return false
end

-- A wanted headcount, not a level. Only small numbers count as a headcount
-- unless the text spells it out with m, more or a spot.
function OCS.RecruitCount(t)
	local explicit = OCS.Match(t, " lf ?(%d+) ?m ") or OCS.Match(t, " lf ?(%d+) ?m[thd] ")
		or OCS.Match(t, " lf ?(%d+) ?more ") or OCS.Match(t, " lfm ?(%d+) ")
		or OCS.Match(t, " need ?(%d+) ") or OCS.Match(t, " (%d+) more ")
		or OCS.Match(t, " (%d+) spot ") or OCS.Match(t, " (%d+) spots ")
		or OCS.Match(t, " want (%d+) ") or OCS.Match(t, " looking for (%d+) ")
	if explicit then
		return tonumber(explicit)
	end
	local loose = OCS.Match(t, " lf ?(%d+) ")
	if loose then
		local v = tonumber(loose)
		if v and v <= 9 then
			return v
		end
	end
	return nil
end

-- Trade has its own pair of intents. Want to trade counts as want to buy.
local WTS_WORDS = { "wts", "selling", "sell", "sells", "for sale", "lfw",
	"offering", "offer", "can craft", "crafting", "your mats",
	"providing", "in stock" }
local WTB_WORDS = { "wtb", "buying", "buy", "wtt", "paying", "will pay",
	"looking for", "need", "needs", "want", "wanted", "searching for",
	"lf", "lfw for", "anyone selling" }

function OCS.TradeIntent(t)
	local head = OCS.Match(t, "^%s*(%a+)")
	if head == "wts" or head == "sell" or head == "selling" then return "WTS" end
	if head == "wtb" or head == "wtt" or head == "buy" or head == "buying" then return "WTB" end
	if has(t, "lfw") or has(t, "looking for work") then return "WTS" end
	if has(t, "lf") or has(t, "looking for") or has(t, "anyone selling")
		or (OCS.GroupRequest(t) == "lfm" and has(t, "crafter")) then return "WTB" end
	for i = 1, OCS.Len(WTS_WORDS) do
		if has(t, WTS_WORDS[i]) then
			return "WTS"
		end
	end
	for i = 1, OCS.Len(WTB_WORDS) do
		if has(t, WTB_WORDS[i]) then
			return "WTB"
		end
	end
	return "UNSURE"
end

function OCS.Classify(t)
	local list = words(t)
	local firstLF, kind
	for i = 1, OCS.Len(list) do
		local k = lfKindOf(list[i])
		if k and not firstLF then
			firstLF, kind = i, k
		end
	end

	local before, after = {}, {}
	local countBefore, countAfter = 0, 0
	for i = 1, OCS.Len(list) do
		local role = roleAt(list[i])
		if role then
			if firstLF and i > firstLF then
				if not after[role] then
					after[role] = true
					countAfter = countAfter + 1
				end
			else
				if not before[role] then
					before[role] = true
					countBefore = countBefore + 1
				end
			end
		end
	end

	local leader = hasAny(t, LEADER_SIGNS) or (has(t, "pug") and has(t, "sr") and has(t, "rt"))
	local selfAd = hasAny(t, SELF_ADS)
	local count = OCS.RecruitCount(t)

	-- 1. Someone asking to be taken along says so plainly.
	if hasAny(t, LFG_STRONG) then
		return "LFG"
	end
	-- A loot reservation "for Guild" does not change an explicit raid LFM.
	if kind == "lfm" or count then return "LFM" end
	if kind == "lfg" then return "LFG" end

	-- 2. Guild adverts and chatter.
	if has(t, "recruiting") or has(t, "recruit") or has(t, "recrute") then
		return "UNSURE"
	end
	if not firstLF and not leader and not hasAny(t, LFM_WEAK)
		and not hasAny(t, LFG_WEAK) and hasAny(t, NOISE_WORDS) then
		return "UNSURE"
	end

	-- 3. need or want: a role after it is being recruited.
	if kind == "need" then
		if hasAny(t, ANY_ROLE_PHRASES) then return "LFM" end
		if countAfter > 0 then
			return "LFM"
		end
		if countBefore > 0 then
			return "LFG"
		end
		return leader and "LFM" or "LFG"
	end

	-- 4. Bare lf: what the token points at wins, then role position.
	if kind == "lf" then
		-- "lf brd", "lf brd dps", "lf group", "searching for brd": the sender
		-- wants the group, so a role afterwards describes the sender.
		if lfObjectIsGroup(list, firstLF) then
			if count or leader or string.find(t, "%d+by%d+") then
				return "LFM"
			end
			return "LFG"
		end
		if countAfter >= 2 then
			return "LFM"
		end
		if countAfter == 1 then
			if leader then
				return "LFM"
			end
			if selfAd or countBefore > 0 then
				return "LFG"
			end
			return "LFM"
		end
		if countBefore > 0 then
			return "LFG"
		end
		if leader then
			return "LFM"
		end
		return "LFG"
	end

	-- 5. No looking-for token at all.
	if string.find(t, "%d+by%d+") then
		-- Group progress such as 2/2 tanks, 8/10 dps, 14/15.
		return "LFM"
	end
	if hasAny(t, LFM_WEAK) or leader then
		return "LFM"
	end
	if hasAny(t, LFG_WEAK) then
		return "LFG"
	end
	if countBefore > 0 and (selfAd or countBefore >= 1) then
		return "LFG"
	end
	return "UNSURE"
end

-- Character level; 60 is the Vanilla cap.
local LEVEL_CAP = 60

-- Published so the cell editor accepts exactly what the parser accepts.
OCS.LEVEL_CAP = LEVEL_CAP

function OCS.SetLevelCap(value)
	value = tonumber(value)
	if not value or value < 10 or value > 255 then
		return
	end
	LEVEL_CAP = value
	OCS.LEVEL_CAP = value
end

local LEVEL_PATTERNS = {
	" lvl (%d+) ", " lvl(%d+) ", " lv (%d+) ", " lv(%d+) ",
	" level (%d+) ", " level(%d+) ", " (%d+) lvl ", " (%d+)lvl ",
	" (%d+) lv ", " (%d+)lv ", " l(%d+) ",
}

function OCS.ParseLevel(t, hasCount)
	for i = 1, OCS.Len(LEVEL_PATTERNS) do
		local v = tonumber(OCS.Match(t, LEVEL_PATTERNS[i]) or "")
		if v and v >= 1 and v <= LEVEL_CAP then
			return v, false
		end
	end
	local lo, hi = OCS.Match(t, " (%d+)%s*%-%s*(%d+) ")
	if lo and hi then
		lo, hi = tonumber(lo), tonumber(hi)
		if lo and hi and lo >= 1 and hi <= LEVEL_CAP and lo <= hi then
			return lo, true
		end
	end
	-- A lone number can be a level, but only when nothing else claims it.
	if not hasCount then
		local found, seen = nil, 0
		for _, w in ipairs(words(t)) do
			if OCS.Match(w, "^%d+$") then
				seen = seen + 1
				found = tonumber(w)
			end
		end
		if seen == 1 and found and found >= 10 and found <= LEVEL_CAP then
			return found, false
		end
	end
	return nil, false
end

-- 7. Pack activities and group progress ------------------------------------

-- Which activity the message is about, or nil when the pack knows nothing
-- about it. Pack order decides precedence; named content beats generic words.
function OCS.MatchActivity(t)
	local pack = OCS.ActivePack and OCS.ActivePack()
	if not pack then
		return nil
	end
	for i = 1, OCS.Len(pack.activities) do
		local a = pack.activities[i]
		local hit = false

		if not hit and a.phrases then
			for j = 1, OCS.Len(a.phrases) do
				if has(t, a.phrases[j]) then
					hit = true
					break
				end
			end
		end
		if not hit and a.words then
			for j = 1, OCS.Len(a.words) do
				if has(t, a.words[j]) then
					hit = true
					break
				end
			end
		end

		-- A named target always enriches the row. It only identifies the
		-- activity when the pack says so.
		local target
		if a.targets then
			for j = 1, OCS.Len(a.targets) do
				if has(t, a.targets[j]) then
					target = a.targets[j]
					if a.targetIdentifies then
						hit = true
					end
					break
				end
			end
		end

		if hit then
			return a.id, a.name, a.short or a.name, target
		end
	end
	-- Octo group adverts use BM for Black Morass, including plain "LFG BM".
	-- Explicit content above wins; a Hunter/spec advert must never be remapped.
	local intent = OCS.Classify(t)
	if pack.bmDungeon and has(t, "bm") and (intent == "LFM" or intent == "LFG")
		and not hasAny(t, { "hunter", "hunters", "hunt", "huntard", "hntr",
			"beast mastery", "beastmastery", "beast master", "pet", "spec" }) then
		return "DGN", "Dungeon", "Dungeon", "black morass"
	end
	if has(t, "pug") and has(t, "sr") and has(t, "rt") then
		return "RAID", "Raid", "Raid", nil
	end
	-- An Emperor run without the BRD acronym. Only interpret it in a group
	-- request; the word emperor by itself is not enough.
	if OCS.GroupRequest(t) and hasAny(t, { "emp runs", "emp run", "emp jump run", "emp lava jump run", "emperor" }) then
		return "DGN", "Dungeon", "Dungeon", "brd"
	end
	if OCS.GroupRequest(t) and has(t, "gnome") then return "DGN", "Dungeon", "Dungeon", "gnomeregan" end
	return nil
end

local XP_WORDS = { "xp", "xps", "exp", "exps", "experience", "leveling",
	"levelling", "lvling", "lvlup", "powerlevel", "powerleveling" }
local XP_PHRASES = {
	"xp farm", "exp farm", "xp farming", "exp farming", "xp spam",
	"exp spam", "xp grind", "exp grind", "xp run", "exp run",
	"got xp", "for xp", "need xp", "want xp", "xp boost", "boost xp",
	"power level", "power leveling", "power levelling", "level up",
	"lvl up", "dungeon leveling", "dungeon levelling",
}

local BOOST_WORDS = { "boost", "boosts", "boosting", "boosted", "boostin",
	"carry", "carries", "carrying", "carried", "plvl", "plevel" }
local BOOST_PHRASES = { "boost run", "boost runs", "carry run", "carry runs",
	"boost group", "carry group" }

function OCS.ParseBoost(t)
	if not (t and OCS.Has) then
		return false
	end
	for i = 1, OCS.Len(BOOST_PHRASES) do
		if OCS.Has(t, BOOST_PHRASES[i]) then
			return true
		end
	end
	for i = 1, OCS.Len(BOOST_WORDS) do
		if OCS.Has(t, BOOST_WORDS[i]) then
			return true
		end
	end
	return false
end

function OCS.ParseLevelling(t)
	if not (t and OCS.Has) then
		return false
	end
	for i = 1, OCS.Len(XP_PHRASES) do
		if OCS.Has(t, XP_PHRASES[i]) then
			return true
		end
	end
	for i = 1, OCS.Len(XP_WORDS) do
		if OCS.Has(t, XP_WORDS[i]) then
			return true
		end
	end
	return false
end

OCS.DIFF_ORDER = {}

-- Raid progress. Normalisation already folded 15/25 into 15by25. A total of
-- ten or more also settles the group size, which is how tours advertise it.
function OCS.ParseProgress(t)
	local a, b = OCS.Match(t, "(%d+)by(%d+)")
	if not a then
		return nil
	end
	local have, total = tonumber(a), tonumber(b)
	if not have or not total then
		return nil
	end
	if total < 2 or total > 40 or have > total then
		return nil
	end
	local size
	if total >= 10 then
		size = total
	end
	return have .. "/" .. total, size
end

-- 8. Entry point ------------------------------------------------------------

-- Addon adverts are not player adverts. FrostSeek broadcasts its own link into
-- the same channels, and it matched the LFG wording in the log.
local AD_MARKS = {
	"frostseek", "github.com", "curseforge",
}

function OCS.IsAddonAdvert(raw)
	local low = string.lower(tostring(raw or ""))
	for i = 1, OCS.Len(AD_MARKS) do
		if string.find(low, AD_MARKS[i], 1, true) then
			return true
		end
	end
	return false
end

local PVP_BG = {
	"bg", "bgs", "battleground", "battlegrounds", "wsg", "warsong",
	"warsong gulch", "ab", "arathi", "arathi basin", "av", "alterac",
	"alterac valley",
}
local PVP_OTHER = {
	"pvp", "premade", "premades", "rated", "wpvp", "world pvp",
	"duel", "duels", "honor farm",
}
local QUEUE_WORDS = { "queue", "que", "queu", "q", "join", "join up", "sign", "reg", "more for", "come av", "come wsg" }
-- Weak pvp words only count when the line also wants people.
local PVP_WEAK = { "honor", "rating", "cap", "partner", "teammates" }

function OCS.MatchPvP(t)
	local entries = OCS.ActivePack().pvp or {}
	for i = 1, OCS.Len(entries) do
		local entry = entries[i]
		for j = 1, OCS.Len(entry.aliases) do
			if has(t, entry.aliases[j]) then return entry.kind, entry.name end
		end
	end
	if OCS.ActivePack().pvp and has(t, "arena") then return "ARENA" end
	for i = 1, OCS.Len(PVP_BG) do
		if has(t, PVP_BG[i]) then return "BG" end
	end
	for i = 1, OCS.Len(PVP_OTHER) do
		if has(t, PVP_OTHER[i]) then return "PVP_OTHER" end
	end
	for i = 1, OCS.Len(PVP_WEAK) do
		if has(t, PVP_WEAK[i]) then
			local intent = OCS.Classify(t)
			if intent == "LFM" or intent == "LFG" then
				return "PVP_UNSURE"
			end
			return nil
		end
	end
	return nil
end

local TRADE_WORDS = { "wts", "wtb", "wtt", "selling", "buying", "trading", "lfw" }

local GOODS = {
	{ id = "MOUNT", name = "Mount", words = { "reins of", "mount" } },
	{ id = "RECIPE", name = "Recipe", words = { "recipe", "pattern", "formula",
		"schematic", "plans" } },
	{ id = "CONSUM", name = "Consumable", words = { "flask", "flasks", "potion",
		"elixir", "scroll of", "arcanum", "mana oil", "wizard oil" } },
	{ id = "GEAR", name = "Gear", words = { "staff", "sword", "greatsword",
		"axe", "dagger", "blade", "runeblade", "warblade", "slicer", "saber",
		"mace", "hammer", "spear", "glaive", "bow", "gun", "wand", "shield", "rapier", "scepter", "bulwark", "cuirass",
		"buckler", "effigy", "tomahawk", "cloak", "cape", "robe", "tunic",
		"vest", "hood", "helm", "crown", "shoulders", "pauldrons", "bracers",
		"gauntlets", "gloves", "belt", "girdle", "leggings", "pants", "boots",
		"treads", "ring of", "band", "pendant", "necklace", "amulet", "wings",
		"attire", "armor", "armour", "gemstone" } },
}

-- What a trade line is about. Only used when nothing more precise matched.
function OCS.MatchGoods(t)
	if hasAny(t, { "head legs", "head and legs", "helm legs", "head leg" })
		and hasAny(t, { "haste", "dodge", "enchants" }) then return "CONSUM", "Consumable" end
	local extra = OCS.ActivePack().goods or {}
	for i = 1, OCS.Len(extra) do
		local g = extra[i]
		for j = 1, OCS.Len(g.words) do
			if has(t, g.words[j]) then return g.id, g.name end
		end
	end
	for i = 1, OCS.Len(GOODS) do
		local g = GOODS[i]
		for j = 1, OCS.Len(g.words) do
			if has(t, g.words[j]) then
				return g.id, g.name
			end
		end
	end
	return nil
end

function OCS.MatchTrade(t)
	for i = 1, OCS.Len(TRADE_WORDS) do
		if has(t, TRADE_WORDS[i]) then return "TRADE_UNSURE" end
	end
	return nil
end

local SPAM_WORDS = { "wts", "wtb", "wtt", "selling", "buying" }

local STREAM_WORDS = { "twitch tv", "twitch", "t tv", "youtube", "youtu be",
	"youtu", "discord gg", "streaming", "live now", "has conjured" }

local GROUP_PROOF = { "lfm", "lfg", "lf inv", "need tank", "need tanks",
	"need heal", "need healer", "need healers", "need dps", "need dd",
	"need dds", "ms os", "pedir inv", "whisp class" }

function OCS.IsSpam(raw, t)
	-- A line that proves it is a real advert is never spam, whatever else it
	-- says.
	if hasAny(t, GROUP_PROOF) or OCS.RecruitCount(t)
		or (OCS.Classify(t) == "LFM" and hasAny(t, { "lf", "looking for", "need" })) then
		return false
	end
	-- Stream adverts are dropped entirely. They are not group content and
	-- they repost endlessly. Trade has its own tabs.
	for i = 1, OCS.Len(STREAM_WORDS) do
		if has(t, STREAM_WORDS[i]) then
			return true
		end
	end
	return false
end

-- Public chat often discusses LFG, trade or recruitment. The keyword alone
-- must not turn that discussion into a group advert.
local META_CHAT = { "why spam", "go lfg", "join lfg", "guild recruitment channel", "command to join pvp", "refuse to join a guild",
	"guild-recruitment channel", "can we make that the channel", "need to read quest text",
	"delete your wdb", "those of you selling", "world is buying phones",
	"buying diesel", "ai selling", "for gardening you simply" }

local questVocabulary
local function questContext(raw, t)
	local first = OCS.Match(raw, "|Hquest:[^|]+|h%[([^%]]+)%]|h")
	local firstPosition
	if not questVocabulary then
		questVocabulary = {}
		for _, title in ipairs(OCS.QUEST_TITLES or {}) do
			table.insert(questVocabulary, { title, OCS.Normalize(title) })
		end
	end
	local detail = t
	-- Known titles also cover copies whose hyperlinks have become plain text.
	for _, entry in ipairs(questVocabulary) do
		local at = string.find(t, entry[2], 1, true)
		if at then
			if not firstPosition or at < firstPosition then
				if not OCS.Match(raw, "|Hquest:") then first = entry[1] end
				firstPosition = at
			end
			local escaped = string.gsub(entry[2], "(%W)", "%%%1")
			detail = string.gsub(detail, escaped, " ")
		end
	end
	-- Unknown quest links still must not contribute role/class/level words.
	for title in string.gfind(raw, "|Hquest:[^|]+|h%[([^%]]+)%]|h") do
		local escaped = string.gsub(OCS.Normalize(title), "(%W)", "%%%1")
		detail = string.gsub(detail, escaped, " ")
	end
	return first, " " .. trim((string.gsub(detail, "%s+", " "))) .. " "
end

local function groupSignal(t)
	return OCS.GroupRequest(t) or hasAny(t, LFG_STRONG) or hasAny(t, LFM_WEAK)
		or OCS.RecruitCount(t) or hasAny(t, { "last spot", "and go", "listo para", "assembling", "queue for", "gogo" })
		or (has(t, "sr") and has(t, "ms") and has(t, "os"))
		or (has(t, "pug") and has(t, "sr") and has(t, "rt"))
		or hasAny(t, { "lf", "looking for", "searching for", "seeking", "need", "needs",
			"want", "wanted", "looking", "forming", "anyone doing", "anyone running",
			"anyone for", "anyone wanna", "anyone want", "anyone need", "anyone help", "anyone up for",
			"anyone recruiting", "anyone one run", "up to chain", "run me", "fl", "down for", "can join",
			"help me", "help with", "wanna help", "gente para", "busco", "busca", "cherchons", "suchen noch" })
		or string.find(t, "%d+by%d+")
end

function OCS.Parse(raw)
	local t = OCS.Normalize(raw)
	if OCS.IsAddonTraffic(raw) or OCS.IsAddonAdvert(raw) then
		return nil, t
	end
	if hasAny(t, META_CHAT) then return nil, t end
	local quest, detail = questContext(raw, t)
	if has(t, "buff may drop soon") and has(t, "might end soon") and not OCS.GroupRequest(t) then return nil, t end
	local guildAdvert = OCS.IsGuildAdvert(t, raw)
	if OCS.IsSpam(raw, t) and not guildAdvert then
		return nil, t
	end
	local size
	t, size = OCS.MarkSize(t)
	detail = OCS.MarkSize(detail)
	local actId, actName, actShort, target = OCS.MatchActivity(t)
	if guildAdvert then actId, actName, actShort, target = "GUILD", "Guild", "Guild", nil end
	if OCS.PrettyName(target) == "Caverns of Time: Black Morass" then
		-- Here BM names the instance, rather than a requested Damage spec.
		t = string.gsub(t, " bm ", " black morass ")
		detail = string.gsub(detail, " bm ", " black morass ")
	end
	-- A line that opens with wts / wtb / wtt is trade whatever it names.
	local head = OCS.Match(t, "^%s*(%a+)")
	local tradeHead = head == "wts" or head == "wtb" or head == "wtt"
		or head == "sell" or head == "selling" or head == "buy" or head == "buying" or head == "lfw"
	if (head == "sell" or head == "buy") and not OCS.MatchGoods(t) then tradeHead = false end
	local offerProfession = OCS.ParseProfession(t, true)
	if guildAdvert or OCS.GroupRequest(t) or OCS.TradeIntent(t) == "WTB" or not hasAny(t, {
		"lfw", "your mats", "all gems", "can craft", "looking for work", "offering", "for sale", "available", "here", "pst", "donations",
	}) and not (offerProfession and string.find(raw, ":", 1, true) and string.find(t, "%d")) then offerProfession = nil end
	if offerProfession then tradeHead = true end
	-- Transport offers often list instances as destinations without WTS.
	local price = string.find(t, " %d+ ?g ") or string.find(t, " %d+ ?gold ")
	local transport = not OCS.GroupRequest(detail) and (
		(hasAny(t, { "summon", "summons", "summoning", "portal", "portals" })
			and (string.find(string.lower(raw), "summons:", 1, true)
				or price or hasAny(t, { "will pay", "paying" })))
		or (price and hasAny(t, { "taxi", "t a x i" }))
		or (hasAny(t, { "ubrs", "ubers" }) and has(t, "key")
			and hasAny(t, { "service", "will pay" })))
	if transport then tradeHead = true end
	if tradeHead then
		actId, actName, actShort, target = nil, nil, nil, nil
	end

	-- PvP. No activity matched, so arenas and battlegrounds get their say
	-- before professions and trade do.
	local route, subBucket
	if not actId and not tradeHead then
		subBucket, target = OCS.MatchPvP(t)
		if subBucket then
			route = "PVP"
		end
	elseif actId == "GUILD" then
		-- Guild recruitment is its own section. A guild that recruits for PvP
		-- or for raids is still a guild, so there is nothing to route by
		-- content and nothing worth splitting by intent.
		route = "GUILD"
		subBucket = "GUILD"
	end

	-- Profession fallback. "LF BS with lionheart" and "Enchanter LFW your
	-- mats" name a craft, not an activity. These rows land in the Prof tab.
	local profession, profMode
	if transport then route, subBucket = "TRADE", "TRADE_UNSURE" end
	-- A role roster with raid loot rules is still a group advert when it
	-- names an enchant recipe reservation but omits the instance name.
	if not actId and not route and not tradeHead and has(t, "sr") and has(t, "ms") and has(t, "os")
		and next(OCS.ParseRoles(detail)) then
		actId, actName, actShort = "OTHER", "Group", "Group"
	end
	if not actId and not route and offerProfession then
		profession, profMode, route, subBucket = offerProfession, "offering", "TRADE", "PROF"
	end
	if not actId and not route and tradeHead and head ~= "lfw" then
		local goodsId, goodsName = OCS.MatchGoods(t)
		local materialService = goodsId == "GEAR" and OCS.TradeIntent(t) == "WTB"
			and hasAny(t, { "my mats", "have mats" })
		if not materialService and (goodsId == "RECIPE" or goodsId == "CONSUM"
			or (goodsId and (string.find(raw, "|Hitem:", 1, true) or string.find(string.lower(raw), "{clink:", 1, true)))) then
			route, subBucket, actName, actShort = "TRADE", goodsId, goodsName, goodsName
		end
	end
	if not actId and not route then
		profession, profMode = OCS.ParseProfession(t)
		if profession then
			route = "TRADE"
			subBucket = "PROF"
		end
	end

	if not actId and not route then
		subBucket = OCS.MatchTrade(t)
		if not subBucket and tradeHead and OCS.MatchGoods(t) then subBucket = "TRADE_UNSURE" end
		if subBucket then
			route = "TRADE"
		end
	end

	if not actId and not route then
        local roles = OCS.ParseRoles(t)
        local classes = OCS.ParseClass(t)
        local request = OCS.GroupRequest(t)
        local questWords = hasAny(t, { "quest", "quests", "elite", "elites", "qs", "exlite" })
            and (request or hasAny(t, { "lf", "need", "looking for" }))
        if (request and OCS.Len(words(t)) > 1)
            or ((next(roles) or classes) and OCS.RecruitCount(t))
            or (quest and (hasAny(t, { "lf", "looking for more", "anyone need" })
                or (next(roles) and OCS.Classify(t) == "LFM"))) or questWords then
            actId, actName, actShort = "OTHER", "Group", "Group"
            if quest or questWords then actName, actShort, target = "Quest group", "Quest", quest end
        else
            return nil, t
        end
    end
	local intent = OCS.Classify(detail)
	-- A question is not an advert.
	if string.find(raw, "%?%s*$") and not hasAny(t, LFG_STRONG)
		and not has(t, "lfm") and not has(t, "lfg") and not OCS.RecruitCount(t) then
		intent = "UNSURE"
	end
	-- Spanish, French and German adverts. Measured in the Vol'jin log:
	-- "GENTE PARA AZUREGOS PEDIR INV QUEDAN POCOS HUECOS" is a leader.
	local LFM_FOREIGN = { "gente para", "mas gente", "pedir inv", "quedan pocos",
		"hay sumon", "faltan", "necesitamos", "vamos a matar", "venez",
		"cherchons", "suchen noch" }
	local LFG_FOREIGN = { "busco grupo", "quiero entrar", "cherche groupe",
		"suche gruppe", "cerco gruppo" }
	if hasAny(t, LFM_FOREIGN) then
		intent = "LFM"
	elseif hasAny(t, LFG_FOREIGN) then
		intent = "LFG"
	end

	-- Talking about content is not looking for it.
	-- Opinions about content, classes and balance are the bulk of what a global
	-- channel carries. None of it is an advert.
	local CHATTER = { "tbh", "imo", "imho", "no point", "i think", "i guess", "i hope",
		"i waited", "i destroyed", "they put", "worst dungeon", "is there a",
		"where is", "how can i", "do we have", "do you have",
		"one of our", "before twow", "big drop", "worth anything",
		"does anyone know", "anyone know", "why is", "what is", "how do",
		"is tier", "tier s", "tier a", "better than", "is better",
		"is worse", "is trash", "is garbage", "any good", "worth it",
		"nerfed", "buffed", "after the buff", "after the nerf", "sucks",
		"suks", "the meta", "in my opinion", "i agree", "i disagree",
		"skill issue", "you should", "they should",
		-- Trade chat argues about prices and warns about people as much as it
		-- sells. None of that is an offer.
		"scam", "scammer", "scamming", "scammed", "flipper", "flipping",
		"dont buy from", "do not buy from", "dont get underpaid",
		"overprice", "overpriced", "underpaid", "check other buyers",
		"doesnt mean", "does not mean", "dont get" }
	-- Anything here means the line still asks for something, so opinion
	-- wording only downgrades it instead of dropping it.
	-- Trade verbs such as "selling" are deliberately not here. Warning other
	-- players off a seller uses the same words as selling does, and this list
	-- only decides whether a line that already reads as opinion is kept.
	local INVITE_MARKERS = { "lf", "inv", "invite", "invites", "pst", "pm",
		"whisper", "w me", "msg me", "dm", "join", "joining", "need",
		"looking for", "wts", "wtb", "wtt", "recruiting", "recruit",
		"apply", "spot", "spots", "summon", "summons", "port", "boost",
		"boosting", "carry" }
	if not guildAdvert and not has(t, "lfm") and not has(t, "lfg") and not OCS.RecruitCount(t)
		and not hasAny(t, LFG_STRONG) then
		if hasAny(t, CHATTER) then
			intent = "UNSURE"
			-- Nothing in the line asks for anything at all. An opinion about a
			-- class, a boss or the meta is not an advert, so it is dropped
			-- rather than parked in Unsure, where it only pads the tab.
			if not hasAny(t, INVITE_MARKERS) then
				return nil
			end
		end
	end
	if intent == "UNSURE" and not guildAdvert and has(t, "trinket")
		and not hasAny(t, INVITE_MARKERS) and not tradeHead then return nil, t end

	-- Asking whether anyone runs a thing is asking to join it.
	local queryRequest
	if not has(t, "lfm") and not OCS.RecruitCount(t) then
		if string.find(t, "any group") or string.find(t, "any .- groups? ")
			or string.find(t, "any .- forming ")
			or string.find(t, "anyone doing") or string.find(t, "anyone running")
			or string.find(t, "any .- spam run") or string.find(t, "any run") or string.find(t, "spammer")
			or string.find(t, "any .- tour") or string.find(t, "can i join")
			or string.find(t, "looking to join") or string.find(t, " any .-going on ")
			or string.find(t, "anyone assembling") then
			intent = "LFG"
			queryRequest = true
		end
	end
	-- Keep compact, ambiguous PvE requests in Unsure, but discard sentences
	-- that only mention content. Queue calls are PvP recruitment, not chatter.
	local anyRequest = string.find(t, "^ any ") and OCS.Len(words(t)) <= 8
		and not hasAny(t, { "buff", "dropping", "drop", "tier", "trinket" })
	if route == "PVP" then
		-- A price such as 1g 3s 63c is not the Blood Ring 3s bracket.
		if not OCS.GroupRequest(detail) and string.find(t, "%d+g ") and string.find(t, "%d+s ") then return nil, t end
		if hasAny(t, QUEUE_WORDS) then
			if not hasAny(t, LFG_STRONG) and not OCS.GroupRequest(detail) then intent = "LFM" end
		elseif anyRequest or queryRequest then intent = "LFG"
		elseif not groupSignal(detail) and not (OCS.Len(words(t)) <= 4 and string.find(t, "%d")) then return nil, t end
	elseif route == "TRADE" then
		if not tradeHead and not offerProfession and not transport and not OCS.GroupRequest(detail)
			and not anyRequest and not (profession and string.find(t, "^ any "))
			and not hasAny(t, { "wts", "wtb", "wtt", "lfw", "lf", "looking for", "can craft", "your mats", "offering", "selling", "buying", "buy", "paying", "donations", "available", "need", "free", "pst" }) then return nil, t end
	elseif not guildAdvert and not groupSignal(detail) and not anyRequest and not queryRequest then
		local compact = OCS.Len(words(t)) <= 3 and target
		local selfRole = next(OCS.ParseRoles(detail)) and OCS.Len(words(t)) <= 7
		if not compact and not selfRole then return nil, t end
	end
	if anyRequest and intent == "UNSURE" and route ~= "GUILD" then intent = "LFG" end
	if route == "PVP" or route == "TRADE" then
		actName = subBucket == "GUILD" and "Guild"
			or subBucket == "ARENA" and "Arena"
			or subBucket == "BG" and "Battleground"
			or subBucket == "PVP_OTHER" and "PvP"
			or subBucket == "PVP_UNSURE" and "PvP"
			or subBucket == "TRADE_UNSURE" and "Trade"
			or actName
		actShort = actName
	end
	-- The tab is decided by intent alone. What the line is about travels with
	-- the row as kind, and the filter panel uses it.
	local kind
	if route == "PVP" then
		kind = (subBucket == "PVP_UNSURE") and "PVP_OTHER" or subBucket
	elseif route == "TRADE" then
		kind = (subBucket == "TRADE_UNSURE") and "TRADE_OTHER" or subBucket
		if kind == "TRADE_OTHER" and not transport then
			local goodsId, goodsName = OCS.MatchGoods(t)
			if goodsId then
				kind = goodsId
				actName, actShort = goodsName, goodsName
			end
		end
	else
		kind = actId or "OTHER"
	end
	-- Emerald Sanctum has a Turtle hard mode. HC alone is also used for
	-- hardcore characters, so only explicit mode wording is interpreted.
	if kind == "RAID" and OCS.PrettyName(target) == "Emerald Sanctum" then
		if hasAny(t, { "hard mode", "hardmode", "eshardmode", "es hm" }) then
			actName, actShort = "Raid (Hard Mode)", "Raid (Hard Mode)"
		elseif hasAny(t, { "normal", "esnormal", "es nm" }) then
			actName, actShort = "Raid (Normal)", "Raid (Normal)"
		end
	end
	local tradeIntent
	if route == "TRADE" then
		tradeIntent = offerProfession and "WTS" or OCS.TradeIntent(t)
		if transport and tradeIntent == "UNSURE" then tradeIntent = "WTS" end
		if profession and tradeIntent == "UNSURE" then tradeIntent = profMode == "offering" and "WTS" or "WTB" end
	end

	local count = OCS.RecruitCount(detail)
	local level, bracket = OCS.ParseLevel(detail, count ~= nil)
	local roleSet = OCS.ParseRoles(detail)
	if intent == "LFM" and route ~= "TRADE" and not next(roleSet) then
		roleSet.tank, roleSet.heal, roleSet.damage = true, true, true
		roleSet.any = true
	end
	local classText, classSet = OCS.ParseClass(detail)
	local prog, progSize = OCS.ParseProgress(t)
	local levelling = OCS.ParseLevelling(t)
	if not levelling and route ~= "TRADE" and OCS.ParseBoost(t) then
		levelling = true
	end
	return {
		intent = intent,
		kind = kind,
		tradeIntent = tradeIntent,
		activity = actId,
		activityName = actName,
		activityShort = actShort,
		levelling = levelling,
		profession = profession,
		profMode = profMode,
		route = route,
		subBucket = subBucket,
		target = OCS.PrettyName and OCS.PrettyName(target) or target,
		roleSet = roleSet,
		roleText = OCS.RoleText(roleSet),
		class = classText,
		classSet = classSet,
		prog = prog,
		level = level,
		bracket = bracket,
		size = size or progSize,
		wanted = count,
	}, t
end
