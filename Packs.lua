-- Vanilla roster and content pack construction. No server API.
OCS = OCS or {}
OCS.PACKS, OCS.PRETTY = {}, {}
OCS.DEFAULT_PACK = "vanilla"
OCS.VANILLA_CONTENT = {
    { "DGN", "Ragefire Chasm", { "ragefire chasm", "rfc" } },
    { "DGN", "Wailing Caverns", { "wailing caverns", "wc" } },
    { "DGN", "The Deadmines", { "the deadmines", "deadmines", "deadmine", "dead mines", "dead mes", "dm", "vc" } },
    { "DGN", "Shadowfang Keep", { "shadowfang keep", "shadownfang keep", "sfk" } },
    { "DGN", "Blackfathom Deeps", { "blackfathom deeps", "blackfathom deep", "blackphantom deeps", "bfd" } },
    { "DGN", "The Stockade", { "stormwind stockade", "the stockade", "the stockades", "stockade", "stockades", "stocks" } },
    { "DGN", "Gnomeregan", { "gnomeregan", "gnomer" } },
    { "DGN", "Razorfen Kraul", { "razorfen kraul", "razorfren kraul", "razorfren", "rfk" } },
    { "DGN", "Scarlet Monastery: Graveyard", { "scarlet monastery graveyard", "sm graveyard", "sm gy", "smgy" } },
    { "DGN", "Scarlet Monastery: Library", { "scarlet monastery library", "sm library", "sm lib", "smlib" } },
    { "DGN", "Scarlet Monastery: Armory", { "scarlet monastery armory", "scarlet monastery armoury", "sm armory", "sm armoury", "sm arm", "smarm" } },
    { "DGN", "Scarlet Monastery: Cathedral", { "scarlet monastery cathedral", "sm cathedral", "sm cath", "smcath" } },
    { "DGN", "Scarlet Monastery", { "scarlet monastery", "sm" } },
    { "DGN", "Razorfen Downs", { "razorfen downs", "razorfen down", "razorfen downes", "rfd" } },
    { "DGN", "Uldaman", { "uldaman", "ulda" } },
    { "DGN", "Zul'Farrak", { "zul farrak", "zulfarrak", "zf" } },
    { "DGN", "Maraudon", { "maraudon", "maraundon", "mauradon", "mara" } },
    { "DGN", "Sunken Temple", { "temple of atal hakkar", "sunken temple", "sunkentemple", "atal hakkar", "st" } },
    { "DGN", "Blackrock Depths", { "blackrock depths", "brd" } },
    { "DGN", "Lower Blackrock Spire", { "lower blackrock spire", "lower blackrock", "lbrs" } },
    { "DGN", "Upper Blackrock Spire", { "upper blackrock spire", "upper blackrock", "ubrs", "ubers", "urbs" } },
    { "DGN", "Dire Maul: East", { "dire maul east", "dm east", "dm e", "dme", "dmeast" } },
    { "DGN", "Dire Maul: West", { "dire maul west", "dm west", "dm w", "dmw", "dmwest" } },
    { "DGN", "Dire Maul: North", { "dire maul north", "dm north", "dm n", "dmn", "dmnorth" } },
    { "DGN", "Dire Maul: Tribute", { "dire maul tribute", "dm tribute", "dmt", "tribute run" } },
    { "DGN", "Dire Maul", { "dire maul" } },
    { "DGN", "Stratholme: Living", { "stratholme living", "strat living", "strat live", "strath live", "live strat", "strat scarlet" } },
    { "DGN", "Stratholme: Undead", { "stratholme undead", "strat undead", "strat ud", "strath ud", "stat ud", "ud strat", "strat dead" } },
    { "DGN", "Stratholme", { "stratholme", "strat", "strath" } },
    { "DGN", "Scholomance", { "scholomance", "scolomance", "scholo" } },
    { "RAID", "Molten Core", { "molten core", "mc" } },
    { "RAID", "Onyxia's Lair", { "onyxia s lair", "onyxias lair", "onyxia", "ony", "onyx", "oni" } },
    { "RAID", "Blackwing Lair", { "blackwing lair", "bwl" } },
    { "RAID", "Zul'Gurub", { "zul gurub", "zulgurub", "zg" } },
    { "RAID", "Ruins of Ahn'Qiraj", { "ruins of ahn qiraj", "ruins of ahnqiraj", "aq20", "aq 20" } },
    { "RAID", "Temple of Ahn'Qiraj", { "temple of ahn qiraj", "temple of ahnqiraj", "aq40", "aq 40" } },
    { "RAID", "Naxxramas", { "naxxramas", "naxx", "nax" } },
    { "WB", "Azuregos", { "azuregos" } },
    { "WB", "Kazzak", { "lord kazzak", "kazzak" } },
    { "WB", "Emeriss", { "emeriss" } },
    { "WB", "Lethon", { "lethon" } },
    { "WB", "Taerar", { "taerar" } },
    { "WB", "Ysondre", { "ysondre" } },
}
local GUILD_PHRASES = {
    "guild recruiting", "guild recruitment", "recruiting guild", "guild looking for",
    "guild is recruiting", "guild is looking", "guild lf", "recruiting for our guild",
    "looking for a guild", "looking for guild", "lf guild", "lfguild",
    "gilde sucht", "guilde recrute", "guilda recrutando",
}
function OCS.BuildPack(id, name, roster, options)
    options = options or {}
    local pack = { id = id, name = name, levelCap = 60, classes = true,
        activities = {}, groupWords = {}, content = roster,
        professions = options.professions, pvp = options.pvp, goods = options.goods, lft = options.lft,
        bmDungeon = options.bmDungeon,
        contentNote = options.note or "Original Vanilla content" }
    pack.activities[1] = { id = "GUILD", name = "Guild", phrases = GUILD_PHRASES }
    local kinds, labels = { "WB", "DGN", "RAID" }, { WB = "World Boss", DGN = "Dungeon", RAID = "Raid" }
    for i = 1, table.getn(kinds) do
        local kind, targets = kinds[i], {}
        for j = 1, table.getn(roster) do
            local entry = roster[j]
            if entry[1] == kind then
                for k = 1, table.getn(entry[3]) do
                    local token = entry[3][k]
                    table.insert(targets, token)
                    OCS.PRETTY[token] = entry[2]
                    if not string.find(token, " ", 1, true) then
                        table.insert(pack.groupWords, token)
                    end
                end
            end
        end
        table.sort(targets, function(a, b)
            if string.len(a) == string.len(b) then return a < b end
            return string.len(a) > string.len(b)
        end)
        table.insert(pack.activities, { id = kind, name = labels[kind],
            targets = targets, targetIdentifies = true,
            sizeStems = kind == "RAID" and { "ony", "onyxia", "zg", "mc", "bwl" } or nil })
    end
    table.insert(pack.activities, { id = "DGN", name = "Dungeon",
        words = { "dungeon", "dungeons", "blackrock spire" } })
    table.insert(pack.activities, { id = "RAID", name = "Raid",
        words = { "raid", "raids", "aq", "ahn qiraj", "ahnqiraj" } })
    table.insert(pack.activities, { id = "WB", name = "World Boss",
        phrases = { "world boss", "world bosses", "worldboss", "worldbosses" } })
    if options.lft then
        table.insert(pack.activities, 5, { id = "LFT", name = "Dungeon Finder",
            words = { "lft", "lfd" }, phrases = { "dungeon finder", "random dungeon" } })
    end
    local generic = { "dungeon", "dungeons", "raid", "raids", "group", "grp", "guild", "boss", "worldboss", "lft" }
    for i = 1, table.getn(generic) do table.insert(pack.groupWords, generic[i]) end
    return pack
