local passed=0
local function eq(actual,expected,label)
    assert(actual==expected,(label or "value")..": expected "..tostring(expected)..", got "..tostring(actual))
    passed=passed+1
end
dofile('tests/wow_mock.lua')
-- Use the shipping load order, rather than maintaining another file list.
for line in io.lines('OctoScanner.toc') do
    if string.find(line,'%.lua%s*$') then
        dofile(''..string.gsub(line,'%s+$',''))
    end
end
OCS.SelectPack('vanilla')
-- Exercise every advertised alias, including wings before parent instances.
for i=1,table.getn(OCS.VANILLA_CONTENT) do
    local entry=OCS.VANILLA_CONTENT[i]
    for j=1,table.getn(entry[3]) do
        local text='LFM '..entry[3][j]..' need healer'
        local row=OCS.Parse(text)
        assert(row,text..' was dropped')
        eq(row.kind,entry[1],text);eq(row.target,entry[2],text)
    end
end
local cases={
    {"LF2M RFD need healer", "DGN", "Razorfen Downs", "LFM"},
    {"60 warrior LFG BRD", "DGN", "Blackrock Depths", "LFG"},
    {"LFM SM cath tank", "DGN", "Scarlet Monastery: Cathedral", "LFM"},
    {"LFM DM tribute", "DGN", "Dire Maul: Tribute", "LFM"},
    {"LFM DM", "DGN", nil, "LFM"},
    {"LFM MC HR MS/OS", "RAID", "Molten Core", "LFM"},
    {"LFM Azuregos", "WB", "Azuregos", "LFM"},
    {"LFM Naxx 15/40", "RAID", "Naxxramas", "LFM"},
}
for i=1,table.getn(cases) do
    local c=cases[i];local row=OCS.Parse(c[1]);assert(row,c[1].." was dropped")
    eq(row.kind,c[2],c[1]);eq(row.target,c[3],c[1]);eq(row.intent,c[4],c[1])
end
local function unknownGroup(text, label)
    local row=OCS.Parse(text)
    eq(row.kind,'OTHER',label);eq(row.target,nil,'unknown content is not a named activity')
end
unknownGroup('LFM Vault of the Inquisition','removed instance remains unknown')
unknownGroup('LFM Manastorm','removed activity remains unknown')
unknownGroup('LFM Karazhan Crypt','custom content absent from Vanilla')
eq(OCS.Parse('LF JC can craft gems'),nil,'no Jewelcrafting in Vanilla')
unknownGroup('LFM Blood Ring','no arena in Vanilla')
unknownGroup('LFM Thorn Gorge','no Thorn Gorge in Vanilla')
eq(OCS.Parse('LFM random dungeon').kind,'DGN','Vanilla generic dungeon')
eq(OCS.KIND_CATEGORY.CAT_DGN.kinds.LFT,nil,'Vanilla filter excludes LFT')
local trade=OCS.Parse('WTS [Flask of the Titans] 25g')
eq(trade.route,'TRADE');eq(trade.kind,'CONSUM')
local pvp=OCS.Parse('LFM WSG premade')
eq(pvp.route,'PVP');eq(pvp.kind,'BG')
eq(OCS.Match('abc','(b)'), 'b')
eq(OCS.Match('abc','b'), 'b')
eq(OCS.Len('abc'),3);eq(OCS.Len({1,2}),2)

-- Cumulative Turtle content is optional and must not alter the Vanilla pack.
OCS.SelectPack('octo')
for i=1,table.getn(OCS.TURTLE_CONTENT) do
    local entry=OCS.TURTLE_CONTENT[i]
    for j=1,table.getn(entry[3]) do
        local text='LFM '..entry[3][j]..' need healer'
        local row=OCS.Parse(text)
        assert(row,text..' was dropped')
        eq(row.kind,entry[1],text);eq(row.target,entry[2],text)
    end
end
local turtleCases={
    {'LFM WC tank','DGN','Wailing Caverns'},
    {'LFM WHC tank','DGN','Windhorn Canyon'},
    {'60 BM hunter LFG','OTHER',nil},
    {'LFM CoT BM healer','DGN','Caverns of Time: Black Morass'},
    {'LFM Kara','RAID',nil},
    {'LFM Karazhan Crypt tank','DGN','Karazhan Crypt'},
    {'LFM Dark Reaver of Karazhan','WB','Dark Reaver of Karazhan'},
    {'LFM Kara10','RAID','Lower Karazhan Halls'},
    {'LFM Kara40','RAID','Upper Karazhan Halls'},
    {'LFM random dungeon','LFT',nil},
    {'LFT BRD need healer','DGN','Blackrock Depths'},
    {'LFM Thorn Gorge premade','BG','Thorn Gorge'},
    {'LFG Blood Ring 3v3','ARENA','Blood Ring'},
    {'LFM 3s healer','ARENA','Blood Ring'},
}
for i=1,table.getn(turtleCases) do
    local c=turtleCases[i];local row=OCS.Parse(c[1]);assert(row,c[1]..' dropped')
    eq(row.kind,c[2],c[1]);eq(row.target,c[3],c[1])
