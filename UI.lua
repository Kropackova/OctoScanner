OCS.UI = OCS.UI or {}
-- OctoScanner
-- UI.lua - window, table, editing, player menu, filters, whisper, minimap button.

OCS = OCS or {}

OCS.UI.ROW_H = 18
OCS.UI.PAD = 14
OCS.UI.SCROLL_W = 20
OCS.UI.EDGE_MARGIN = 16

-- Scroll bar placement. Fine tune here.
-- SCROLL_TOP: pixels from the top of the window to the top of the bar.
--   Raise the number to push the bar further down, below the alert box.
-- SCROLL_BOTTOM: pixels from the bottom of the window to the bottom of
--   the bar. Raise it to keep more space above the resize grip.
-- TITLE_INDENT: how many edge margins the title and the sub line sit in
--   from the left. 1 lines them up with the table, 2 is the current look.
-- Right hand button groups, stacked. VIEW_TOP is the top of the Skins,
-- Rows and Filters row, ALERT_TOP the top of the Scope, bell and Alerts
-- row below it. HEADER_TOP has to clear the lower box.
OCS.UI.BOX_PAD = 7
OCS.UI.BOX_GAP = 6
-- ALERT_TOP matches the section row, VIEW_TOP matches the tab row, so the
-- right hand groups sit on the same two lines as PvE and LFM.
OCS.UI.ALERT_TOP = 46
OCS.UI.VIEW_TOP = 72
OCS.UI.ROW_TOP = 46
OCS.UI.ROW_BOTTOM = 72
-- How the two right hand rows are framed.
--   "none"  no frame at all. The rows line up with the rows on the left
--           and the table header keeps its own height.
--   "one"   one frame around both rows, with a thin line between them.
--           Costs 13 px of height, so the header moves down.
-- Two separate frames cannot line up with the left: the rows are 26 px
-- apart and two frames need 20 px of padding between them.
OCS.UI.GROUP_FRAME = "none"
OCS.UI.HEADER_TOP = (OCS.UI.GROUP_FRAME == "none") and 100
	or (OCS.UI.ROW_BOTTOM + 22 + OCS.UI.BOX_PAD + 6)
OCS.UI.SCROLL_TOP = OCS.UI.HEADER_TOP + 28
OCS.UI.SCROLL_BOTTOM = 40
OCS.UI.TITLE_INDENT = 1.33
OCS.UI.TITLE_W, OCS.UI.TITLE_H = 118.2, 15
OCS.UI.TITLE_TOP = 20

-- Distance from the top of the window to the top of the table area, and from
-- the bottom of the window to the bottom of the table area. These mirror the
-- anchors used when the frames are built: the header bar sits HEADER_TOP down and is
-- 18 px tall, and the table starts 4 px under it. The footer buttons start
-- EDGE_MARGIN - 4 above the bottom and are 20 high; leave a 4-unit gap above.
-- Explicit dimensions avoid Vanilla's root-coordinate measurements for frames
-- whose size comes only from anchors, as well as delayed anchor layout.
OCS.UI.TABLE_TOP = OCS.UI.HEADER_TOP + 18 + 4
OCS.UI.TABLE_BOTTOM = OCS.UI.EDGE_MARGIN + 20

-- Every column the addon can draw. The active pack picks which of the middle
-- ones appear, see Packs.lua. Time, Name, Role, Lvl, W and Message are fixed.
OCS.UI.ALL_COLS = {
	time    = { key = "time",    label = "Time",     w = 62 },
	name    = { key = "name",    label = "Name",     w = 104 },
	role    = { key = "role",    label = "Role",     w = 104, edit = true },
	class   = { key = "class",   label = "Class",    w = 84 },
	act     = { key = "act",     label = "Activity", w = 132 },
	prog    = { key = "prog",    label = "Filled",   w = 52, edit = true },
	level   = { key = "level",   label = "Lvl",      w = 40,  edit = true },
	wsp     = { key = "wsp",     label = "W",        w = 26,  whisper = true },
	message = { key = "message", label = "Message",  w = 260, flex = true },
}

-- Filled in by buildCols. Kept as one table the whole file shares, because
-- layout, headers, cells and hit testing all read it.
OCS.UI.COLS = {}

function OCS.UI.buildCols()
	-- Every section draws from one superset. Which of these are visible is
	-- decided per section inside layout(), so a section change needs no
	-- reload.
	local order = { "time", "name", "role", "class", "act", "prog", "level", "wsp", "message" }

	for i = OCS.Len(OCS.UI.COLS), 1, -1 do
		table.remove(OCS.UI.COLS, i)
	end
	for i = 1, OCS.Len(order) do
		local def = OCS.UI.ALL_COLS[order[i]]
		if def then
			table.insert(OCS.UI.COLS, {
				key = def.key,
				label = def.label,
				w = def.w,
				edit = def.edit,
				whisper = def.whisper,
				flex = def.flex,
			})
		end
	end
end

OCS.UI.buildCols()

OCS.UI.SKINS = {
	vanilla = {
		backdrop = {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		},
		titleColor = { 1, 0.82, 0 },
		headerColor = { 1, 0.82, 0 },
		altAlpha = 0.10,
		lines = false,
	},
	dark = {
		backdrop = {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		},
		bgColor = { 0.06, 0.07, 0.09, 0.94 },
		borderColor = { 0.35, 0.38, 0.45, 1 },
		titleColor = { 1, 1, 1 },
		headerColor = { 0.75, 0.82, 0.95 },
		altAlpha = 0.06,
		lines = false,
	},
	grid = {
		backdrop = {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		},
		bgColor = { 0.04, 0.05, 0.07, 0.96 },
		borderColor = { 0.45, 0.40, 0.30, 1 },
		titleColor = { 1, 0.9, 0.6 },
		headerColor = { 1, 0.86, 0.5 },
		altAlpha = 0.16,
		lines = true,
	},
	slate = {
		backdrop = {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		},
		bgColor = { 0.10, 0.13, 0.18, 0.92 },
		borderColor = { 0.30, 0.45, 0.62, 1 },
		titleColor = { 0.66, 0.86, 1 },
		headerColor = { 0.56, 0.76, 0.96 },
		altAlpha = 0.12,
		lines = true,
	},
	-- Almost no window at all. For a crowded screen where the addon should
	-- read as a list floating over the world.
	glass = {
		backdrop = {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		},
		bgColor = { 0, 0, 0, 0.35 },
		borderColor = { 0.75, 0.78, 0.82, 0.55 },
		titleColor = { 1, 1, 1 },
		headerColor = { 0.88, 0.90, 0.94 },
		altAlpha = 0.04,
		lines = false,
	},
	-- Loud green on near black, hard ruled. Easy to spot in a corner.
	felfire = {
		backdrop = {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		},
		bgColor = { 0.02, 0.06, 0.03, 0.96 },
		borderColor = { 0.35, 0.95, 0.40, 1 },
		titleColor = { 0.62, 1, 0.52 },
		headerColor = { 0.50, 0.94, 0.45 },
		altAlpha = 0.18,
		lines = true,
	},
	parchment = {
		backdrop = {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		},
		bgColor = { 0.17, 0.14, 0.10, 0.95 },
		borderColor = { 0.62, 0.52, 0.34, 1 },
		titleColor = { 1, 0.93, 0.76 },
		headerColor = { 0.96, 0.86, 0.62 },
		altAlpha = 0.14,
		lines = false,
	},
}

local frame, headerBar, tableArea, scrollBar, countText, titleText
local titleHolder, titleShadow, titleCaption, titleHelp
local filtersButton, alertsButton, clearButton, whisperButton, resizeGrip
local rowsButton, scopeButton, clearAllButton, rowsMenu
local soundButton
local skinsButton, skinsMenu
local scaleButton, scaleMenu
local alertBox, viewBox, rowsCatcher
local filterPanel, clickCatcher, menuFrame, copyFrame, levelEdit
local headers, rows, tabs, seps = {}, {}, {}, {}
local currentList = {}
local offset = 0

-- Core calls this at login, after the pack is chosen. The columns are the same
-- for every pack, so there is nothing to do once the window exists.
function OCS.ApplyPackColumns()
	if frame then
		return
	end
	OCS.UI.buildCols()
end

-- The bottom hint is gone. The fontstring stays so the anchors around the
-- resize grip do not have to be redone, it simply never carries text.
function OCS.UI.updateHint()
	if not frame or not frame.hint then
		return
	end
	frame.hint:SetText("")
end

local visibleRows = 15

OCS.UI.YESNO_COLOR = {
	yes = { 0.45, 0.95, 0.5 },
	maybe = { 1, 0.82, 0.2 },
	no = { 0.75, 0.75, 0.75 },
}

function OCS.UI.skin()
	local name = (OCS_DB and OCS_DB.style) or "vanilla"
	return OCS.UI.SKINS[name] or OCS.UI.SKINS.vanilla
end

-- Mini mode draws itself with the same skin.
function OCS.CurrentSkin()
	return OCS.UI.skin()
end

-- Menu order and captions for the Skins button.
OCS.UI.SKIN_ORDER = {
	{ id = "vanilla", label = "Vanilla" },
	{ id = "dark", label = "Dark" },
	{ id = "grid", label = "Grid" },
	{ id = "slate", label = "Slate" },
	{ id = "parchment", label = "Parchment" },
	{ id = "glass", label = "Glass" },
	{ id = "felfire", label = "Felfire" },
}
OCS.SKIN_ORDER = OCS.UI.SKIN_ORDER

function OCS.SetSkin(id)
	if not OCS.UI.SKINS[id] or not OCS_DB then
		return
	end
	OCS_DB.style = id
	if OCS.ApplyStyle then
		OCS.ApplyStyle()
	end
end

-- Player menu ---------------------------------------------------------------

function OCS.UI.ensureTarget(name)
	if UnitExists("target") and UnitName("target") == name then
		return true
	end
	TargetByName(name, true)
	if UnitExists("target") and UnitName("target") == name then
		return true
	end
	OCS.Print(name .. " is not nearby, so that action needs the player in range.")
	return false
end

function OCS.UI.showCopyBox(name)
	if not copyFrame then
		copyFrame = CreateFrame("Frame", "OCS_CopyFrame", UIParent)
		OCS.RegisterScaleFrame(copyFrame)
		copyFrame:SetWidth(240)
		copyFrame:SetHeight(70)
		copyFrame:SetPoint("CENTER")
		copyFrame:SetFrameStrata("DIALOG")
		copyFrame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 26,
			insets = { left = 9, right = 9, top = 9, bottom = 9 },
		})
		local label = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOP", 0, -14)
		label:SetText("Ctrl+C to copy")
		local box = CreateFrame("EditBox", "OCS_CopyBox", copyFrame, "InputBoxTemplate")
		box:SetWidth(180)
		box:SetHeight(20)
		box:SetPoint("BOTTOM", 0, 16)
		box:SetAutoFocus(true)
		OCS.SetScript(box, "OnEscapePressed", function(self) copyFrame:Hide() end)
		OCS.SetScript(box, "OnEnterPressed", function(self) copyFrame:Hide() end)
		copyFrame.box = box
		table.insert(UISpecialFrames, "OCS_CopyFrame")
	end
	copyFrame:Show()
	copyFrame.box:SetText(name)
	copyFrame.box:HighlightText()
	copyFrame.box:SetFocus()
end

-- Vanilla only permits invitations from a leader or raid assistant when grouped.
function OCS.UI.inviteEntry(name)
	if OCS.CanInvite and not OCS.CanInvite() then
        return { text = "Invite (leader or assistant only)", disabled = true, notCheckable = true }
    end
	return { text = "Invite", notCheckable = true, func = function()
		InviteByName(name)
	end }
end

function OCS.UI.openPlayerMenu(bucket, name, anchor)
	if not menuFrame then
		menuFrame = CreateFrame("Frame", "OCS_MenuFrame", UIParent, "UIDropDownMenuTemplate")
	end
	local menu = {
		{ text = name, isTitle = true, notCheckable = true },
		{ text = "Whisper", notCheckable = true, func = function()
			ChatFrame_OpenChat("/w " .. name .. " ", DEFAULT_CHAT_FRAME)
		end },
		OCS.UI.inviteEntry(name),
		{ text = "Target", notCheckable = true, func = function()
			OCS.UI.ensureTarget(name)
		end },
		{ text = "Add friend", notCheckable = true, func = function()
			AddFriend(name)
		end },
		{ text = "Ignore", notCheckable = true, func = function()
			AddIgnore(name)
		end },
		{ text = "Copy name", notCheckable = true, func = function()
			OCS.UI.showCopyBox(name)
		end },
		{ text = "Remove row", notCheckable = true, func = function()
			OCS.RemoveRow(bucket, name)
		end },
		{ text = "Cancel", notCheckable = true, func = function() end },
	}
	-- Wording is sometimes genuinely ambiguous, so allow a manual move.
	-- The targets come from the section table, every tab of every section
	-- except the one the row already sits in, tucked into a submenu so the
	-- player menu stays short.
	local moves = {}
	for i = 1, OCS.Len(OCS.SECTIONS) do
		local section = OCS.SECTIONS[i]
		for j = 1, OCS.Len(section.buckets) do
			local target = section.buckets[j]
			if target ~= bucket then
				table.insert(moves, {
					text = section.label .. " " .. (OCS.BUCKET_LABEL[target] or target),
					notCheckable = true,
					func = function()
						OCS.MoveRow(bucket, name, target)
					end,
				})
			end
		end
	end
	table.insert(menu, OCS.Len(menu), {
		text = "Move to",
		notCheckable = true,
		hasArrow = true,
		menuList = moves,
	})
	OCS.InitializeMenu(menuFrame, function(self, level, menuList)
		local list = (level == 1) and menu or menuList
		if not list then
			return
		end
		for i = 1, OCS.Len(list) do
			local info = list[i]
			info.value = info.menuList
			UIDropDownMenu_AddButton(info, level)
		end
	end, "MENU")
	OCS.ToggleMenu(1, nil, menuFrame, "cursor", 0, 0)
end

-- Same right click menu from the mini window.
OCS.OpenPlayerMenu = OCS.UI.openPlayerMenu

-- Layout --------------------------------------------------------------------

-- How many rows fit inside the table area right now.
--
-- Use the explicitly sized main window's logical units throughout. An
-- anchor-derived child height can be scaled or stale in the 1.12 client.
function OCS.UI.tableHeight()
	return frame and math.max(0, frame:GetHeight() - OCS.UI.TABLE_TOP - OCS.UI.TABLE_BOTTOM) or 0
end

function OCS.UI.fitRows()
	return math.max(0, math.floor((OCS.UI.tableHeight() + 0.000001) / OCS.UI.ROW_H))
end

-- Columns are dropped from this list, first to last, until the remaining
-- columns fit the width of the table. Time, Name, W and Message always stay.
OCS.UI.COL_DROP_ORDER = { "prog", "level",
	"class", "act", "role" }
OCS.UI.MIN_MESSAGE_W = 120

-- The columns each section uses. Trade has no role and no level, a seller
-- has neither.
OCS.UI.SECTION_COLS = {
	PVE = { time = true, name = true, role = true, class = true, act = true,
		prog = true,
		level = true, wsp = true, message = true },
	PVP = { time = true, name = true, role = true, class = true, act = true,
		level = true, wsp = true, message = true },
	TRADE = { time = true, name = true, act = true, wsp = true, message = true },
	-- A guild advert is a name and a pitch. There is no role, no level and no
	-- place to show.
	GUILD = { time = true, name = true, message = true },
}

function OCS.PackHasClasses()
	local pack = OCS.ActivePack and OCS.ActivePack()
	return (pack and pack.classes) and true or false
end

function OCS.SectionColumnSet()
	local id = (OCS.GetSection and OCS.GetSection()) or "PVE"
	local set = OCS.UI.SECTION_COLS[id] or OCS.UI.SECTION_COLS.PVE
	if set.class and not OCS.PackHasClasses() then
		local copy = {}
		for k, v in pairs(set) do
			copy[k] = v
		end
		copy.class = nil
		return copy
	end
	return set
end
local hiddenCols = {}

function OCS.ColumnIsHidden(key)
	return hiddenCols[key] == true
end