end
OCS.PROFESSIONS = {
    { id = "ALCH", name = "Alchemy", aliases = { "alchemy", "alchemist", "alch", "alchy", "transmute", "xmute", "arcanite bar cd" } },
    { id = "BS", name = "Blacksmithing", aliases = { "blacksmithing", "blacksmith", "bs", "armorsmith", "swordsmith", "weaponsmith" } },
    { id = "ENCH", name = "Enchanting", aliases = { "enchanting", "enchanter", "encahnter", "ench", "enchant", "enchants", "enc", "mining on gloves" } },
    { id = "ENG", name = "Engineering", aliases = { "engineering", "engineer", "eng", "engi" } },
    { id = "HERB", name = "Herbalism", aliases = { "herbalism", "herbalist" } },
    { id = "LW", name = "Leatherworking", aliases = { "leatherworking", "leatherworker", "lw" } },
    { id = "MIN", name = "Mining", aliases = { "mining", "miner" } },
    { id = "SKIN", name = "Skinning", aliases = { "skinning", "skinner" } },
    { id = "TAIL", name = "Tailoring", aliases = { "tailoring", "tailor", "tailorer" } },
    { id = "COOK", name = "Cooking", aliases = { "cooking", "cook", "chef" } },
    { id = "FISH", name = "Fishing", aliases = { "fishing", "fisherman" } },
    { id = "FA", name = "First Aid", aliases = { "first aid", "firstaid" } },
    { id = "LOCK", name = "Lockpicking", aliases = { "lockpicking", "lock picking", "lockpick" } },
}
function OCS.ParseProfession(t, headOnly)
    local lists = { OCS.PROFESSIONS, OCS.ActivePack().professions or {} }
    -- Enchanting a gathering bonus is not hiring a gatherer. A gemologist
    -- crafts the neck enchant on Turtle; the generic word enchant loses here.
    if not headOnly and (OCS.Has(t, "mining on gloves")
        or (OCS.Has(t, "enchanter") and (OCS.Has(t, "mining") or OCS.Has(t, "skinning")))) then
        return "Enchanting", OCS.TradeIntent(t) == "WTS" and "offering" or "looking"
    end
    if not headOnly and OCS.ActivePack().id ~= "vanilla"
        and (OCS.Has(t, "gemologist") or OCS.Has(t, "geomologist")) then
        return "Jewelcrafting", OCS.TradeIntent(t) == "WTS" and "offering" or "looking"
    end
    local selected, position
    for l = 1, table.getn(lists) do
        for i = 1, table.getn(lists[l]) do
            local profession = lists[l][i]
            for j = 1, table.getn(profession.aliases) do
                local alias = profession.aliases[j]
                if OCS.Has(t, alias) and (not headOnly or string.find(t, "^%s*" .. alias .. " ")) then
                    local at = string.find(t, " " .. alias .. " ", 1, true)
                    if not position or at < position then selected, position = profession, at end
                end
            end
        end
    end
    if selected then
        local mode, intent = "looking", OCS.TradeIntent(t)
        if intent == "WTS" then mode = "offering"
        elseif intent ~= "WTB" then
            for _, sign in ipairs({ "lfw", "offering", "offer", "selling", "can craft", "your mats", "service", "services", "tips", "free", "here", "pst", "available", "donations" }) do
                if OCS.Has(t, sign) then mode = "offering" end
            end
        end
        return selected.name, mode
    end
    -- A generic crafter is only a fallback after every named profession,
    -- including Turtle Survival crafting and Jewelcrafting.
    if not headOnly and (OCS.Has(t, "crafter") or OCS.Has(t, "craftsman") or OCS.Has(t, "lfw")) then
        return "Crafting", OCS.TradeIntent and OCS.TradeIntent(t) == "WTS" and "offering" or "looking"
    end
