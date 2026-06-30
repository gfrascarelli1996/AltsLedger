local ADDON_NAME, NS = ...

local DEFAULT_W, DEFAULT_H = 820, 500
local MIN_W, MIN_H = 720, 260
local MAX_W, MAX_H = 1600, 1000
local ROW_H = 38
local PAD = 16
local HEADER_H = 30
local TITLEBAR_H = 36
local FOOTER_H = 78
local SCROLLBAR_W = 18
local NAME_LEFT_PAD = 36

local CLASS_ICON_TEX = "Interface\\TargetingFrame\\UI-Classes-Circles"

local C_ACCENT          = { 1.0, 0.78, 0.20 }
local C_TITLE_BG_TOP    = { 0.13, 0.13, 0.17 }
local C_TITLE_BG_BOTTOM = { 0.06, 0.06, 0.09 }
local C_FRAME_BG        = { 0.045, 0.05, 0.07, 0.97 }
local C_HEADER_BG       = { 0.085, 0.09, 0.12, 1 }
local C_ROW_ALT         = { 1, 1, 1, 0.025 }
local C_ROW_HOVER       = { 0.40, 0.65, 1.00, 0.10 }
local C_ROW_SEP         = { 1, 1, 1, 0.05 }
local C_ROW_CURRENT     = { 1.0, 0.78, 0.20, 0.10 }
local C_BORDER          = { 0.50, 0.42, 0.18, 1 }

local COLUMNS = {
    { key = "name",  label = "CHARACTER",   width = 240, justify = "LEFT",   sortable = true,  stretch = true, minWidth = 180 },
    { key = "level", label = "LVL",         width = 50,  justify = "CENTER", sortable = true  },
    { key = "ilvl",  label = "ILVL",        width = 80,  justify = "CENTER", sortable = true  },
    { key = "gold",  label = "GOLD",        width = 150, justify = "RIGHT",  sortable = true  },
    { key = "mplus", label = "M+",          width = 60,  justify = "CENTER", sortable = true  },
    { key = "vault", label = "GREAT VAULT", width = 165, justify = "CENTER", sortable = false },
    { key = "del",   label = "",            width = 26,  justify = "CENTER", sortable = false },
}

local frame, headerFrame, scroll, scrollChild
local rowPool = {}
local headerCells = {}

local function SetGradient(tex, top, bottom)
    if tex.SetGradient and CreateColor then
        local ok = pcall(tex.SetGradient, tex, "VERTICAL",
            CreateColor(bottom[1], bottom[2], bottom[3], bottom[4] or 1),
            CreateColor(top[1],    top[2],    top[3],    top[4]    or 1))
        if ok then return end
    end
    tex:SetColorTexture(bottom[1], bottom[2], bottom[3], bottom[4] or 1)
end

local function SavePoint()
    if not frame then return end
    local point, _, _, x, y = frame:GetPoint()
    if point then NS.db.framePoint = { point, x, y } end
end

local function SaveSize()
    if not frame then return end
    NS.db.frameSize = { math.floor(frame:GetWidth()), math.floor(frame:GetHeight()) }
end

local function ApplyPoint()
    if not frame or not NS.db or not NS.db.framePoint then return end
    local p = NS.db.framePoint
    frame:ClearAllPoints()
    frame:SetPoint(p[1] or "CENTER", UIParent, p[1] or "CENTER", p[2] or 0, p[3] or 0)
end

local function ApplySize()
    if not frame or not NS.db then return end
    local size = NS.db.frameSize or { DEFAULT_W, DEFAULT_H }
    local w = math.max(MIN_W, math.min(MAX_W, size[1] or DEFAULT_W))
    local h = math.max(MIN_H, math.min(MAX_H, size[2] or DEFAULT_H))
    frame:SetSize(w, h)
end

local function ComputeLayout()
    local w = (frame and frame:GetWidth()) or DEFAULT_W
    local rowAreaW = w - 2 * PAD - SCROLLBAR_W

    local fixedTotal = 0
    for _, col in ipairs(COLUMNS) do
        if not col.stretch then fixedTotal = fixedTotal + col.width end
    end

    local stretchableW = math.max(0, rowAreaW - fixedTotal)

    local layout = {}
    local x = 0
    for _, col in ipairs(COLUMNS) do
        local cw
        if col.stretch then
            cw = math.max(col.minWidth or col.width, stretchableW)
        else
            cw = col.width
        end
        layout[col.key] = { x = x, width = cw }
        x = x + cw
    end
    layout._total = x
    return layout