-- Columns switched off by hand with the Rows button. Kept per section, so
-- PvE can be wide while Trade stays compact, and saved between sessions.
-- Name and Message can never be switched off: without them there is no table.
OCS.UI.LOCKED_COLS = { name = true, message = true }

function OCS.UI.colStore(create)
	local section = (OCS.GetSection and OCS.GetSection()) or "PVE"
	if not OCS_DB then
		return nil
	end
	if create then
		OCS_DB.cols = OCS_DB.cols or {}
		OCS_DB.cols[section] = OCS_DB.cols[section] or {}
	end
	return OCS_DB.cols and OCS_DB.cols[section]
end

function OCS.ColumnOff(key)
	if OCS.UI.LOCKED_COLS[key] then
		return false
	end
	local set = OCS.UI.colStore(false)
	return set ~= nil and set[key] == true
end

function OCS.ToggleColumn(key)
	if OCS.UI.LOCKED_COLS[key] then
		return
	end
	local set = OCS.UI.colStore(true)
	if not set then
		return
	end
	if set[key] then
		set[key] = nil
	else
		set[key] = true
	end
	if OCS.Refresh then
		OCS.Refresh()
	end
end

function OCS.ShowAllColumns()
	local set = OCS.UI.colStore(true)
	if not set then
		return
	end
	for k in pairs(set) do
		set[k] = nil
	end
	if OCS.Refresh then
		OCS.Refresh()
	end
end

-- One fixed logical margin shared by the window's edge-anchored widgets.
function OCS.EdgeMargin()
	return OCS.UI.EDGE_MARGIN
end

-- Widgets that sit on an edge register how they anchor themselves. The list is
-- replayed on every resize, so no anchor is left behind at a stale offset.
local edgeAnchors = {}

function OCS.UI.edgeAnchor(fn)
	table.insert(edgeAnchors, fn)
	fn(OCS.EdgeMargin())
end

function OCS.LayoutEdges()
	local m = OCS.EdgeMargin()
	for i = 1, OCS.Len(edgeAnchors) do
		edgeAnchors[i](m)
	end
end

-- Column widths the user dragged in the header row. Kept per section and per
-- character, so a wide PvE table does not force the same widths on Trade.
OCS.UI.MAX_COL_W = 500

function OCS.UI.widthStore(create)
	local section = (OCS.GetSection and OCS.GetSection()) or "PVE"
	if not OCS_DB then
		return nil
	end
	if type(OCS_DB.colw) ~= "table" then
		if not create then
			return nil
		end
		OCS_DB.colw = {}
	end
	if type(OCS_DB.colw[section]) ~= "table" then
		if not create then
			return nil
		end
		OCS_DB.colw[section] = {}
	end
	return OCS_DB.colw[section]
end

-- A column can be dragged down to 15 px. Nothing is held up by the heading,
-- because the heading and the cells are both cut to the width they get.
function OCS.UI.colMinWidth(i)
	return 15
end

-- Clipping without an ellipsis.
--
-- The client cuts a FontString that carries a width of its own and writes
-- "..." behind it, and "Myth..." says less than "Myth". Measuring on the real
-- FontString would mean writing the long text first and the short one after,
-- which is what made the dots flash up and disappear again. So nothing is ever
-- measured on screen: one hidden FontString does the measuring, and the cell
-- is written exactly once, already short enough that the client has no reason
-- to cut anything.
local measureFS
function OCS.UI.measureWidth(fs, text)
	if not measureFS then
		measureFS = UIParent:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
		measureFS:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 100)
		measureFS:Hide()
	end
	local file, size, flags = fs:GetFont()
	if file then
		measureFS:SetFont(file, size, flags)
	end
	measureFS:SetText(text or "")
	return measureFS:GetStringWidth() or 0
end

-- Longest leading part of the text that fits, found by halving rather than one
-- character at a time, because this runs for every cell of every row.
function OCS.UI.clipText(fs, text, width)
	text = text or ""
	if not width or width <= 0 or text == "" then
		return text
	end
	local room = width - 2
	if room < 1 then
		return ""
	end
	if OCS.UI.measureWidth(fs, text) <= room then
		return text
	end
	local lo, hi = 0, string.len(text)
	while lo < hi do
		local mid = math.floor((lo + hi + 1) / 2)
		if OCS.UI.measureWidth(fs, string.sub(text, 1, mid)) <= room then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return string.sub(text, 1, lo)
end

-- Writes the text already cut, and remembers the whole of it, so widening the
-- column brings the rest back instead of cutting a stump down again.
function OCS.UI.setClipped(fs, text, width)
	if not fs then
		return
	end
	fs.fullText = text or ""
	fs:SetText(OCS.UI.clipText(fs, fs.fullText, width))
end

-- Re-cut what is already on a FontString, after its column changed width.
function OCS.UI.reclip(fs, width)
	if not fs then
		return
	end
	local full = fs.fullText or fs:GetText() or ""
	fs.fullText = full
	fs:SetText(OCS.UI.clipText(fs, full, width))
end

function OCS.ResetColumnWidths()
	if OCS_DB then
		OCS_DB.colw = {}
	end
end

function OCS.UI.layout()
	if not frame then
		return
	end
	OCS.LayoutEdges()
	local avail = frame:GetWidth() - OCS.EdgeMargin() * 2 - OCS.UI.SCROLL_W
	tableArea:SetWidth(avail)
	tableArea:SetHeight(OCS.UI.tableHeight())

	-- A dragged width wins over the built in one. Everything below measures
	-- from c.w, so this is the only place that has to know about it.
	local saved = OCS.UI.widthStore(false)
	for i = 1, OCS.Len(OCS.UI.COLS) do
		local c = OCS.UI.COLS[i]
		local def = OCS.UI.ALL_COLS[c.key]
		local w = (def and def.w) or c.w
		local override = saved and tonumber(saved[c.key])
		if override then
			local min = OCS.UI.colMinWidth(i)
			if override < min then
				override = min
			end
			if override > OCS.UI.MAX_COL_W then
				override = OCS.UI.MAX_COL_W
			end
			w = override
		end
		c.w = w
	end

	-- Step 1. Find the columns that fit. A column that does not fit is hidden.
	-- Columns are measured, not drawn at fixed offsets, so the last
	-- columns ran past the right edge of the table.
	for k in pairs(hiddenCols) do
		hiddenCols[k] = nil
	end

	-- Step 0. Hide what this section does not use at all.
	local allowed = OCS.SectionColumnSet()
	for i = 1, OCS.Len(OCS.UI.COLS) do
		local key = OCS.UI.COLS[i].key
		if not allowed[key] or OCS.ColumnOff(key) then
			hiddenCols[key] = true
		end
	end

	local function neededWidth()
		local sum = 6
		for i = 1, OCS.Len(OCS.UI.COLS) do
			local c = OCS.UI.COLS[i]
			if not hiddenCols[c.key] then
				sum = sum + (c.flex and OCS.UI.MIN_MESSAGE_W or c.w) + 6
			end
		end
		return sum
	end
	local present = {}
	for i = 1, OCS.Len(OCS.UI.COLS) do
		present[OCS.UI.COLS[i].key] = true
	end
	for n = 1, OCS.Len(OCS.UI.COL_DROP_ORDER) do
		if neededWidth() <= avail then
			break
		end
		local key = OCS.UI.COL_DROP_ORDER[n]
		if present[key] then
			hiddenCols[key] = true
		end
	end

	-- Step 2. Share the leftover width with the message column.
	local fixed = 0
	for i = 1, OCS.Len(OCS.UI.COLS) do
		local c = OCS.UI.COLS[i]
		if not hiddenCols[c.key] and not c.flex then
			fixed = fixed + c.w + 6
		end
	end
	local flexW = avail - fixed - 6
	if flexW < OCS.UI.MIN_MESSAGE_W then
		flexW = OCS.UI.MIN_MESSAGE_W
	end

	local x = 0
	local lastVisible = 0
	for i = 1, OCS.Len(OCS.UI.COLS) do
		local c = OCS.UI.COLS[i]
		if hiddenCols[c.key] then
			c.cw = 0
			c.x = 0
		else
			c.cw = c.flex and flexW or c.w
			c.x = x
			x = x + c.cw + 6
			lastVisible = i
		end
	end

	for i = 1, OCS.Len(OCS.UI.COLS) do
		local h = headers[i]
		if hiddenCols[OCS.UI.COLS[i].key] then
			h:Hide()
		else
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", headerBar, "TOPLEFT", OCS.UI.COLS[i].x, 0)
			h:SetWidth(OCS.UI.COLS[i].cw)
			h:SetHeight(18)
			-- The label sits 2 px in from the left edge.
			OCS.UI.reclip(h.label, OCS.UI.COLS[i].cw - 2)
			h:Show()
		end
		-- The drag handle sits on the right edge of its heading. Message is
		-- the flex column and takes whatever is left, so it has no handle.
		local grip = h and h.widthGrip
		if grip then
			if hiddenCols[OCS.UI.COLS[i].key] or OCS.UI.COLS[i].flex then
				grip:Hide()
			else
				grip:ClearAllPoints()
				grip:SetPoint("TOPLEFT", headerBar, "TOPLEFT",
					OCS.UI.COLS[i].x + OCS.UI.COLS[i].cw - 3, 0)
				grip:Show()
			end
		end
	end

	visibleRows = OCS.UI.fitRows()
	OCS.UI.ensureRows(visibleRows)

	for i = 1, OCS.Len(rows) do
		local row = rows[i]
		row:SetWidth(avail)
		for j = 1, OCS.Len(OCS.UI.COLS) do
			local cell = row.cells[OCS.UI.COLS[j].key]
			if cell then
				if hiddenCols[OCS.UI.COLS[j].key] then
					cell:Hide()
				else
					cell:ClearAllPoints()
					cell:SetPoint("LEFT", row, "LEFT", OCS.UI.COLS[j].x, 0)
					cell:SetWidth(OCS.UI.COLS[j].cw)
					if OCS.UI.COLS[j].key ~= "message" then
						OCS.UI.reclip(cell, OCS.UI.COLS[j].cw)
					end
					cell:Show()
				end
			end
		end
		if i <= visibleRows then
			row:Show()
		else
			row:Hide()
		end
	end

	local useLines = OCS.UI.skin().lines
	for i = 1, OCS.Len(OCS.UI.COLS) do
		local sep = seps[i]
		if hiddenCols[OCS.UI.COLS[i].key] or not useLines or i >= lastVisible then
			sep:Hide()
		else
			sep:ClearAllPoints()
			sep:SetPoint("TOPLEFT", tableArea, "TOPLEFT", OCS.UI.COLS[i].x + OCS.UI.COLS[i].cw + 2, 0)
			sep:SetPoint("BOTTOMLEFT", tableArea, "BOTTOMLEFT", OCS.UI.COLS[i].x + OCS.UI.COLS[i].cw + 2, 0)
			sep:SetWidth(1)
			sep:Show()
		end
	end
end

-- Rendering -----------------------------------------------------------------

function OCS.UI.levelText(data)
	if not data.level then
		return "?"
	end
	if data.bracket then
		return tostring(data.level) .. "+"
	end
	return tostring(data.level)
end

-- Cut every cell to its column once the row is painted, so each branch above
-- can go on writing the full value. Message is the flex column and keeps the
-- client behaviour, ellipsis and all.
function OCS.UI.clipRowCells(cells)
	for i = 1, OCS.Len(OCS.UI.COLS) do
		local c = OCS.UI.COLS[i]
		if c.key ~= "message" and not hiddenCols[c.key] then
			local cell = cells[c.key]
			if cell then
				OCS.UI.setClipped(cell, cell:GetText(), c.cw or c.w)
			end
		end
	end
end

function OCS.UI.paintRow(row, data, index)
	row.data = data
	local cells = row.cells
	local now = time()
	local age = now - (data.time or now)
	local stale = age > (OCS_DB.stale or 300)

	cells.time:SetText(date("%H:%M:%S", data.time or now))
	if stale then
		cells.time:SetTextColor(0.55, 0.55, 0.55)
	else
		cells.time:SetTextColor(0.85, 0.85, 0.85)
	end

	cells.name:SetText(data.name or "?")
	cells.name:SetTextColor(1, 1, 1)

	if cells.class then
		cells.class:SetText(data.class or "-")
		cells.class:SetTextColor(0.85, 0.85, 0.85)
	end

	cells.role:SetText(OCS.RoleDisplay(data.roleText))
	if data.locked and data.locked.role then
		cells.role:SetTextColor(0.4, 0.75, 1)
	else
		cells.role:SetTextColor(0.95, 0.9, 0.7)
	end

	-- Pack columns. Each one is drawn only when the pack asked for it.
	if cells.act then
		local text = data.activityShort or data.activityName
		if not text and data.profession then
			text = data.profession
			if data.profMode then
				text = text .. " (" .. data.profMode .. ")"
			end
		end
		text = text or "?"
		if data.target then
			text = text .. ": " .. data.target
		end
		cells.act:SetText(text)
		cells.act:SetTextColor(0.68, 0.84, 1)
	end
	if cells.prog then
		if levelEdit and levelEdit:IsShown() and levelEdit.cell == cells.prog then
			cells.prog:SetText("")
		else
			cells.prog:SetText(data.prog or "-")
		end
		if data.locked and data.locked.prog then
			cells.prog:SetTextColor(0.4, 0.75, 1)
		else
			cells.prog:SetTextColor(0.85, 0.85, 0.85)
		end
	end

	-- While the level box is open over this cell, the cell stays blank, so the
	-- old value is not drawn behind the box.
	if levelEdit and levelEdit:IsShown() and levelEdit.cell == cells.level then
		cells.level:SetText("")
	else
		cells.level:SetText(OCS.UI.levelText(data))
	end
	if data.locked and data.locked.level then
		cells.level:SetTextColor(0.4, 0.75, 1)
	else
		cells.level:SetTextColor(0.85, 0.85, 0.85)
	end

	-- The whisper cell is a one click send, so show plainly when it was used.
	if data.whispered then
		cells.wsp:SetText("|cff40ff90sent|r")
	else
		cells.wsp:SetText("|cffffd200>>|r")
	end

	cells.message:SetText(data.message or data.rawMessage or "")
	cells.message:SetTextColor(0.8, 0.82, 0.88)

	local alt = OCS.UI.skin().altAlpha
	if math.mod(index, 2) == 0 then
		row.bg:SetTexture(1, 1, 1, alt)
	else
		row.bg:SetTexture(1, 1, 1, alt * 0.35)
	end
	OCS.UI.clipRowCells(cells)
	row.bg:Show()
	row:Show()
end

function OCS.UI.updateRows()
	if not frame then
		return
	end
	-- Recount here as well. Painting can run from a timer or from an incoming
	-- message, after a resize but before the next layout pass, and a stale
	-- count is what let rows draw past the bottom edge.
	visibleRows = OCS.UI.fitRows()
	if visibleRows > OCS.Len(rows) then OCS.UI.layout() end
	local total = OCS.Len(currentList)
	local maxOffset = total - visibleRows
	if maxOffset < 0 then maxOffset = 0 end
	if offset > maxOffset then offset = maxOffset end

	scrollBar:SetMinMaxValues(0, maxOffset)
	scrollBar.updating = true
	scrollBar:SetValue(offset)
	scrollBar.updating = nil
	if maxOffset > 0 then
		scrollBar:Show()
	else
		scrollBar:Hide()
	end

	for i = 1, OCS.Len(rows) do
		local row = rows[i]
		if i <= visibleRows then
			local data = currentList[i + offset]
			if data then
				OCS.UI.paintRow(row, data, i + offset)
			else
				row.data = nil
				for j = 1, OCS.Len(OCS.UI.COLS) do
					local cell = row.cells[OCS.UI.COLS[j].key]
					cell.fullText = ""
					cell:SetText("")
				end
				row.bg:Hide()
			end
		else
			row:Hide()
		end
	end
end

