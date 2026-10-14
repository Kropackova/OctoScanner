-- Private Lua 5.0/UI adapters. No stock globals are replaced.
OCS = OCS or {}
function OCS.Len(value)
    if type(value) == "string" then return string.len(value) end
    return table.getn(value)
end
function OCS.Match(text, pattern, start)
    local result = { string.find(text, pattern, start) }
    if not result[1] then return nil end
    if table.getn(result) == 2 then return string.sub(text, result[1], result[2]) end
    table.remove(result, 1)
    table.remove(result, 1)
    return unpack(result)
end
function OCS.SetScript(frame, script, handler)
    frame.ocsScripts = frame.ocsScripts or {}
    frame.ocsScripts[script] = handler
    if not handler then frame:SetScript(script, nil) return end
    frame:SetScript(script, function()
        if script == "OnEvent" then
            return handler(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        end
        return handler(this, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end)
end
function OCS.GetScript(frame, script)
    return frame.ocsScripts and frame.ocsScripts[script]
end
function OCS.HookScript(frame, script, handler)
    local previous = OCS.GetScript(frame, script)
    OCS.SetScript(frame, script, function(self, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        if previous then previous(self, a1, a2, a3, a4, a5, a6, a7, a8, a9) end
        return handler(self, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    end)
end
function OCS.IsMouseOver(frame) return MouseIsOver(frame) end
function OCS.InitializeMenu(frame, initialize, mode)
    OCS.RegisterMenu(frame)
    UIDropDownMenu_Initialize(frame, function(level)
        OCS.ScaleActiveMenu(level or UIDROPDOWNMENU_MENU_LEVEL or 1)
        initialize(frame, level or UIDROPDOWNMENU_MENU_LEVEL or 1, UIDROPDOWNMENU_MENU_VALUE)
    end, mode)
end
-- Original Blizzard artwork bundled as 32-bit uncompressed TGA. The paths
-- used by the Ascension release are absent in the Vanilla client archives.
function OCS.SetControlArtwork(button, kind)
    local root = "Interface\\AddOns\\OctoScanner\\Textures\\"
    local art = kind == "resize" and "UI-ChatIM-SizeGrabber"
        or (kind == "up" and "UI-Panel-BiggerButton" or "UI-Panel-SmallerButton")
    button:SetNormalTexture(root .. art .. "-Up.tga")
    button:SetPushedTexture(root .. art .. "-Down.tga")
    if kind == "resize" then
        button:SetHighlightTexture(root .. art .. "-Highlight.tga")
    else
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    end
    if kind == "out" then
        button:GetNormalTexture():SetTexCoord(1, 0, 1, 0)
        button:GetPushedTexture():SetTexCoord(1, 0, 1, 0)
    end
    button.ocsArtwork = kind
end
function OCS.GroupState()
    local raid, party = GetNumRaidMembers() or 0, GetNumPartyMembers() or 0
    local inRaid, inParty = raid > 0, party > 0
    local rank = false
    if inRaid then rank = (IsRaidLeader() or IsRaidOfficer()) and true or false
    elseif inParty then rank = IsPartyLeader() and true or false end
    return { raidMembers = raid, partyMembers = party, inRaid = inRaid,
        inParty = inParty, inGroup = inRaid or inParty, rank = rank,
        canInvite = not (inRaid or inParty) or rank }
end
function OCS.CanInvite() return OCS.GroupState().canInvite end
function OCS.Probe()
    local version, build, date = GetBuildInfo()
    OCS.Print("Addon " .. OCS.VERSION .. ", client " .. tostring(version)
        .. " build " .. tostring(build) .. " (" .. tostring(date) .. ")")
    OCS.Print("Lua " .. tostring(_VERSION) .. ", Interface 11200; native chat events")
    local s = OCS.stats or {}
    OCS.Print("Chat " .. tostring(s.events or 0) .. ", stored " .. tostring(s.stored or 0)
        .. ", addon traffic " .. tostring(s.comm or 0) .. ", errors " .. tostring(s.errors or 0))
    OCS.Print("Pack " .. OCS.ActivePack().name .. ", realm " .. tostring(OCS.realmName)
        .. "; may invite: " .. tostring(OCS.CanInvite()))
end
