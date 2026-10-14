-- UI roots that live outside the main window need their own scale.
OCS = OCS or {}
local roots, menus = {}, {}
local tooltip

function OCS.ScalePercent(value)
    value = tonumber(value) or 100
    if value ~= value then value = 100 end
    return math.floor(math.max(50, math.min(100, value)) / 5 + 0.5) * 5
end

function OCS.UIScale()
    return OCS.ScalePercent(OCS_DB and OCS_DB.window and OCS_DB.window.scale) / 100
end

-- Register independent roots only; their children inherit once.
function OCS.RegisterScaleFrame(frame, savePlacement)
    roots[frame] = { savePlacement = savePlacement }
    frame:SetScale(OCS.UIScale())
end

-- Shared Blizzard popup frames belong to us only while our dialog is shown.
function OCS.UnregisterScaleFrame(frame)
	roots[frame] = nil
end

function OCS.RefreshUIScale()
    local scale = OCS.UIScale()
    for frame, settings in pairs(roots) do
        local oldScale = frame:GetScale()
        local point, parent, relative, x, y = frame:GetPoint(1)
        local cx, cy
        if settings.savePlacement then cx, cy = frame:GetCenter() end
        frame:SetScale(scale)
        if settings.savePlacement and point and parent == UIParent then
            x, y = (x or 0) * oldScale / scale, (y or 0) * oldScale / scale
            frame:ClearAllPoints()
            frame:SetPoint(point, parent, relative, x, y)
            settings.savePlacement(point, relative, x, y, cx and cx * oldScale / scale, cy and cy * oldScale / scale)
        end
    end
    if tooltip then tooltip:Hide() end
end

-- A private tooltip leaves the game's tooltip and other addons untouched.
function OCS.GetTooltip()
    if not tooltip then
        tooltip = CreateFrame("GameTooltip", "OctoScannerTooltip", UIParent, "GameTooltipTemplate")
        OCS.RegisterScaleFrame(tooltip)
        tooltip:Hide()
    end
    tooltip:SetScale(OCS.UIScale())
    return tooltip
end

local function ownMenu()
    local active = UIDROPDOWNMENU_OPEN_MENU
    if active and type(active) ~= "string" and active.GetName then active = active:GetName() end
    return active and menus[active]
end

local function restoreList(list)
    if list.ocsOriginalScale then
        list:SetScale(list.ocsOriginalScale)
        list.ocsOriginalScale = nil
    end
end

-- Vanilla shares DropDownList frames. Borrow their scale only while one of
-- our menus owns them, retaining the native handlers and restoring on hide.
function OCS.ScaleMenuLevel(level)
    local list = _G["DropDownList" .. tostring(level or 1)]
    if not list then return end
    if not list.ocsScaleHooks then
        list.ocsScaleHooks = true
        local onHide, onShow, onUpdate = list:GetScript("OnHide"), list:GetScript("OnShow"), list:GetScript("OnUpdate")
        list:SetScript("OnHide", function()
            local current = this
            if onHide then onHide() end
            restoreList(current)
        end)
        list:SetScript("OnShow", function()
            local current = this
            if onShow then onShow() end
            if ownMenu() then
                current.ocsOriginalScale = current.ocsOriginalScale or current:GetScale()
                current:SetScale(OCS.UIScale())
            else
                restoreList(current)
            end
        end)
        list:SetScript("OnUpdate", function()
            local current = this
            if onUpdate then onUpdate() end
            if current.ocsOriginalScale and not ownMenu() then restoreList(current) end
        end)
    end
    list.ocsOriginalScale = list.ocsOriginalScale or list:GetScale()
    list:SetScale(OCS.UIScale())
end

function OCS.RegisterMenu(frame)
    menus[frame:GetName()] = true
end

function OCS.ScaleActiveMenu(level)
    if ownMenu() then OCS.ScaleMenuLevel(level) end
end

function OCS.ToggleMenu(level, value, menu, anchor, x, y)
    -- Existing list frames must be scaled before native placement runs.
    OCS.ScaleMenuLevel(level)
    ToggleDropDownMenu(level, value, menu, anchor, x, y)
    local list = _G["DropDownList" .. tostring(level or 1)]
    if ownMenu() and list and list:IsShown() then OCS.ScaleMenuLevel(level) end
end
