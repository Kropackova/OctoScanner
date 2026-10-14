-- Strict, explicit subset of the Vanilla API used by this addon.
Mock = { frames = {}, messages = {}, sent = {}, now = 1000, clock = 0, raid = 0, party = 0 }
DropDownList1,DropDownList2,DropDownList3,UIDROPDOWNMENU_OPEN_MENU=nil,nil,nil,nil
function Mock.fire(frame, script, a1,a2,a3,a4,a5,a6,a7,a8,a9)
    local previous = { this=this, event=event, a1=arg1,a2=arg2,a3=arg3,a4=arg4,a5=arg5,a6=arg6,a7=arg7,a8=arg8,a9=arg9 }
    this=frame
    arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9=a1,a2,a3,a4,a5,a6,a7,a8,a9
    local handler=frame.scripts and frame.scripts[script]
    local ok,err=true,nil
    if handler then ok,err=pcall(handler) end
    this,event=previous.this,previous.event
    arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9=previous.a1,previous.a2,previous.a3,previous.a4,previous.a5,previous.a6,previous.a7,previous.a8,previous.a9
    if not ok then error(tostring(frame.name).." "..script..": "..tostring(err)) end
end
function Mock.event(name,a1,a2,a3,a4,a5,a6,a7,a8,a9)
    for i=1,table.getn(Mock.frames) do
        local f=Mock.frames[i]
        if f.events[name] then event=name; Mock.fire(f,"OnEvent",a1,a2,a3,a4,a5,a6,a7,a8,a9) end
    end
    event=nil