end
eq(OCS.Parse('LFM ES hard mode healer').activityShort,'Raid (Hard Mode)')
eq(OCS.Parse('LFM ES normal').activityShort,'Raid (Normal)')
eq(OCS.Parse('LFM ES HC').activityShort,'Raid','HC does not imply difficulty')
eq(OCS.Parse('LF JC can craft gems').profession,'Jewelcrafting')
eq(OCS.Parse('Goldsmith LFW your mats').profMode,'offering')
eq(OCS.Parse('LF gardening service').profession,'Gardening')
eq(OCS.Parse('LF survival crafter').profession,'Survival')
eq(OCS.Parse('Survival hunter LFG').kind,'OTHER','Survival spec is not profession')
eq(OCS.Parse('WTS fashion tokens').kind,'TRANSMOG')
eq(OCS.Parse('WTS Arathi Basin tabard transmog').route,'TRADE','explicit sale beats PvP keywords')
eq(OCS.Parse('WTS Arathi Basin tabard transmog').kind,'TRANSMOG')
eq(OCS.Parse('WTS enchanting service').kind,'PROF','explicit sale still recognizes a profession')
unknownGroup('LFM Sunnyglade Valley','removed battleground remains unknown')
unknownGroup('LFM Hellfire Ramparts','no TBC instance')
eq(OCS.KIND_CATEGORY.CAT_DGN.kinds.LFT,true,'Octo LFT filter')
eq(OCS.PackForRealm("Tel'Abim"),'turtle')
eq(OCS.PackForRealm('Nordanaar'),'turtle')
eq(OCS.PackForRealm("N'Zoth"),'octo')
eq(OCS.PackForRealm('Unknown Realm'),'octo')
OCS.SelectPack('turtle')
eq(OCS.Parse('LFM Timbermaw Hold').target,'Timbermaw Hold')
OCS.SelectPack('vanilla')
unknownGroup('LFM Windhorn Canyon','profile switch removes custom content')
eq(OCS.KIND_CATEGORY.CAT_DGN.kinds.LFT,nil,'profile switch removes custom filters')
OCS.SelectPack('octo')
Mock.event('ADDON_LOADED','OtherAddon')
eq(OCS_DB,nil,'unrelated load')
Mock.event('ADDON_LOADED','OctoScanner')
assert(OCS_DB and OCS.initDone)
Mock.event('PLAYER_LOGIN')
for i=1,table.getn(Mock.messages) do assert(not string.find(Mock.messages[i],'interface error',1,true),Mock.messages[i]) end
OCS.Show()
OCS.UI.createFilterPanel()
OCS.RefreshFilterPanel()
OCS_DB.filter.class='Warrior'
OCS.SetSection('TRADE');OCS.SetSection('PVE')
eq(OCS_DB.filter.class,'Warrior','per-section class filter survives')
OCS_DB.filter.class='ALL'
OCS.ShowWhisperSetup()
OCS.MiniShow()
OCS.SetSection('TRADE');OCS.SetSection('PVP');OCS.SetSection('GUILD');OCS.SetSection('PVE')
Mock.event('CHAT_MSG_CHANNEL','LF2M BRD tank','Recruiter',nil,'1. World',nil,nil,nil,1,'World')
eq(table.getn(OCS_DB.rows.PVE_LFM),1,'chat stored')
eq(OCS_DB.rows.PVE_LFM[1].channel,'World','channel payload')
eq(OCS.stats.errors,0,'capture errors')
Mock.event('CHAT_MSG_CHANNEL','LF2M BRD tank','Recruiter',nil,'1. World',nil,nil,nil,1,'World')
eq(table.getn(OCS_DB.rows.PVE_LFM),1,'repeat deduplicated')
eq(table.getn(Mock.sent),0,'no automatic whispers')
OCS.SendWhisper(OCS_DB.rows.PVE_LFM[1],'PVE_LFM')
eq(table.getn(Mock.sent),1,'explicit whisper');eq(Mock.sent[1].target,'Recruiter')
Mock.party=2;eq(OCS.CanInvite(),false,'party member');Mock.leader=true;eq(OCS.CanInvite(),true,'party leader')
Mock.leader=nil;Mock.party=0;Mock.raid=20;Mock.officer=true;eq(OCS.CanInvite(),true,'raid assistant')
Mock.raid=0;Mock.officer=nil
OCS.UI.inviteEntry('Recruiter').func()
eq(Mock.invited,'Recruiter','Vanilla InviteByName action')
Mock.party=1
eq(OCS.UI.inviteEntry('Recruiter').disabled,true,'disabled invite for party member')
Mock.party=0