end
function OCS.PrettyName(token)
    if not token then return nil end
    return OCS.PRETTY[token] or token
end
function OCS.TargetsForKind(kind)
    local out, seen, content = {}, {}, OCS.ActivePack().content
    for i = 1, table.getn(content) do
        local entry = content[i]
        if entry[1] == kind and not seen[entry[2]] then
            table.insert(out, entry[2])
            seen[entry[2]] = true
        end
    end
    table.sort(out)
    return out
end
function OCS.PackForRealm(realm) return OCS.DEFAULT_PACK end
function OCS.ActivePack() return OCS.PACKS[OCS.packId] or OCS.PACKS[OCS.DEFAULT_PACK] end
function OCS.SelectPack(override)
    OCS.realmName = (GetRealmName and GetRealmName()) or "?"
    OCS.packId = OCS.PACKS[override or ""] and override or OCS.PackForRealm(OCS.realmName)
    OCS.LEVEL_CAP = 60
    if OCS.SetLevelCap then OCS.SetLevelCap(60) end
    local pack = OCS.ActivePack()
    if OCS.BASE_KINDS then
        OCS.BASE_KINDS.PVP = pack.pvp and { "ARENA", "BG", "PVP_OTHER" } or { "BG", "PVP_OTHER" }
        OCS.BASE_KINDS.TRADE = { "PROF", "MOUNT", "RECIPE", "CONSUM", "GEAR", "TRADE_OTHER" }
        if pack.goods then table.insert(OCS.BASE_KINDS.TRADE, "TRANSMOG") end
    end
    if OCS.KIND_CATEGORY then
        local cat = OCS.KIND_CATEGORY.CAT_DGN
        cat.kinds.LFT = pack.lft or nil
        cat.lead = pack.lft and { { value = "LFT", label = "Dungeon Finder" } } or nil
    end
    return pack
end
OCS.PACKS.vanilla = OCS.BuildPack("vanilla", "Vanilla", OCS.VANILLA_CONTENT)
OCS.packId = OCS.DEFAULT_PACK
