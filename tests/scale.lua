local passed = 0
local function eq(a, b, label)
    assert(a == b, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
    passed = passed + 1
end
local function near(a, b, label)
    assert(math.abs(a - b) < 0.000001, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a))
    passed = passed + 1
end
local function loadAddon()
    OCS = nil
    dofile('tests/wow_mock.lua')
    for line in io.lines('OctoScanner.toc') do
        if string.find(line, '%.lua%s*$') then dofile('' .. string.gsub(line, '%s+$', '')) end
    end
    Mock.event('ADDON_LOADED', 'OctoScanner')
    Mock.event('PLAYER_LOGIN')
    OCS.ShowMain()
end
loadAddon()
eq(OCS_DB.window.scale, 100, 'existing profiles default to 100%')
eq(OCS_Window:GetScale(), 1, 'default size')
local buttons = OCS.UI.menuButtons()
local filters, rows, skins, scale = buttons[1], buttons[2], buttons[3], buttons[4]
eq(scale:GetText(), 'Scale', 'caption')
local point, alerts, rel, gap = scale:GetPoint()
eq(point, 'RIGHT'); eq(rel, 'LEFT'); eq(gap, -6)
eq(alerts:GetText(), 'Alerts: OFF', 'Scale sits left of Alerts')
eq(OCS.alertRowWidth, 252, 'upper row matches lower row width above Filters')
eq(OCS_Window.minWidth, 680, 'minimum width leaves room beside section buttons')
for i = 1, 11 do
    Mock.fire(scale, 'OnClick', 'LeftButton')
    eq(UIDROPDOWNMENU_OPEN_MENU, 'OCSScaleMenu', 'opens scale menu')
    eq(table.getn(Mock.menu), 11, 'eleven percentage choices')
    local selected = 100 - (i - 1) * 5
    for j = 1, 11 do
        local percent = 100 - (j - 1) * 5
        eq(Mock.menu[j].text, tostring(percent) .. '%', 'descending 5% steps')
        eq(Mock.menu[j].checked, OCS_DB.window.scale == percent, 'current selection')
    end
    Mock.menu[i].func()
    eq(OCS_DB.window.scale, selected, 'each callback saves its own value')
    near(OCS_Window:GetScale(), selected / 100, 'entire main frame scaled')
    eq(DropDownList1:IsShown(), false, 'selection closes dropdown')
    eq(OCS_ViewMenuCatcher:IsShown(), false, 'selection releases mouse catcher')
end
-- Fullscreen catchers must forward Scale clicks just like Rows and Skins.
Mock.fire(scale, 'OnClick', 'LeftButton')
Mock.over = scale
Mock.fire(OCS_ViewMenuCatcher, 'OnMouseDown', 'LeftButton')
eq(DropDownList1:IsShown(), false, 'same button toggles closed')
for _, button in ipairs({rows, skins}) do
    Mock.fire(button, 'OnClick', 'LeftButton')
    Mock.over = scale
    Mock.fire(OCS_ViewMenuCatcher, 'OnMouseDown', 'LeftButton')
    eq(UIDROPDOWNMENU_OPEN_MENU, 'OCSScaleMenu', 'other menu switches directly to Scale')
    Mock.over = button
    Mock.fire(OCS_ViewMenuCatcher, 'OnMouseDown', 'LeftButton')
    eq(OCS.UI.openMenuButton, button, 'Scale switches back to other menu')
    OCS.UI.closeViewMenu()
end
Mock.fire(filters, 'OnClick', 'LeftButton')
Mock.over = scale
Mock.fire(OCS_ClickCatcher, 'OnMouseDown', 'LeftButton')
eq(OCS_FilterPanel:IsShown(), false, 'Scale closes Filters')
eq(UIDROPDOWNMENU_OPEN_MENU, 'OCSScaleMenu', 'Filters switches to Scale')
OCS.HideMain()
eq(DropDownList1:IsShown(), false, 'hiding window closes Scale')
eq(OCS_ViewMenuCatcher:IsShown(), false, 'hiding releases catcher')
OCS.ShowMain()

-- Supply real frame-coordinate semantics for placement checks. GetLeft/Top
-- use the frame's units, while the cursor uses physical screen coordinates.
function OCS_Window:GetLeft()
    local p, _, _, x = self:GetPoint()
    if p == 'CENTER' then return UIParent:GetWidth() / self:GetScale() / 2 + x - self:GetWidth() / 2 end
    return x
