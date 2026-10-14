-- Real Octo chat patterns; guild names and invite URLs are anonymized.
local passed=0
local function eq(a,b,label)
    assert(a==b,(label or 'value')..': expected '..tostring(b)..', got '..tostring(a))
    passed=passed+1
end
dofile('tests/wow_mock.lua')
for line in io.lines('OctoScanner.toc') do
    if string.find(line,'%.lua%s*$') then dofile(''..string.gsub(line,'%s+$','')) end
end
OCS.SelectPack('octo')
local cases={
    {'LFM Ubers need all :D','DGN','Upper Blackrock Spire','LFM'},
    {'Deadmine need dps','DGN','The Deadmines','LFM'},
    {'Deadmine need dps and healer','DGN','The Deadmines','LFM'},
    {'LF3M Maraundon full quest run, need dps or heal','DGN','Maraudon','LFM'},
    {'LFM Strat UD need tank dps','DGN','Stratholme: Undead','LFM'},
    {'lfm Strath UDneed tank and dps 3spot','DGN','Stratholme: Undead','LFM'},
    {'LFM Strath live TANK','DGN','Stratholme: Living','LFM'},
    {'LFM HEALERS [PRIEST/DRUID] ONY25!','RAID',"Onyxia's Lair",'LFM'},
    {'LFM KZ10 Need Tank','RAID','Lower Karazhan Halls','LFM'},
    {'LFG BM REP FARM !','DGN','Caverns of Time: Black Morass','LFG'},
    {'LFG BM','DGN','Caverns of Time: Black Morass','LFG'},
    {'BM LFG','DGN','Caverns of Time: Black Morass','LFG'},
    {'LF BM','DGN','Caverns of Time: Black Morass','LFG'},
    {'LFG BM healer','DGN','Caverns of Time: Black Morass','LFG'},
    {'LFM ZG. Need 2 dps. First Idol HR for Guild.','RAID',"Zul'Gurub",'LFM'},
    {'LFG BRD guild run warrior','DGN','Blackrock Depths','LFG'},
    {'LF healer for guild MC run','RAID','Molten Core','LFM'},
    {'<Test Guild> LF healer for guild MC run','RAID','Molten Core','LFM'},
    {'<Test Guild> LFM ZG need tank','RAID',"Zul'Gurub",'LFM'},
    {'MC weekly group SUNDAY 1500 Server Time. LFM Need 2-3healer and Mage. https://discord.gg/example','RAID','Molten Core','LFM'},
    {'LFM for Hogger /w for inv','OTHER',nil,'LFM'},
    {'LFM for HYJAL gold farm, have summon 25/40','OTHER',nil,'LFM'},
    {'LF4M for SC or SD Need All ~Can summon','OTHER',nil,'LFM'},
    {'LFG Northwind exlite quests','OTHER',nil,'LFG'},
    {'LFM |cffffff00|Hquest:60116:29|h[Paint the Roses Red]|h|r','OTHER','Paint the Roses Red','LFM'},
    {"lfg |cff3fbf3f|Hquest:41761:33|h[Into The Hornet's Nest]|h|r / Northwind Elites",'OTHER',"Into The Hornet's Nest",'LFG'},
    {'Need Heal & DPS |cFFFFFF00|Hquest:0:13|h[Deep Blue Sea]|h|r','OTHER','Deep Blue Sea','LFM'},
    {'Any ony groups?','RAID',"Onyxia's Lair",'LFG'},
    {'hello world) any k10 forming?','RAID','Lower Karazhan Halls','LFG'},
}
for _,c in ipairs(cases) do
    local row=OCS.Parse(c[1]);assert(row,'dropped: '..c[1])
    eq(row.kind,c[2],c[1]);eq(row.target,c[3],c[1]);eq(row.intent,c[4],c[1])
