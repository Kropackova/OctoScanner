-- October 12 screenshots and chat exports. Player/guild identities removed.
local passed = 0
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
    local row = OCS.Parse(text)
    assert(row, 'dropped advert: ' .. text)
    for key, value in pairs(expected) do eq(row[key], value, text .. ' / ' .. key) end
    return row
end
-- Bare DM means Deadmines; explicit Dire Maul wings still win.
for _, profile in ipairs({'vanilla', 'octo', 'turtle'}) do
    OCS.SelectPack(profile)
    for _, text in ipairs({'LFM DM', 'LFG DM', 'LF1M for DM Need heal',
        'DM need healer', 'LFM DM dm me', 'LFM DM dm me dm me', 'DM me for info LFM DM healer'}) do
        parse(text, {kind = 'DGN', target = 'The Deadmines'})
    end
    for _, c in ipairs({
        {'LFM DM East', 'Dire Maul: East'}, {'LFM DM e', 'Dire Maul: East'},
        {'LFG DME', 'Dire Maul: East'}, {'LFM DMW', 'Dire Maul: West'},
        {'LFM DM West', 'Dire Maul: West'}, {'LFM DM N', 'Dire Maul: North'},
        {'LFG DMN', 'Dire Maul: North'}, {'LFM DMT', 'Dire Maul: Tribute'},
        {'LFM DM tribute', 'Dire Maul: Tribute'}, {'LFG Dire Maul', 'Dire Maul'},
    }) do parse(c[1], {kind = 'DGN', target = c[2]}) end
    parse('LFM MC dm me', {kind = 'RAID', target = 'Molten Core'})
    parse('LFM MC dm me dm me', {kind = 'RAID', target = 'Molten Core'})
    parse('LFM Naxx dm for invite', {kind = 'RAID', target = 'Naxxramas'})
    parse('LFG WSG dm me', {route = 'PVP', kind = 'BG'})
    local trade = parse('WTS boots 5g DM me', {route = 'TRADE', tradeIntent = 'WTS'})
    eq(trade.target, nil, 'DM contact text does not supply a trade destination')
    for _, text in ipairs({'DM me', 'DM me DM me', 'dm for price', 'send me a dm', 'dm for details'}) do
        eq(OCS.Parse(text), nil, 'contact instructions are not dungeon adverts: ' .. text)
    end
end
OCS.SelectPack('octo')
for _, c in ipairs({
    {'LFM 1 heal, 3 dps BLACKPHANTOM DEEPS', 'Blackfathom Deeps'},
    {'lvl 27 hunter LFG Blackfathom Deep, quests run', 'Blackfathom Deeps'},
    {'LF1M Dead,mes', 'The Deadmines'},
    {'LF1M tank gileans city', 'Gilneas City'},
    {'LF1M Razorfren kraul TANK', 'Razorfen Kraul'},
    {'LFG Razorfen Down', 'Razorfen Downs'},
    {'LFM STROMWROUGHT RUINS TANK FULL RUN', 'Stormwrought Ruins'},
    {'LF2M STROMWROUGHT DESCENT TANK HEALER', 'Stormwrought Ruins'},
    {'LF3M CS GROVE / SW CASTLE TANK&HEAL&1DPS', 'Stormwrought Ruins'},
    {'LFM Stat UD - need tank + dps', 'Stratholme: Undead'},
    {'LF1M SunkenTemple NEED HEALER', 'Sunken Temple'},
    {'LF3M Scolomance', 'Scholomance'},
    {'LFM URBS Need 2 dps Flask hr', 'Upper Blackrock Spire'},
    {'lf1m heal for emp runs', 'Blackrock Depths'},
    {'dps lfg emperor', 'Blackrock Depths'},
    {'DPS LFG - Emp Lava jump run, need only JC recipe', 'Blackrock Depths'},
    {'DPS LFG Emp Jump run, need JC recipie', 'Blackrock Depths'},
    {'lfg mauradon qrun', 'Maraudon'},
    {'DPS LFG SHADOWNFANG KEEP', 'Shadowfang Keep'},
    {'LFM Gnome need tank and dps or heal', 'Gnomeregan'},
    {'SFK 1 dps and go lvl 22+w', 'Shadowfang Keep'},
    {'last spot ZF we got a 60', "Zul'Farrak"},
    {'anyone up for RFK or Windhorn Canyon?', 'Windhorn Canyon'},
    {'Healer up to chain sm Lib/Armo/Cath', 'Scarlet Monastery: Library'},
}) do parse(c[1], {kind = 'DGN', target = c[2]}) end
parse('LFG ONI DPS PAl', {kind = 'RAID', target = "Onyxia's Lair", intent = 'LFG'})
parse('ZG LF2 Dps || 1Sr-Ms-Os || Wsp Class+Spec', {target = "Zul'Gurub", intent = 'LFM', wanted = 2})
parse('any MC pugs?', {target = 'Molten Core', intent = 'LFG'})
parse('Any ZG rep farms going on?', {target = "Zul'Gurub", intent = 'LFG'})
parse('Hello. Any raids going on?', {kind = 'RAID', intent = 'LFG'})
parse('down for tribute run?', {target = 'Dire Maul: Tribute'})
parse('group finder made for RFC if any can join', {target = 'Ragefire Chasm'})
parse('Anyone assembling a WC group?', {target = 'Wailing Caverns', intent = 'LFG'})
parse('Queue for Strath Live.', {target = 'Stratholme: Living'})
parse('gogo ppl quick stockade :)', {target = 'The Stockade', intent = 'LFM'})
parse('Heals, Tanks, DPS - 1x SR MS > OS - Ench Recipes HR', {kind = 'OTHER', activityShort = 'Group'})
parse('gilneas?', {target = 'Gilneas City', intent = 'UNSURE'})
local row = parse('LF1M |Hquest:115:23|h[Shadow Magic]|h|Hquest:19:25|h[Tharil\'zun]|h|Hquest:169:26|h[Wanted: Gath\'Ilzogg]|h need healer',
    {kind = 'OTHER', activityShort = 'Quest', target = 'Shadow Magic', roleText = 'heal', wanted = 1})