end
function OCS_Window:GetBottom()
    local p, _, _, _, y = self:GetPoint()
    if p == 'TOPLEFT' then return y - self:GetHeight() end
    if p == 'CENTER' then return UIParent:GetHeight() / self:GetScale() / 2 + y - self:GetHeight() / 2 end
    return y
end
function OCS_Window:GetTop() return self:GetBottom() + self:GetHeight() end
UIParent:SetScale(0.8)
OCS.SetWindowScale(100)
OCS_Window:ClearAllPoints()
OCS_Window:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 300, 400)
local left = OCS_Window:GetLeft() * OCS_Window:GetEffectiveScale()
local top = OCS_Window:GetTop() * OCS_Window:GetEffectiveScale()
local logicalW, logicalH = OCS_Window:GetWidth(), OCS_Window:GetHeight()
OCS.SetWindowScale(50)
near(OCS_Window:GetLeft() * OCS_Window:GetEffectiveScale(), left, 'left stays in screen position')
near(OCS_Window:GetTop() * OCS_Window:GetEffectiveScale(), top, 'top stays in screen position')
eq(OCS_Window:GetWidth(), logicalW, 'scale preserves logical width')
eq(OCS_Window:GetHeight(), logicalH, 'scale preserves logical height')
near(OCS_Window:GetEffectiveScale(), 0.4, 'respects game UI scale')
eq(OCS_Window.maxWidth, 3840, 'resize bound accounts for scale')
eq(OCS_Window.maxHeight, 2160, 'height bound accounts for scale')
local w, h = OCS.UI.clampSize(9999, 9999)
eq(w, 3840); eq(h, 2160)
OCS.SetWindowScale(100)
near(OCS_Window:GetLeft() * OCS_Window:GetEffectiveScale(), left, 'roundtrip position')
near(OCS_Window:GetTop() * OCS_Window:GetEffectiveScale(), top, 'roundtrip top')

-- Grow a window placed near the screen edge: it must remain reachable.
OCS.SetWindowScale(50)
OCS_Window:SetWidth(3000); OCS_Window:SetHeight(1500)
OCS_Window:ClearAllPoints()
OCS_Window:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 840, 660)
OCS.SetWindowScale(100)
eq(OCS_Window:GetWidth(), 1920, 'oversized width clamps on enlargement')
eq(OCS_Window:GetHeight(), 1080, 'oversized height clamps on enlargement')
eq(OCS_DB.window.x, 0, 'left on screen'); eq(OCS_DB.window.y, 0, 'bottom on screen')
OCS.ResetWindow()
eq(OCS_DB.window.scale, 100, 'reset restores 100%')
eq(OCS_Window:GetScale(), 1, 'reset applies 100%')
eq(OCS_Window:GetWidth(), 780, 'reset width'); eq(OCS_Window:GetHeight(), 460, 'reset height')

-- Existing drag math must still convert physical cursor movement at 50%.
OCS.SetWindowScale(50)
local grip
for _, f in ipairs(Mock.frames) do
    if f.parent == OCS_Window and f.ocsArtwork == 'resize' then grip = f end
end
assert(grip, 'resize grip missing')
function IsMouseButtonDown() return Mock.down end
Mock.cursorX, Mock.cursorY, Mock.down = 500, 500, true
Mock.fire(grip, 'OnMouseDown', 'LeftButton')
Mock.cursorX, Mock.cursorY = 540, 460
Mock.fire(grip, 'OnUpdate', 0.1)
near(OCS_Window:GetWidth(), 880, '40 physical pixels add 100 logical pixels at effective scale .4')
near(OCS_Window:GetHeight(), 560, 'resize height at effective scale .4')
Mock.fire(grip, 'OnMouseUp', 'LeftButton')
near(OCS_DB.window.w, 880, 'scaled resize saved')
local savedX, savedY = OCS_DB.window.x, OCS_DB.window.y
loadAddon()
eq(OCS_DB.window.scale, 50, 'scale survives reload')
eq(OCS_Window:GetScale(), 0.5, 'saved scale applied before placement')
local _, _, _, x, y = OCS_Window:GetPoint()
near(x, savedX, 'reload placement x'); near(y, savedY, 'reload placement y')
eq(OCS_Window:GetWidth(), 880, 'reload size')
for _, case in ipairs({{'broken', 100}, {0, 50}, {500, 100}, {73, 75}, {'65', 65}}) do
    OCS_DB.window.scale = case[1]
    loadAddon()
    eq(OCS_DB.window.scale, case[2], 'saved value sanitized')
    near(OCS_Window:GetScale(), case[2] / 100, 'sanitized scale applied')