function OCS.Refresh()
	if not frame or not OCS_DB then
		return
	end
	-- Nothing to paint while the window is hidden, and OnShow refreshes.
	if not frame:IsShown() then
		return
	end
	local mode = OCS.GetMode()
	currentList = OCS.GetSortedRows(mode, OCS_DB.sortKey, OCS_DB.sortAsc)
	for i = 1, OCS.Len(OCS.BUCKETS) do
		local key = OCS.BUCKETS[i]
		local tab = tabs[key]
		if tab then
			local shown, total = OCS.FilterCount(key)
			local text = (OCS.BUCKET_LABEL[key] or key) .. " " .. shown
			if OCS.FilterActive() and shown ~= total then
				text = text .. "/" .. total
			end
			tab:SetText(text)
			-- "Unsure 3/56" needs more room than a plain label.
			local fs = tab:GetFontString()
			local need = fs and (fs:GetStringWidth() + 24) or 92
			if need < 92 then
				need = 92
			end
			tab:SetWidth(need)
			if key == mode then
				tab:LockHighlight()
			else
				tab:UnlockHighlight()
			end
		end
	end
	if frame.layoutTabs then
		frame.layoutTabs()
	end
	-- The section decides the column set, so lay the table out again.
	OCS.UI.layout()
	countText:SetText(OCS.Len(currentList) .. " of " .. OCS.Len(OCS_DB.rows[mode] or {})
		.. " shown" .. ((OCS.FilterSummary and OCS.FilterSummary()) or ""))
	OCS.UpdateAlertButtons()
	OCS.UI.updateRows()
end

-- Alerts, the bell and the scope button all decide the same thing, so they
-- sit next to each other on one row, level with the section row on the left.
function OCS.LayoutAlertBar()
	if not alertsButton or not soundButton or not scopeButton or not frame then
		return
	end
	-- The same margin the title, the tabs and the table use.
	local margin = OCS.EdgeMargin()
	-- Padding is zero unless the optional frame is switched on.
	local boxPad = (OCS.UI.GROUP_FRAME == "none") and 0 or OCS.UI.BOX_PAD
	local gap = OCS.UI.BOX_GAP
	local scopeW = scopeButton:GetWidth()
	local soundW = soundButton:GetWidth()
	local alertsW = alertsButton:GetWidth()
	alertsButton:ClearAllPoints()
	soundButton:ClearAllPoints()
	scopeButton:ClearAllPoints()
	if alertBox then
		alertBox:ClearAllPoints()
	end
	-- Reading order: Scale, Alerts, bell, scope. Both rows are 252 px wide,
	-- placing Scale directly above the left edge of Filters.
	local groupW = alertsW + gap + soundW + gap + scopeW
	scopeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
		-(margin + boxPad), -OCS.UI.ALERT_TOP)
	soundButton:SetPoint("RIGHT", scopeButton, "LEFT", -gap, 0)
	alertsButton:SetPoint("RIGHT", soundButton, "LEFT", -gap, 0)
	if scaleButton then
		scaleButton:ClearAllPoints()
		scaleButton:SetPoint("RIGHT", alertsButton, "LEFT", -gap, 0)
		groupW = groupW + gap + scaleButton:GetWidth()
	end
	-- One frame wraps both rows. LayoutViewBox sizes it, because it needs
	-- the width of both.
	OCS.alertRowWidth = groupW
	OCS.LayoutViewBox()
end

-- Skins, Rows and Filters in one row inside their own box, left of the
-- alert box. Two groups, two frames, one job each.
function OCS.LayoutViewBox()
	if not frame or not filtersButton or not rowsButton or not skinsButton then
		return
	end
	local margin = OCS.EdgeMargin()
	local boxPad = (OCS.UI.GROUP_FRAME == "none") and 0 or OCS.UI.BOX_PAD
	local gap = OCS.UI.BOX_GAP
	filtersButton:ClearAllPoints()
	rowsButton:ClearAllPoints()
	skinsButton:ClearAllPoints()
	-- Lower row, same right edge as the alert row above it.
	-- Reading order: Filters, Rows, Skins.
	skinsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
		-(margin + boxPad), -OCS.UI.VIEW_TOP)
	rowsButton:SetPoint("RIGHT", skinsButton, "LEFT", -gap, 0)
	filtersButton:SetPoint("RIGHT", rowsButton, "LEFT", -gap, 0)
	-- The frame covers whichever row is wider, so both rows keep the same
	-- right edge and the same padding.
	local viewW = skinsButton:GetWidth() + gap + rowsButton:GetWidth()
		+ gap + filtersButton:GetWidth()
	local widest = OCS.alertRowWidth or 0
	if viewW > widest then
		widest = viewW
	end
	if viewBox then
		viewBox:Hide()
	end
	if alertBox then
		if OCS.UI.GROUP_FRAME == "none" then
			alertBox:Hide()
		else
			alertBox:ClearAllPoints()
			alertBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -margin,
				-(OCS.UI.ROW_TOP - boxPad))
			alertBox:SetWidth(widest + (boxPad * 2))
			alertBox:SetHeight((OCS.UI.ROW_BOTTOM + 22 + boxPad) - (OCS.UI.ROW_TOP - boxPad))
			-- A hair line keeps the two jobs apart inside one frame.
			if not alertBox.divider then
				alertBox.divider = alertBox:CreateTexture(nil, "OVERLAY")
				alertBox.divider:SetTexture(1, 1, 1, 0.12)
				alertBox.divider:SetHeight(1)
			end
			alertBox.divider:ClearAllPoints()
			local midY = -((OCS.UI.ROW_BOTTOM - OCS.UI.ROW_TOP - 22) / 2 + 22 + boxPad)
			alertBox.divider:SetPoint("TOPLEFT", alertBox, "TOPLEFT", 5, midY)
			alertBox.divider:SetPoint("TOPRIGHT", alertBox, "TOPRIGHT", -5, midY)
			alertBox.divider:Show()
			alertBox:Show()
		end
	end
end

function OCS.UpdateAlertButtons()
	local a = OCS_DB and OCS_DB.alert
	if not a then
		return
	end
	if alertsButton then
		alertsButton:SetText("Alerts: " .. (a.enabled and "ON" or "OFF"))
	end
	if scopeButton then
		scopeButton:SetText((a.scope or "SECTION") == "SECTION" and "Section" or "All")
	end
	if rowsButton then
		rowsButton:SetText("Rows")
	end
	if soundButton then
		-- Sound on is a bright bell. Muted is the same bell desaturated, with the
		-- stock red cross over it. VOICECHAT-MUTED is only the cross, so it fills
		-- the button cleanly.
		local icon = soundButton:GetNormalTexture()
		if icon and icon.SetDesaturated then
			icon:SetDesaturated(not a.sound)
		end
		if soundButton.cross then
			if a.sound then
				soundButton.cross:Hide()
			else
				soundButton.cross:Show()
			end
		end
		-- Only a slight dim while alerts are off. The bell still has to be legible
		-- against the window frame.
		soundButton:SetAlpha(a.enabled and 1 or 0.85)
	end
end

function OCS.RefreshTimes()
	if frame and frame:IsShown() then
		OCS.UI.updateRows()
	end
end

-- Editing -------------------------------------------------------------------

function OCS.UI.nextInCycle(cycle, current)
	for i = 1, OCS.Len(cycle) do
		if cycle[i] == current then
			return cycle[math.mod(i, OCS.Len(cycle)) + 1]
		end
	end
	return cycle[1]
end

OCS.UI.ROLE_CYCLE = { "?", "tank", "heal", "damage", "tank, damage", "heal, damage", "tank, heal, damage" }
OCS.UI.YESNO_CYCLE = { "no", "maybe", "yes" }

function OCS.UI.applyRoleText(data, text)
	data.roleText = text
	data.roleSet = {}
	for i = 1, OCS.Len(OCS.ROLE_ORDER) do
		if string.find(text, OCS.ROLE_ORDER[i], 1, true) then
			data.roleSet[OCS.ROLE_ORDER[i]] = true
		end
	end
end

-- A full screen catcher sits under the open editor. The next click anywhere,
-- left or right button, closes the editor. That also stops an editor from
-- staying alive over another tab.
local editCatcher

function OCS.UI.ensureEditCatcher()
	if editCatcher then
		return
	end
	editCatcher = CreateFrame("Button", "OCS_EditCatcher", UIParent)
	editCatcher:SetAllPoints(UIParent)
	editCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
	editCatcher:EnableMouse(true)
	editCatcher:RegisterForClicks("AnyDown")
	editCatcher:Hide()
	OCS.SetScript(editCatcher, "OnClick", function()
		OCS.CloseCellEditor()
	end)
end

-- Closes the editor and keeps the value that was there before. Escape and any
-- click outside the box both use this.
function OCS.CloseCellEditor()
	if levelEdit then
		levelEdit.data = nil
		levelEdit.cell = nil
		levelEdit:ClearFocus()
		levelEdit:Hide()
	end
	if editCatcher then
		editCatcher:Hide()
	end
	if OCS.Refresh then
		OCS.Refresh()
	end
end

OCS.UI.EDIT_KINDS = {
	level = { numeric = true, maxLetters = 2, width = 40 },

	prog = { numeric = false, maxLetters = 7, width = 56 },
}

function OCS.UI.openCellEditor(row, cell, kind)
	local spec = OCS.UI.EDIT_KINDS[kind] or OCS.UI.EDIT_KINDS.level
	OCS.UI.ensureEditCatcher()
	if not levelEdit then
		-- Parented to the catcher, so the box draws above it and takes its own
		-- clicks while every other click closes the editor.
		levelEdit = CreateFrame("EditBox", "OCS_LevelEdit", editCatcher, "InputBoxTemplate")
		OCS.RegisterScaleFrame(levelEdit)
		levelEdit:SetHeight(18)
		levelEdit:SetAutoFocus(true)
		levelEdit:Hide()

		OCS.SetScript(levelEdit, "OnEnterPressed", function(self)
			local data = self.data
			local k = self.kind or "level"
			if data then
				local text = self:GetText() or ""
				data.locked = data.locked or {}
				if k == "prog" then
					if text == "" then
						data.prog = data.orig and data.orig.prog or nil
						data.locked.prog = nil
					elseif OCS.Match(text, "^%d+%s*/%s*%d+$") then
						data.prog = text
						data.locked.prog = true
					end
				else
					local v = tonumber(text)
					if text == "" then
						data.level = data.orig and data.orig.level or nil
						data.bracket = (data.orig and data.orig.bracket) or false
						data.locked.level = nil
					elseif v and v >= 1 and v <= (OCS.LEVEL_CAP or 60) then
						data.level = v
						data.bracket = false
						data.locked.level = true
					end
				end
			end
			OCS.CloseCellEditor()
		end)
		OCS.SetScript(levelEdit, "OnSpacePressed", function(self)
			local save = OCS.GetScript(self, "OnEnterPressed")
			if save then
				save(self)
			end
		end)
		-- A numeric box swallows the space bar before OnSpacePressed fires on
		-- some clients, so the character itself is caught as well.
		OCS.SetScript(levelEdit, "OnChar", function(self, ch)
			if ch == " " then
				self:SetText(string.gsub(self:GetText() or "", " ", ""))
				local save = OCS.GetScript(self, "OnEnterPressed")
				if save then
					save(self)
				end
			end
		end)
		OCS.SetScript(levelEdit, "OnEscapePressed", function(self)
			-- Escape is the only way to throw the typed value away.
			self.data = nil
			OCS.CloseCellEditor()
		end)
		OCS.SetScript(levelEdit, "OnEditFocusLost", function(self)
			-- Clicking away keeps what was typed. Losing an edit because the
			-- mouse moved is never what anyone wanted.
			if self.data and not self.saving then
				self.saving = true
				local save = OCS.GetScript(self, "OnEnterPressed")
				if save then
					save(self)
				end
				self.saving = nil
			end
			self.data = nil
			self.cell = nil
			self:Hide()
			if editCatcher then
				editCatcher:Hide()
			end
		end)
	end
	levelEdit:SetNumeric(spec.numeric and true or false)
	levelEdit:SetMaxLetters(spec.maxLetters)
	levelEdit:SetWidth(spec.width)
	levelEdit.data = row.data
	levelEdit.cell = cell
	levelEdit.kind = kind
	-- Blank the cell, otherwise the old value shows through the box.
	cell:SetText("")
	levelEdit:ClearAllPoints()
	levelEdit:SetPoint("LEFT", cell, "LEFT", -4, 0)
	local current
	if kind == "prog" then
		current = row.data.prog or ""
	else
		current = row.data.level and tostring(row.data.level) or ""
	end
	levelEdit:SetText(current)
	editCatcher:Show()
	levelEdit:Show()
	levelEdit:SetFocus()
	levelEdit:HighlightText()
end

-- Steps a yes, maybe, no cell. Every state is reachable and the step after the
-- last one puts back what the message said.
--
-- The count of clicks is held per cell instead of being worked out from the
-- value on screen. Reading the value was wrong whenever the parsed value was
-- the last one in the list: an LFM row parsed as "maybe" only flipped between
-- maybe and yes, because the revert test fired one step too early.
function OCS.UI.columnAt(row)
	local scale = row:GetEffectiveScale()
	local cursorX = GetCursorPosition() / scale
	local rel = cursorX - row:GetLeft()
	for i = 1, OCS.Len(OCS.UI.COLS) do
		if rel >= OCS.UI.COLS[i].x and rel < OCS.UI.COLS[i].x + (OCS.UI.COLS[i].cw or OCS.UI.COLS[i].w) then
			return OCS.UI.COLS[i]
		end
	end
	return nil
end

function OCS.UI.onRowClick(row, button)
	local data = row.data
	if not data then
		return
	end
	if button == "RightButton" then
		OCS.UI.openPlayerMenu(OCS.GetMode(), data.name, row)
		return
	end
	local col = OCS.UI.columnAt(row)
	if col and col.whisper then
		OCS.SendWhisper(data, OCS.GetMode())
		return
	end
	if not col or not col.edit then
		return
	end
	data.locked = data.locked or {}
	if col.key == "role" then
		-- Same rule as the yes/no cells: every entry is reachable and the step
		-- after the last one restores the roles the message named.
		local orig = (data.orig and data.orig.roleText) or "?"
		data.step = data.step or {}
		local step = (data.locked.role and data.step.role) or 0
		step = step + 1
		if step > OCS.Len(OCS.UI.ROLE_CYCLE) then
			OCS.UI.applyRoleText(data, orig)
			data.locked.role = nil
			data.step.role = nil
		else
			OCS.UI.applyRoleText(data, OCS.UI.nextInCycle(OCS.UI.ROLE_CYCLE, data.roleText or "?"))
			data.locked.role = true
			data.step.role = step
		end
	elseif col.key == "level" then
		OCS.UI.openCellEditor(row, row.cells.level, "level")
		return
	elseif col.key == "prog" then
		OCS.UI.openCellEditor(row, row.cells.prog, "prog")
		return
	end
	OCS.Refresh()
end

-- Whisper setup -------------------------------------------------------------

local whisperPanel

-- Built without the stock input box art, which only drew its stretched middle
-- piece on the first box. Own backdrop, so every box looks the same.
function OCS.UI.makeTemplateBox(parent, y, maxLetters)
	local box = CreateFrame("EditBox", nil, parent)
	box:SetPoint("TOPLEFT", parent, "TOPLEFT", 22, y)
	box:SetWidth(410)
	box:SetHeight(22)
	box:SetAutoFocus(false)
	box:SetMaxLetters(maxLetters or 200)
	box:SetFontObject("ChatFontNormal")
	box:SetTextColor(1, 1, 1)
	box:SetTextInsets(6, 6, 0, 0)
	box:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	box:SetBackdropColor(0, 0, 0, 0.9)
	box:SetBackdropBorderColor(0.45, 0.45, 0.52, 1)
	box:EnableMouse(true)
	OCS.SetScript(box, "OnEscapePressed", function(self) self:ClearFocus() end)
	return box
end

function OCS.UI.saveWhisperPanel()
	if not whisperPanel or not whisperPanel.boxes then
		return
	end
	for i = 1, OCS.Len(whisperPanel.boxes) do
		local box = whisperPanel.boxes[i]
		OCS.SetWhisperTemplate(box.slot, box:GetText() or "")
	end
	OCS.Print("Whisper lines saved")
end

