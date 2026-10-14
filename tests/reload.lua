local passed=0
local function eq(actual,expected,label)
    assert(actual==expected,(label or 'value')..': expected '..tostring(expected)..', got '..tostring(actual))
    passed=passed+1
end
dofile('tests/wow_mock.lua')
-- Simulate WoW deserializing this character's SavedVariables before load.
OCS_DB={pack='vanilla',style='dark',colsSeeded=true,cols={PVE={prog=false}},
    expiry=60,maxRows=1,sortKey='time',sortAsc=true,
    window={shown=true,w=850,h=500},mini={shown=true},
    filter={class='Druid',roles={heal=true}},
    whisper={pveLfm='Hello {name}, {myname} lvl {mylevel} here'},
    rows={PVE_LFM={
        {name='Saved',time=Mock.now-10,message='LFM SM cath healer',kind='DGN'},
        {name='Expired',time=Mock.now-10000,message='LFM MC',kind='RAID'},
    }}}
ACS_DB={sentinel=true} -- The old addon can coexist without sharing settings.
for line in io.lines('OctoScanner.toc') do
    if string.find(line,'%.lua%s*$') then dofile(''..string.gsub(line,'%s+$','')) end
end
Mock.event('ADDON_LOADED','OctoScanner')
eq(OCS.packId,'vanilla','saved pack')
eq(OCS_DB.style,'dark','saved skin')
eq(OCS_DB.filter.class,'Druid','saved class')
eq(OCS_DB.filter.roles.heal,true,'saved role')
eq(OCS_DB.cols.PVE.prog,false,'saved visible progress column')
eq(table.getn(OCS_DB.rows.PVE_LFM),1,'load restores only the last hour')
eq(OCS_DB.expiry,nil,'legacy expiry removed');eq(OCS_DB.maxRows,nil,'legacy row cap removed')
eq(OCS_DB.sortKey,'time','upgrade uses time sort');eq(OCS_DB.sortAsc,false,'upgrade uses newest first')
eq(OCS_DB.rows.PVE_LFM[1].target,'Scarlet Monastery: Cathedral','saved row reparsed')
eq(OCS_DB.rows.PVE_LFM[1].schema,OCS.ROW_SCHEMA)
eq(OCS.BuildWhisper(OCS_DB.rows.PVE_LFM[1],'PVE_LFM'),'Hello Saved, Tester lvl 60 here','saved whisper template')
Mock.event('PLAYER_LOGIN')
eq(OCS_Window:IsShown(),true,'main window restored')
eq(OCS_MiniWindow:IsShown(),true,'mini window restored')
eq(OCS_MinimapButton:IsShown(),true,'minimap created')
for i=1,table.getn(Mock.messages) do assert(not string.find(Mock.messages[i],'interface error',1,true),Mock.messages[i]) end
Mock.event('ADDON_LOADED','OctoScanner')
eq(table.getn(OCS_DB.rows.PVE_LFM),1,'init is idempotent')
SlashCmdList.OCTOCS('pack octo')
eq(OCS.packId,'octo','pack command switches')
eq(OCS_DB.pack,'octo','pack command saves')
Mock.event('PLAYER_ENTERING_WORLD')
eq(OCS.packId,'octo','manual pack survives world entry')
SlashCmdList.OCTOCS('pack vanilla')
Mock.event('PLAYER_ENTERING_WORLD')
eq(OCS.packId,'vanilla','Vanilla override survives Octo realm')
SlashCmdList.OCTOCS('pack auto')
eq(OCS.packId,'octo','automatic Octo selection')
eq(ACS_DB.sentinel,true,'upstream settings untouched')
eq(table.getn(Mock.sent),0,'reload sends no messages')

local function reload(settings)
    OCS = nil
    dofile('tests/wow_mock.lua')
    OCS_DB = settings
    for line in io.lines('OctoScanner.toc') do
        if string.find(line, '%.lua%s*$') then dofile('' .. string.gsub(line, '%s+$', '')) end
    end
    Mock.event('ADDON_LOADED', 'OctoScanner'); Mock.event('PLAYER_LOGIN'); OCS.ShowMain()
