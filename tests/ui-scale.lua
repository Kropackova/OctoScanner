local passed = 0
local function eq(a, b, label)
    assert(a == b, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
    passed = passed + 1
end
local function near(a, b, label)
    assert(math.abs(a - b) < 0.000001, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
    passed = passed + 1
end
local function read(path)
    local f = assert(io.open(path)); local text = f:read('*a'); f:close(); return text
end
local function loadCode()
    for line in io.lines('OctoScanner.toc') do
        if string.find(line, '%.lua%s*$') then dofile('' .. string.gsub(line, '%s+$', '')) end
    end
end
dofile('tests/wow_mock.lua')
Mock.freezeTitleTemplate = true
local nativeToggle, nativeInitialize = ToggleDropDownMenu, UIDropDownMenu_Initialize
local toc = read('OctoScanner.toc')
eq(string.find(toc, 'OctoChatScanner', 1, true), nil, 'scanner no longer depends on migration addon')
eq(string.find(toc, '## Title: OctoScanner', 1, true) ~= nil, true, 'new addon title')
OCS_DB = {style = 'dark', window = {scale = 50}, mini = {shown = true, hasPos = true, point = 'CENTER', rel = 'CENTER', x = 240, y = 100}}
local oldSettings = OCS_DB
loadCode()
Mock.event('ADDON_LOADED', 'OctoChatScanner')
eq(OCS.initDone, nil, 'old folder never initializes scanner')
Mock.event('ADDON_LOADED', 'OctoScanner')
eq(OCS_DB, oldSettings, 'legacy settings retained')
eq(OCS_DB.style, 'dark', 'old skin retained')
eq(OCS_DB.alert.scope, 'SECTION', 'missing alert scope defaults to Section')
Mock.event('PLAYER_LOGIN')
OCS.ShowMain()
eq(OCS_MiniWindow:GetScale(), 0.5, 'restored mini feed starts scaled')
local _, _, _, mx, my = OCS_MiniWindow:GetPoint()
eq(mx, 480, 'legacy mini offset preserves screen position'); eq(my, 200)
UIParent:SetScale(0.8)
GameTooltip:SetScale(1.1)
local title = OctoScannerTitle
local shadow = OctoScannerTitleShadow
local caption = OctoScannerCaption
assert(title, 'renamed title missing')
eq(caption:GetText(), 'Find groups, PvP, trades and guilds - all parsed from messages in your joined chat channels.')
eq(caption.parent, title.parent, 'caption inherits title visibility and scale')
local cp, cr, crel, cx, cy = caption:GetPoint()
eq(cp, 'BOTTOMLEFT'); eq(cr, title.parent); eq(crel, 'BOTTOMRIGHT')
eq(cx, 12, 'caption has a gap after title'); eq(cy, 0, 'caption aligns beside title')
eq(title.parent.mouseEnabled, true, 'title hover enabled')
eq(title.parent.dragButton, 'LeftButton', 'title remains a window drag handle')
eq(title.parent.parent, OCS_Window, 'title stays in main visibility and stacking hierarchy')
eq(title.kind, 'Texture', 'title uses native texture rendering rather than font cache')
eq(title.texture[1], 'Interface\\AddOns\\OctoScanner\\Textures\\OctoScannerTitle.tga', 'full wordmark asset')
eq(title.parent:GetWidth(), 118.2); eq(title.parent:GetHeight(), 15)
eq(shadow.parent, title.parent, 'shadow shares title scaling and visibility')
eq(shadow.texture[1], title.texture[1], 'shadow matches complete title glyphs')
eq(shadow.vertexColor[1] + shadow.vertexColor[2] + shadow.vertexColor[3], 0, 'shadow is black')
eq(shadow.vertexColor[4], 1, 'shadow uses stock opacity')
local sp, sr, srel, sx, sy = shadow:GetPoint()
eq(sp, 'TOPLEFT'); eq(sr, title.parent); eq(srel, 'TOPLEFT')
eq(sx, 1, 'stock font shadow horizontal offset'); eq(sy, -1, 'stock font shadow vertical offset')
local scope
for _, f in ipairs(Mock.frames) do
    if f.kind == 'Button' and f:GetText() == 'Section' then scope = f end
end
assert(scope, 'Section scope button missing')
Mock.fire(scope, 'OnClick', 'LeftButton'); eq(OCS_DB.alert.scope, 'ALL'); eq(scope:GetText(), 'All')
Mock.fire(scope, 'OnClick', 'LeftButton'); eq(OCS_DB.alert.scope, 'SECTION'); eq(scope:GetText(), 'Section')
local advert = OCS.Parse('LFM BRD need healer')
eq(OCS.AlertMatch('PVE_LFM', advert), true, 'current tab matches default scope')
eq(OCS.AlertMatch('PVE_LFG', advert), false, 'other tab does not match default scope')
OCS_DB.filter.target = 'Shadowfang Keep'
OCS_DB.filter.kind = 'CAT_DGN'
eq(OCS.AlertMatch('PVE_LFM', advert), false, 'scope still honors active filters')
OCS_DB.filter.target = 'ALL'
OCS_DB.filter.kind = 'ALL'
OCS_DB.alert.scope = nil
eq(OCS.AlertMatch('PVE_LFG', advert), false, 'nil scope also falls back to Section')
OCS.UpdateAlertButtons(); eq(scope:GetText(), 'Section', 'nil scope displays Section')
OCS_DB.alert.scope = 'SECTION'
local filters, rows, skins, scale = unpack(OCS.UI.menuButtons())
DropDownList1 = CreateFrame('Frame', 'DropDownList1', UIParent); DropDownList1:Hide(); DropDownList1:SetScale(1.2)
local hides, shows, updates = 0, 0, 0
DropDownList1:SetScript('OnHide', function() hides = hides + 1 end)
DropDownList1:SetScript('OnShow', function() shows = shows + 1 end)
DropDownList1:SetScript('OnUpdate', function() updates = updates + 1 end)
for _, percent in ipairs({50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 50}) do
    local factor = percent / 100
    OCS.SetWindowScale(percent)
    near(OCS_Window:GetEffectiveScale(), 0.8 * factor, 'main scale')
    near(OCS_MiniWindow:GetEffectiveScale(), 0.8 * factor, 'mini scale')
    near(title.parent:GetEffectiveScale(), 0.8 * factor, 'title quad inherits main scale')
    near(caption:GetEffectiveScale(), 0.8 * factor, 'caption follows addon scale')
    near(title:GetWidth() * title.parent:GetEffectiveScale(), 118.2 * 0.8 * factor, 'reduced wordmark width follows Scale')
    near(title:GetHeight() * title.parent:GetEffectiveScale(), 15 * 0.8 * factor, 'reduced wordmark height follows Scale')
    near(shadow:GetWidth() * shadow:GetEffectiveScale(), title:GetWidth() * title:GetEffectiveScale(), 'shadow width follows title')
    near(shadow:GetHeight() * shadow:GetEffectiveScale(), title:GetHeight() * title:GetEffectiveScale(), 'shadow height follows title')
    near(sx * shadow:GetEffectiveScale(), 0.8 * factor, 'shadow offset scales with normal text')
    eq(title.font, nil, 'title does not use font resizing')
    eq(title.texCoord[2], 394 / 512, 'all title glyphs fit texture crop')
    eq(title.texCoord[4], 50 / 64, 'full glyph height fits texture crop')
    local point, parent, relative, x, y = title.parent:GetPoint()
    eq(parent, OCS_Window, 'title stays attached to main window')
    near(x * title.parent:GetEffectiveScale() / OCS_Window:GetEffectiveScale(), OCS.EdgeMargin() * OCS.UI.TITLE_INDENT, 'title left padding scales with window')
    eq(x + title:GetWidth() + 12 + caption:GetWidth() <= OCS_Window:GetWidth() - 104 + 0.000001, true, 'caption leaves room for window controls')
    near(y, -20, 'title uses configured top offset')
    eq(-y + title.parent:GetHeight() + 8 <= OCS.UI.ROW_TOP, true, 'title clears compact button rows')
    eq(OCS.UI.ROW_TOP, 46, 'no extra blank header space')
    local section
    for _, f in ipairs(Mock.frames) do
        if f.kind == 'Button' and f:GetText() == 'PvE' then section = f end
    end
    local _, _, _, _, sy = section:GetPoint()
    eq(-sy, OCS.UI.ALERT_TOP, 'section and alert rows align below title')
    Mock.fire(title.parent, 'OnEnter')
    near(OctoScannerTitleHelp:GetEffectiveScale(), 0.8 * factor, 'two-line help follows addon scale')
    local hp, hr, hrel, hx, hy = OctoScannerTitleHelp:GetPoint()
    eq(hp, 'BOTTOMLEFT'); eq(hr, title.parent); eq(hrel, 'TOPLEFT')
    eq(hx, 0); eq(hy, 6, 'help appears above title with a small gap')
    eq(table.getn(OctoScannerTitleHelp.lines), 2, 'exactly two help rows')
    eq(OctoScannerTitleHelp.lines[1]:GetText(), 'Use Filters to narrow results and set alerts for matching messages.')
    eq(OctoScannerTitleHelp.lines[2]:GetText(), 'Click >> in the W column to send messages using whisper templates.')
    for _, line in ipairs(OctoScannerTitleHelp.lines) do
        eq(line:GetWidth() > line:GetStringWidth(), true, 'each full sentence fits a single visual line')
    end
    Mock.fire(title.parent, 'OnLeave'); eq(OctoScannerTitleHelp:IsShown(), false, 'leaving title hides help')
    for _, button in ipairs({scale, rows, skins}) do
        Mock.fire(button, 'OnClick', 'LeftButton')
        near(DropDownList1:GetScale(), factor, 'dropdown scale')
        near(DropDownList1:GetEffectiveScale(), 0.8 * factor, 'dropdown respects game UI scale')
        OCS.UI.closeViewMenu()
        near(DropDownList1:GetScale(), 1.2, 'shared dropdown scale restored')
    end
    Mock.fire(filters, 'OnClick', 'LeftButton')
    near(OCS_FilterPanel:GetScale(), factor, 'Filters panel')
    Mock.fire(OCS_FilterPanel.kindButton, 'OnClick', 'LeftButton')
    near(OCS_KindPicker:GetScale(), factor, 'activity picker')
    -- Drill into a category: the second-level panel inherits exactly once.
    local category
    for _, f in ipairs(Mock.frames) do
        if f.parent == OCS_KindPicker and f.text and string.find(f.text:GetText(), 'Dungeon', 1, true) then category = f end
    end
    assert(category, 'activity category missing')
    Mock.fire(category, 'OnEnter')
    local subpanel
    for _, f in ipairs(Mock.frames) do if f.kind == 'Frame' and f.parent == OCS_KindPicker then subpanel = f end end
    assert(subpanel, 'activity submenu missing')
    near(subpanel:GetEffectiveScale(), 0.8 * factor, 'activity submenu scales once')
    OCS.UI.closeFilterPanel()
end
local originalWidth, originalCaptionWidth = OCS_Window:GetWidth(), caption:GetWidth()
OCS_Window:SetWidth(680); OCS.UI.layout()
eq(caption:GetWidth() < originalCaptionWidth, true, 'caption adapts to a narrower window')
OCS_Window:SetWidth(originalWidth); OCS.UI.layout()
near(caption:GetWidth(), originalCaptionWidth, 'caption width recovers when window grows')
-- Short control explanations remain one visual line per sentence.
for _, percent in ipairs({100, 50}) do
    OCS.SetWindowScale(percent)
    for _, button in ipairs({scale, rows}) do
        Mock.fire(button, 'OnEnter')
        local lines = OctoScannerTooltip.lines
        eq(table.getn(lines), 3, 'control heading and two complete sentences')
        if button == scale then
            eq(lines[2].text, 'Addon size: 100% to 50% in 5% steps.')
            eq(lines[3].text, 'Saved for this character. /ocs reset restores 100%.')
        else
            eq(lines[2].text, 'Chooses which columns the table shows.')
            eq(lines[3].text, 'Each section keeps its own choice.')
        end
        eq(lines[2].wrap, false, 'first explanation does not wrap')
        eq(lines[3].wrap, false, 'second explanation does not wrap')
        Mock.fire(button, 'OnLeave')
    end
end
Mock.fire(scale, 'OnClick', 'LeftButton')
Mock.fire(DropDownList1, 'OnUpdate', 0.1)
eq(updates, 1, 'native dropdown update retained')
OCS.UI.closeViewMenu()
eq(shows > 0, true, 'native dropdown show retained'); eq(hides, shows, 'native dropdown hide retained')
local foreign = CreateFrame('Frame', 'ForeignMenu', UIParent)
UIDropDownMenu_Initialize(foreign, function() end)
ToggleDropDownMenu(1, nil, foreign)
near(DropDownList1:GetScale(), 1.2, 'unrelated menu unaffected')
CloseDropDownMenus()
Mock.fire(scale, 'OnClick', 'LeftButton')
ToggleDropDownMenu(1, nil, foreign)
Mock.fire(DropDownList1, 'OnUpdate', 0.1)
near(DropDownList1:GetScale(), 1.2, 'direct foreign takeover releases shared scale')
CloseDropDownMenus()

-- Both main and mini rows must use the private, scaled tooltip.
Mock.event('CHAT_MSG_CHANNEL', 'LFM BRD need healer', 'Recruiter', nil, '1. World', nil, nil, nil, 1, 'World')
local row = OCS_DB.rows.PVE_LFM[1]
OCS.MiniPush(row, 'PVE_LFM'); OCS.MiniShow(); OCS.Refresh()
local mainRow, miniRow
for _, f in ipairs(Mock.frames) do
    if f.kind == 'Button' and f.data == row then mainRow = f end
    if f.kind == 'Button' and f.entry and f.entry.name == 'Recruiter' then miniRow = f end
end
assert(mainRow and miniRow, 'message rows missing')
for _, f in ipairs({mainRow, miniRow, scale}) do
    Mock.fire(f, 'OnEnter')
    eq(OctoScannerTooltip:IsShown(), true, 'private tooltip visible')
    near(OctoScannerTooltip:GetScale(), 0.5, 'message/control tooltip scaled')
    near(GameTooltip:GetScale(), 1.1, 'game tooltip untouched')
    Mock.fire(f, 'OnLeave'); eq(OctoScannerTooltip:IsShown(), false)
end
OCS.OpenPlayerMenu('PVE_LFM', 'Recruiter', mainRow)
near(DropDownList1:GetScale(), 0.5, 'player menu')
local move
for _, entry in ipairs(Mock.menu) do if entry.text == 'Move to' then move = entry end end
assert(move, 'player submenu missing')
ToggleDropDownMenu(2, move.value, OCS_MenuFrame)
near(DropDownList2:GetScale(), 0.5, 'native player submenu')
CloseDropDownMenus(); near(DropDownList2:GetScale(), 1, 'submenu restored')
OCS.UI.showCopyBox('Recruiter'); near(OCS_CopyFrame:GetScale(), 0.5, 'copy dialog')
OCS.ShowWhisperSetup(); near(OCS_WhisperPanel:GetScale(), 0.5, 'whisper dialog')
OCS.ShowAlert(row, 'PVE_LFM'); near(OCS_Alert:GetScale(), 0.5, 'notification scaled')
local clearButton
for _, f in ipairs(Mock.frames) do
    if f.kind == 'Button' and f:GetText() == 'Clear All' then clearButton = f end
end
assert(clearButton, 'Clear All missing')
StaticPopupDialogs.FOREIGN_TEST = {text = 'Game dialog'}
local confirmation = StaticPopup_Show('FOREIGN_TEST')
confirmation:Hide(); confirmation:SetScale(1.2)
Mock.fire(clearButton, 'OnClick', 'LeftButton')
eq(confirmation.which, 'OCS_CLEAR_ALL', 'Clear All opens its confirmation')
near(confirmation:GetScale(), 0.5, 'clear confirmation follows addon scale')
near(confirmation:GetEffectiveScale(), 0.8 * 0.5, 'clear confirmation inherits game scale once')
Mock.fire(clearButton, 'OnClick', 'LeftButton')
near(confirmation:GetScale(), 0.5, 'repeat click retains original shared scale')
OCS.SetWindowScale(75)
near(confirmation:GetScale(), 0.75, 'visible confirmation follows scale changes')
confirmation:Hide()
near(confirmation:GetScale(), 1.2, 'confirmation returns shared popup scale on cancel')
StaticPopup_Show('FOREIGN_TEST')
OCS.SetWindowScale(50)
near(confirmation:GetScale(), 1.2, 'unrelated shared popup is no longer registered')
confirmation:Hide()
Mock.fire(clearButton, 'OnClick', 'LeftButton')
near(confirmation:GetScale(), 0.5, 'confirmation can reopen at the new scale')
StaticPopupDialogs.OCS_CLEAR_ALL.OnAccept()
confirmation:Hide()
near(confirmation:GetScale(), 1.2, 'accept restores shared scale too')
eq(OCS.CountAll(), 0, 'confirmed clearing still removes rows')
OCS.SetWindowScale(75)
near(OCS_MiniWindow:GetScale(), 0.75, 'existing mini follows change')
near(OCS_CopyFrame:GetScale(), 0.75, 'existing dialog follows change')
near(OCS_Alert:GetScale(), 0.75, 'existing alert follows change')
near(OCS_DB.alert.pos.x, 500 * 0.5 / 0.75, 'alert saves converted center instead of drag anchor')
near(OCS_DB.alert.pos.y, 400 * 0.5 / 0.75, 'alert converted center y')
local savedPoint, savedRelative, savedX, savedY = OCS_DB.mini.point, OCS_DB.mini.rel, OCS_DB.mini.x, OCS_DB.mini.y
local newSettings = OCS_DB
newSettings.alert.scope = 'ALL'
eq(ToggleDropDownMenu, nativeToggle, 'native menu API unchanged')
eq(UIDropDownMenu_Initialize, nativeInitialize, 'native menu initializer unchanged')
OCS = nil; dofile('tests/wow_mock.lua'); loadCode()
-- New saved file overrides the optional legacy file, as the WoW loader does.
OCS_DB = {style = 'vanilla', window = {scale = 100}}
OCS_DB = newSettings
Mock.event('ADDON_LOADED', 'OctoScanner'); Mock.event('PLAYER_LOGIN')
eq(OCS_DB.style, 'dark', 'new settings take precedence')
eq(OCS_DB.alert.scope, 'ALL', 'explicitly saved All scope survives reload')
local restoredTitle = OctoScannerTitle
near(restoredTitle:GetHeight() * restoredTitle.parent:GetEffectiveScale(), 15 * 0.75, 'restored title quad draws at saved scale')
Mock.fire(restoredTitle.parent, 'OnEnter')
near(OctoScannerTitleHelp:GetScale(), 0.75, 'title help inherits restored addon scale')
Mock.fire(restoredTitle.parent, 'OnDragStart'); eq(OctoScannerTitleHelp:IsShown(), false, 'title drag dismisses help')
Mock.fire(restoredTitle.parent, 'OnDragStop'); eq(OCS_DB.window.hasPos, true, 'title drag saves placement')
OCS.HideMain(); eq(restoredTitle.parent:IsShown(), false, 'title hides with main window')
eq(OctoScannerCaption:IsVisible(), false, 'caption hides with main window')
eq(OctoScannerTitleHelp:IsShown(), false, 'hiding main window dismisses title help')
OCS.ShowMain(); eq(restoredTitle.parent:IsShown(), true, 'title returns with main window')
eq(OctoScannerCaption:IsVisible(), true, 'caption returns with main window')
OCS.MiniShow()
near(OCS_MiniWindow:GetScale(), 0.75, 'mini scale survives reload')
local p, _, rel, x, y = OCS_MiniWindow:GetPoint()
eq(p, savedPoint); eq(rel, savedRelative); near(x, savedX); near(y, savedY)
for _, gameScale in ipairs({0.64, 1}) do
    UIParent:SetScale(gameScale)
    for _, percent in ipairs({50, 100}) do
        OCS.SetWindowScale(percent)
        near(restoredTitle:GetWidth() * restoredTitle.parent:GetEffectiveScale(), 118.2 * gameScale * percent / 100, 'title pixels follow game and addon scales')
    end
end
-- The mini feed also sizes rows in logical units, independent of both scales.
OCS.MiniClear()
for i = 1, 90 do
    OCS.MiniPush({name = 'MiniCapacity' .. i, message = 'LFM BRD', time = Mock.now}, 'PVE_LFM')
end
for _, gameScale in ipairs({0.64, 0.8, 1}) do
    UIParent:SetScale(gameScale)
    for percent = 50, 100, 5 do
        OCS.SetWindowScale(percent)
        for _, height in ipairs({90, 200, 700}) do
            OCS_MiniWindow:SetHeight(height)
            Mock.fire(OCS_MiniWindow, 'OnSizeChanged')
            OCS.MiniRefresh()
            local visible = 0
            for _, f in ipairs(Mock.frames) do
                if f.kind == 'Button' and f.parent == OCS_MiniWindow and f.entry and f:IsShown() then
                    visible = visible + 1
                    local _, _, _, _, y = f:GetPoint()
                    eq(-y + f:GetHeight() <= height - 10, true, 'mini row clears bottom padding')
                end
            end
            eq(visible, math.floor((height - 26 - 10) / 16), 'mini uses every logical row slot')
            eq(OCS.MiniCount(), 90, 'scale and resizing never discard mini entries')
        end
    end
end
OCS_MiniWindow:SetHeight(90); Mock.fire(OCS_MiniWindow, 'OnSizeChanged')
Mock.fire(OCS_MiniWindow, 'OnMouseWheel', -1000)
local oldestVisible = false
for _, f in ipairs(Mock.frames) do
    if f.parent == OCS_MiniWindow and f.entry and f:IsShown() and f.entry.name == 'MiniCapacity1' then
        oldestVisible = true
    end
end
eq(oldestVisible, true, 'oldest mini entry remains reachable after shrinking')
eq(OCS.stats.errors, 0, 'no UI or parser errors')
eq(table.getn(Mock.sent), 0, 'no chat sent by scale or migration')
print('PASS ' .. passed .. ' assertions; complete UI scaling, private tooltips, shared menu restoration and renamed settings')