-- One box per slot, built from OCS.WHISPER_SLOTS, so the panel can never drift
-- away from what OCS.WhisperTemplate actually sends.
function OCS.UI.createWhisperPanel()
	whisperPanel = CreateFrame("Frame", "OCS_WhisperPanel", UIParent)
	OCS.RegisterScaleFrame(whisperPanel)
	whisperPanel:SetWidth(470)
	whisperPanel:SetHeight(300)
	whisperPanel:SetPoint("CENTER")
	whisperPanel:SetFrameStrata("FULLSCREEN_DIALOG")
	whisperPanel:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	whisperPanel:EnableMouse(true)
	whisperPanel:SetMovable(true)
	whisperPanel:RegisterForDrag("LeftButton")
	OCS.SetScript(whisperPanel, "OnDragStart", function(self) self:StartMoving() end)
	OCS.SetScript(whisperPanel, "OnDragStop", function(self) self:StopMovingOrSizing() end)

	-- Solid backing so chat behind the panel cannot be read through it.
	local solid = whisperPanel:CreateTexture(nil, "BORDER")
	solid:SetTexture(0.04, 0.04, 0.05, 1)
	solid:SetPoint("TOPLEFT", 7, -7)
	solid:SetPoint("BOTTOMRIGHT", -7, 7)

	local title = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 20, -18)
	title:SetText("Whisp Templates")

	local intro = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	intro:SetPoint("TOPLEFT", 22, -38)
	intro:SetWidth(420)
	intro:SetJustifyH("LEFT")
	intro:SetText("Nothing is sent automatically. The W cell in a row sends the"
		.. " line of that row's own tab, once per click.")

	whisperPanel.boxes = {}
	local slots = OCS.WHISPER_SLOTS or {}
	local y = -68
	for i = 1, OCS.Len(slots) do
		local label = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("TOPLEFT", 20, y)
		label:SetWidth(420)
		label:SetJustifyH("LEFT")
		label:SetText(slots[i].label)

		local box = OCS.UI.makeTemplateBox(whisperPanel, y - 16)
		box.slot = slots[i].key
		OCS.SetScript(box, "OnEnterPressed", function(self)
			self:ClearFocus()
			OCS.UI.saveWhisperPanel()
		end)
		whisperPanel.boxes[i] = box
		y = y - 56
	end

	local tokens = whisperPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tokens:SetPoint("TOPLEFT", 22, y - 6)
	tokens:SetWidth(420)
	tokens:SetJustifyH("LEFT")
	tokens:SetText("Placeholders, filled in when you click: {name} {role} {level}"
		.. " {size} read from the post, {myname}"
		.. " {mylevel} {myclass} for you, {prof} {profmode} on profession rows.")

	-- Height follows the number of slots, so nothing can overlap again.
	whisperPanel:SetHeight(-y + 116)

	local save = CreateFrame("Button", nil, whisperPanel, "UIPanelButtonTemplate")
	save:SetWidth(90)
	save:SetHeight(22)
	save:SetPoint("BOTTOMRIGHT", -114, 18)
	save:SetText("Save")
	OCS.SetScript(save, "OnClick", OCS.UI.saveWhisperPanel)

	local close = CreateFrame("Button", nil, whisperPanel, "UIPanelButtonTemplate")
	close:SetWidth(90)
	close:SetHeight(22)
	close:SetPoint("BOTTOMRIGHT", -18, 18)
	close:SetText("Close")
	OCS.SetScript(close, "OnClick", function()
		OCS.UI.saveWhisperPanel()
		whisperPanel:Hide()
	end)

	local reset = CreateFrame("Button", nil, whisperPanel, "UIPanelButtonTemplate")
	reset:SetWidth(110)
	reset:SetHeight(22)
	reset:SetPoint("BOTTOMLEFT", 18, 18)
	reset:SetText("Reset lines")
	OCS.SetScript(reset, "OnClick", function()
		if OCS.ResetWhisperTemplates then
			OCS.ResetWhisperTemplates()
			OCS.ShowWhisperSetup()
		end
	end)

	table.insert(UISpecialFrames, "OCS_WhisperPanel")
	whisperPanel:Hide()
end

function OCS.ShowWhisperSetup()
	if not whisperPanel then
		OCS.UI.createWhisperPanel()
	end
	for i = 1, OCS.Len(whisperPanel.boxes) do
		local box = whisperPanel.boxes[i]
		box:SetText(OCS.WhisperTemplate(box.slot) or "")
		if box.SetCursorPosition then box:SetCursorPosition(0) end
	end
	whisperPanel:Show()
end

-- Whisp Templates is a switch, so a second click closes the panel. Whatever
-- is typed is kept, the same as the Close button does.
function OCS.ToggleWhisperSetup()
	if whisperPanel and whisperPanel:IsShown() then
		OCS.UI.saveWhisperPanel()
		whisperPanel:Hide()
		return
	end
	OCS.ShowWhisperSetup()
end

-- Filters panel -------------------------------------------------------------

-- The menu buttons in the corner of the window. A full screen catcher
-- covers them while a menu is open, which is why both the hover highlight and
-- the click have to be driven by hand from here.
function OCS.UI.menuButtons()
	return { filtersButton, rowsButton, skinsButton, scaleButton }
end

function OCS.UI.menuButtonUnderCursor(skip)
	local buttons = OCS.UI.menuButtons()
	for i = 1, OCS.Len(buttons) do
		local b = buttons[i]
		if b and b ~= skip and b:IsShown() then
			local over = false
			if MouseIsOver then
				over = MouseIsOver(b)
			elseif b.IsMouseOver then
				over = OCS.IsMouseOver(b)
			end
			if over then
				return b
			end
		end
	end
	return nil
end

-- The catcher takes the mouse, so the button underneath never gets OnEnter and
-- never lights up. The highlight is locked on by hand instead, from the same
-- cursor test the click forwarding uses.
function OCS.UI.clearMenuHover()
	local buttons = OCS.UI.menuButtons()
	for i = 1, OCS.Len(buttons) do
		if buttons[i] then
			buttons[i]:UnlockHighlight()
		end
	end
end

function OCS.UI.paintMenuHover()
	local hot = OCS.UI.menuButtonUnderCursor()
	local buttons = OCS.UI.menuButtons()
	for i = 1, OCS.Len(buttons) do
		local b = buttons[i]
		if b then
			if b == hot then
				b:LockHighlight()
			else
				b:UnlockHighlight()
			end
		end
	end
	return hot
end

-- Clicking one menu button while another menu is open should switch straight
-- to it. The catcher swallows that click, so after closing what was open it is
-- handed to the button the cursor is actually over.
function OCS.UI.forwardMenuClick(skip)
	OCS.UI.clearMenuHover()
	local b = OCS.UI.menuButtonUnderCursor(skip)
	if not b then
		return false
	end
	local script = OCS.GetScript(b, "OnClick")
	if script then
		script(b, "LeftButton")
	end
	return true
end

function OCS.UI.closeViewMenu()
	CloseDropDownMenus()
	if rowsCatcher then rowsCatcher:Hide() end
	OCS.UI.openMenuButton = nil
end

function OCS.UI.ensureViewMenuCatcher()
	if rowsCatcher then return rowsCatcher end
	rowsCatcher = CreateFrame("Frame", "OCS_ViewMenuCatcher", UIParent)
	rowsCatcher:SetAllPoints(UIParent)
	rowsCatcher:SetFrameStrata("FULLSCREEN")
	rowsCatcher:EnableMouse(true)
	OCS.SetScript(rowsCatcher, "OnMouseDown", function()
		local previous = OCS.UI.openMenuButton
		OCS.UI.closeViewMenu()
		-- Clicking the same button only closes; another button switches menus.
		OCS.UI.forwardMenuClick(previous)
	end)
	OCS.SetScript(rowsCatcher, "OnUpdate", function(catcher)
		if not (DropDownList1 and DropDownList1:IsShown()) then
			catcher:Hide()
			OCS.UI.openMenuButton = nil
			return
		end
		OCS.UI.paintMenuHover()
	end)
	OCS.SetScript(rowsCatcher, "OnHide", OCS.UI.clearMenuHover)
	rowsCatcher:Hide()
	return rowsCatcher
end

function OCS.UI.toggleViewMenu(button, menu, initialize)
	if OCS.UI.openMenuButton == button and DropDownList1 and DropDownList1:IsShown() then
		OCS.UI.closeViewMenu()
		return
	end
	OCS.UI.closeFilterPanel()
	OCS.UI.closeViewMenu()
	local catcher = OCS.UI.ensureViewMenuCatcher()
	OCS.InitializeMenu(menu, initialize, "MENU")
	OCS.ToggleMenu(1, nil, menu, button, 0, 0)
	if DropDownList1 and DropDownList1:IsShown() then
		OCS.UI.openMenuButton = button
		catcher:Show()
	end
end

function OCS.UI.closeFilterPanel()
	-- The activity dropdown is parented to UIParent, so it survives the
	-- panel unless it is closed by hand.
	CloseDropDownMenus()
	if filterPanel then filterPanel:Hide() end
	if clickCatcher then clickCatcher:Hide() end
end

function OCS.UI.makeCheck(parent, label, x, y, onClick)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetWidth(16)
	check:SetHeight(16)
	check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	local text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("LEFT", check, "RIGHT", 2, 0)
	text:SetText(label)
	check.label = text
	OCS.SetScript(check, "OnClick", function(self)
		onClick(self:GetChecked() and true or false)
		OCS.Refresh()
		OCS.RefreshFilterPanel()
	end)
	return check
end