eq(row.roleSet.damage, nil, 'Shadow in quest title is not Damage')
eq(row.level, nil, 'quest metadata is not player level')
row = parse('LFM |Hquest:208:43|h[Big Game Hunter]|h', {activityShort = 'Quest', roleText = 'any'})
eq(row.class, nil, 'Hunter in quest title is not a requested class')
parse('LFM [Wanted: Gath\'Ilzogg][Tharil\'zun][Shadow Magic]', {activityShort = 'Quest', target = "Wanted: Gath'Ilzogg", roleText = 'any'})
parse('LFM [Humbert\'s Sword][Battle of Hillsbrad]', {activityShort = 'Quest', target = "Humbert's Sword"})
parse('LFM The Missing Diplomat last part', {kind = 'OTHER'}) -- unlisted quest remains an unknown group
for _, text in ipairs({'LFM Northwind Elite Quests', 'LFM Hinterland Elite Qs - Dps & Heal',
    'Heal or DPS LFG Hinterlands Quests', 'LFM Redridge elite', 'LFG hillsbrad elites'}) do
    parse(text, {kind = 'OTHER', activityShort = 'Quest'})
end
for _, c in ipairs({
    {'que ab lvl 30+', 'Arathi Basin'}, {'queue 40-49 bg', false},
    {'Q WSG 30-39', 'Warsong Gulch'}, {'que av', 'Alterac Valley'},
    {'Queu AV', 'Alterac Valley'}, {'Join 30-39 WSG', 'Warsong Gulch'},
    {'join AB lvl 40-49', 'Arathi Basin'}, {'join wsg 20-29', 'Warsong Gulch'},
    {'4v3 ab 40-49, starting 20 sec. join up', 'Arathi Basin'},
    {'1 more wsg lvl 39+', 'Warsong Gulch'}, {'1 more lvl 30+ to wsg', 'Warsong Gulch'},
}) do
    row = parse(c[1], {route = 'PVP', kind = 'BG', intent = 'LFM'})
    eq(row.target, c[2] or nil, 'queue destination')