end
reload(nil)
eq(OCS_DB.cols.PVE.class, true, 'fresh PvE hides Class')
eq(OCS_DB.cols.PVE.prog, true, 'fresh PvE hides Filled')
eq(OCS_DB.cols.PVE.level, true, 'fresh PvE hides Lvl')
eq(OCS_DB.cols.PVP.role, true, 'fresh PvP hides Role')
eq(OCS_DB.cols.PVP.level, true, 'fresh PvP hides Lvl')
eq(OCS_DB.cols.PVP.class, nil, 'PvP Class stays available by default')
OCS_Window:SetWidth(1100)
for _, section in ipairs({'PVE', 'PVP'}) do
    OCS.SetSection(section)
    local keys = section == 'PVE' and {'class', 'prog', 'level'} or {'role', 'level'}
    for _, key in ipairs(keys) do
        eq(OCS.ColumnIsHidden(key), true, 'default column is hidden in the table')
        OCS.ToggleColumn(key)
        eq(OCS.ColumnOff(key), false, 'Rows can enable default-hidden column')
        eq(OCS.ColumnIsHidden(key), false, 'enabled column is drawn')
    end
end
local settings = OCS_DB
reload(settings)
for _, section in ipairs({'PVE', 'PVP'}) do
    OCS.SetSection(section)
    local keys = section == 'PVE' and {'class', 'prog', 'level'} or {'role', 'level'}
    for _, key in ipairs(keys) do eq(OCS.ColumnOff(key), false, 'visible column choice survives reload') end
end

local row = {name = 'Advertiser', level = 22, class = 'Mage'}
local expected = {
    PVE_LFM = 'Hi! Level 60 Warrior here.', PVE_UNSURE = 'Hi! Level 60 Warrior here.',
    PVE_LFG = 'Hi! Still looking for a group?',
    PVP_LFM = 'Hi! Level 60 Warrior here.', PVP_UNSURE = 'Hi! Level 60 Warrior here.',
    PVP_LFG = 'Hi! Still looking for a PvP group?',
    TRADE_WTS = 'Hi! Is this still available?', TRADE_UNSURE = 'Hi! Is this still available?',
    TRADE_WTB = 'Hi! Are you still looking?',
    GUILD_ALL = 'Hi! I saw your guild post. Could you tell me more?',
}
for bucket, text in pairs(expected) do eq(OCS.BuildWhisper(row, bucket), text, 'approved wording and own character fields') end
function UnitClass() return 'Druid', 'DRUID' end
eq(OCS.BuildWhisper(row, 'PVE_LFM'), 'Hi! Level 60 Druid here.', 'class is read from player at click time')
OCS.SetWhisperTemplate('pveLfm', '{name}/{myname}/{mylevel}/{myclass}/{unknown}')
eq(OCS.BuildWhisper(row, 'PVE_LFM'), 'Advertiser/Tester/60/Druid/{unknown}', 'existing tokens and unknown token handling retained')
OCS.ResetWhisperTemplates()
eq(OCS.BuildWhisper(row, 'PVE_LFM'), 'Hi! Level 60 Druid here.', 'Reset lines uses approved defaults')
eq(table.getn(Mock.sent), 0, 'template setup and preview send nothing')
OCS.SendWhisper(row, 'PVE_LFM')
eq(Mock.sent[1].text, 'Hi! Level 60 Druid here.', 'explicit click sends complete new line')
eq(Mock.sent[1].target, 'Advertiser', 'whisper targets selected player')

reload({colsSeeded = true, cols = {PVE = {prog = true}, PVP = {}},
    whisper = {pveLfm = 'Hi {name}, lvl {mylevel} room in your group?',
        pveLfg = 'My custom invitation', tradeWtb = ''}})
eq(OCS_DB.cols.PVE.class, true, 'old default PvE layout upgraded once')
eq(OCS_DB.cols.PVE.level, true)
eq(OCS_DB.cols.PVP.role, true, 'old default PvP layout upgraded once')
eq(OCS_DB.cols.PVP.level, true)
eq(OCS_DB.whisper.pveLfm, 'Hi! Level {mylevel} {myclass} here.', 'old shipped whisper upgraded')
eq(OCS_DB.whisper.pveLfg, 'My custom invitation', 'custom invitation preserved')
eq(OCS_DB.whisper.tradeWtb, '', 'intentionally disabled whisper preserved')
reload({colsSeeded = true, cols = {PVE = {prog = false}, PVP = {class = true}}})
eq(OCS_DB.cols.PVE.prog, false, 'custom visible Filled stays visible')
eq(OCS_DB.cols.PVE.class, nil, 'custom PvE layout is preserved')
eq(OCS_DB.cols.PVP.class, true, 'custom PvP layout is preserved')
eq(OCS_DB.cols.PVP.role, nil, 'custom PvP choices are not overwritten')
reload({whisper = {
    pveLfm = 'Hi! Level {mylevel} {myclass} here. Still need more?',
    pveLfg = 'Hi! Still looking for a group? Want to team up?',
    pvpLfm = 'Hi! Level {mylevel} {myclass} here. Still need more for PvP?',
    pvpLfg = 'Hi! Still looking for a PvP group? Want to team up?',
}})
eq(OCS_DB.whisper.pveLfm, 'Hi! Level {mylevel} {myclass} here.', 'reviewed PvE greeting shortened')
eq(OCS_DB.whisper.pveLfg, 'Hi! Still looking for a group?', 'reviewed PvE question shortened')
eq(OCS_DB.whisper.pvpLfm, 'Hi! Level {mylevel} {myclass} here.', 'reviewed PvP greeting shortened')
eq(OCS_DB.whisper.pvpLfg, 'Hi! Still looking for a PvP group?', 'reviewed PvP question shortened')
reload({rows = {PVE_LFM = {{name = 'SavedDM', time = 990, message = 'LFM DM need healer',
    kind = 'DGN', schema = 5, level = 33, locked = {level = true}}}}})