end

local function SortChars(chars)
    local key = (NS.db and NS.db.sortKey) or "ilvl"
    local desc = NS.db and NS.db.sortDesc
    table.sort(chars, function(a, b)
        local av, bv
        if     key == "name"  then av, bv = (a.name or ""):lower(), (b.name or ""):lower()
        elseif key == "gold"  then av, bv = a.gold or 0, b.gold or 0
        elseif key == "level" then av, bv = a.level or 0, b.level or 0
        elseif key == "mplus" then av, bv = a.mythicPlusRating or 0, b.mythicPlusRating or 0
        else                       av, bv = a.ilvl or 0, b.ilvl or 0
        end
        if av == bv then return (a.name or "") < (b.name or "") end
        if desc then return av > bv else return av < bv end
    end)
end

local function ClassColorRGB(classFile)
    if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
        local c = RAID_CLASS_COLORS[classFile]
        return c.r or 1, c.g or 1, c.b or 1
    end
    return 0.6, 0.6, 0.6
end

local function SetClassIcon(tex, classFile)
    if not classFile or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[classFile] then
        tex:SetTexture(nil)
        return
    end
    tex:SetTexture(CLASS_ICON_TEX)
    tex:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
end

local function ApplyRowLayout(row, layout)
    local nameL = layout.name
    local nameTextX  = nameL.x + NAME_LEFT_PAD
    local nameTextW  = math.max(20, nameL.width - NAME_LEFT_PAD - 4)
    row.classIcon:ClearAllPoints()
    row.classIcon:SetPoint("LEFT", row, "LEFT", nameL.x + 6, 0)

    row.fontStrings.name:ClearAllPoints()
    row.fontStrings.name:SetPoint("TOPLEFT", row, "TOPLEFT", nameTextX, -6)
    row.fontStrings.name:SetWidth(nameTextW)

    row.fontStrings.realm:ClearAllPoints()
    row.fontStrings.realm:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", nameTextX, 6)
    row.fontStrings.realm:SetWidth(nameTextW)

    for _, col in ipairs(COLUMNS) do
        if col.key ~= "name" and col.key ~= "del" then
            local lay = layout[col.key]
            local fs = row.fontStrings[col.key]
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", row, "LEFT", lay.x + 4, 0)
            fs:SetWidth(math.max(20, lay.width - 8))
        end
    end

    local delL = layout.del
    row.delBtn:ClearAllPoints()
    row.delBtn:SetPoint("CENTER", row, "LEFT", delL.x + delL.width / 2, 0)
end

local function ApplyHeaderLayout(layout)
    for _, h in ipairs(headerCells) do
        local lay = layout[h.key]
        h.btn:ClearAllPoints()
        h.btn:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", lay.x, 0)
        h.btn:SetSize(lay.width, HEADER_H)

        local leftPad = (h.key == "name") and NAME_LEFT_PAD or 0
        h.label:ClearAllPoints()
        h.label:SetPoint("LEFT", h.btn, "LEFT", leftPad + 4, 0)
        h.label:SetWidth(math.max(20, lay.width - leftPad - 8))
    end
end

