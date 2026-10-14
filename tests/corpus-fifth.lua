local passed = 0
local row
local function eq(a, b, label)
    assert(a == b, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
    passed = passed + 1
end
dofile('tests/wow_mock.lua')
for line in io.lines('OctoScanner.toc') do
    if string.find(line, '%.lua%s*$') then dofile('' .. string.gsub(line, '%s+$', '')) end
end
OCS.SelectPack('octo')
local function parse(text, expected)
    local row = assert(OCS.Parse(text), 'dropped advert: ' .. text)
    for k, v in pairs(expected) do eq(row[k], v, text .. ' / ' .. k) end
    return row
end
for _, c in ipairs({
    {'LF4M for Crescent', 'The Crescent Grove'},
    {'Tank/DPS LFG Blackfathom', 'Blackfathom Deeps'},
    {'LFM DM-West', 'Dire Maul: West'},
    {'DM-E LFM need tank and healer', 'Dire Maul: East'},
    {'LF3M Deadmines- Need Tank & Healer', 'The Deadmines'},
    {'LFM StratUD - Tank+DPS', 'Stratholme: Undead'},
    {'LF1M Strathome Undead need Tank and Helaer', 'Stratholme: Undead'},
    {'LF1M dps HTFQ (hateforgequarry)', 'Hateforge Quarry'},
    {'LFM Tank to Crescent Grow (33-39 lvls)', 'The Crescent Grove'},
    {'lf2m crecentgrove healer and a dps', 'The Crescent Grove'},
    {'LFG Windhord Canyon', 'Windhorn Canyon'},
    {'LFM 2DPS frosmane hollow', 'Frostmane Hollow'},
    {'LF healer 1 dps Stomrwind vault', 'Stormwind Vault'},
    {'LFG diremaul west', 'Dire Maul: West'},
    {'Mage LF Z\'G', "Zul'Gurub"},
    {'LF DPS LAVA RUN IF HR', 'Blackrock Depths'},
    {'LFM STRATH UNDEAD 1TANK', 'Stratholme: Undead'},
    {'LF Healer HateFroge Quarry WE CAN SUM', 'Hateforge Quarry'},
    {'tank LFG frostamane hollow', 'Frostmane Hollow'},
    {'LFM Heal dps Gilney City', 'Gilneas City'},
}) do parse(c[1], {target = c[2]}) end
for _, c in ipairs({
    {'LF 3xDPS and HEAL for Dragonmaw', 'heal, damage'},
    {'LFM BFD 2xdps & 1xheal lvl 24min', 'heal, damage'},
    {'LFM Razorfen Downs need tank1 heal1', 'tank, heal'},
    {'LFM Razorfen Downs need heal1', 'heal'},
    {'LF3M ZulFarrak need tank & 2xDPS', 'tank, damage'},
    {'LF2M UBRS Need 1xTanks 1xHealers', 'tank, heal'},
    {'LFM UBRS 2/2TANKS 1/3HEALERS 5/5DPS', 'heal'},
    {'LFM UBRS 2/2TANKS 3/3HEALERS 4/5DPS', 'damage'},
    {'LFM UBRS 2/2 tanks 3/3 healers 4/5 dps', 'damage'},
    {'LFM UBRS 2/2 tanks 3/3 healers 5/5 dps', '?'},
    {"LF2m dps for BM, reset after whelp boss, tank/healer don't need sand.", 'damage'},
    {'LFM BRD need dps, no tank or healer', 'damage'},
    {'LFM BRD need healer, full on tanks', 'heal'},
    {'LFM BRD Arena x5 + T0.5 boss Summon', 'any'},
    {'LFM ZG Need DPS, T2 helm HR', 'damage'},
    {'LF1HEALER DEADMINES AND GTG', 'heal'},
    {'LFM ZG12 - 1xHealer+1xWarriorDPS', 'heal, damage'},
}) do parse(c[1], {roleText = c[2], intent = 'LFM'}) end
parse('LF tank for scholo 4/5 summ ready!', {intent = 'LFM', target = 'Scholomance'})
parse('Tank LF Heal to whole first part of BRD', {intent = 'LFM'})
parse('Tank LF Heal to whole first part of BRD', {roleText = 'heal'})
local selfRecruit = parse('Lvl 52 Warlock Twink Tank LF3M dps for BRD 43+', {roleText = 'damage', level = 43})
eq(selfRecruit.class, nil, 'recruitment does not require the sender class')
parse('Tank, Healer LFM BRD', {roleText = 'tank, heal'})
parse('LF priest MC and Onyxia', {intent = 'LFM', class = 'Priest'})
parse('HEALER LF BM OR STRAT UD', {intent = 'LFG'})
parse('LFG BRD full dps', {roleText = 'damage'})
row = parse('tank lf sfk. need summon', {target = 'Shadowfang Keep', intent = 'LFG'})
eq(row.route, nil, 'group search with a transport requirement stays PvE')
parse("LF MAGE PORTAL ALAH'THALAS", {route = 'TRADE', tradeIntent = 'WTB'})
parse('LF2M UBRS 53+ need healer', {level = 53, wanted = 2})
parse('LFM Scholo Need 58+ DPS', {level = 58})
parse('LFM BFD 2xdps & 1xheal lvl 24min', {level = 24})
for _, text in ipairs({'TANK LFG KARA-10', 'LFR KARA 10 tank', 'LFG karazhan 40'}) do
    local row = parse(text, {kind = 'RAID', intent = 'LFG'})
    eq(row.level, nil, 'Karazhan group size is not a character level')
end
for _, c in ipairs({
    {'LF summ', 'TRADE_OTHER'}, {'LF UC port', 'TRADE_OTHER'},
    {'lf summ sfk', 'TRADE_OTHER'}, {'buy summon to eastern plague', 'TRADE_OTHER'},
    {'LF +6agi belt', 'GEAR'},
    {'LF Rogue to open my boxes!', 'PROF'},
    {'LF rogue [Strong Iron Lockbox]', 'PROF'},
    {'Looking for alchemists transmutes! Paying tips!', 'PROF'},
    {'Can any1 craft me a |Hitem:55340:0:0:0|h[Shadowforged Eye]|h pls?', 'PROF'},
    {'Anyone able to craft [Warbear Harness]? Got mats', 'PROF'},
    {'LF Gold smith |Hitem:55363:0:0:0|h[Grail of Forgotten Memories]|h my mats', 'PROF'},
}) do parse(c[1], {route = 'TRADE', kind = c[2], tradeIntent = 'WTB'}) end
parse('WTS |Hitem:1:0:0:0|h[Miner\'s Rucksack]|h 15G', {route = 'TRADE', kind = 'GEAR', tradeIntent = 'WTS'})
parse('WTS |Hitem:1:0:0:0|h[Arcanite Bar]|h CD 10g', {profession = 'Alchemy', tradeIntent = 'WTS'})
parse('WTS 2% dodge to leg/helm enchant = 50g', {profession = 'Enchanting', tradeIntent = 'WTS'})
parse('LF |Hitem:1:0:0:0|h[Brilliant Opal Gemstone]|h crafter', {profession = 'Jewelcrafting', tradeIntent = 'WTB'})
row = parse('LF TANK get your |Hitem:1:0:0:0|h[Greaves of the Elite Guard]|h', {intent = 'LFM', activityShort = 'Group', roleText = 'tank'})
eq(row.route, nil, 'loot in a recruitment post is not a trade advert')
row = parse('LFM tank |Hitem:1:0:0:0|h[Onyxia Scale Cloak]|h HR', {kind = 'OTHER'})
eq(row.target, nil, 'loot does not name a raid')
row = parse('LF 1 Heal Start can summon', {intent = 'LFM', roleText = 'heal'})
eq(row.route, nil, 'summoning offered by a group does not become a transport request')
for _, c in ipairs({
    {'LFM |Hquest:1:60|h[The Mystery of Karazhan V]|h', 'The Mystery of Karazhan V'},
    {'LFG |Hquest:1:60|h[The Depths of Karazhan V]|h', 'The Depths of Karazhan V'},
    {'LFM |Hquest:1:33|h[The Crescent Grove]|h', 'The Crescent Grove'},
    {'LF1 |Hquest:60131:13|h[Deep Blue Sea]|h', 'Deep Blue Sea'},
    {'can someone help me with quest |Hquest:1:60|h[WANTED: Overseer Maltorius]|h', 'WANTED: Overseer Maltorius'},
    {'LFM Ony attune Healer |Hquest:1:60|h[Marshal Windsor]|h', 'Marshal Windsor'},
    {"LFM |Hquest:1:60|h[The Hermit's Wrath]|h Lapidis Isle Elite ST Chain", "The Hermit's Wrath"},
    {"LFM |Hquest:1:60|h[Into The Hornet's Nest]|h SWR preq 2/5", "Into The Hornet's Nest"},
}) do
    row = parse(c[1], {kind = 'OTHER', target = c[2], activityShort = 'Quest'})
    eq(row.level, nil, 'quest link metadata is not a character level')
end
row = parse('LF elite quests |Hquest:1:40|h[Necklace Recovery]|h|Hquest:2:40|h[Uldaman Reagent Run]|h', {activityShort = 'Quest'})
eq(row.route, nil, 'quest title does not sell a necklace')
for _, text in ipairs({'LFG Arathi Elite q', 'LFM Alterac elites'}) do
    row = parse(text, {kind = 'OTHER', activityShort = 'Quest'})
    eq(row.route, nil, 'elite quest zone is not a battleground')
end
parse('Any world bosses raids?', {kind = 'WB'})
parse('LF help for STV elite (Ogre + south boss)', {kind = 'OTHER', activityShort = 'Quest'})
parse('LF 1M Hinterlands Elites Last Spot', {kind = 'OTHER', activityShort = 'Quest', wanted = 1})
parse("lf horde companion to do gillijim's isle quests", {kind = 'OTHER', activityShort = 'Quest'})
row = parse('LF a partner for Mirage Race!', {kind = 'OTHER', intent = 'LFG'})
eq(row.route, nil, 'race partner is not a PvP teammate')
row = parse('LF Friends age 30+ to quest and hang out', {activityShort = 'Quest'})
eq(row.level, nil, 'real-world age is not a character level')
parse('<Example> is looking for new members! Active discord, friendly vibe. Whisper for info! Raiding, bg and more!', {route = 'GUILD'})
parse('Guild Example LF for people', {route = 'GUILD'})
parse('LFW Enchants your mats, discord.gg/example', {route = 'TRADE', tradeIntent = 'WTS'})
row = parse('LFW Enchanter cloak 15+Fire res, your mats', {route = 'TRADE'})
eq(row.level, nil, 'enchant strength is not a character level')
for _, text in ipairs({
    'what happened to all the warlocks selling summons?',
    'how many quests do you need for loremaster?',
    "why people don't use LFG chat for party group find spam?",
    'how can I join AV?', 'hunters need serious pvp nerfs',
    'Does Kara 10 need attune?',
    'dont join wsg and ab at 50-59', 'now buy the dagger',
    'need unreal port with more dances for the parties',
    'LF hot babe wife must play healer or tank',
    'How could we possibly need tank AND heal, we have 4 people in party',
}) do eq(OCS.Parse(text), nil, 'conversation is not an advert: ' .. text) end
print('PASS ' .. passed .. ' assertions; chat formats, role counts, quest routing, transport and trade services')