function OCS.UI.createFilterPanel()
	clickCatcher = CreateFrame("Frame", "OCS_ClickCatcher", UIParent)
	clickCatcher:SetAllPoints(UIParent)
	clickCatcher:SetFrameStrata("FULLSCREEN")
	clickCatcher:EnableMouse(true)
	OCS.SetScript(clickCatcher, "OnMouseDown", function()
		OCS.UI.closeFilterPanel()
		-- A click that landed on Rows or Skins opens that menu right away.
		OCS.UI.forwardMenuClick(filtersButton)
	end)
	-- Hover highlight for the buttons the catcher covers. Twenty times a second
	-- is more than enough and costs nothing measurable.
	OCS.SetScript(clickCatcher, "OnUpdate", function(self, elapsed)
		self.hoverAt = (self.hoverAt or 0) + (elapsed or 0)
		if self.hoverAt < 0.05 then
			return
		end
		self.hoverAt = 0
		OCS.UI.paintMenuHover()
	end)
	OCS.SetScript(clickCatcher, "OnHide", OCS.UI.clearMenuHover)
	clickCatcher:Hide()

	filterPanel = CreateFrame("Frame", "OCS_FilterPanel", UIParent)
	OCS.RegisterScaleFrame(filterPanel)
	filterPanel:SetWidth(210)
	filterPanel:SetHeight(438)
	filterPanel:SetFrameStrata("FULLSCREEN_DIALOG")
	filterPanel:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	filterPanel:EnableMouse(true)
	-- A click on the panel itself closes the activity menu, which now floats
	-- above the panel and would otherwise stay open behind your next click.
	OCS.SetScript(filterPanel, "OnMouseDown", function()
		if OCS.HideKindPicker then
			OCS.HideKindPicker()
		end
	end)

	-- Solid backing so nothing underneath shows through the panel.
	local solid = filterPanel:CreateTexture(nil, "BORDER")
	solid:SetTexture(0.04, 0.04, 0.05, 1)
	solid:SetPoint("TOPLEFT", 7, -7)
	solid:SetPoint("BOTTOMRIGHT", -7, 7)

	filterPanel:Hide()

	local title = filterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 16, -14)
	title:SetText("Show and alert on")

	local p = filterPanel
	-- Every widget is built once here and placed by LayoutFilterPanel. A
	-- filter a section cannot use is hidden and leaves no gap behind.
	p.items = {}
	local function item(f, sections, height, indent, when)
		table.insert(p.items, { frame = f, sections = sections,
			h = height or 24, x = indent or 14, when = when })
		return f
	end
	local GROUPS = { PVE = true, PVP = true }
	local EVERY = { PVE = true, PVP = true, TRADE = true }
	-- Guild has one list and no activities, so the word box is the only
	-- filter it shows.
	local ALL_TABS = { PVE = true, PVP = true, TRADE = true, GUILD = true }
	local PVE_ONLY = { PVE = true }

	-- A blank spacer. Headings sit tight above the widget they name, and the
	-- air between groups goes here, above the heading. A spacer hides with
	-- the same rules as the item it precedes, so no gap is left behind.
	local function gap(height, sections, when)
		local f = CreateFrame("Frame", nil, p)
		f:SetWidth(1)
		f:SetHeight(1)
		return item(f, sections, height, 0, when)
	end

	p.roleChecks = {}
	for i = 1, OCS.Len(OCS.ROLE_ORDER) do
		local role = OCS.ROLE_ORDER[i]
		p.roleChecks[role] = OCS.UI.makeCheck(p, OCS.RoleLabel(role), 14, 0, function(value)
			OCS_DB.filter.roles[role] = value
		end)
		item(p.roleChecks[role], GROUPS, 15, 13)
	end
	p.maxOnlyCheck = OCS.UI.makeCheck(p, "Level " .. (OCS.LEVEL_CAP or 60)
		.. " only", 14, 0, function(value)
		OCS_DB.filter.maxOnly = value
	end)

	gap(4, EVERY)
	p.intentLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	p.intentLabel:SetText("I am looking for")
	item(p.intentLabel, EVERY, 13, 14)

	p.intentChecks = {}
	local INTENTS = { "GROUP", "PLAYERS", "BOTH" }
	for i = 1, OCS.Len(INTENTS) do
		local value = INTENTS[i]
		p.intentChecks[value] = OCS.UI.makeCheck(p, value, 14, 0, function()
			OCS.SetFilterIntent(value)
			OCS.RefreshFilterPanel()
		end)
		item(p.intentChecks[value], EVERY, 15, 13)
	end

	gap(4, GROUPS)
	p.levelLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	p.levelLabel:SetText("Level from / to, 0 = any")
	item(p.levelLabel, GROUPS, 12, 14)

	p.minLevel = CreateFrame("EditBox", "OCS_MinLevel", p, "InputBoxTemplate")
	p.minLevel:SetWidth(38)
	p.minLevel:SetHeight(18)
	p.minLevel:SetAutoFocus(false)
	p.minLevel:SetNumeric(true)
	p.minLevel:SetMaxLetters(2)
	item(p.minLevel, GROUPS, 20, 18)

	p.maxLevel = CreateFrame("EditBox", "OCS_MaxLevel", p, "InputBoxTemplate")
	p.maxLevel:SetWidth(38)
	p.maxLevel:SetHeight(18)
	p.maxLevel:SetPoint("LEFT", p.minLevel, "RIGHT", 14, 0)
	p.maxLevel:SetAutoFocus(false)
	p.maxLevel:SetNumeric(true)
	p.maxLevel:SetMaxLetters(2)
	p.maxLevelFollows = true

	local function commitLevels()
		OCS_DB.filter.minLevel = tonumber(p.minLevel:GetText()) or 0
		OCS_DB.filter.maxLevel = tonumber(p.maxLevel:GetText()) or 0
		OCS.Refresh()
	end
	OCS.SetScript(p.minLevel, "OnEnterPressed", function(self) self:ClearFocus() end)
	OCS.SetScript(p.maxLevel, "OnEnterPressed", function(self) self:ClearFocus() end)
	OCS.SetScript(p.minLevel, "OnEditFocusLost", commitLevels)
	OCS.SetScript(p.maxLevel, "OnEditFocusLost", commitLevels)

	gap(4, ALL_TABS)
	p.wordLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	p.wordLabel:SetText("Message contains")
	item(p.wordLabel, ALL_TABS, 12, 14)

	p.word = CreateFrame("EditBox", "OCS_WordFilter", p, "InputBoxTemplate")
	p.word:SetWidth(150)
	p.word:SetHeight(18)
	p.word:SetAutoFocus(false)

	-- The list follows what you type. The rebuild is held back by a tenth of
	-- a second, so a fast typist sorts and redraws once, not once per letter.
	local WORD_DELAY = 0.1
	local wordTimer = CreateFrame("Frame", nil, p)
	wordTimer:Hide()
	wordTimer.left = 0
	OCS.SetScript(wordTimer, "OnUpdate", function(self, elapsed)
		self.left = self.left - (elapsed or 0)
		if self.left > 0 then
			return
		end
		self:Hide()
		OCS.Refresh()
	end)
	local function typedWord(self)
		-- RefreshFilterPanel writes the saved text back into the box. That is
		-- not the user typing, so it must not schedule anything.
		if p.wordSuppress then
			return
		end
		OCS_DB.filter.word = self:GetText() or ""
		wordTimer.left = WORD_DELAY
		wordTimer:Show()
	end
	OCS.SetScript(p.word, "OnTextChanged", typedWord)
	OCS.SetScript(p.word, "OnEnterPressed", function(self) self:ClearFocus() end)
	OCS.SetScript(p.word, "OnEditFocusLost", function(self)
		wordTimer:Hide()
		OCS_DB.filter.word = self:GetText() or ""
		OCS.Refresh()
	end)
	item(p.word, ALL_TABS, 20, 18)

	gap(4, PVE_ONLY)
	item(p.maxOnlyCheck, PVE_ONLY, 15, 13)

	gap(4, EVERY)
	p.kindLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	p.kindLabel:SetText("Activity")
	item(p.kindLabel, EVERY, 12, 14)

	-- One button that steps through the types present in this section.
	p.kindButton = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	p.kindButton:SetWidth(150)
	p.kindButton:SetHeight(20)
	p.kindButton:SetText("All activities")
	-- Smaller face than the other buttons: an activity plus a place name needs
	-- every pixel of the 150 the button has.
	p.kindButton:SetTextFontObject(GameFontNormalSmall)
	p.kindButton:SetHighlightFontObject(GameFontHighlightSmall)
	p.kindButton:SetDisabledFontObject(GameFontDisableSmall)

	-- kind holds a category such as CAT_DGN, or a single activity id for the
	-- ones that stand alone. target names one dungeon, raid or boss inside the
	-- category, or ALL for every one of them.
	local function pickKind(kind, target)
		OCS_DB.filter.kind = kind
		OCS_DB.filter.target = target or "ALL"
		OCS.RefreshFilterPanel()
		OCS.Refresh()
	end

	-- The Activity menu is built from plain frames instead of Blizzard's
	-- dropdown. That one cannot lay a long list out in two columns, gives no
	-- way to force a submenu to open upwards, and indents rows that carry a
	-- check mark while leaving the others flush left. All three are needed
	-- here, so the menu is ours.
	local MENU_ROW_H = 16
	local MENU_PAD = 10
	local MENU_BACKDROP = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 },
	}

	local kindPanel, placePanel, catcher

	-- SetBackdrop on its own left the menu see through on this client, so the
	-- backdrop colours are set by hand and a solid texture sits under the rows.
	local function skinPanel(frame)
		frame:SetBackdrop(MENU_BACKDROP)
		frame:SetBackdropColor(0.06, 0.06, 0.08, 1)
		frame:SetBackdropBorderColor(0.5, 0.5, 0.56, 1)
		local solid = frame:CreateTexture(nil, "BACKGROUND")
		solid:SetTexture(0.05, 0.05, 0.06, 1)
		solid:SetPoint("TOPLEFT", 4, -4)
		solid:SetPoint("BOTTOMRIGHT", -4, 4)
	end

	local function hidePicker()
		if placePanel then placePanel:Hide() end
		if kindPanel then kindPanel:Hide() end
		if catcher then catcher:Hide() end
	end
	OCS.HideKindPicker = hidePicker

	-- Rows are made once and reused, so opening the menu costs nothing after
	-- the first time.
	local function panelRow(panel, index)
		panel.rows = panel.rows or {}
		local row = panel.rows[index]
		if not row then
			row = CreateFrame("Button", nil, panel)
			row:SetHeight(MENU_ROW_H)
			row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			local hl = row:GetHighlightTexture()
			if hl then hl:SetBlendMode("ADD") end
			row.text = row:CreateFontString(nil, "OVERLAY",
				"GameFontHighlightSmall")
			row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
			row.text:SetJustifyH("LEFT")
			row.arrow = row:CreateFontString(nil, "OVERLAY",
				"GameFontHighlightSmall")
			row.arrow:SetPoint("RIGHT", row, "RIGHT", -2, 0)
			OCS.SetScript(row, "OnEnter", function(self)
				if self.onEnter then self.onEnter() end
			end)
			OCS.SetScript(row, "OnClick", function(self)
				if self.onClick then self.onClick() end
			end)
			panel.rows[index] = row
		end
		return row
	end

	-- Fills a panel with entries over the given number of equally tall columns.
	-- The panel keeps its bottom edge, so it always grows upward.
	local function fillPanel(panel, entries, columns, colWidth)
		local total = OCS.Len(entries)
		local perCol = math.max(1, math.ceil(total / columns))
		local used = math.max(1, math.ceil(total / perCol))
		panel:SetWidth(used * colWidth + MENU_PAD * 2)
		panel:SetHeight(perCol * MENU_ROW_H + MENU_PAD * 2)
		for i = 1, total do
			local row = panelRow(panel, i)
			local col = math.floor((i - 1) / perCol)
			local line = math.mod(i - 1, perCol)
			row:SetWidth(colWidth)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", panel, "TOPLEFT",
				MENU_PAD + col * colWidth, -(MENU_PAD + line * MENU_ROW_H))
			row.text:SetText(entries[i].text or "")
			row.arrow:SetText(entries[i].arrow or "")
			row.onClick = entries[i].onClick
			row.onEnter = entries[i].onEnter
			-- A note row is a caption, not a choice, so it takes no mouse.
			row:EnableMouse(not entries[i].note)
			row:Show()
		end
		for i = total + 1, OCS.Len(panel.rows or {}) do
			panel.rows[i]:Hide()
		end
	end

	local function mark(text, current)
		if current then
			return "|cff40d0ff" .. text .. "|r"
		end
		return text
	end

	local function ensurePanels()
		if kindPanel then
			return
		end
		-- A full screen catcher behind the menu closes it on any click outside.
		catcher = CreateFrame("Frame", nil, UIParent)
		catcher:SetAllPoints(UIParent)
		catcher:EnableMouse(true)
		catcher:SetFrameStrata("FULLSCREEN")
		catcher:Hide()
		OCS.SetScript(catcher, "OnMouseDown", function() hidePicker() end)

		kindPanel = CreateFrame("Frame", "OCS_KindPicker", UIParent)
		OCS.RegisterScaleFrame(kindPanel)
		skinPanel(kindPanel)
		-- Above the filter panel, which sits in FULLSCREEN_DIALOG itself. In the
		-- same strata the menu was drawn behind the panel, which read as a menu
		-- with no background at all.
		kindPanel:SetFrameStrata("TOOLTIP")
		kindPanel:SetFrameLevel(20)
		kindPanel:EnableMouse(true)
		kindPanel:Hide()
		OCS.SetScript(kindPanel, "OnHide", function()
			if placePanel then placePanel:Hide() end
			if catcher then catcher:Hide() end
		end)
		table.insert(UISpecialFrames, "OCS_KindPicker")

		placePanel = CreateFrame("Frame", nil, kindPanel)
		skinPanel(placePanel)
		placePanel:SetFrameStrata("TOOLTIP")
		placePanel:SetFrameLevel(kindPanel:GetFrameLevel() + 10)
		placePanel:EnableMouse(true)
		placePanel:Hide()
	end

	local function kindCounts()
		return (OCS.KindCounts and OCS.KindCounts(OCS.GetSection())) or {}
	end

	local function countIn(counts, kind)
		for i = 1, OCS.Len(counts) do
			if counts[i].kind == kind then
				return counts[i].count
			end
		end
		return 0
	end

	-- Second level: the places inside one category, Any at the top, then the
	-- activities that stand on their own such as Random Dungeon, then the list.
	-- Anything longer than fourteen rows goes into two columns of equal height.
	local function openPlaces(cat)
		ensurePanels()
		local f = (OCS_DB and OCS_DB.filter) or {}
		local current, target = f.kind or "ALL", f.target or "ALL"
		local counts = kindCounts()
		-- No Any row here. Clicking Dungeon, Raid or World Boss itself takes
		-- the whole category, which is what Any used to do.
		local entries = {}
		if cat.lead then
			for i = 1, OCS.Len(cat.lead) do
				local lead = cat.lead[i]
				table.insert(entries, {
					text = mark(lead.label .. "  (" .. countIn(counts, lead.value)
						.. ")", current == cat.id and target == lead.value),
					onClick = function()
						pickKind(cat.id, lead.value)
						hidePicker()
					end,
				})
			end
		end
		local list = (OCS.TargetsForKind and OCS.TargetsForKind(cat.targetKind))
			or {}
		-- How many stored posts name each place, so every row carries a count
		-- the way the first level does.
		local named = (OCS.TargetCounts
			and OCS.TargetCounts(OCS.GetSection(), cat)) or {}
		for i = 1, OCS.Len(list) do
			local name = list[i]
			table.insert(entries, {
				text = mark(name .. "  (" .. (named[name] or 0) .. ")",
					current == cat.id and target == name),
				onClick = function()
					pickKind(cat.id, name)
					hidePicker()
				end,
			})
		end
		fillPanel(placePanel, entries, (OCS.Len(entries) > 14) and 2 or 1, 196)
		placePanel:ClearAllPoints()
		placePanel:SetPoint("TOPLEFT", kindPanel, "TOPRIGHT", -4, 0)
		placePanel:Show()
	end

	-- First level: All activities, then Dungeon, Raid and World Boss with an
	-- arrow, then everything that has no places under it. Every row is flush
	-- left, and the panel hangs from the button, so it opens downwards and the
	-- second level opens alongside it.
	local function openKinds()
		ensurePanels()
		CloseDropDownMenus()
		local f = (OCS_DB and OCS_DB.filter) or {}
		local current = f.kind or "ALL"
		local target = f.target or "ALL"
		local counts = kindCounts()
		local entries = {}
		table.insert(entries, {
			text = mark("All activities", current == "ALL"),
			onClick = function()
				pickKind("ALL", "ALL")
				hidePicker()
			end,
			onEnter = function()
				if placePanel then placePanel:Hide() end
			end,
		})
		local grouped = {}
		local cats = OCS.KIND_CATEGORIES or {}
		for c = 1, OCS.Len(cats) do
			local cat = cats[c]
			local total, any = 0, false
			for i = 1, OCS.Len(counts) do
				if cat.kinds[counts[i].kind] then
					any = true
					grouped[counts[i].kind] = true
					total = total + counts[i].count
				end
			end
			if any then
				table.insert(entries, {
					text = mark(cat.label .. "  (" .. total .. ")",
						current == cat.id and target == "ALL"),
					arrow = ">",
					-- Hover shows the places, click takes all of them.
					onEnter = function() openPlaces(cat) end,
					onClick = function()
						pickKind(cat.id, "ALL")
						hidePicker()
					end,
				})
			end
		end
		for i = 1, OCS.Len(counts) do
			local c = counts[i]
			if not grouped[c.kind] then
				table.insert(entries, {
					text = mark(c.label .. "  (" .. c.count .. ")",
						current == c.kind),
					onClick = function()
						pickKind(c.kind, "ALL")
						hidePicker()
					end,
					onEnter = function()
						if placePanel then placePanel:Hide() end
					end,
				})
			end
		end
		fillPanel(kindPanel, entries, 1, 156)
		kindPanel:ClearAllPoints()
		kindPanel:SetPoint("TOPLEFT", p.kindButton, "BOTTOMLEFT", 0, -2)
		kindPanel:Show()
		catcher:Show()
	end

	p.kindButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	OCS.SetScript(p.kindButton, "OnClick", function(self, button)
		if button == "RightButton" then
			hidePicker()
			pickKind("ALL", "ALL")
			return
		end
		if kindPanel and kindPanel:IsShown() then
			hidePicker()
		else
			openKinds()
		end
	end)
	OCS.HookScript(p, "OnHide", hidePicker)
	item(p.kindButton, EVERY, 21, 18)

	gap(4, GROUPS, OCS.PackHasClasses)
	p.classLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	p.classLabel:SetText("Class")
	item(p.classLabel, GROUPS, 12, 14, OCS.PackHasClasses)

	p.classButton = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	p.classButton:SetWidth(150)
	p.classButton:SetHeight(20)
	p.classButton:SetText("All classes")
	p.classMenu = CreateFrame("Frame", "OCSClassMenu", UIParent, "UIDropDownMenuTemplate")
	p.classMenu.displayMode = "MENU"

	local function pickClass(value)
		OCS_DB.filter.class = value
		OCS.RefreshFilterPanel()
		OCS.Refresh()
	end

	local function initClassMenu(self, level)
		local current = (OCS_DB and OCS_DB.filter and OCS_DB.filter.class) or "ALL"
		local info = {}
		info.text = "All classes"
		info.checked = (current == "ALL")
		info.func = function() pickClass("ALL") end
		UIDropDownMenu_AddButton(info, level)
		local list = OCS.CLASSES or {}
		for i = 1, OCS.Len(list) do
			local name = list[i]
			local entry = {}
			entry.text = name
			entry.checked = (current == name)
			entry.func = function() pickClass(name) end
			UIDropDownMenu_AddButton(entry, level)
		end
	end

	OCS.InitializeMenu(p.classMenu, initClassMenu, "MENU")

	p.classButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	OCS.SetScript(p.classButton, "OnClick", function(self, button)
		if button == "RightButton" then
			pickClass("ALL")
			return
		end
		if OCS.HideKindPicker then
			OCS.HideKindPicker()
		end
		OCS.ToggleMenu(1, nil, p.classMenu, self, 0, 0)
	end)
	item(p.classButton, GROUPS, 21, 18, OCS.PackHasClasses)

	p.resetButton = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	p.resetButton:SetWidth(80)
	p.resetButton:SetHeight(20)
	p.resetButton:SetText("Reset")
	OCS.SetScript(p.resetButton, "OnClick", function()
		OCS_DB.filter.roles = { tank = false, heal = false, damage = false,
			}

		OCS_DB.filter.maxOnly = false
		OCS_DB.filter.class = "ALL"
		OCS_DB.filter.minLevel = 0
		OCS_DB.filter.maxLevel = 0

		OCS_DB.filter.word = ""
		OCS_DB.filter.intent = "BOTH"
		OCS_DB.filter.kind = "ALL"
		OCS_DB.filter.target = "ALL"
		OCS.RefreshFilterPanel()
		OCS.Refresh()
	end)

	local close = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	close:SetWidth(80)
	close:SetHeight(20)
	close:SetPoint("LEFT", p.resetButton, "RIGHT", 8, 0)
	close:SetText("Close")
	OCS.SetScript(close, "OnClick", OCS.UI.closeFilterPanel)
end

-- Wording changes with the section, because a trade line has no group.
OCS.UI.INTENT_TEXT = {
	PVE = { title = "I am looking for", GROUP = "A group to join",
		PLAYERS = "Players to join me", BOTH = "Both" },
	PVP = { title = "I am looking for", GROUP = "A group to join",
		PLAYERS = "Players to join me", BOTH = "Both" },
	TRADE = { title = "I want to see", GROUP = "Players selling",
		PLAYERS = "Players buying", BOTH = "Both" },
}

-- Places the widgets the open section uses, top down, and sizes the panel to
-- what it placed. Nothing is left floating in a gap.
function OCS.LayoutFilterPanel()
	if not filterPanel or not filterPanel.items then
		return
	end
	local section = (OCS.GetSection and OCS.GetSection()) or "PVE"
	-- Checkbox rows sit three pixels closer together than they did, and the
	-- title gets those pixels back so the first checkbox does not hang off it.
	local y = -28
	for i = 1, OCS.Len(filterPanel.items) do
		local it = filterPanel.items[i]
		if it.sections[section] and (not it.when or it.when()) then
			it.frame:ClearAllPoints()
			it.frame:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", it.x, y)
			it.frame:Show()
			y = y - it.h
		else
			it.frame:Hide()
		end
	end
	if filterPanel.maxLevel then
		if filterPanel.minLevel:IsShown() then
			filterPanel.maxLevel:Show()
		else
			filterPanel.maxLevel:Hide()
		end
	end
	y = y - 8
	filterPanel.resetButton:ClearAllPoints()
	filterPanel.resetButton:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 20, y)
	-- Room for the button itself plus a margin, so Reset and Close no longer
	-- sit on the bottom edge of the frame.
	filterPanel:SetHeight(-y + 34)
