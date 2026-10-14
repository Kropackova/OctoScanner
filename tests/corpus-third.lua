-- Oct 11 screenshots and enlarged chat sample. Names/URLs are anonymized.
local passed = 0
local function eq(a, b, label)
    assert(a == b, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
    passed = passed + 1
end
dofile('tests/wow_mock.lua')
for line in io.lines('OctoScanner.toc') do
    if string.find(line, '%.lua%s*$') then dofile('' .. string.gsub(line, '%s+$', '')) end
end
Mock.event('ADDON_LOADED', 'OctoScanner'); Mock.event('PLAYER_LOGIN')
local function parse(raw, expected)
    local row = OCS.Parse(raw)
    assert(row, 'dropped advert: ' .. raw)
    for key, value in pairs(expected) do eq(row[key], value, raw .. ' / ' .. key) end
    return row
end
for _, text in ipairs({
    '<Test Guild> is a NA guild, Raid Days Sunday/Monday at 10 PM EST! Recently cleared all content, looking for Resto Druid and Ranged DPS.',
    '<Test Guild> raiding guild. 50 min MC clears. LF Boomkin || Rogue || Mage || Warlock. 1500 ST weekends, 2 raids.',
    'RU Guild <Test Guild> NabiraeT AdeKBATHblX igrokov. ZG KARA na Farme MC sobiraem Static!',
    '[RU] Guild <Test Guild> looking for priest and shamans for our raid roster. MC/ONY/ZG/K10 on farm. RT Saturday 20 MSK; SR+ discord.gg/example',
    '<Test Guild> Semi HC Community Searching HEALERS / DPS In Our Two Teams! x2 SR Raid Schedule Monday 19:00CET. Ony/MC/k10 on farm.',
    '<Test Guild> new leveling/social guild for noobs and pros hop on the crazy train',
    'The Test Crew looking for more shipmates! All Raids MC & Ony Wednesdays 19:00 GMT. Guild Events, friendly crew.',
    'Looking for based and friendly guild? <Test Guild> recruits',
}) do
    local row = parse(text, {route = 'GUILD', kind = 'GUILD'})
    eq(row.target, nil, 'guild is not an instance'); eq(row.level, nil, 'guild raid time is not a level')
end
local row = parse('LF5M Onyxia Mage Lock Healers Hunter Tonight at 0030 ST/ 830 PM EST Smooth run by <Test Guild> 1SR Discord REQUIRED',
    {kind = 'RAID', target = "Onyxia's Lair", intent = 'LFM', wanted = 5})
eq(row.level, nil, 'Onyxia clock not a character level'); eq(row.route, nil, 'named guild PUG stays PvE')
parse('LF1M ST healer start 15:00 ST', {kind = 'DGN', target = 'Sunken Temple', intent = 'LFM'})
parse('50 ST LFG', {kind = 'DGN', target = 'Sunken Temple', level = 50, intent = 'LFG'})
row = parse('LFM ZG12 Need OT DPS (no Hunters) and Heal 1SR MS OS (9/12)',
    {kind = 'RAID', target = "Zul'Gurub", intent = 'LFM', size = 12})
eq(row.class, nil, 'excluded Hunter is not a requested class'); eq(row.level, nil, 'ZG12 not level 12')
row = parse('ZG 12 LF 1Tank 1Heals & 2Dps (Full war/hunter) 1Sr Ms OS', {target = "Zul'Gurub", size = 12})
eq(row.class, nil, 'full class list excluded')
parse('LFM K10 1 Tank (sham pref) 1 Heal 3 DPS (full on warr/druid)', {class = 'Shaman', target = 'Lower Karazhan Halls'})
parse('LFM ZG Need 2 dps First Idol HR for Guild', {kind = 'RAID', target = "Zul'Gurub", intent = 'LFM'})
parse('<Test Guild> LFM MC guild run need healer', {kind = 'RAID', target = 'Molten Core', intent = 'LFM'})
row = parse('<Test PUG> Sub-hour runs guaranteed wipe! SR+, RT Saturday Sunday Pug 17:00 ST Healers and Mages in demand!',
    {kind = 'RAID', intent = 'LFM'})
eq(row.target, nil, 'unnamed PUG does not guess instance'); eq(row.level, nil, 'PUG clock not level')
parse('LFM Cresent Grove Need TANK and DPS can summon', {kind = 'DGN', target = 'The Crescent Grove', intent = 'LFM'})
for _, c in ipairs({
    {'looking for more |Hquest:41761:33|h[Into The Hornets Nest]|h', 'Into The Hornets Nest', 'LFM'},
    {'anyone need |Hquest:6584:60|h[The Test of Skulls, Chronalis]|h', 'The Test of Skulls, Chronalis', 'LFM'},
    {'Need All |Hquest:0:12|h[Protecting the Herd]|h', 'Protecting the Herd', 'LFM'},
    {'|Hquest:7701:50|h[WANTED: Overseer Maltorius]|h LF', 'WANTED: Overseer Maltorius', 'LFG'},
}) do parse(c[1], {kind = 'OTHER', target = c[2], activityName = 'Quest group', intent = c[3]}) end
parse('LF Heal Hinterland elites', {kind = 'OTHER', activityName = 'Quest group', intent = 'LFM'})
local recipe = 'WTS {CLINK:ff1eff00:16252:0:0:0:Formula: Enchant Weapon - Crusader}'
row = parse(recipe, {route = 'TRADE', kind = 'RECIPE', tradeIntent = 'WTS'})
eq(row.profession, nil, 'recipe not enchanting service')
eq(OCS.DisplayText(recipe), 'WTS Formula: Enchant Weapon - Crusader', 'CLINK shown as readable item name')
parse('WTS {CLINK:ff1eff00:18330:0:0:0:Arcanum of Focus} 12sp HEAD LEGS ENCHANT',
    {route = 'TRADE', kind = 'CONSUM', tradeIntent = 'WTS'})
row = parse('SELL {CLINK:ff0070dd:15138:0:0:0:Onyxia Scale Cloak} bring your mats+tip',
    {route = 'TRADE', kind = 'GEAR', tradeIntent = 'WTS'})
eq(row.target, nil, 'item name Onyxia is not a raid advert')
for _, c in ipairs({
    {'WTB transmute 5g', 'Alchemy', 'WTB', 'looking'},
    {'WTS Transmute Arcanite CD', 'Alchemy', 'WTS', 'offering'},
    {'LF ArmorSmith Fiery Plate Gauntlets', 'Blacksmithing', 'WTB', 'looking'},
    {'Swordsmith Looking for work! Can craft shield spikes', 'Blacksmithing', 'WTS', 'offering'},
    {'WTS enchant service weapon crusader +15 agi', 'Enchanting', 'WTS', 'offering'},
    {'WTB 100hp+ head enchant', 'Enchanting', 'WTB', 'looking'},
    {'lf encahnter with healing on 2h', 'Enchanting', 'WTB', 'looking'},
    {'WTB 2x |Hitem:56014:0:0:0|h[Stunning Imperial Gemstone]|h my mats + tip', 'Jewelcrafting', 'WTB', 'looking'},
    {'LFW |Hitem:55056:0:0:0|h[Spellwoven Nobility Drape]|h', 'Crafting', 'WTS', 'offering'},
    {'LFW Enchanter: Wep +30 SP/+15Agi/Crusader/Fiery/RiftTear || Boots +7agi/15sta/9int/speed; Your Mats + Tip', 'Enchanting', 'WTS', 'offering'},
    {'ENC&JC Horde OGR/Ally CoT: Wp Crus/30sp/Rift/55h/Fie/LifeS/15-25agi; brac 7agi/24heal/12sp/9sta/5def/7int/vam/9str; All Gems', 'Enchanting', 'WTS', 'offering'},
}) do
    row = parse(c[1], {route = 'TRADE', kind = 'PROF', profession = c[2], tradeIntent = c[3], profMode = c[4]})
    eq(row.target, nil, 'service not an instance')
end
parse('LFM CoT need healer enchanter welcome', {kind = 'DGN', target = 'Caverns of Time: Black Morass', intent = 'LFM'})
for _, text in ipairs({
    'Onyxia raid #330 might end soon (~17m in, typical 25-60m). Buff may drop soon in Orgrimmar.',
    'dire maul trinket, sliver from k10, argent dawn rep trinket',
    'PLower Karazhan Hall~0.6435~0.2896~1.1.0',
    'one of our k40 healers before twow was a healing touch druid',
    'Big drop or no ? |Hitem:1:0:0:0|h[Recipe: Transmute Undeath to Water]|h',
    "you can't sell that ring", 'nvm on key buy', 'now buy the dagger', 'sell deez nuts', 'buy shellcoin',
}) do eq(OCS.Parse(text), nil, 'conversation / transport excluded: ' .. text) end
-- Channel/language rejection must precede the instant-repeat cache. The same
-- readable advert arriving in a public player channel must remain eligible.
for _, channel in ipairs({'LFT', 'TTRP'}) do
    Mock.event('CHAT_MSG_CHANNEL', 'LFM BM need healer', channel .. 'Sender', 'Common', channel, nil, nil, nil, 7, channel)
    eq(OCS.CountAll(), channel == 'LFT' and 0 or 1, 'technical channel ignored')
    Mock.event('CHAT_MSG_CHANNEL', 'LFM BM need healer', channel .. 'Sender', 'Common', 'World', nil, nil, nil, 1, 'World')
    eq(OCS.CountAll(), channel == 'LFT' and 1 or 2, 'public copy not poisoned by technical copy')
end
Mock.event('CHAT_MSG_GUILD', 'LFM BRD need tank', 'AddonSender', 'ADDON')
eq(OCS.CountAll(), 2, 'ADDON language ignored')
Mock.event('CHAT_MSG_GUILD', 'LFM BRD need tank', 'AddonSender', 'Common')
eq(OCS.CountAll(), 3, 'human language can store same text')
eq(OCS.stats.errors, 0, 'no event errors'); eq(table.getn(Mock.sent), 0, 'no chat sent')
print('PASS ' .. passed .. ' assertions; enlarged corpus, clock/content collisions, trade services and transport gating')