local function GetRow(index, layout)
    local row = rowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, scrollChild)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT",  scrollChild, "LEFT",  0, 0)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(unpack(C_ROW_ALT))
    row.stripe:Hide()

    row.currentBg = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.currentBg:SetAllPoints()
    row.currentBg:SetColorTexture(unpack(C_ROW_CURRENT))
    row.currentBg:Hide()

    row.classBar = row:CreateTexture(nil, "BORDER")
    row.classBar:SetPoint("TOPLEFT",    row, "TOPLEFT",     0, -2)
    row.classBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT",  0,  2)
    row.classBar:SetWidth(3)

    row.currentGlow = row:CreateTexture(nil, "OVERLAY")
    row.currentGlow:SetPoint("TOPLEFT",     row.classBar, "TOPRIGHT", 0, 0)
    row.currentGlow:SetPoint("BOTTOMLEFT",  row.classBar, "BOTTOMRIGHT", 0, 0)
    row.currentGlow:SetWidth(14)
    row.currentGlow:SetColorTexture(1.0, 0.82, 0.25, 0.18)
    row.currentGlow:Hide()

    row.sep = row:CreateTexture(nil, "BORDER")
    row.sep:SetColorTexture(unpack(C_ROW_SEP))
    row.sep:SetHeight(1)
    row.sep:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  8, 0)
    row.sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 0)

    row.hover = row:CreateTexture(nil, "ARTWORK")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(unpack(C_ROW_HOVER))
    row.hover:Hide()
    row:SetScript("OnEnter", function(self) self.hover:Show() end)
    row:SetScript("OnLeave", function(self) self.hover:Hide() end)

    row.classIcon = row:CreateTexture(nil, "ARTWORK")
    row.classIcon:SetSize(24, 24)

    row.fontStrings = {}

    row.fontStrings.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.fontStrings.name:SetJustifyH("LEFT")
    row.fontStrings.name:SetWordWrap(false)

    row.fontStrings.realm = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.fontStrings.realm:SetJustifyH("LEFT")
    row.fontStrings.realm:SetWordWrap(false)

    for _, col in ipairs(COLUMNS) do
        if col.key ~= "name" and col.key ~= "del" then
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetJustifyH(col.justify)
            fs:SetWordWrap(false)
            row.fontStrings[col.key] = fs
        end
    end

    row.delBtn = CreateFrame("Button", nil, row)
    row.delBtn:SetSize(20, 20)
    row.delBtn.label = row.delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.delBtn.label:SetPoint("CENTER", 0, 0)
    row.delBtn.label:SetText("|cff666666x|r")
    row.delBtn:SetScript("OnEnter", function(self)
        self.label:SetText("|cffff5555x|r")
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffff5555Remove|r", 1, 1, 1)
        GameTooltip:AddLine("Forget this character from the ledger.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    row.delBtn:SetScript("OnLeave", function(self)
        self.label:SetText("|cff666666x|r")
        GameTooltip:Hide()
    end)

    rowPool[index] = row
    ApplyRowLayout(row, layout)
    return row
end

local function FormatIlvl(entry)
    if not entry.ilvl or entry.ilvl <= 0 then return "|cff666666–|r" end
    local avg = entry.ilvl
    local eq  = entry.ilvlEquipped or 0
    if eq > 0 and math.abs(avg - eq) > 0.5 then
        return string.format("|cffffffff%.1f|r |cff666666(%.0f)|r", avg, eq)
    end
    return string.format("|cffffffff%.1f|r", avg)
end

local function FormatMplus(entry)
    local r = entry.mythicPlusRating
    if not r or r <= 0 then return "|cff666666–|r" end
    local color = "ffffffff"
    if     r >= 3500 then color = "ffe6cc80"
    elseif r >= 3000 then color = "ffff8000"
    elseif r >= 2500 then color = "ffa335ee"
    elseif r >= 2000 then color = "ff0070dd"
    elseif r >= 1500 then color = "ff1eff00"
    end
    return string.format("|c%s%d|r", color, math.floor(r))
end

local INDICATOR_FILLED = "|TInterface\\COMMON\\Indicator-Yellow:11:11:0:0|t"
local INDICATOR_EMPTY  = "|TInterface\\COMMON\\Indicator-Gray:11:11:0:0|t"
local INDICATOR_DONE   = "|TInterface\\COMMON\\Indicator-Green:11:11:0:0|t"

local VAULT_LABELS = { raid = "R", mythicPlus = "M", world = "W" }
local VAULT_ORDER  = { "raid", "mythicPlus", "world" }

local function FormatVaultRich(entry)
    local vault = entry.vault
    local parts = {}
    for _, key in ipairs(VAULT_ORDER) do
        local v = vault and vault[key]
        local label = VAULT_LABELS[key] or "?"
        local total = (v and v.total and v.total > 0) and v.total or 3
        local unlocked = (v and v.unlocked) or 0
        local full = total > 0 and unlocked >= total and v ~= nil
        local some = unlocked > 0
        local labelColor = (not v) and "ff555555"
                        or full and "ff40e040"
                        or (some and "ffffd100" or "ff666666")
        local dots = {}
        for i = 1, total do
            if v and i <= unlocked then
                table.insert(dots, full and INDICATOR_DONE or INDICATOR_FILLED)
            else
                table.insert(dots, INDICATOR_EMPTY)
            end
        end
        table.insert(parts, string.format("|c%s%s|r %s", labelColor, label, table.concat(dots, "")))
    end
    return table.concat(parts, "  ")
end

local function UpdateHeaderArrows()
    local sortKey = NS.db and NS.db.sortKey or "ilvl"
    local sortDesc = NS.db and NS.db.sortDesc
    for _, h in ipairs(headerCells) do
        if h.arrow then
            if h.key == sortKey then
                h.arrow:Show()
                if sortDesc then
                    h.arrow:SetTexCoord(0, 0.5625, 0, 1)
                else
                    h.arrow:SetTexCoord(0, 0.5625, 1, 0)
                end
            else
                h.arrow:Hide()
            end
        end
    end
end

local function Refresh()
    if not frame or not frame:IsShown() or not NS.db then return end

    local layout = ComputeLayout()
    ApplyHeaderLayout(layout)

    local chars = NS:GetCharacters()
    SortChars(chars)

    local currentKey = NS:CharacterKey()
    local totalGold = 0
    for i, entry in ipairs(chars) do
        totalGold = totalGold + (entry.gold or 0)

        local row = GetRow(i, layout)
        ApplyRowLayout(row, layout)

        row:ClearAllPoints()
        row:SetPoint("LEFT",  scrollChild, "LEFT",  0, 0)
        row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        row:SetPoint("TOP",   scrollChild, "TOP",   0, -(i - 1) * ROW_H)

        local isCurrent = (entry.key == currentKey)
        if i % 2 == 0 then row.stripe:Show() else row.stripe:Hide() end
        if isCurrent then
            row.currentBg:Show()
            row.currentGlow:Show()
        else
            row.currentBg:Hide()
            row.currentGlow:Hide()
        end

        local r, g, b = ClassColorRGB(entry.class)
        row.classBar:SetColorTexture(r, g, b, 0.9)

        SetClassIcon(row.classIcon, entry.class)
        local nameStr = string.format("|cff%02x%02x%02x%s|r",
            r * 255, g * 255, b * 255, entry.name or "?")
        if isCurrent then
            nameStr = nameStr .. "  |cffffd100[active]|r"
        end
        row.fontStrings.name:SetText(nameStr)
        row.fontStrings.realm:SetText(entry.realm or "")
        row.fontStrings.level:SetText("|cffffffff" .. tostring(entry.level or "?") .. "|r")
        row.fontStrings.ilvl:SetText(FormatIlvl(entry))
        row.fontStrings.gold:SetText(NS:FormatGold(entry.gold or 0))
        row.fontStrings.mplus:SetText(FormatMplus(entry))
        row.fontStrings.vault:SetText(FormatVaultRich(entry))

        local key = entry.key
        row.delBtn:SetScript("OnClick", function() NS:RemoveCharacter(key) end)
        row.delBtn:Show()
        row:Show()
    end

    for i = #chars + 1, #rowPool do rowPool[i]:Hide() end

    scrollChild:SetHeight(math.max(1, #chars * ROW_H))

    frame.footerGold:SetText("|cffffd100Total gold|r    " .. NS:FormatGold(totalGold))
    local wb = NS:GetWarbandGold()
    local wbAge = NS:GetWarbandUpdatedAt()
    local wbText = "|cff7eb3ffWarband Bank|r    " .. NS:FormatGold(wb)
    if wbAge == 0 then
        wbText = wbText .. "   |cff666666(open the warband bank once to record)|r"
    end
    frame.footerWarband:SetText(wbText)

    frame.subtitle:SetText(string.format("|cff888888%d alts tracked|r", #chars))
    UpdateHeaderArrows()
end

local function Relayout()
    if not frame then return end
    local layout = ComputeLayout()
    ApplyHeaderLayout(layout)
    for _, row in ipairs(rowPool) do
        if row:IsShown() then ApplyRowLayout(row, layout) end
    end
end

local function BuildHeader(parent)
    local headerBg = parent:CreateTexture(nil, "ARTWORK")
    headerBg:SetColorTexture(unpack(C_HEADER_BG))
    headerBg:SetPoint("TOPLEFT",  parent, "TOPLEFT",  4, -(TITLEBAR_H + 4))
    headerBg:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -(TITLEBAR_H + 4))
    headerBg:SetHeight(HEADER_H)

    headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetHeight(HEADER_H)
    headerFrame:SetPoint("TOPLEFT",  parent, "TOPLEFT",  PAD, -(TITLEBAR_H + 4))
    headerFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD - SCROLLBAR_W, -(TITLEBAR_H + 4))

    local sep = parent:CreateTexture(nil, "OVERLAY")
    sep:SetColorTexture(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.55)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  headerFrame, "BOTTOMLEFT",  -PAD + 4, 0)
    sep:SetPoint("TOPRIGHT", headerFrame, "BOTTOMRIGHT", PAD - 4 + SCROLLBAR_W, 0)

    for _, col in ipairs(COLUMNS) do
        local btn = CreateFrame("Button", nil, headerFrame)
        btn:SetHeight(HEADER_H)
        btn.key = col.key

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetJustifyH(col.justify)
        label:SetText(string.format("|cff%02x%02x%02x%s|r",
            C_ACCENT[1] * 255, C_ACCENT[2] * 255, C_ACCENT[3] * 255, col.label))

        local cell = { key = col.key, btn = btn, label = label }

        if col.sortable then
            local arrow = btn:CreateTexture(nil, "OVERLAY")
            arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
            arrow:SetSize(10, 8)
            if col.justify == "RIGHT" then
                arrow:SetPoint("RIGHT", label, "LEFT", -3, 0)
            elseif col.justify == "CENTER" then
                arrow:SetPoint("LEFT", label, "RIGHT", 1, 0)
            else
                arrow:SetPoint("LEFT", label, "RIGHT", 3, 0)
            end
            arrow:Hide()
            cell.arrow = arrow

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.06)

            btn:SetScript("OnClick", function()
                if NS.db.sortKey == col.key then
                    NS.db.sortDesc = not NS.db.sortDesc
                else
                    NS.db.sortKey = col.key
                    NS.db.sortDesc = (col.key ~= "name")
                end
                Refresh()
            end)
        end

        table.insert(headerCells, cell)
    end
end

local function StyleScrollBar(s)
    local sb = s.ScrollBar or _G[s:GetName() .. "ScrollBar"]
    if not sb then return end
    local up   = sb.ScrollUpButton   or _G[sb:GetName() .. "ScrollUpButton"]
    local down = sb.ScrollDownButton or _G[sb:GetName() .. "ScrollDownButton"]
    if up   then up:SetAlpha(0)   end
    if down then down:SetAlpha(0) end
    sb:ClearAllPoints()
    sb:SetPoint("TOPRIGHT",    s, "TOPRIGHT",    SCROLLBAR_W, 0)
    sb:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", SCROLLBAR_W, 0)
    sb:SetWidth(10)
end

local function BuildResizer(parent)
    local resizer = CreateFrame("Button", nil, parent)
    resizer:SetSize(16, 16)
    resizer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    resizer:SetFrameLevel(parent:GetFrameLevel() + 5)
    resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizer:SetScript("OnMouseDown", function() parent:StartSizing("BOTTOMRIGHT") end)
    resizer:SetScript("OnMouseUp", function()
        parent:StopMovingOrSizing()
        SaveSize()
        Relayout()
        Refresh()
    end)
    return resizer
end

local function BuildFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", "AltsLedgerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(DEFAULT_W, DEFAULT_H)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
    elseif frame.SetMinResize then
        frame:SetMinResize(MIN_W, MIN_H)
        frame:SetMaxResize(MAX_W, MAX_H)
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePoint() end)
    frame:SetScript("OnSizeChanged", function() Relayout() end)
    frame:Hide()

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        frame:SetBackdropColor(unpack(C_FRAME_BG))
        frame:SetBackdropBorderColor(unpack(C_BORDER))
    end

    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT",  frame, "TOPLEFT",  4, -4)
    titleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    titleBg:SetHeight(TITLEBAR_H)
    SetGradient(titleBg, C_TITLE_BG_TOP, C_TITLE_BG_BOTTOM)

    local titleAccent = frame:CreateTexture(nil, "OVERLAY")
    titleAccent:SetColorTexture(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.85)
    titleAccent:SetPoint("BOTTOMLEFT",  titleBg, "BOTTOMLEFT",  0, 0)
    titleAccent:SetPoint("BOTTOMRIGHT", titleBg, "BOTTOMRIGHT", 0, 0)
    titleAccent:SetHeight(1)

    local titleIcon = frame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(20, 20)
    titleIcon:SetPoint("LEFT", titleBg, "LEFT", 10, 0)
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local titleBorder = frame:CreateTexture(nil, "OVERLAY")
    titleBorder:SetSize(22, 22)
    titleBorder:SetPoint("CENTER", titleIcon, "CENTER")
    titleBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    titleBorder:SetAlpha(0.6)

    local titleDragArea = CreateFrame("Frame", nil, frame)
    titleDragArea:SetAllPoints(titleBg)
    titleDragArea:EnableMouse(true)
    titleDragArea:RegisterForDrag("LeftButton")
    titleDragArea:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleDragArea:SetScript("OnDragStop",  function() frame:StopMovingOrSizing(); SavePoint() end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
    frame.title:SetText("Alts Ledger")
    frame.title:SetTextColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3])

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("LEFT", frame.title, "RIGHT", 10, -1)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() frame:Hide() end)

    BuildHeader(frame)

    scroll = CreateFrame("ScrollFrame", "AltsLedgerScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PAD, -(TITLEBAR_H + HEADER_H + 12))
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD - SCROLLBAR_W, FOOTER_H + 8)

    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(1, 1)
    scroll:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scroll:GetWidth())
    scroll:SetScript("OnSizeChanged", function(self, w) scrollChild:SetWidth(w) end)
    StyleScrollBar(scroll)

    local footerBg = frame:CreateTexture(nil, "ARTWORK")
    SetGradient(footerBg, { 0.085, 0.09, 0.12 }, { 0.04, 0.05, 0.07 })
    footerBg:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  4, 4)
    footerBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    footerBg:SetHeight(FOOTER_H)

    local footerAccent = frame:CreateTexture(nil, "OVERLAY")
    footerAccent:SetColorTexture(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.6)
    footerAccent:SetPoint("TOPLEFT",  footerBg, "TOPLEFT",  0, 0)
    footerAccent:SetPoint("TOPRIGHT", footerBg, "TOPRIGHT", 0, 0)
    footerAccent:SetHeight(1)

    frame.footerNote = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.footerNote:SetPoint("TOPLEFT", footerBg, "TOPLEFT", PAD, -8)
    frame.footerNote:SetPoint("TOPRIGHT", footerBg, "TOPRIGHT", -PAD, -8)
    frame.footerNote:SetJustifyH("LEFT")
    frame.footerNote:SetText("|cffffd100Tip|r  Log into each of your characters once to add them to the ledger — there is no way to sync them automatically.")
    frame.footerNote:SetTextColor(0.85, 0.85, 0.85)

    frame.footerGold = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.footerGold:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, 34)
    frame.footerGold:SetJustifyH("LEFT")

    frame.footerWarband = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.footerWarband:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, 14)
    frame.footerWarband:SetJustifyH("LEFT")

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD - 20, 14)
    hint:SetText("Drag titlebar to move  |  drag corner to resize  |  click column to sort")

    BuildResizer(frame)

    ApplyPoint()
    ApplySize()
    Relayout()
    return frame
end

function NS:Frame() return frame end

function NS:ShowFrame()
    BuildFrame()
    self:Collect()
    Refresh()
    frame:Show()
end

function NS:HideFrame()
    if frame then frame:Hide() end
end

function NS:ToggleFrame()
    if frame and frame:IsShown() then self:HideFrame() else self:ShowFrame() end
end

NS:RegisterRefresh(Refresh)

NS:OnReady(function()
    BuildFrame()
end)