end

function OCS.RefreshFilterPanel()
	if not filterPanel then
		return
	end
	local f = OCS_DB.filter
	local section = (OCS.GetSection and OCS.GetSection()) or "PVE"
	for i = 1, OCS.Len(OCS.ROLE_ORDER) do
		local role = OCS.ROLE_ORDER[i]
		filterPanel.roleChecks[role]:SetChecked(f.roles[role] and true or false)
	end
	filterPanel.maxOnlyCheck:SetChecked(f.maxOnly and true or false)
	-- The cap follows the realm, so the caption is rebuilt on every refresh.
	if filterPanel.maxOnlyCheck.label then
		filterPanel.maxOnlyCheck.label:SetText("Level "
			.. (OCS.LEVEL_CAP or 60) .. " only")
	end

	local words = OCS.UI.INTENT_TEXT[section] or OCS.UI.INTENT_TEXT.PVE
	filterPanel.intentLabel:SetText(words.title)
	local intent = f.intent or "BOTH"
	for value, check in pairs(filterPanel.intentChecks) do
		check:SetChecked(value == intent)
		if check.label then
			check.label:SetText(words[value] or value)
		end
	end

	filterPanel.minLevel:SetText((f.minLevel or 0) > 0 and tostring(f.minLevel) or "")
	filterPanel.maxLevel:SetText((f.maxLevel or 0) > 0 and tostring(f.maxLevel) or "")
	filterPanel.wordSuppress = true
	filterPanel.word:SetText(f.word or "")
	filterPanel.wordSuppress = false
	local kindText = (OCS.KindFilterText and OCS.KindFilterText(f))
		or "All activities"
	-- The button is 150 wide. A long name is cut off with two dots rather than
	-- shortened into something unrecognisable.
	if OCS.Len(kindText) > 21 then
		kindText = string.sub(kindText, 1, 19) .. ".."
	end
	filterPanel.kindButton:SetText(kindText)
	local class = f.class or "ALL"
	filterPanel.classButton:SetText(class == "ALL" and "All classes" or class)
	OCS.LayoutFilterPanel()
end

function OCS.UI.toggleFilterPanel()
	OCS.UI.closeViewMenu()
	if not filterPanel then
		OCS.UI.createFilterPanel()
	end
	if filterPanel:IsShown() then
		OCS.UI.closeFilterPanel()
		return
	end
	-- Always anchored to the button, never to the cursor.
	filterPanel:ClearAllPoints()
	filterPanel:SetPoint("TOPRIGHT", filtersButton, "BOTTOMRIGHT", 0, -4)
	OCS.RefreshFilterPanel()
	clickCatcher:Show()
	filterPanel:Show()
end

-- Style ---------------------------------------------------------------------

function OCS.ApplyStyle()
	if not frame then
		return
	end
	local s = OCS.UI.skin()
	frame:SetBackdrop(s.backdrop)
	if s.bgColor then
		frame:SetBackdropColor(s.bgColor[1], s.bgColor[2], s.bgColor[3], s.bgColor[4])
	end
	if s.borderColor then
		frame:SetBackdropBorderColor(s.borderColor[1], s.borderColor[2], s.borderColor[3], s.borderColor[4])
	end
	titleText:SetVertexColor(s.titleColor[1], s.titleColor[2], s.titleColor[3])
	for i = 1, OCS.Len(headers) do
		headers[i].label:SetTextColor(s.headerColor[1], s.headerColor[2], s.headerColor[3])
	end
	OCS.UI.layout()
	OCS.Refresh()
	if OCS.MiniApplyStyle then
		OCS.MiniApplyStyle()
	end
end

-- Grow the reusable row pool only when more rows fit the window.
function OCS.UI.ensureRows(count)
	for i = OCS.Len(rows) + 1, count do
		local row = CreateFrame("Button", nil, tableArea)
		row:SetHeight(OCS.UI.ROW_H)
		row:SetPoint("TOPLEFT", tableArea, "TOPLEFT", 0, -(i - 1) * OCS.UI.ROW_H)
		row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints(row)
		row.bg:SetTexture(1, 1, 1, 0.05)
		row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
		row.highlight:SetAllPoints(row)
		row.highlight:SetTexture(1, 1, 1, 0.14)
		row.cells = {}
		for j = 1, OCS.Len(OCS.UI.COLS) do
			local cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			cell:SetHeight(OCS.UI.ROW_H)
			cell:SetJustifyH("LEFT")
			cell:SetJustifyV("MIDDLE")
			cell:SetNonSpaceWrap(false)
			row.cells[OCS.UI.COLS[j].key] = cell
		end
		OCS.SetScript(row, "OnClick", OCS.UI.onRowClick)
		OCS.SetScript(row, "OnEnter", function(self)
			if not self.data then
				return
			end
			OCS.GetTooltip():SetOwner(self, "ANCHOR_TOPLEFT")
			OCS.GetTooltip():AddLine(self.data.name or "?", 1, 0.82, 0)
			OCS.GetTooltip():AddLine(self.data.message or self.data.rawMessage or "(no message stored)", 1, 1, 1, true)
			OCS.GetTooltip():AddLine(" ")
			if self.data.size then
				OCS.GetTooltip():AddLine("Group size: " .. self.data.size .. " players", 0.6, 0.6, 0.6)
			end
			if self.data.wanted then
				OCS.GetTooltip():AddLine("Asking for: " .. self.data.wanted, 0.6, 0.6, 0.6)
			end
			OCS.GetTooltip():AddLine("Channel: " .. tostring(self.data.channel or "?"), 0.6, 0.6, 0.6)
			local preview = OCS.BuildWhisper and OCS.BuildWhisper(self.data, OCS.GetMode())
			if preview and preview ~= "" then
				OCS.GetTooltip():AddLine("W sends: " .. preview, 0.45, 0.7, 1, true)
			else
				OCS.GetTooltip():AddLine("No whisper line for this tab yet, set one with the Whisp Templates button", 0.6, 0.6, 0.6, true)
			end
			if self.data.whispered then
				OCS.GetTooltip():AddLine("Whispered at " .. date("%H:%M:%S", self.data.whispered), 0.6, 0.6, 0.6)
			end
			OCS.GetTooltip():AddLine("Left-click a value to edit it, right-click the row for actions", 0.6, 0.6, 0.6, true)
			OCS.GetTooltip():Show()
		end)
		OCS.SetScript(row, "OnLeave", function() OCS.GetTooltip():Hide() end)
		rows[i] = row
	end
end

-- Window --------------------------------------------------------------------

OCS.UI.DEFAULT_W, OCS.UI.DEFAULT_H = 780, 460
OCS.UI.MIN_W, OCS.UI.MIN_H = 680, 260

OCS.UI.scalePercent = OCS.ScalePercent

function OCS.UI.updateTitleScale()
	if not titleHolder then return end
	-- Both wordmark layers inherit main scale like the control artwork.
	-- The shadow uses the stock MasterFont offset, independent of title size.
	titleHolder:ClearAllPoints()
	titleHolder:SetPoint("TOPLEFT", frame, "TOPLEFT", OCS.EdgeMargin() * OCS.UI.TITLE_INDENT, -OCS.UI.TITLE_TOP)
	titleHolder:SetWidth(OCS.UI.TITLE_W)
	titleHolder:SetHeight(OCS.UI.TITLE_H)
	titleHolder:SetFrameLevel(frame:GetFrameLevel() + 1)
	titleShadow:SetWidth(OCS.UI.TITLE_W)
	titleShadow:SetHeight(OCS.UI.TITLE_H)
	-- Leave room for the window controls; narrow windows can wrap the caption.
	titleCaption:SetWidth(math.max(100, frame:GetWidth()
		- OCS.EdgeMargin() * OCS.UI.TITLE_INDENT - OCS.UI.TITLE_W - 12 - 104))
end

function OCS.UI.showTitleHelp()
	if not titleHelp then
		titleHelp = CreateFrame("Frame", "OctoScannerTitleHelp", UIParent)
		OCS.RegisterScaleFrame(titleHelp)
		titleHelp:SetFrameStrata("TOOLTIP")
		titleHelp:SetClampedToScreen(true)
		titleHelp:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true,
			tileSize = 16, edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
		titleHelp:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
		titleHelp.lines = {}
		local text = {
			"Use Filters to narrow results and set alerts for matching messages.",
			"Click >> in the W column to send messages using whisper templates.",
		}
		for i = 1, OCS.Len(text) do
			local line = titleHelp:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			line:SetJustifyH("LEFT")
			line:SetNonSpaceWrap(false)
			line:SetText(text[i])
			titleHelp.lines[i] = line
		end
	end
	-- Size to the longest complete sentence; native GameTooltip wraps long
	-- AddLine strings even though each sentence should occupy a single line.
	local width, lineHeight = 0, 16
	for i = 1, OCS.Len(titleHelp.lines) do
		local line = titleHelp.lines[i]
		line:SetWidth(0)
		width = math.max(width, math.ceil(line:GetStringWidth()) + 4)
		local _, size = line:GetFont()
		lineHeight = math.max(lineHeight, (size or 12) + 4)
	end
	for i = 1, OCS.Len(titleHelp.lines) do
		local line = titleHelp.lines[i]
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", titleHelp, "TOPLEFT", 12, -10 - (i - 1) * lineHeight)
		line:SetWidth(width)
		line:SetHeight(lineHeight)
	end
	titleHelp:SetWidth(width + 24)
	titleHelp:SetHeight(20 + OCS.Len(titleHelp.lines) * lineHeight)
	titleHelp:SetScale(OCS.UIScale())
	titleHelp:ClearAllPoints()
	titleHelp:SetPoint("BOTTOMLEFT", titleHolder, "TOPLEFT", 0, 6)
	titleHelp:Show()
end

local function hideTitleHelp()
	if titleHelp then titleHelp:Hide() end
end

function OCS.UI.screenSize()
	local w = UIParent:GetWidth() or OCS.UI.DEFAULT_W
	local h = UIParent:GetHeight() or OCS.UI.DEFAULT_H
	-- Parent dimensions and frame dimensions use different units when scaled.
	local scale = frame and frame:GetScale() or 1
	return w / scale, h / scale
end

-- A saved size is never trusted. A bad drag, a resolution change or an older
-- build can leave a window wider than the screen, and without this the only
-- way back was to wipe the saved variables.
function OCS.UI.clampSize(w, h)
	local sw, sh = OCS.UI.screenSize()
	w = tonumber(w) or OCS.UI.DEFAULT_W
	h = tonumber(h) or OCS.UI.DEFAULT_H
	if w < OCS.UI.MIN_W then w = OCS.UI.MIN_W end
	if h < OCS.UI.MIN_H then h = OCS.UI.MIN_H end
	if w > sw then w = sw end
	if h > sh then h = sh end
	return w, h
end

function OCS.UI.savePosition()
	local x, y = frame:GetLeft(), frame:GetBottom()
	if x and y then
		OCS_DB.window.x = x
		OCS_DB.window.y = y
		OCS_DB.window.hasPos = true
	end
	OCS_DB.window.w = frame:GetWidth()
	OCS_DB.window.h = frame:GetHeight()
end

function OCS.SetWindowScale(value)
	if not OCS_DB or not OCS_DB.window then return end
	local percent = OCS.UI.scalePercent(value)
	OCS_DB.window.scale = percent
	if not frame then OCS.RefreshUIScale(); return end
	OCS.UI.closeFilterPanel()
	OCS.UI.closeViewMenu()
	local oldScale = frame:GetEffectiveScale()
	local left, top = frame:GetLeft(), frame:GetTop()
	frame:SetScale(percent / 100)
	local sw, sh = OCS.UI.screenSize()
	frame:SetMaxResize(sw, sh)
	local w, h = OCS.UI.clampSize(frame:GetWidth(), frame:GetHeight())
	frame:SetWidth(w)
	frame:SetHeight(h)
	if left and top then
		-- Keep the top left in the same screen position. Clamp when enlarging
		-- near an edge so the controls and resize grip remain reachable.
		local ratio = oldScale / frame:GetEffectiveScale()
		left = math.max(0, math.min(sw - w, left * ratio))
		top = math.max(h, math.min(sh, top * ratio))
		local bottom = top - h
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
		-- Use the known coordinates: frame getters can lag a layout pass.
		OCS_DB.window.x, OCS_DB.window.y = left, bottom
		OCS_DB.window.hasPos = true
	end
	OCS_DB.window.w, OCS_DB.window.h = w, h
	OCS.RefreshUIScale()
	OCS.UI.updateTitleScale()
	OCS.UI.layout()
	OCS.Refresh()
end

-- A window held by its centre grows in both directions while it is sized, so
-- it has to hang from its bottom left corner before any drag starts. Doing
-- that rewrite in the same moment sizing began is what threw the window into
-- the screen corner: the client had not recalculated the rect yet, so the new
-- anchor was resolved against a stale one. It now happens only when nothing
-- else is going on, which is on show and after a move.
function OCS.UI.normalizeAnchor()
	if not frame then
		return
	end
	if frame:GetNumPoints() == 1 then
		local point, _, relPoint = frame:GetPoint(1)
		if point == "BOTTOMLEFT" and relPoint == "BOTTOMLEFT" then
			return
		end
	end
	local left, bottom = frame:GetLeft(), frame:GetBottom()
	if not left or not bottom then
		return
	end
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
end