-- Native menu initializer receives level only; submenu is passed via VALUE.
OCS.OpenPlayerMenu('PVE_LFM','Recruiter',OCS_Window)
local moveEntry
for i=1,table.getn(Mock.menu) do
    if Mock.menu[i].text=='Move to' then moveEntry=Mock.menu[i] end
end
assert(moveEntry and moveEntry.value)
ToggleDropDownMenu(2,moveEntry.value,OCS_MenuFrame)
local moveToTrade
for i=1,table.getn(Mock.menu) do
    if Mock.menu[i].text=='Trade WTS' then moveToTrade=Mock.menu[i] end
end
assert(moveToTrade,'move submenu did not populate')
moveToTrade.func()
eq(table.getn(OCS_DB.rows.PVE_LFM),0,'manual move removes old row')
eq(table.getn(OCS_DB.rows.TRADE_WTS),1,'manual move places row')
OCS.MoveRow('TRADE_WTS','Recruiter','PVE_LFM')

local row=OCS_DB.rows.PVE_LFM[1]
local displayRow=CreateFrame('Button',nil,OCS_Window);displayRow.data=row
local cell=displayRow:CreateFontString()
OCS.UI.openCellEditor(displayRow,cell,'level')
OCS_LevelEdit:SetText('59');Mock.fire(OCS_LevelEdit,'OnEnterPressed')
eq(row.level,59,'native Enter callback saves edit');eq(row.locked.level,true)
Mock.event('CHAT_MSG_CHANNEL','LFM BRD healer','Recruiter',nil,'1. World',nil,nil,nil,1,'World')
eq(row.level,59,'manual level survives next advert')
OCS.UI.openCellEditor(displayRow,cell,'level')
OCS_LevelEdit:SetText('');Mock.fire(OCS_LevelEdit,'OnEnterPressed')
eq(row.level,nil,'blank edit restores parsed value');eq(row.locked.level,nil)
OCS.UI.openCellEditor(displayRow,cell,'prog')
OCS_LevelEdit:SetText('4/5');Mock.fire(OCS_LevelEdit,'OnEnterPressed')
eq(row.prog,'4/5','progress edit')

local classRow=OCS.Parse('60 warrior LFG BRD')
eq(OCS.PassesFilterWith(classRow,{class='Warrior',kind='CAT_DGN',target='Blackrock Depths'}),true,'named instance and class filter')
eq(OCS.PassesFilterWith(classRow,{class='Mage'}),false,'class mismatch')
eq(OCS.PassesFilterWith(classRow,{kind='CAT_RAID'}),false,'kind mismatch')
eq(OCS.PassesFilterWith(classRow,{minLevel=60,maxLevel=60}),true,'character level filter')
eq(OCS.PassesFilterWith(OCS.Parse('LFM random dungeon'),{kind='CAT_DGN',target='LFT'}),true,'LFT subfilter')

-- Clear and repopulate lists: Lua 5.0 keeps table sizes after table.insert.
OCS.MiniClear();eq(OCS.MiniCount(),0)
OCS.MiniPush(row,'PVE_LFM');eq(OCS.MiniCount(),1)
OCS.MiniClear();OCS.MiniPush(row,'PVE_LFM');eq(OCS.MiniCount(),1,'feed reused after clear')
OCS.UI.buildCols();OCS.UI.buildCols()
eq(table.getn(OCS.UI.COLS),9,'column list reused')
for i=1,table.getn(OCS.SKIN_ORDER) do
    OCS.SetSkin(OCS.SKIN_ORDER[i].id)
    eq(OCS_DB.style,OCS.SKIN_ORDER[i].id,'skin applied')
end
OCS.SetSkin('vanilla')
OCS.ShowAlert({name='First',message='one'},'PVE_LFM')
OCS.ShowAlert({name='Second',message='two'},'PVE_LFM')
eq(OCS_Alert.body:GetText(),'one','first queued popup')
for i=1,3 do Mock.fire(OCS_AlertDriver,'OnUpdate',10) end
eq(OCS_Alert.body:GetText(),'two','second queued popup')
for i=1,3 do Mock.fire(OCS_AlertDriver,'OnUpdate',10) end
eq(OCS_Alert:IsShown(),false,'queue drained')
OCS.ShowAlert({name='Third',message='three'},'PVE_LFM')
eq(OCS_Alert.body:GetText(),'three','queue reused after drain')
OCS.SetAlertUnlocked(true);eq(OCS.AlertUnlocked(),true)
OCS.SetAlertUnlocked(false);eq(OCS.AlertUnlocked(),false)
eq(OCS.stats.errors,0,'capture stays healthy after edits')
OCS.Probe()
print('PASS '..passed..' assertions; Lua '.._VERSION..'; parser, load, UI, chat and actions')