end
parse('let me join AV please', {route = 'PVP', target = 'Alterac Valley', intent = 'LFG'})
parse('any wsg happening 20-29?', {route = 'PVP', target = 'Warsong Gulch', intent = 'LFG'})
parse('any AV?', {route = 'PVP', target = 'Alterac Valley', intent = 'LFG'})
parse('let me into AV!', {route = 'PVP', target = 'Alterac Valley', intent = 'LFG'})
parse('more for AV', {route = 'PVP', target = 'Alterac Valley', intent = 'LFM'})
row = parse('join AB lvl 40-49', {level = 40, bracket = true})
for _, c in ipairs({
    {'WTS arc xmute', 'Alchemy', 'WTS'},
    {'WTB Arcanite Bar Xmute 10g', 'Alchemy', 'WTB'},
    {'WTB Arcanite Bar CD Org, will tip', 'Alchemy', 'WTB'},
    {'WTS Arcanite bar cd, SW fountain', 'Alchemy', 'WTS'},
    {'LF mining on gloves', 'Enchanting', 'WTB'},
    {'LF +5 mining enchanter', 'Enchanting', 'WTB'},
    {'LF Geomologist enchant neck my mats', 'Jewelcrafting', 'WTB'},
    {'Enchants LFW, +30SP/+55Heal/Crusader', 'Enchanting', 'WTS'},
    {'Jewel LFW : 6agility/5strength my mat 5 gold', 'Jewelcrafting', 'WTS'},
    {'LFW TAILORER FLARECORE SET / ENCHANTER 300', 'Tailoring', 'WTS'},
    {'Crafting ALL Gems! Also Enchanting Crusader, 20 Arcane Power', 'Jewelcrafting', 'WTS'},
    {'Paying a Blacksmith to attach an Iron Counterweight', 'Blacksmithing', 'WTB'},
    {'any BS that can attach a counterweight in STV?', 'Blacksmithing', 'WTB'},
    {'ENCHANTING HERE! +4 Stats +15 stam to boots. PST', 'Enchanting', 'WTS'},
}) do parse(c[1], {route = 'TRADE', kind = 'PROF', profession = c[2], tradeIntent = c[3]}) end
for _, c in ipairs({
    {'Cels Summons: Mount Hyjal,Blackfathom Deeps,Dire Maul', 'WTS'},
    {'ubrs key service 9g', 'WTS'},
    {'Anyone with an Ubrs key that can open up for my group? Will pay', 'WTB'},
    {'T A X I 3Gold: Hyjal + EPL/Stratholme + DireMaul', 'WTS'},
    {'LF Summon to Booty Bay. 5g tip!', 'WTB'},
}) do
    row = parse(c[1], {route = 'TRADE', kind = 'TRADE_OTHER', tradeIntent = c[2]})
    eq(row.target, nil, 'service destinations are not dungeon recruitment')
end
parse('WTS 1% Haste to Head/Legs - 45g', {route = 'TRADE', kind = 'CONSUM'})
parse('WTS Golden Scale Cuirass', {route = 'TRADE', kind = 'GEAR'})
for _, text in ipairs({
    'Join THE TEST, we are a social guild and growing, starting to raid',
    '<Test Guild> Recrutement actif de joueur francophone. Raid Onyxia/MC/Karazhan Mercredi&Dimanche.',
    '<Test Guild> PvE - Dungs - Raids - RP casual. Buscamos raiders y viajeros para el crew. Te unes?',
    '<Test Guild> sucht dauerhafte Verstärkung für den Raidkader: 1 Heal Shamane - MC mittwochs 19:30 Uhr',
    '<Test Guild> hat noch feste Raidplätze frei! Gesucht: 1 Heal Druide - MC Mi 19:30 Uhr',
    'Feel our Test Embrace - MC every Thursday, Onyxia and K10 every reset. Casters, Resto Druids, Holy Paladins welcome.',
}) do parse(text, {route = 'GUILD', kind = 'GUILD'}) end
parse('<Test Guild> LFM MC guild run need healer', {kind = 'RAID', target = 'Molten Core', intent = 'LFM'})
row = parse('<Test Guild> LF5M Onyxia join us /w for invite', {kind = 'RAID', target = "Onyxia's Lair", intent = 'LFM'})
eq(row.route, nil, 'join wording does not turn a named guild PUG into a guild advert')
for _, text in ipairs({
    'why spam 3 times for lfm?', '"Join LFG!!" as if anyone is posting anything', 'go LFG',
    'So honest question. If we have a guild-recruitment channel can we make that the channel for guild recruitment?',
    'I refuse to join a guild that would have me as a member',
    'Hello all! Any Mage with the refreshments table quest, delete your WDB folder and log back in.',
    'I have a problem, I feel the need to read quest text, please send help',
    'so for gardening you simply need a planter and a seed right?',
    'those of you selling 150 individual items in the AH deserve a painful death',
    'whole world is buying phones for 1k', 'this the same us buying diesel from russia?',
    "I don't really see AI selling drugs", 'Mc Donalds for breakfast AND calling other losers? lol',
    'its wsg day XDD', 'no AV on AV day?', 'not in AV', 'have the alliance given up on AV',
    'one in av one outside av', 'there is a cow icon when getting kicked out of BG',
    'horde defenders appearing in middle of wsg, bug or hack?', 'its AV day tomorrow',
    'does ret pally have trouble getting in raids or is it normal?',
    'Onyxia raid cleared. Buff may drop in Orgrimmar.', '1g 3s 63c',
    'no father want his son to be a gnome', 'gnome',
}) do eq(OCS.Parse(text), nil, 'conversation excluded: ' .. text) end
row = parse('LFM BM need healer :D', {roleText = 'heal'})
eq(row.roleSet.damage, nil, 'emote is not Damage')
parse('LFG BM', {target = 'Caverns of Time: Black Morass', intent = 'LFG'})
row = parse('60 BM hunter LFG', {kind = 'OTHER', class = 'Hunter'})
eq(row.target, nil, 'BM spec still not a dungeon')
print('PASS ' .. passed .. ' assertions; fourth sample aliases, quest fields, queue calls, guilds, services and chatter')