function OCS.UI.createWindow()
	frame = CreateFrame("Frame", "OCS_Window", UIParent)
	OCS_DB.window.scale = OCS.UI.scalePercent(OCS_DB.window.scale)
	frame:SetScale(OCS_DB.window.scale / 100)
	local startW, startH = OCS.UI.clampSize(OCS_DB.window.w, OCS_DB.window.h)
	frame:SetWidth(startW)
	frame:SetHeight(startH)
	OCS_DB.window.w, OCS_DB.window.h = startW, startH
	if OCS_DB.window.hasPos then
		frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", OCS_DB.window.x, OCS_DB.window.y)
	else
		frame:SetPoint("CENTER")
	end
	frame:SetFrameStrata("MEDIUM")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetMinResize(OCS.UI.MIN_W, OCS.UI.MIN_H)
	-- The client happily sizes a frame past the screen edge, which is how the
	-- window ended up twice as wide as the monitor with the grip out of reach.
	frame:SetMaxResize(OCS.UI.screenSize())
	frame:RegisterForDrag("LeftButton")
	OCS.SetScript(frame, "OnDragStart", function(self) self:StartMoving() end)
	OCS.SetScript(frame, "OnDragStop", function(self)
		self:StopMovingOrSizing()
		OCS.UI.normalizeAnchor()
		OCS.UI.savePosition()
	end)
	frame:EnableMouseWheel(true)
	OCS.SetScript(frame, "OnMouseWheel", function(self, delta)
		scrollBar:SetValue(offset - (delta or 0) * 3)
	end)
	table.insert(UISpecialFrames, "OCS_Window")

	titleHolder = CreateFrame("Frame", "OctoScannerTitleFrame", frame)
	titleHolder:SetFrameStrata("MEDIUM")
	titleHolder:SetWidth(1)
	titleHolder:SetHeight(1)
	titleShadow = titleHolder:CreateTexture("OctoScannerTitleShadow", "ARTWORK")
	titleShadow:SetTexture("Interface\\AddOns\\OctoScanner\\Textures\\OctoScannerTitle.tga")
	titleShadow:SetTexCoord(0, 394 / 512, 0, 50 / 64)
	titleShadow:SetVertexColor(0, 0, 0, 1)
	titleShadow:SetPoint("TOPLEFT", titleHolder, "TOPLEFT", 1, -1)
	titleText = titleHolder:CreateTexture("OctoScannerTitle", "OVERLAY")
	titleText:SetTexture("Interface\\AddOns\\OctoScanner\\Textures\\OctoScannerTitle.tga")
	titleText:SetTexCoord(0, 394 / 512, 0, 50 / 64)
	titleText:SetAllPoints(titleHolder)
	titleCaption = titleHolder:CreateFontString("OctoScannerCaption", "OVERLAY", "GameFontNormalSmall")
	titleCaption:SetPoint("BOTTOMLEFT", titleHolder, "BOTTOMRIGHT", 12, 0)
	titleCaption:SetHeight(24)
	titleCaption:SetJustifyH("LEFT")
	titleCaption:SetJustifyV("BOTTOM")
	titleCaption:SetNonSpaceWrap(false)
	titleCaption:SetTextColor(0.55, 0.55, 0.55)
	titleCaption:SetText("Find groups, PvP, trades and guilds - all parsed from messages in your joined chat channels.")
	OCS.UI.edgeAnchor(function(m)
		OCS.UI.updateTitleScale()
	end)
	titleHolder:EnableMouse(true)
	titleHolder:RegisterForDrag("LeftButton")
	OCS.SetScript(titleHolder, "OnEnter", OCS.UI.showTitleHelp)
	OCS.SetScript(titleHolder, "OnLeave", hideTitleHelp)
	OCS.SetScript(titleHolder, "OnHide", hideTitleHelp)
	OCS.SetScript(titleHolder, "OnDragStart", function()
		hideTitleHelp()
		frame:StartMoving()
	end)
	OCS.SetScript(titleHolder, "OnDragStop", function()
		frame:StopMovingOrSizing()
		OCS.UI.normalizeAnchor()
		OCS.UI.savePosition()
	end)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -8, -8)
	OCS.SetScript(close, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Close the window")
		OCS.GetTooltip():AddLine("Scanning carries on in the background.",
			1, 1, 1, true)
		OCS.GetTooltip():AddLine("/ocs opens it again.", 0.7, 0.7, 0.7, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(close, "OnLeave", function() OCS.GetTooltip():Hide() end)

	-- Minimize: hand over to the mini feed. The mini window carries the
	-- same pair of buttons and switches back.
	-- Built by Mini.lua so both windows carry the identical control.
	if OCS.MiniModeButton then
		local mini = OCS.MiniModeButton(frame, close, "down", "Mini feed",
			"Swap this window for a small feed of the alerted posts:"
				.. " name, W and message.",
			function()
				OCS.MiniMode(true)
			end)
		-- Pop out. Same feed, but this window stays where it is.
		OCS.MiniModeButton(frame, mini, "out", "Pop out the mini feed",
			"Opens the small feed beside this window instead of"
				.. " replacing it.",
			function()
				if OCS.MiniIsShown and OCS.MiniIsShown() then
					OCS.MiniHide()
				else
					OCS.MiniPopOut()
				end
			end)
	end

	-- Section row: PvE, PvP, Trade. Sits above the tab row.
	local sectionButtons = {}
	local sprev
	for i = 1, OCS.Len(OCS.SECTIONS) do
		local s = OCS.SECTIONS[i]
		local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		-- Same size as a tab, so the two left rows read as one block.
		b:SetWidth(92)
		b:SetHeight(22)
		if sprev then
			b:SetPoint("LEFT", sprev, "RIGHT", 6, 0)
		else
			OCS.UI.edgeAnchor(function(m)
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", m, -OCS.UI.ROW_TOP)
			end)
		end
		b:SetText(s.label)
		OCS.SetScript(b, "OnClick", function()
			offset = 0
			OCS.SetSection(s.id)
		end)
		sectionButtons[s.id] = b
		sprev = b
	end

	-- Tabs. Every bucket gets a button; only the active section's show.
	for i = 1, OCS.Len(OCS.BUCKETS) do
		local key = OCS.BUCKETS[i]
		local tab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		tab:SetWidth(92)
		tab:SetHeight(22)
		tab:SetText(OCS.BUCKET_LABEL[key] or key)
		OCS.SetScript(tab, "OnClick", function()
			offset = 0
			OCS.SetMode(key)
		end)
		tabs[key] = tab
	end

	local function layoutTabs()
		local section = OCS.GetSection()
		local prev
		for i = 1, OCS.Len(OCS.BUCKETS) do
			local key = OCS.BUCKETS[i]
			local tab = tabs[key]
			tab:ClearAllPoints()
			if OCS.BUCKET_SECTION[key] == section then
				if prev then
					tab:SetPoint("LEFT", prev, "RIGHT", 6, 0)
				else
					tab:SetPoint("TOPLEFT", OCS.EdgeMargin(), -OCS.UI.ROW_BOTTOM)
				end
				tab:Show()
				prev = tab
			else
				tab:Hide()
			end
		end
		for i = 1, OCS.Len(OCS.SECTIONS) do
			local s = OCS.SECTIONS[i]
			local b = sectionButtons[s.id]
			if s.id == section then
				b:LockHighlight()
			else
				b:UnlockHighlight()
			end
		end
	end
	frame.layoutTabs = layoutTabs

	alertsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	alertsButton:SetWidth(96)
	alertsButton:SetHeight(22)
	alertsButton:SetText("Alerts: OFF")
	alertsButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	OCS.SetScript(alertsButton, "OnClick", function(self, button)
		if button == "RightButton" then
			-- Same switch as the minimap button: unlock the popup, drag it
			-- where you want it, right-click again to lock it.
			if OCS.ToggleAlertLock then
				OCS.ToggleAlertLock()
			end
			return
		end
		OCS_DB.alert.enabled = not OCS_DB.alert.enabled
		OCS.Print("Alerts " .. (OCS_DB.alert.enabled and "on" or "off"))
		OCS.Refresh()
	end)
	OCS.SetScript(alertsButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Alerts")
		OCS.GetTooltip():AddLine("Turns alerts on or off.", 1, 1, 1, true)
		OCS.GetTooltip():AddLine("Right-click to move the popup window.",
			0.7, 0.7, 0.7, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(alertsButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	local function initScaleMenu(self, level)
		local current = OCS_DB.window.scale
		for percent = 100, 50, -5 do
			local selected = percent
			local info = {}
			info.text = tostring(selected) .. "%"
			info.checked = (current == selected)
			info.func = function() OCS.SetWindowScale(selected) end
			UIDropDownMenu_AddButton(info, level)
		end
	end
	scaleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	scaleButton:SetWidth(50)
	scaleButton:SetHeight(22)
	scaleButton:SetText("Scale")
	OCS.SetScript(scaleButton, "OnClick", function(self)
		if not scaleMenu then
			scaleMenu = CreateFrame("Frame", "OCSScaleMenu", UIParent, "UIDropDownMenuTemplate")
		end
		OCS.UI.toggleViewMenu(self, scaleMenu, initScaleMenu)
	end)
	OCS.SetScript(scaleButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Scale: " .. tostring(OCS_DB.window.scale) .. "%")
		OCS.GetTooltip():AddLine("Addon size: 100% to 50% in 5% steps.", 1, 1, 1, false)
		OCS.GetTooltip():AddLine("Saved for this character. /ocs reset restores 100%.", 0.7, 0.7, 0.7, false)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(scaleButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	-- Speaker. The popup is always shown when alerts are on. This only decides
	-- whether the popup is silent or comes with a sound.
	soundButton = CreateFrame("Button", nil, frame)
	soundButton:SetWidth(22)
	soundButton:SetHeight(22)
	soundButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	soundButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Bell_01")
	local speaker = soundButton:GetNormalTexture()
	if speaker then
		speaker:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		-- 87 percent of the button, centred. 22 x 0.87 is 19.1, so the inset is
		-- 1.4 on every side.
		speaker:ClearAllPoints()
		speaker:SetPoint("TOPLEFT", soundButton, "TOPLEFT", 1.4, -1.4)
		speaker:SetPoint("BOTTOMRIGHT", soundButton, "BOTTOMRIGHT", -1.4, 1.4)
	end
	-- VOICECHAT-ON is dropped. The arcs sit off centre inside their own file and
	-- fill only part of it, so they cannot be lined up with the bell without
	-- guessing at texture coordinates. Sound on is a bright bell instead.
	soundButton.cross = soundButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	soundButton.cross:SetText("x")
	soundButton.cross:SetTextColor(1, 0.2, 0.2)
	soundButton.cross:SetPoint("CENTER", soundButton, "CENTER", 0, 0)
	soundButton.cross:Hide()

	-- One builder, used by OnEnter and again by OnClick, so the text follows the
	-- state without the cursor having to leave the button and come back.
	local function soundTooltip()
		OCS.GetTooltip():SetOwner(soundButton, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Alert sound")
		OCS.GetTooltip():AddLine(OCS_DB.alert.sound
			and "On. The popup comes with a sound."
			or "Muted. The popup appears silently.", 1, 1, 1)
		OCS.GetTooltip():AddLine("Click to " .. (OCS_DB.alert.sound and "mute it." or "unmute it."), 0.7, 0.7, 0.7, true)
		OCS.GetTooltip():Show()
	end

	OCS.SetScript(soundButton, "OnClick", function()
		OCS_DB.alert.sound = not OCS_DB.alert.sound
		OCS.Print("Alert sound " .. (OCS_DB.alert.sound and "on" or "off"))
		if OCS_DB.alert.sound then
			PlaySound("RaidWarning")
		end
		OCS.UpdateAlertButtons()
		if GetMouseFocus and GetMouseFocus() == soundButton then
			soundTooltip()
		end
	end)
	OCS.SetScript(soundButton, "OnEnter", function()
		soundTooltip()
	end)
	OCS.SetScript(soundButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	filtersButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	filtersButton:SetWidth(80)
	filtersButton:SetHeight(22)
	-- Room on the right for the speaker button.
	filtersButton:SetText("Filters")
	OCS.SetScript(filtersButton, "OnClick", OCS.UI.toggleFilterPanel)
	OCS.SetScript(filtersButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Filters")
		OCS.GetTooltip():AddLine("Shows only the posts you want to see.",
			1, 1, 1, true)
		OCS.GetTooltip():AddLine("Each section keeps its own set.",
			0.7, 0.7, 0.7, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(filtersButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	-- Scope. Sits above Alerts, next to the mute bell, because both decide how
	-- alerts behave rather than what the table shows.
	scopeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	scopeButton:SetWidth(66)
	scopeButton:SetHeight(22)
	scopeButton:SetText("Section")
	OCS.SetScript(scopeButton, "OnClick", function()
		local a = OCS_DB.alert
		a.scope = ((a.scope or "SECTION") == "ALL") and "SECTION" or "ALL"
		OCS.Print("Alert scope " .. (a.scope == "ALL" and "All" or "Section"))
		OCS.UpdateAlertButtons()
	end)
	OCS.SetScript(scopeButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Alert scope")
		OCS.GetTooltip():AddLine("All: every tab can alert, each judged by its"
			.. " own section filters.", 1, 1, 1, true)
		OCS.GetTooltip():AddLine("Section: only the tab you are looking at can"
			.. " alert, for example PvE LFG.", 1, 1, 1, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(scopeButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	-- Thin box around mute, scope and alerts, so the three read as one control.
	alertBox = CreateFrame("Frame", nil, frame)
	alertBox:SetFrameLevel(math.max(0, frame:GetFrameLevel()))
	alertBox:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	alertBox:SetBackdropColor(0, 0, 0, 0.25)
	alertBox:SetBackdropBorderColor(0.55, 0.45, 0.25, 0.9)

	viewBox = CreateFrame("Frame", nil, frame)
	viewBox:SetFrameLevel(math.max(0, frame:GetFrameLevel()))
	viewBox:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	viewBox:SetBackdropColor(0, 0, 0, 0.25)
	viewBox:SetBackdropBorderColor(0.55, 0.45, 0.25, 0.9)

	OCS.LayoutAlertBar()

	-- Rows. Which columns this section draws.
	local function initRowsMenu(self, level)
		local allowed = OCS.SectionColumnSet()
		local info = {}
		local sid = (OCS.GetSection and OCS.GetSection()) or "PVE"
		local sectionLabel = sid
		for i = 1, OCS.Len(OCS.SECTIONS) do
			if OCS.SECTIONS[i].id == sid then
				sectionLabel = OCS.SECTIONS[i].label
			end
		end
		info.text = "Columns in " .. sectionLabel
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
		for i = 1, OCS.Len(OCS.UI.COLS) do
			local c = OCS.UI.COLS[i]
			if allowed[c.key] and c.key ~= "name" and c.key ~= "message" then
				local key = c.key
				info = {}
				info.text = c.label
				info.checked = not OCS.ColumnOff(key)
				info.isNotRadio = true
				info.keepShownOnClick = true
				info.func = function()
					OCS.ToggleColumn(key)
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
		info = {}
		info.text = "Show all"
		info.notCheckable = true
		info.func = function()
			OCS.ShowAllColumns()
		end
		UIDropDownMenu_AddButton(info, level)
	end

	rowsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	rowsButton:SetWidth(80)
	rowsButton:SetHeight(22)
	rowsButton:SetPoint("RIGHT", filtersButton, "LEFT", -6, 0)
	rowsButton:SetText("Rows")
	OCS.SetScript(rowsButton, "OnClick", function(self)
		if not rowsMenu then
			rowsMenu = CreateFrame("Frame", "OCSRowsMenu", UIParent, "UIDropDownMenuTemplate")
		end
		OCS.UI.toggleViewMenu(self, rowsMenu, initRowsMenu)
	end)
	OCS.SetScript(rowsButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Rows")
		OCS.GetTooltip():AddLine("Chooses which columns the table shows.",
			1, 1, 1, false)
		OCS.GetTooltip():AddLine("Each section keeps its own choice.",
			0.7, 0.7, 0.7, false)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(rowsButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	local function initSkinsMenu(self, level)
		local current = (OCS_DB and OCS_DB.style) or "vanilla"
		for i = 1, OCS.Len(OCS.UI.SKIN_ORDER) do
			local entry = OCS.UI.SKIN_ORDER[i]
			local info = {}
			info.text = entry.label
			info.checked = (current == entry.id)
			info.func = function()
				OCS.SetSkin(entry.id)
				OCS.UI.closeViewMenu()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end

	skinsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	skinsButton:SetWidth(80)
	skinsButton:SetHeight(22)
	skinsButton:SetPoint("BOTTOMRIGHT", filtersButton, "TOPRIGHT", 0, 6)
	skinsButton:SetText("Skins")
	OCS.SetScript(skinsButton, "OnClick", function(self)
		if not skinsMenu then
			skinsMenu = CreateFrame("Frame", "OCSSkinsMenu", UIParent,
				"UIDropDownMenuTemplate")
		end
		OCS.UI.toggleViewMenu(self, skinsMenu, initSkinsMenu)
	end)
	OCS.SetScript(skinsButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("Skins")
		OCS.GetTooltip():AddLine("Changes how both windows look.", 1, 1, 1, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(skinsButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	OCS.LayoutViewBox()

	-- Header bar
	headerBar = CreateFrame("Frame", nil, frame)
	OCS.UI.edgeAnchor(function(m)
		headerBar:ClearAllPoints()
		headerBar:SetPoint("TOPLEFT", m, -OCS.UI.HEADER_TOP)
		headerBar:SetPoint("TOPRIGHT", -(m + OCS.UI.SCROLL_W), -OCS.UI.HEADER_TOP)
	end)
	headerBar:SetHeight(18)

	for i = 1, OCS.Len(OCS.UI.COLS) do
		local col = OCS.UI.COLS[i]
		local button = CreateFrame("Button", nil, headerBar)
		button:SetHeight(18)
		local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("LEFT", 2, 0)
		label:SetText(col.label)
		button.label = label
		OCS.SetScript(button, "OnClick", function()
			if OCS_DB.sortKey == col.key then
				OCS_DB.sortAsc = not OCS_DB.sortAsc
			else
				OCS_DB.sortKey = col.key
				OCS_DB.sortAsc = false
			end
			offset = 0
			OCS.Refresh()
		end)

		-- Width handle. It lives on the right edge of the heading and only
		-- there, so a click anywhere else in the header still sorts.
		local grip = CreateFrame("Frame", nil, headerBar)
		grip:SetWidth(8)
		grip:SetHeight(18)
		grip:EnableMouse(true)
		grip:SetFrameLevel(button:GetFrameLevel() + 4)
		grip.index = i
		local mark = grip:CreateTexture(nil, "OVERLAY")
		mark:SetTexture(1, 1, 1, 0.4)
		mark:SetWidth(1)
		mark:SetHeight(12)
		mark:SetPoint("CENTER")
		mark:Hide()
		local function cursorX(self)
			local scale = self:GetEffectiveScale()
			if not scale or scale == 0 then
				scale = 1
			end
			return GetCursorPosition() / scale
		end
		local function dragWidth(self)
			local col = OCS.UI.COLS[self.index]
			if not col then
				return
			end
			local w = (self.startW or col.w) + (cursorX(self) - (self.startX or 0))
			local min = OCS.UI.colMinWidth(self.index)
			if w < min then
				w = min
			end
			if w > OCS.UI.MAX_COL_W then
				w = OCS.UI.MAX_COL_W
			end
			w = math.floor(w + 0.5)
			if w ~= col.w then
				local store = OCS.UI.widthStore(true)
				if store then
					store[col.key] = w
				end
				col.w = w
				OCS.UI.layout()
			end
		end
		local function stopDrag(self)
			self.dragging = false
			OCS.SetScript(self, "OnUpdate", nil)
			if not OCS.IsMouseOver(self) then
				mark:Hide()
			end
		end
		OCS.SetScript(grip, "OnEnter", function()
			mark:Show()
		end)
		OCS.SetScript(grip, "OnLeave", function(self)
			if not self.dragging then
				mark:Hide()
			end
		end)
		OCS.SetScript(grip, "OnMouseDown", function(self)
			local col = OCS.UI.COLS[self.index]
			if not col then
				return
			end
			self.startX = cursorX(self)
			self.startW = col.w
			self.dragging = true
			mark:Show()
			-- Released outside the handle still ends the drag, because the
			-- button state is checked on every frame.
			OCS.SetScript(self, "OnUpdate", function(s)
				if not IsMouseButtonDown("LeftButton") then
					stopDrag(s)
					return
				end
				dragWidth(s)
			end)
		end)
		OCS.SetScript(grip, "OnMouseUp", stopDrag)
		button.widthGrip = grip

		headers[i] = button
	end

	local headerLine = frame:CreateTexture(nil, "ARTWORK")
	headerLine:SetTexture(1, 1, 1, 0.25)
	headerLine:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -1)
	headerLine:SetPoint("TOPRIGHT", headerBar, "BOTTOMRIGHT", 0, -1)
	headerLine:SetHeight(1)

	-- Table area
	tableArea = CreateFrame("Frame", nil, frame)
	OCS.UI.edgeAnchor(function(m)
		tableArea:ClearAllPoints()
		tableArea:SetPoint("TOPLEFT", frame, "TOPLEFT", m, -OCS.UI.TABLE_TOP)
	end)
	tableArea:EnableMouseWheel(true)
	OCS.SetScript(tableArea, "OnMouseWheel", function(self, delta)
		scrollBar:SetValue(offset - (delta or 0) * 3)
	end)

	for i = 1, OCS.Len(OCS.UI.COLS) do
		local sep = tableArea:CreateTexture(nil, "BACKGROUND")
		sep:SetTexture(1, 1, 1, 0.12)
		sep:Hide()
		seps[i] = sep
	end

	scrollBar = CreateFrame("Slider", "OCS_ScrollBar", frame, "UIPanelScrollBarTemplate")
	-- The stock template assumes its parent is a ScrollFrame and calls
	-- parent:SetVerticalScroll() on every value change. Our parent is a plain
	-- frame, so the inherited handler is replaced before any value is set.
	OCS.SetScript(scrollBar, "OnValueChanged", function(self, value)
		local newOffset = math.floor((value or 0) + 0.5)
		if newOffset ~= offset then
			offset = newOffset
			if not self.updating then
				OCS.UI.updateRows()
			end
		end
	end)
	OCS.UI.edgeAnchor(function(m)
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -OCS.UI.PAD + 2, -OCS.UI.SCROLL_TOP)
		scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -OCS.UI.PAD + 2, OCS.UI.SCROLL_BOTTOM)
	end)
	scrollBar:SetWidth(16)
	scrollBar:SetMinMaxValues(0, 0)
	scrollBar:SetValueStep(1)
	scrollBar:SetValue(0)

	OCS.UI.ensureRows(OCS.UI.fitRows())

	-- Bottom bar
	clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearButton:SetWidth(110)
	clearButton:SetHeight(20)
	OCS.UI.edgeAnchor(function(m)
		clearButton:ClearAllPoints()
		clearButton:SetPoint("BOTTOMLEFT", m, m - 4)
	end)
	clearButton:SetText("Clear Tab")
	OCS.SetScript(clearButton, "OnClick", function()
		OCS.ClearBucket(OCS.GetMode())
	end)
	OCS.SetScript(clearButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_RIGHT")
		OCS.GetTooltip():AddLine("Clear Tab")
		OCS.GetTooltip():AddLine("Empties the tab you are looking at.", 1, 1, 1, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(clearButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	-- Clear all wipes every tab in every section, so it asks first.
	if not StaticPopupDialogs["OCS_CLEAR_ALL"] then
		StaticPopupDialogs["OCS_CLEAR_ALL"] = {
			text = "Clear every tab in PvE, PvP, Trade and Guild?",
			button1 = YES,
			button2 = NO,
			OnShow = function()
				this.ocsPopupScale = this:GetScale()
				OCS.RegisterScaleFrame(this)
			end,
			OnHide = function()
				OCS.UnregisterScaleFrame(this)
				if this.ocsPopupScale then
					this:SetScale(this.ocsPopupScale)
					this.ocsPopupScale = nil
				end
			end,
			OnAccept = function()
				-- Empty the tables directly, then repaint once.
				for i = 1, OCS.Len(OCS.BUCKETS) do
					OCS_DB.rows[OCS.BUCKETS[i]] = {}
				end
				if OCS.ForgetAllNames then
					OCS.ForgetAllNames()
				end
				if OCS.MiniClear then OCS.MiniClear() end
				OCS.Refresh()
				OCS.Print("All tabs cleared")
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	end

	clearAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearAllButton:SetWidth(90)
	clearAllButton:SetHeight(20)
	clearAllButton:SetPoint("LEFT", clearButton, "RIGHT", 6, 0)
	clearAllButton:SetText("Clear All")
	OCS.SetScript(clearAllButton, "OnClick", function()
		StaticPopup_Show("OCS_CLEAR_ALL")
	end)
	OCS.SetScript(clearAllButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_RIGHT")
		OCS.GetTooltip():AddLine("Clear All")
		OCS.GetTooltip():AddLine("Empties every tab in all sections.",
			1, 1, 1, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(clearAllButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	whisperButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	whisperButton:SetWidth(116)
	whisperButton:SetHeight(20)
	whisperButton:SetPoint("LEFT", clearAllButton, "RIGHT", 6, 0)
	whisperButton:SetText("Whisp Templates")
	OCS.SetScript(whisperButton, "OnClick", function()
		OCS.ToggleWhisperSetup()
	end)
	OCS.SetScript(whisperButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_RIGHT")
		OCS.GetTooltip():AddLine("Whisp Templates")
		OCS.GetTooltip():AddLine("Seven whisper lines, with the details of the post"
			.. " filled in as you send.", 1, 1, 1, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(whisperButton, "OnLeave", function() OCS.GetTooltip():Hide() end)

	countText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	countText:SetPoint("BOTTOMLEFT", whisperButton, "BOTTOMRIGHT", 10, 5)
	countText:SetText("")

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	OCS.UI.edgeAnchor(function(m)
		hint:ClearAllPoints()
		hint:SetPoint("BOTTOMRIGHT", -(m + 16), m)
	end)
	hint:SetText("")
	hint:SetJustifyH("RIGHT")
	frame.hint = hint

	resizeGrip = CreateFrame("Button", nil, frame)
	resizeGrip:SetWidth(16)
	resizeGrip:SetHeight(16)
	resizeGrip:SetPoint("BOTTOMRIGHT", -6, 6)
	OCS.SetControlArtwork(resizeGrip, "resize")
	-- StartSizing is gone. It resolves the drag against whatever anchor the
	-- frame happens to carry, and after /ocs reset or a fresh login that is a
	-- CENTER anchor, so the window grew away from the middle in both
	-- directions at twice the speed and the corner shot off the screen. The
	-- size is driven by hand now: the top left corner is pinned before the
	-- first pixel moves and width and height follow the cursor one to one.
	local DRAG_SLOP = 4
	local function sizeStep(self)
		if not self.sizing then
			OCS.SetScript(self, "OnUpdate", nil)
			return
		end
		-- A mouse up over another frame never reaches this button, so the drag
		-- also ends when the button is simply no longer held.
		if not IsMouseButtonDown("LeftButton") then
			local stop = OCS.GetScript(self, "OnMouseUp")
			if stop then
				stop(self)
			end
			return
		end
		local scale = frame:GetEffectiveScale()
		if not scale or scale <= 0 then
			scale = 1
		end
		local x, y = GetCursorPosition()
		local w = self.startW + (x - self.startX) / scale
		local h = self.startH - (y - self.startY) / scale
		w, h = OCS.UI.clampSize(w, h)
		frame:SetWidth(w)
		frame:SetHeight(h)
	end
	OCS.SetScript(resizeGrip, "OnMouseDown", function(self)
		self.startX, self.startY = GetCursorPosition()
		self.startW, self.startH = frame:GetWidth(), frame:GetHeight()
		self.sizing = true
		-- Growing from the bottom right corner has to leave the top left one
		-- where it is, so that is the corner the frame hangs from while the
		-- drag lasts. Exact numbers, no jump.
		local left, top = frame:GetLeft(), frame:GetTop()
		if left and top then
			frame:ClearAllPoints()
			frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		end
		OCS.SetScript(self, "OnUpdate", sizeStep)
	end)
	OCS.SetScript(resizeGrip, "OnMouseUp", function(self)
		if not self.sizing then
			return
		end
		self.sizing = false
		OCS.SetScript(self, "OnUpdate", nil)
		frame:StopMovingOrSizing()
		OCS.UI.normalizeAnchor()
		local x, y = GetCursorPosition()
		local dx = x - (self.startX or x)
		local dy = y - (self.startY or y)
		if dx < 0 then dx = -dx end
		if dy < 0 then dy = -dy end
		if dx <= DRAG_SLOP and dy <= DRAG_SLOP then
			frame:SetWidth(self.startW or frame:GetWidth())
			frame:SetHeight(self.startH or frame:GetHeight())
		end
		OCS.UI.savePosition()
		OCS.UI.layout()
		OCS.Refresh()
	end)

	OCS.SetScript(frame, "OnSizeChanged", function()
		OCS.UI.layout()
		OCS.UI.updateHint()
		OCS.UI.updateRows()
	end)
	OCS.SetScript(frame, "OnShow", function()
		if OCS_DB then OCS_DB.window.shown = true end
		OCS.UI.normalizeAnchor()
		OCS.UI.layout()
		titleHolder:Show()
		OCS.UI.updateHint()
		OCS.Refresh()
	end)
	OCS.SetScript(frame, "OnHide", function()
		if OCS_DB then OCS_DB.window.shown = false end
		titleHolder:Hide()
		OCS.UI.closeFilterPanel()
		OCS.UI.closeViewMenu()
	end)

	OCS.ApplyStyle()
	frame:Hide()
end

-- The full window on its own, used by mini mode when it hands back.
function OCS.ShowMain()
	if not frame then
		return
	end
	frame:Show()
	OCS.Refresh()
end

function OCS.HideMain()
	if frame then
		frame:Hide()
	end
end

-- /ocs reset. The way back when the window has been dragged off screen or
-- sized into something unusable.
function OCS.ResetWindow()
	if not frame then
		return false
	end
	frame:StopMovingOrSizing()
	if resizeGrip then
		resizeGrip.armed = false
		resizeGrip.sizing = false
	end
	OCS.SetWindowScale(100)
	local w, h = OCS.UI.clampSize(OCS.UI.DEFAULT_W, OCS.UI.DEFAULT_H)
	frame:SetWidth(w)
	frame:SetHeight(h)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER")
	-- Straight back to a bottom left anchor. A window left on CENTER is what
	-- made the next resize drag explode.
	OCS.UI.normalizeAnchor()
	OCS.ResetColumnWidths()
	OCS_DB.window.w, OCS_DB.window.h = w, h
	OCS_DB.window.x, OCS_DB.window.y = nil, nil
	OCS_DB.window.hasPos = false
	OCS.UI.closeFilterPanel()
	OCS.UI.layout()
	OCS.Refresh()
	return true
end

-- /ocs always toggles the main window. The mini feed is a separate layer
-- controlled by /ocs mini and the switch button; it stays open independently.
function OCS.Show()
	OCS.ShowMain()
end

function OCS.Toggle()
	if not frame then
		return
	end
	if frame:IsShown() then
		frame:Hide()
	else
		OCS.ShowMain()
	end
end

-- Minimap button ------------------------------------------------------------

local minimapButton

function OCS.UI.placeMinimapButton()
	local angle = math.rad(OCS_DB.minimap.angle or 205)
	local x = 80 * math.cos(angle)
	local y = 80 * math.sin(angle)
	minimapButton:ClearAllPoints()
	minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function OCS.UI.createMinimapButton()
	minimapButton = CreateFrame("Button", "OCS_MinimapButton", Minimap)
	minimapButton:SetWidth(31)
	minimapButton:SetHeight(31)
	minimapButton:SetFrameStrata("MEDIUM")
	minimapButton:SetMovable(true)

	local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
	icon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetPoint("CENTER", 0, 1)

	local border = minimapButton:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetWidth(53)
	border:SetHeight(53)
	border:SetPoint("TOPLEFT")

	minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	OCS.SetScript(minimapButton, "OnClick", function(self, button)
		if button == "RightButton" then
			-- Locks or unlocks the alert popup for dragging.
			if OCS.ToggleAlertLock then
				OCS.ToggleAlertLock()
			end
		else
			OCS.Toggle()
		end
	end)
	OCS.SetScript(minimapButton, "OnEnter", function(self)
		OCS.GetTooltip():SetOwner(self, "ANCHOR_LEFT")
		OCS.GetTooltip():AddLine("OctoScanner")
		OCS.GetTooltip():AddLine("Left-click opens or closes the window.",
			1, 1, 1, true)
		OCS.GetTooltip():AddLine("Right-click locks or unlocks the alert popup"
			.. " for dragging.", 0.7, 0.7, 0.7, true)
		OCS.GetTooltip():AddLine("Drag to move this button around the minimap.",
			0.7, 0.7, 0.7, true)
		OCS.GetTooltip():Show()
	end)
	OCS.SetScript(minimapButton, "OnLeave", function() OCS.GetTooltip():Hide() end)
	minimapButton:RegisterForDrag("LeftButton")
	OCS.SetScript(minimapButton, "OnDragStart", function(self)
		self.dragging = true
	end)
	OCS.SetScript(minimapButton, "OnDragStop", function(self)
		self.dragging = nil
	end)
	OCS.SetScript(minimapButton, "OnUpdate", function(self)
		if not self.dragging then
			return
		end
		local mx, my = Minimap:GetCenter()
		local scale = UIParent:GetScale()
		local cx, cy = GetCursorPosition()
		cx, cy = cx / scale, cy / scale
		OCS_DB.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
		OCS.UI.placeMinimapButton()
	end)
	OCS.UI.placeMinimapButton()
end

function OCS.UpdateMinimapButton()
	if not minimapButton then
		return
	end
	if OCS_DB.minimap.show then
		OCS.UI.placeMinimapButton()
		minimapButton:Show()
	else
		minimapButton:Hide()
	end
end

-- Bootstrap -----------------------------------------------------------------

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
OCS.SetScript(loader, "OnEvent", function()
	-- createWindow hides the frame, which fires OnHide and clears the flag,
	-- so read the saved state first.
	local wasShown = OCS_DB and OCS_DB.window.shown
	local wasMini = OCS_DB and OCS_DB.mini and OCS_DB.mini.shown
	local ok, err = pcall(OCS.UI.createWindow)
	if not ok then
		OCS.Print("|cffff5555interface error|r " .. tostring(err))
		return
	end
	pcall(OCS.UI.createMinimapButton)
	OCS.UpdateMinimapButton()
	if wasShown then
		OCS.Show()
	end
	if wasMini and OCS.MiniShow then
		OCS.MiniShow()
	end
end)