end
local ony=OCS.Parse('LFM HEALERS [PRIEST/DRUID] ONY25!')
eq(ony.size,25,'attached raid size');eq(ony.level,nil,'raid size is not a character level')
eq(OCS.Parse('LFM ONY300').target,nil,'invalid attached raid size stays unknown')
local bm=OCS.Parse('LFG BM REP FARM !')
eq(bm.roleSet.damage,nil,'BM instance is not a damage role')
eq(OCS.Parse('LFG BM').roleSet.damage,nil,'plain BM request is not a damage role')
eq(OCS.Parse('LFG BM healer').roleSet.heal,true,'healer role retained with BM dungeon')
eq(OCS.Parse('60 BM hunter LFG').target,nil,'BM Hunter stays ambiguous')
eq(OCS.Parse('BM spec LFG rep farm').target,nil,'explicit spec is not a dungeon')
eq(OCS.Parse('LFM MC Need 2-3healer and Mage').roleSet.heal,true,'attached range of healers')
eq(OCS.Parse('MC need 2-3healer').intent,'LFM','role range describes recruitment')
for _,text in ipairs({
    '<Test Guild>(EU) Recruiting new raiders. LF Healers. discord.gg/example',
    '<Test Guild> LF raiders Saturday / Sunday 20:00 CET raids https://discord.gg/example',
    '<Test Guild> Guilde FR recrute ! Raids MC / Ony / KZ10 / ZG',
    '[CZ SK]Guilda (Test) otevira brany, hledame CZ/SK krajany pro PVE i pvp',
    '<Test Guild> is an international guild rebuilding. Join us! Kara 10 + ZG on farm',
    '<Test Guild> Join for guild runs. Whisper me for an invite and future raids.',
    '<Test Guild> är serverns bästa svenska guild. Vi var 9/9 i kara40. Alla roller är välkomna!',
    '<Test Guild>, serverns bästa svenska guild. 9/9 i K40 resten farmades på Turtle. Häng med!',
    '{RU}-{SNG} Guild "Test Guild" looking for ru speaking players to farm PvP/PvE chill and positive vibe',
    'lf woke guild',
    'any guilds recruiting need a rogue?',
}) do
    local row=OCS.Parse(text);assert(row,'guild dropped: '..text)
    eq(row.route,'GUILD',text);eq(row.kind,'GUILD',text);eq(row.target,nil,'guild does not become a raid')
end
for _,text in ipairs({
    'I waited 3 days to heal a Scholo group on retail hardcore. I feel the pain.',
    'I destroyed that kaoss guy in bgs yday',
    'They put a whole strip of area called the Dragonmaw Retreat in wetlands',
    'Worst dungeon ever',
    'is there a skinning trainer in gilneas',
    'where is the NPC to up 150 Engineering pls',
    'Do we have bonus wsg/ab reps days?',
    '|cff3fbf3f|Hquest:50005:42|h[In Need of Biggins]|h|r Anal',
    'FrostSeek LFG addon https://example.com',
}) do eq(OCS.Parse(text),nil,text) end
for _,c in ipairs({
    {'LF |cffFFd200|Henchant:20034|h[Enchant Weapon - Crusader]|h|r my mats + tip','Enchanting','WTB','looking'},
    {'LFM crafter |cff0070dd|Hitem:58134:0:0:0|h[Stormreaver Gloves]|h|r my mats + tip','Crafting','WTB','looking'},
    {'LF enchanting service my mats','Enchanting','WTB','looking'},
    {'Enchanter LFW your mats','Enchanting','WTS','offering'},
}) do
    local row=OCS.Parse(c[1]);assert(row,c[1])
    eq(row.route,'TRADE',c[1]);eq(row.kind,'PROF',c[1]);eq(row.profession,c[2],c[1])
    eq(row.tradeIntent,c[3],c[1]);eq(row.profMode,c[4],c[1])
end
eq(OCS.Parse('WTB boots /w offer').tradeIntent,'WTB','explicit buying beats offer wording')
eq(OCS.Parse('gilneas?').intent,'UNSURE','short ambiguous reference remains available')
OCS.SelectPack('vanilla')
eq(OCS.Parse('LFG BM REP FARM !').target,nil,'custom instance stays out of Vanilla')
eq(OCS.Parse('LFG BM').target,nil,'plain custom instance stays out of Vanilla')
eq(OCS.Parse('LFM KZ10').target,nil,'custom raid stays out of Vanilla')
eq(OCS.Parse('LFM Ubers need all').target,'Upper Blackrock Spire','Vanilla spelling alias')
print('PASS '..passed..' assertions; observed Octo adverts, guilds, quest groups, services and conversation')
