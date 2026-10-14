-- Cumulative Turtle content through 1.18.1, also used by OctoWoW.
-- Server encounter implementations and release phases are not queried.
-- Sources and deliberate ambiguous aliases: docs/03-content.md.
OCS.TURTLE_ADDITIONS = {
    { "DGN", "Frostmane Hollow", { "frostmane hollow", "frostmane", "fmh", "fh" } },
    { "DGN", "Windhorn Canyon", { "windhorn canyon", "windhorn", "whc" } },
    { "DGN", "Dragonmaw Retreat", { "dragonmaw retreat", "dragonmaw", "dmr" } },
    { "DGN", "The Crescent Grove", { "the crescent grove", "crescent grove", "cresent grove", "cs grove", "tcg", "cg" } },
    { "DGN", "Stormwrought Ruins", { "stormwrought ruins", "stormwrought castle", "stormwrought", "stromwrought ruins", "stromwrought descent", "sw castle", "swr", "swc" } },
    { "DGN", "Gilneas City", { "gilneas city", "gileans city", "gilneas dungeon", "gilneas", "gc" } },
    { "DGN", "Hateforge Quarry", { "hateforge quarry", "hateforge", "hfq", "hq" } },
    { "DGN", "Karazhan Crypt", { "karazhan crypt", "karazhan crypts", "kara crypt", "kara crypts", "crypts", "kc" } },
    { "DGN", "Stormwind Vault", { "stormwind vault", "stormwind vaults", "sw vault", "swvault", "swv" } },
    { "DGN", "Caverns of Time: Black Morass", { "caverns of time black morass", "caverns of time", "black morass", "cot bm", "cotbm", "cot" } },
    { "RAID", "Lower Karazhan Halls", { "lower karazhan halls", "lower karazhan", "lower kara", "karazhan 10", "kara 10", "kara10", "kz10", "k10", "lkh" } },
    { "RAID", "Upper Karazhan Halls", { "upper karazhan halls", "tower of karazhan", "karazhan tower", "upper karazhan", "upper kara", "karazhan 40", "kara 40", "kara40", "k40", "ukh" } },
    { "RAID", "Emerald Sanctum", { "emerald sanctum", "es hardmode", "es hard mode", "esnormal", "eshardmode", "es" } },
    { "RAID", "Timbermaw Hold", { "timbermaw hold", "timbermaw raid", "tmh" } },
    { "WB", "Concavius", { "concavius" } },
    { "WB", "Ostarius", { "ostarius of uldum", "ostarius" } },
    { "WB", "Nerubian Overseer", { "nerubian overseer" } },
    { "WB", "Dark Reaver of Karazhan", { "dark reaver of karazhan", "dark reaver", "darkreaver" } },
}
OCS.TURTLE_CONTENT = {}
for i = 1, table.getn(OCS.VANILLA_CONTENT) do
    table.insert(OCS.TURTLE_CONTENT, OCS.VANILLA_CONTENT[i])
end
for i = 1, table.getn(OCS.TURTLE_ADDITIONS) do
    table.insert(OCS.TURTLE_CONTENT, OCS.TURTLE_ADDITIONS[i])
end
local options = {
    note = "Vanilla + Turtle content through 1.18.1; server phases may differ",
    lft = true,
    bmDungeon = true,
    professions = {
        { id = "JC", name = "Jewelcrafting", aliases = { "jewelcrafting", "jewelcrafter", "jeweler", "jeweller", "jewel", "jc", "jwc", "goldsmithing", "goldsmith", "gemology", "gemologist", "geomologist", "gemstone", "crafting all gems" } },
        { id = "SURV", name = "Survival", aliases = { "survival crafting", "survival crafter", "tent crafting", "tent crafter" } },
        { id = "GARD", name = "Gardening", aliases = { "gardening", "gardener" } },
    },
    pvp = {
        { kind = "BG", name = "Warsong Gulch", aliases = { "warsong gulch", "warsong", "wsg" } },
        { kind = "BG", name = "Arathi Basin", aliases = { "arathi basin", "arathi", "ab" } },
        { kind = "BG", name = "Alterac Valley", aliases = { "alterac valley", "alterac", "av" } },
        { kind = "BG", name = "Thorn Gorge", aliases = { "thorn gorge", "thorngorge", "tg" } },
        { kind = "ARENA", name = "Blood Ring", aliases = { "steamwheedle blood ring", "blood ring", "bloodring", "3v3", "3s" } },
    },
    goods = {
        { id = "TRANSMOG", name = "Transmog", words = { "transmog", "tmog", "fashion token", "fashion tokens", "fashion coin", "fashion coins" } },
    },
}
OCS.PACKS.turtle = OCS.BuildPack("turtle", "Turtle WoW 1.18.1", OCS.TURTLE_CONTENT, options)
OCS.PACKS.octo = OCS.BuildPack("octo", "OctoWoW", OCS.TURTLE_CONTENT, options)
-- Unqualified Kara names a raid, without guessing a wing. Crypt names and the
-- Dark Reaver are checked earlier. BM needs recruitment context; WC stays WC.
for _, id in ipairs({ "turtle", "octo" }) do
    local pack = OCS.PACKS[id]
    table.insert(pack.activities, { id = "RAID", name = "Raid",
        words = { "karazhan", "kara" } })
    table.insert(pack.groupWords, "kara")
    table.insert(pack.groupWords, "karazhan")
end
OCS.DEFAULT_PACK, OCS.packId = "octo", "octo"
function OCS.PackForRealm(realm)
    local name = string.lower(realm or "")
    name = string.gsub(name, "[^%a%d]", "")
    if name == "nordanaar" or name == "telabim" or name == "ambershire" then return "turtle" end
    return "octo"
end
