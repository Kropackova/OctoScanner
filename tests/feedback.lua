local passed=0
local function eq(a,b,label)
    assert(a==b,(label or 'value')..': expected '..tostring(b)..', got '..tostring(a))
    passed=passed+1
end
dofile('tests/wow_mock.lua')
for line in io.lines('OctoScanner.toc') do
    if string.find(line,'%.lua%s*$') then dofile(''..string.gsub(line,'%s+$','')) end
end
Mock.event('ADDON_LOADED','OctoScanner');Mock.event('PLAYER_LOGIN');OCS.Show()
local buttons=OCS.UI.menuButtons()
local filters,rows,skins=buttons[1],buttons[2],buttons[3]
CloseDropDownMenus()
-- Reproduce the actual click recipient: the fullscreen catcher, not the button.
for _,button in ipairs({rows,skins}) do
    Mock.fire(button,'OnClick','LeftButton')
    eq(DropDownList1:IsShown(),true,'menu opens')
    Mock.over=button
    Mock.fire(OCS_ViewMenuCatcher,'OnMouseDown','LeftButton')
    eq(DropDownList1:IsShown(),false,'same button closes through catcher')
    eq(OCS_ViewMenuCatcher:IsShown(),false,'catcher releases mouse')
    Mock.fire(button,'OnClick','LeftButton');Mock.fire(button,'OnClick','LeftButton')
    eq(DropDownList1:IsShown(),false,'direct second click also closes')
end
Mock.fire(rows,'OnClick','LeftButton');Mock.over=skins
Mock.fire(OCS_ViewMenuCatcher,'OnMouseDown','LeftButton')
eq(UIDROPDOWNMENU_OPEN_MENU,'OCSSkinsMenu','Rows switches to Skins')
eq(DropDownList1:IsShown(),true)
Mock.over=filters;Mock.fire(OCS_ViewMenuCatcher,'OnMouseDown','LeftButton')
eq(OCS_FilterPanel:IsShown(),true,'Skins switches to Filters')
eq(DropDownList1:IsShown(),false)
Mock.over=rows;Mock.fire(OCS_ClickCatcher,'OnMouseDown','LeftButton')
eq(UIDROPDOWNMENU_OPEN_MENU,'OCSRowsMenu','Filters switches to Rows')
eq(OCS_FilterPanel:IsShown(),false)
Mock.over=nil;Mock.fire(OCS_ViewMenuCatcher,'OnMouseDown','LeftButton')
eq(DropDownList1:IsShown(),false,'outside click closes')
Mock.fire(rows,'OnClick','LeftButton');OCS.HideMain()
eq(OCS_ViewMenuCatcher:IsShown(),false,'hiding window releases catcher')
eq(DropDownList1:IsShown(),false,'hiding window closes menu')
OCS.Show()
OCS.MiniShow()
local artwork={}
for i=1,table.getn(Mock.frames) do
    local f=Mock.frames[i]
    if f.ocsArtwork then
        artwork[f.ocsArtwork]=(artwork[f.ocsArtwork] or 0)+1
        local stem=f.ocsArtwork=='resize' and 'UI-ChatIM-SizeGrabber'
            or (f.ocsArtwork=='up' and 'UI-Panel-BiggerButton' or 'UI-Panel-SmallerButton')
        local root='Interface\\AddOns\\OctoScanner\\Textures\\'
        eq(f:GetNormalTexture().texture[1],root..stem..'-Up.tga','bundled original normal state')
        eq(f:GetPushedTexture().texture[1],root..stem..'-Down.tga','bundled original pressed state')
        if f.ocsArtwork=='resize' then
            eq(f:GetHighlightTexture().texture[1],root..stem..'-Highlight.tga','original resize highlight')
        elseif f.ocsArtwork=='out' then
            eq(table.concat(f:GetNormalTexture().texCoord,','),'1,0,1,0','original popout orientation')
            eq(table.concat(f:GetPushedTexture().texCoord,','),'1,0,1,0','pressed popout orientation')
        end
    end
end
eq(artwork.down,1,'main minimise artwork');eq(artwork.out,1,'main popout artwork')
eq(artwork.up,1,'mini full-window artwork');eq(artwork.resize,2,'both resize handles')
for _,text in ipairs({'LFM BM farm need 2 dps 1 heal','LF1M BM rep farm Healer','LF1M DPS BM'}) do
    local row=OCS.Parse(text)
    eq(row.target,'Caverns of Time: Black Morass',text);eq(row.kind,'DGN')
end
local heal=OCS.Parse('LF1M BM rep farm Healer')
eq(heal.roleSet.heal,true);eq(heal.roleSet.damage,nil,'instance BM is not a Damage request')
eq(OCS.Parse('LFM BM hunter').target,nil,'Hunter recruitment stays ambiguous')
eq(OCS.Parse('60 BM hunter LFG').target,nil,'BM Hunter spec stays a spec')
eq(OCS.Parse('LFM BRD BM hunter').target,'Blackrock Depths','explicit instance wins')
eq(OCS.Parse('i hope the world boss kills you all c:< !'),nil,'screenshot chatter')
local raw='WTS|cff00ff00|Hitem:1:0:0:0|h[Golden Scale Boots]|h|r1.75g'
eq(OCS.DisplayText(raw),'WTS Golden Scale Boots 1.75g','linked item boundaries stay readable')
eq(OCS.Parse(raw).kind,'GEAR')
OCS.SelectPack('vanilla')
eq(OCS.Parse('LF1M BM rep farm Healer').target,nil,'no Black Morass in Vanilla')
print('PASS '..passed..' assertions; screenshot regressions, menu clicks and original control artwork')