end
local methods={}
local function noop() end
local names={"SetFrameStrata","SetFrameLevel","SetAlpha","SetMovable","SetResizable","SetMinResize","SetMaxResize","SetClampedToScreen","SetToplevel","EnableMouse","EnableMouseWheel","RegisterForClicks","RegisterForDrag","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetBlendMode","SetTexCoord","SetDesaturated","SetTextColor","SetJustifyH","SetJustifyV","SetNonSpaceWrap","SetAutoFocus","SetNumeric","SetMaxLetters","SetTextInsets","HighlightText","StartMoving","StartSizing","StopMovingOrSizing","SetVerticalScroll","SetOwner","ClearLines","AddLine","SetTextFontObject","SetHighlightFontObject","SetDisabledFontObject","SetValueStep"}
for i=1,table.getn(names) do methods[names[i]]=noop end
function methods:SetScript(script,fn) self.scripts[script]=fn end
function methods:GetScript(script) return self.scripts[script] end
function methods:RegisterEvent(name) self.events[name]=true end
function methods:UnregisterEvent(name) self.events[name]=nil end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.allPoints and self.allPoints:GetWidth() or self.width or 100 end
function methods:GetHeight() return self.allPoints and self.allPoints:GetHeight() or self.height or 18 end
function methods:GetName() return self.name end
function methods:GetObjectType() return self.kind end
function methods:GetFrameLevel() return 1 end
function methods:GetScale() return self.scale or 1 end
function methods:SetScale(v) self.scale=v end
function methods:GetEffectiveScale() return self:GetScale() * (self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetMinResize(w,h) self.minWidth,self.minHeight=w,h end
function methods:SetMaxResize(w,h) self.maxWidth,self.maxHeight=w,h end
function methods:GetLeft() return self.left or 50 end
function methods:GetTop() return self.top or 500 end
function methods:GetBottom() return self:GetTop()-self:GetHeight() end
function methods:GetCenter() return 500,400 end
function methods:SetPoint(a,b,c,d,e)
    if type(b)=="number" then self.point={a,self.parent,a,b,c}
    else self.point={a,b or self.parent,c or a,d or 0,e or 0} end
end
function methods:GetPoint() return unpack(self.point or {"CENTER",UIParent,"CENTER",0,0}) end
function methods:GetNumPoints() return self.point and 1 or 0 end
function methods:ClearAllPoints() self.point=nil end
function methods:SetAllPoints(parent) self.allPoints=parent or self.parent end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:Show() local changed=not self.shown; self.shown=true;if changed then Mock.fire(self,"OnShow") end end
function methods:Hide() local changed=self.shown; self.shown=false;if changed then Mock.fire(self,"OnHide") end end
function methods:SetChecked(value) self.checked=value and 1 or nil end
function methods:GetChecked() return self.checked end
function methods:SetText(text) self.text=tostring(text or "");Mock.fire(self,"OnTextChanged") end
function methods:GetText() return self.text or "" end
function methods:EnableMouse(value) self.mouseEnabled=value end
function methods:RegisterForDrag(button) self.dragButton=button end
function methods:SetOwner(owner,anchor) self.owner=owner;self.anchor=anchor;self.lines={} end
function methods:ClearLines() self.lines={} end
function methods:AddLine(text,r,g,b,wrap)
    self.lines=self.lines or {}
    table.insert(self.lines,{text=text,r=r,g=g,b=b,wrap=wrap})
end
function methods:SetFont(name,size,flags) self.font=name;self.fontSize=size;self.fontFlags=flags end
function methods:SetTextHeight(size) self.textHeight=size end
function methods:SetShadowOffset(x,y) self.shadowX=x;self.shadowY=y end
function methods:SetShadowColor(r,g,b,a) self.shadowColor={r,g,b,a} end
function methods:SetVertexColor(r,g,b,a) self.vertexColor={r,g,b,a or 1} end
function methods:SetFontObject(value) self.fontObject=value end
function methods:GetFont() return self.font or "Fonts\\FRIZQT__.TTF",self.fontSize or 12,self.fontFlags or "" end
function methods:GetStringWidth() return string.len(self:GetText())*6*(self.textHeight or self.fontSize or 12)/12 end
function methods:GetStringHeight() return self.textHeight or self.fontSize or 12 end
function methods:GetFontString() if not self.fs then self.fs=self:CreateFontString() end return self.fs end
function methods:SetTexture(a,b,c,d) self.texture={a,b,c,d} end
function methods:SetTexCoord(a,b,c,d) self.texCoord={a,b,c,d} end
function methods:SetNormalTexture(v) self.normal=self:CreateTexture();self.normal:SetTexture(v) end
function methods:SetPushedTexture(v) self.pushed=self:CreateTexture();self.pushed:SetTexture(v) end
function methods:SetHighlightTexture(v) self.highlight=self:CreateTexture();self.highlight:SetTexture(v) end
function methods:GetNormalTexture() return self.normal end
function methods:GetPushedTexture() return self.pushed end
function methods:GetHighlightTexture() return self.highlight end
function methods:LockHighlight() self.lockedHighlight=true end
function methods:UnlockHighlight() self.lockedHighlight=false end
function methods:SetFocus() if not self.focus then self.focus=true;Mock.fire(self,"OnEditFocusGained") end end
function methods:ClearFocus() if self.focus then self.focus=nil;Mock.fire(self,"OnEditFocusLost") end end
function methods:SetMinMaxValues(low,high) self.low,self.high=low,high end
function methods:GetMinMaxValues() return self.low or 0,self.high or 1 end
function methods:SetValue(value) local changed=self.value~=value;self.value=value;if changed then Mock.fire(self,"OnValueChanged",value) end end
function methods:GetValue() return self.value or 0 end
function methods:NumLines() return 0 end
function CreateFrame(kind,name,parent,template)
    local f={kind=kind,name=name,parent=parent,template=template,scripts={},events={},shown=true}
    setmetatable(f,{__index=methods})
    Mock.frames[table.getn(Mock.frames)+1]=f
    if name then _G[name]=f end
    return f
end
function methods:CreateTexture(name) return CreateFrame("Texture",name,self) end
function methods:CreateFontString(name,layer,template)
    local f=CreateFrame("FontString",name,self,template)
    if template == "GameFontNormalLarge" then
        f.fontSize=16;f.shadowX=1;f.shadowY=-1
        -- Optional regression mode: template glyphs stay at their initial
        -- screen size, reproducing the template font cache regression.
        if Mock.freezeTitleTemplate then f.frozenGlyphHeight=16*UIParent:GetEffectiveScale() end
    end
    return f
end
function Mock.glyphHeight(fs)
    return fs.frozenGlyphHeight or (fs.textHeight or fs.fontSize or 12)*fs.parent:GetEffectiveScale()
end
UIParent=CreateFrame("Frame","UIParent");UIParent:SetWidth(1920);UIParent:SetHeight(1080)
Minimap=CreateFrame("Frame","Minimap",UIParent)
GameTooltip=CreateFrame("GameTooltip","GameTooltip",UIParent)
DEFAULT_CHAT_FRAME={AddMessage=function(self,text) Mock.messages[table.getn(Mock.messages)+1]=text end}
SlashCmdList,UISpecialFrames,StaticPopupDialogs={},{},{}
GameFontNormal,GameFontNormalSmall,GameFontHighlight,GameFontHighlightSmall="normal","normal-small","highlight","highlight-small"
GameFontDisableSmall,ChatFontNormal,STANDARD_TEXT_FONT="disabled","chat","Fonts\\FRIZQT__.TTF"
YES,NO,ACCEPT,CANCEL="Yes","No","Accept","Cancel"
function UnitName() return "Tester" end
function UnitLevel() return 60 end
function UnitClass() return "Warrior","WARRIOR" end
function UnitExists() return nil end
function GetRealmName() return "N'Zoth" end
function GetBuildInfo() return "1.18.1","7272","Mar 20 2026" end
function GetNumRaidMembers() return Mock.raid end
function GetNumPartyMembers() return Mock.party end
function IsRaidLeader() return Mock.leader end
function IsRaidOfficer() return Mock.officer end
function IsPartyLeader() return Mock.leader end
function GetCursorPosition() return Mock.cursorX or 0,Mock.cursorY or 0 end
function GetTime() return Mock.clock end
function EnumerateFrames(previous)
    if not previous then return Mock.frames[1] end
    for i=1,table.getn(Mock.frames) do if Mock.frames[i]==previous then return Mock.frames[i+1] end end
end
function UnitIsDeadOrGhost() return Mock.dead end
function UnitOnTaxi() return Mock.taxi end
function UnitAffectingCombat() return Mock.combat end
function UnitIsConnected() return not Mock.disconnected end
function GetBindingAction(key) return Mock.binding or (key=='W' and 'MOVEFORWARD' or '') end
function LoggingChat(value)
    if Mock.chatLogFailure then error('chat log write failed') end
    if value~=nil then Mock.chatLogging=value end
    return Mock.chatLogging
end
function time() return Mock.now end
function date(format,value) return os.date(format,value) end
function MouseIsOver(frame) return Mock.over==frame end
function IsShiftKeyDown() return nil end
function IsControlKeyDown() return nil end
function PlaySound(name) Mock.sound=name end
function SendChatMessage(text,kind,language,target) Mock.sent[table.getn(Mock.sent)+1]={text=text,kind=kind,target=target} end
function InviteByName(name) Mock.invited=name end
function InviteUnit(name) error("Wrath InviteUnit must not be used; Vanilla has InviteByName") end
function TargetByName(name,exact) Mock.targeted=name end
function AddFriend(name) Mock.friend=name end
function AddIgnore(name) Mock.ignore=name end
function ChatFrame_OpenChat(text) Mock.chat=text end
function ChatFrame_SendTell(name) Mock.chat="/w "..name end
function StaticPopup_Show(name)
    Mock.popup = name
    local dialog = Mock.popupFrame
    if not dialog then
        dialog = CreateFrame('Frame', 'StaticPopup1', UIParent)
        dialog:Hide()
        dialog:SetScript('OnShow', function()
            local handler = StaticPopupDialogs[this.which].OnShow
            if handler then handler(this.data) end
        end)
        dialog:SetScript('OnHide', function()
            local handler = StaticPopupDialogs[this.which].OnHide
            if handler then handler(this.data) end
        end)
        Mock.popupFrame = dialog
    end
    if dialog:IsShown() then dialog:Hide() end
    dialog.which = name
    dialog:Show()
    return dialog
end
UIDROPDOWNMENU_MENU_LEVEL=1
function UIDropDownMenu_Initialize(frame,initialize,mode) frame.initialize=initialize;frame.displayMode=mode;initialize(1) end
function UIDropDownMenu_AddButton(info,level) Mock.menu=Mock.menu or {};Mock.menu[table.getn(Mock.menu)+1]=info end
function ToggleDropDownMenu(level,value,frame,anchor,x,y)
    UIDROPDOWNMENU_MENU_LEVEL,UIDROPDOWNMENU_MENU_VALUE=level or 1,value
    local name='DropDownList'..(level or 1)
    local list=_G[name]
    if not list then list=CreateFrame('Frame',name,UIParent);list:Hide() end
    if list:IsShown() and UIDROPDOWNMENU_OPEN_MENU==frame:GetName() then list:Hide();return end
    if (level or 1)==1 then UIDROPDOWNMENU_OPEN_MENU=frame:GetName() end
    Mock.menu={};frame.initialize(level or 1)
    list:Show()
end
function CloseDropDownMenus()
    for i=1,3 do local list=_G['DropDownList'..i];if list then list:Hide() end end
end