eq(OCS_DB.rows.PVE_LFM[1].target, 'The Deadmines', 'recent generic DM row gains its dungeon on upgrade')
eq(OCS_DB.rows.PVE_LFM[1].schema, OCS.ROW_SCHEMA, 'DM row uses current parser schema')
eq(OCS_DB.rows.PVE_LFM[1].level, 33, 'DM upgrade preserves manual level')
eq(OCS_DB.rows.PVE_LFM[1].locked.level, true, 'DM upgrade preserves manual lock')
reload({rows = {
    PVE_LFG = {
        {name = 'Recruiter', time = 990, schema = 6, rawMessage = 'LF tank for scholo 4/5 summ ready!',
            kind = 'OTHER', target = 'Old value', roleText = 'damage', level = 33,
            locked = {role = true, level = true}},
        {name = 'Manual', time = 991, schema = 6, manualBucket = 'PVE_LFG',
            rawMessage = 'LFM DM healer', kind = 'DGN'},
    },
    PVE_LFM = {{name = 'Crescent', time = 992, schema = 6, rawMessage = 'LF4M for Crescent', kind = 'OTHER'}},
    TRADE_WTS = {
        {name = 'Conversation', time = 993, schema = 6, rawMessage = 'what happened to all the warlocks selling summons?', kind = 'TRADE_OTHER'},
        {name = 'Bag', time = 994, schema = 6, rawMessage = "WTS |Hitem:1:0:0:0|h[Miner's Rucksack]|h 15G", kind = 'PROF', profession = 'Mining'},
    },
}})
local function saved(bucket, name)
    for _, row in ipairs(OCS_DB.rows[bucket]) do if row.name == name then return row end end
end
local recruiter = assert(saved('PVE_LFM', 'Recruiter'))
eq(saved('PVE_LFG', 'Recruiter'), nil, 'upgraded recruiter moves to LFM')
eq(recruiter.target, 'Scholomance', 'obsolete activity replaced')
eq(recruiter.kind, 'DGN', 'obsolete generic kind replaced')
eq(recruiter.roleText, 'damage', 'upgrade preserves manual role')
eq(recruiter.level, 33, 'upgrade preserves manual level')
eq(recruiter.orig.roleText, 'tank', 'reset value uses current parse')
eq(saved('PVE_LFM', 'Crescent').target, 'The Crescent Grove', 'recent unknown gains its named instance')
eq(saved('TRADE_WTS', 'Conversation'), nil, 'previously accepted conversation removed on upgrade')
eq(saved('TRADE_WTS', 'Bag').kind, 'GEAR', 'item is no longer a profession service')
eq(saved('TRADE_WTS', 'Bag').profession, nil, 'obsolete profession removed')
local manual = assert(saved('PVE_LFG', 'Manual'))
eq(manual.target, 'The Deadmines', 'manual tab keeps updated activity')
Mock.now = 1100
OCS.Ingest('CHAT_MSG_CHANNEL', 'LFM DM tank', 'Manual', 'World', 'World', 'test', 'Common')
eq(saved('PVE_LFM', 'Manual'), manual, 'repeat advert moves the same manually moved record')
eq(manual.manualBucket, nil, 'repeat advert restores automatic tab classification')
eq(manual.schema, OCS.ROW_SCHEMA, 'new adverts retain their parser schema')
OCS.MoveRow('PVE_LFM', 'Manual', 'PVE_LFG')
eq(saved('PVE_LFG', 'Manual').manualBucket, 'PVE_LFG', 'manual tab choice retained for later upgrades')
print('PASS '..passed..' assertions; SavedVariables, reload and profile commands')