end
eq(OCS.stats.errors, 0, 'no UI errors')
eq(table.getn(Mock.sent), 0, 'scale sends no chat')

-- Vanilla can report an anchor-derived child size in root coordinates.
-- Replay the screenshot failure with enough data to fill every row slot.
OCS.SetSection('PVE')
OCS_DB.rows.PVE_LFM = {}
for i = 1, 95 do
    Mock.now = Mock.now + 1
    Mock.event('CHAT_MSG_CHANNEL', 'LF1M BRD need healer', 'Viewport' .. i, nil, '1. World', nil, nil, nil, 1, 'World')
end
OCS.Refresh()
local area
local function mainRows()
    local found = {}
    for _, f in ipairs(Mock.frames) do
        if f.kind == 'Button' and f.cells and f.cells.wsp and f.parent.parent == OCS_Window then
            table.insert(found, f)
            area = f.parent
        end
    end
    return found
end
mainRows()
assert(area, 'main table area missing')
function area:GetHeight()
    if self.height then return self.height end
    return (OCS_Window:GetHeight() - 168) * self:GetEffectiveScale()
end
UIParent:SetHeight(1800)
for _, gameScale in ipairs({0.64, 0.8, 1}) do
    UIParent:SetScale(gameScale)
    for percent = 50, 100, 5 do
        for _, height in ipairs({260, 460, 720, 1400}) do
            OCS_Window:SetHeight(height)
            OCS.SetWindowScale(percent)
            Mock.fire(OCS_Window, 'OnSizeChanged')
            OCS.Refresh()
            local room = height - 122 - 36
            local capacity = math.floor(room / 18)
            eq(OCS.UI.fitRows(), capacity, 'row capacity fills full logical viewport')
            near(area.height, room, 'table uses explicit logical height')
            local visible = 0
            for _, row in ipairs(mainRows()) do
                if row:IsShown() and row.data then
                    visible = visible + 1
                    local _, _, _, _, ry = row:GetPoint()
                    eq(-ry + row:GetHeight() <= room + 0.000001, true, 'whole row stays above footer')
                end
            end
            eq(visible, capacity, 'every available slot paints a message')
            local _, maximum = OCS_ScrollBar:GetMinMaxValues()
            eq(maximum, 95 - capacity, 'scroll range matches visible slots')
        end
    end
end
eq(OCS.UI.fitRows() > 40, true, 'tall windows grow beyond former 40-row limit')
local poolSize = table.getn(mainRows())
OCS_ScrollBar:SetValue(95)
local oldestVisible = false
for _, row in ipairs(mainRows()) do
    if row:IsShown() and row.data and row.data.name == 'Viewport1' then oldestVisible = true end
end
eq(oldestVisible, true, 'scroll reaches the last message')
OCS_Window:SetHeight(260); Mock.fire(OCS_Window, 'OnSizeChanged')
local _, maximum = OCS_ScrollBar:GetMinMaxValues()
eq(OCS_ScrollBar:GetValue(), 26, 'shrinking retains the first visible message')
OCS_ScrollBar:SetValue(maximum)
OCS_Window:SetHeight(1400); Mock.fire(OCS_Window, 'OnSizeChanged')
local _, maximum = OCS_ScrollBar:GetMinMaxValues()
eq(OCS_ScrollBar:GetValue(), maximum, 'growing while scrolled to bottom clamps offset')
eq(table.getn(mainRows()), poolSize, 'row frames are reused after shrinking and growing')
for _, boundary in ipairs({{265.99, 5}, {266, 6}, {266.01, 6}}) do
    OCS_Window:SetHeight(boundary[1])
    eq(OCS.UI.fitRows(), boundary[2], 'only complete rows fit at fractional height boundaries')
end
eq(OCS.stats.errors, 0, 'no viewport regression errors')
print('PASS ' .. passed .. ' assertions; scale menu, placement, resize, reset and reload')
