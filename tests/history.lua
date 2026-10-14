-- Data-loss regressions: age/caps, reload, per-player updates and manual clears.
local passed = 0
local function eq(a, b, label)
    assert(a == b, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
    passed = passed + 1
end
local function loadAddon(now)
    dofile('tests/wow_mock.lua')
    Mock.now = now or Mock.now
    for line in io.lines('OctoScanner.toc') do
        if string.find(line, '%.lua%s*$') then dofile('' .. string.gsub(line, '%s+$', '')) end
    end
    Mock.event('ADDON_LOADED', 'OctoScanner')
    Mock.event('PLAYER_LOGIN')
end
OCS_DB = {expiry = 60, maxRows = 1, sortKey = 'name', sortAsc = true, alert = {scope = 'ALL'}, rows = {PVE_LFM = {}}}
for i = 1, 250 do
    table.insert(OCS_DB.rows.PVE_LFM, {name = 'Saved' .. i, time = i,
        message = 'LFM BRD need healer', kind = 'DGN', target = 'Blackrock Depths', schema = 5})
end
OCS_DB.rows.GUILD_ALL = {
    {name = 'Old', time = -2601, schema = 5},
    {name = 'Invalid', schema = 5},
    {name = 'Future', time = 1001, schema = 5},
    {name = 'ExactlyOneHour', time = -2600, schema = 5},
}
OCS_DB.rows.PVE_UNSURE = {{name = 'Boundary', time = -2599, schema = 5}}
loadAddon()
eq(OCS.CountAll(), 251, 'load keeps recent rows beyond old cap and expiry')
eq(table.getn(OCS_DB.rows.GUILD_ALL), 0, 'load drops timestamps one hour or older, invalid and future')
eq(table.getn(OCS_DB.rows.PVE_UNSURE), 1, 'one second younger than an hour survives load')
OCS.RemoveRow('PVE_UNSURE', 'Boundary')
eq(OCS_DB.expiry, nil, 'old expiry removed'); eq(OCS_DB.maxRows, nil, 'old cap removed')
eq(OCS_DB.sortKey, 'time', 'upgrade resets sort column'); eq(OCS_DB.sortAsc, false, 'newest first')
local list = OCS.GetSortedRows('PVE_LFM', OCS_DB.sortKey, OCS_DB.sortAsc)
eq(list[1].name, 'Saved250', 'newest saved row first'); eq(list[250].name, 'Saved1', 'oldest saved row last')
OCS.Show(); OCS.MiniShow()
for i = 1, 121 do
    Mock.now = Mock.now + 4
    Mock.event('CHAT_MSG_CHANNEL', 'LFM BM need healer', 'Player' .. i, 'Common', 'World', nil, nil, nil, 1, 'World')
end
eq(OCS.CountAll(), 371, 'new rows do not evict old rows')
eq(OCS.MiniCount(), 121, 'mini feed exceeds former 100-row cap')
local original
for _, row in ipairs(OCS_DB.rows.PVE_LFM) do if row.name == 'Player1' then original = row end end
assert(original, 'first row missing')
original.locked.level, original.level = true, 55
Mock.now = Mock.now + 4
Mock.event('CHAT_MSG_CHANNEL', 'LFM BRD need tank', 'Player1', 'Common', 'World', nil, nil, nil, 1, 'World')
eq(OCS.CountAll(), 371, 'repeat updates existing player')
eq(OCS.MiniCount(), 121, 'repeat replaces mini entry')
eq(original.target, 'Blackrock Depths', 'existing row receives new advert')
eq(original.roleSet.tank, true, 'new role replaces previous role')
eq(original.roleSet.heal, nil, 'previous role cleared')
eq(original.level, 55, 'manual edit remains locked')
eq(OCS.GetSortedRows('PVE_LFM', 'time', false)[1], original, 'updated row moves to top')
Mock.now = Mock.now + 172800
Mock.fire(OCS_Driver, 'OnUpdate', 172800)
Mock.fire(OCS_MiniTicker, 'OnUpdate', 172800)
OCS.Refresh(); OCS.MiniRefresh()
eq(OCS.CountAll(), 371, 'two days of time do not prune main rows')
eq(OCS.MiniCount(), 121, 'two days of time do not prune mini feed')
Mock.event('CHAT_MSG_CHANNEL', 'LFG BM', 'Player1', 'Common', 'World', nil, nil, nil, 1, 'World')
eq(OCS.CountAll(), 371, 'changed intent moves existing player between tabs')
eq(table.getn(OCS_DB.rows.PVE_LFG), 1, 'new player intent bucket')
eq(OCS_DB.rows.PVE_LFG[1], original, 'intent change moves the same row object')
eq(OCS_DB.rows.PVE_LFG[1].level, 55, 'intent change retains manual level')
eq(OCS_DB.rows.PVE_LFG[1].locked.level, true, 'intent change retains manual cell lock')
eq(OCS.MiniCount(), 121, 'intent move keeps one mini entry')
OCS.RemoveRow('PVE_LFG', 'Player1')
eq(OCS.CountAll(), 370, 'manual row removal works'); eq(OCS.MiniCount(), 120, 'manual removal reaches mini')
Mock.event('CHAT_MSG_CHANNEL', 'WTS boots 5g', 'Seller', 'Common', 'World', nil, nil, nil, 1, 'World')
eq(table.getn(OCS_DB.rows.TRADE_WTS), 1, 'other section populated')
OCS.ClearBucket('PVE_LFM')
eq(OCS.CountAll(), 1, 'clear tab preserves other section'); eq(OCS.MiniCount(), 1, 'clear tab removes only matching mini entries')
StaticPopupDialogs.OCS_CLEAR_ALL.OnAccept()
eq(OCS.CountAll(), 0, 'Clear All button empties all sections'); eq(OCS.MiniCount(), 0, 'Clear All empties mini')
Mock.event('CHAT_MSG_CHANNEL', 'LFM BM need healer', 'Player2', 'Common', 'World', nil, nil, nil, 1, 'World')
eq(OCS.CountAll(), 1, 'cleared identical advert can immediately return')
SlashCmdList.OCTOCS('clearall')
eq(OCS.CountAll(), 0, 'slash clearall works'); eq(OCS.MiniCount(), 0, 'slash clearall reaches mini')
Mock.event('CHAT_MSG_CHANNEL', 'LFM BRD need tank', 'Persistent', 'Common', 'World', nil, nil, nil, 1, 'World')
local header, hasPackSubtitle, title
for _, f in ipairs(Mock.frames) do
    if f.kind == 'FontString' and string.find(f:GetText(), 'Pack:', 1, true) then hasPackSubtitle = true end
    if f.name == 'OctoScannerTitle' then title = f end
    if f.kind == 'Button' and f.label and f.label:GetText() == 'Time' then header = f end
end
eq(hasPackSubtitle, nil, 'no pack subtitle')
assert(title, 'title missing')
eq(title:GetWidth() * title.parent:GetEffectiveScale() / OCS_Window:GetEffectiveScale(), 118.2, 'title keeps its reduced logical width')
assert(header, 'time header missing'); Mock.fire(header, 'OnClick', 'LeftButton')
eq(OCS_DB.sortAsc, true, 'explicit time-header click still reverses order')
-- Prune on logout to avoid writing old history, and on load after a crash.
table.insert(OCS_DB.rows.PVE_LFM, {name = 'LogoutOld', time = Mock.now - 3601, schema = 5})
Mock.fire(OCS_Driver, 'OnUpdate', 10)
eq(OCS.CountAll(), 2, 'old row remains throughout live session')
Mock.event('PLAYER_LOGOUT')
eq(OCS.CountAll(), 1, 'logout only saves the last hour')
local reloadNow = Mock.now + 120
-- Fresh Lua globals/frame state, but the same character SavedVariables.
OCS = nil
loadAddon(reloadNow)
eq(OCS.CountAll(), 1, 'reload keeps manually retained history')
eq(OCS_DB.rows.PVE_LFM[1].name, 'Persistent', 'saved player survives reload')
eq(OCS_DB.sortAsc, true, 'later explicit sort choice survives reload')
eq(OCS_DB.manualCleanupVersion, 1, 'upgrade migration only runs once')
table.insert(OCS_DB.rows.PVE_LFM, {name = 'CrashOld', time = Mock.now - 3601, schema = 5})
OCS = nil
loadAddon(reloadNow + 1)
eq(OCS.CountAll(), 1, 'next load prunes old crash-restored data')
eq(OCS.stats.errors, 0, 'no capture errors')
eq(table.getn(Mock.sent), 0, 'history checks send no chat')
print('PASS ' .. passed .. ' assertions; one-hour restore, unbounded live history, logout, reload and manual clears')
