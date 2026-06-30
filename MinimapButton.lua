local ADDON_NAME, NS = ...

local ICON_PATH = "Interface\\Icons\\INV_Misc_Coin_01"
local button

local MINIMAP_SHAPES = {
    ["ROUND"]                 = { true,  true,  true,  true  },
    ["SQUARE"]                = { false, false, false, false },
    ["CORNER-TOPLEFT"]        = { false, false, false, true  },
    ["CORNER-TOPRIGHT"]       = { false, false, true,  false },
    ["CORNER-BOTTOMLEFT"]     = { false, true,  false, false },
    ["CORNER-BOTTOMRIGHT"]    = { true,  false, false, false },
    ["SIDE-LEFT"]             = { false, true,  false, true  },
    ["SIDE-RIGHT"]            = { true,  false, true,  false },
    ["SIDE-TOP"]              = { false, false, true,  true  },
    ["SIDE-BOTTOM"]           = { true,  true,  false, false },
    ["TRICORNER-TOPLEFT"]     = { false, true,  true,  true  },
    ["TRICORNER-TOPRIGHT"]    = { true,  false, true,  true  },
    ["TRICORNER-BOTTOMLEFT"]  = { true,  true,  false, true  },
    ["TRICORNER-BOTTOMRIGHT"] = { true,  true,  true,  false },
}

local function UpdatePosition()
    if not button then return end
    local angle = math.rad(NS.db.minimapAngle or 215)
    local x, y = math.cos(angle), math.sin(angle)

    local mw = Minimap:GetWidth() or 140
    local mh = Minimap:GetHeight() or 140
    if mw < 50 then mw = 140 end
    if mh < 50 then mh = 140 end

    local w = mw / 2 + 10
    local h = mh / 2 + 10

    local shape = (GetMinimapShape and GetMinimapShape()) or "ROUND"
    local quad = MINIMAP_SHAPES[shape] or MINIMAP_SHAPES["ROUND"]
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end

    if quad[q] then
        x, y = x * w, y * h
    else
        local d = math.sqrt(2 * w * w) - 10
        x = math.max(-w, math.min(x * d, w))
        y = math.max(-h, math.min(y * d, h))
    end

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    if not mx then return end
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    local angle = math.deg(math.atan2(py - my, px - mx))
    NS.db.minimapAngle = angle
    UpdatePosition()
end

local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cffffd100AltsLedger|r")
    GameTooltip:AddLine(" ")
    local n = 0
    if NS.db then for _ in pairs(NS.db.characters or {}) do n = n + 1 end end
    GameTooltip:AddLine(string.format("|cff7eb3ff%d|r tracked alts", n), 1, 1, 1)
    if NS.db then
        local total = 0
        for _, c in pairs(NS.db.characters) do total = total + (c.gold or 0) end
        GameTooltip:AddLine("Total gold: " .. NS:FormatGold(total), 1, 1, 1)
        GameTooltip:AddLine("Warband Bank: " .. NS:FormatGold(NS:GetWarbandGold()), 0.7, 0.85, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff7eb3ffLeft-click:|r toggle window", 1, 1, 1)
    GameTooltip:AddLine("|cff7eb3ffDrag:|r reposition", 1, 1, 1)
    GameTooltip:Show()
end

local function OnClick(_, btn)
    if btn == "LeftButton" then
        NS:ToggleFrame()
    end
end

local function CreateButton()
    if button then return end

    button = CreateFrame("Button", "AltsLedgerMinimapButton", Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    button:SetSize(31, 31)
    button:SetMovable(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetClampedToScreen(false)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetTexture(ICON_PATH)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("CENTER", 0, 0)
    button.icon = icon

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", -2, 2)

    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(28, 28)
    hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    hl:SetPoint("CENTER", 0, 0)
    hl:SetBlendMode("ADD")

    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnClick", OnClick)
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    button:Show()
    UpdatePosition()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, UpdatePosition)
        C_Timer.After(2.0, UpdatePosition)
    end
end

function NS:SetMinimapButtonShown(shown)
    NS.db.minimapShown = shown
    if shown and not button then CreateButton() end
    if button then
        if shown then button:Show() else button:Hide() end
    end
end

NS:OnReady(function()
    if NS.db.minimapShown then
        CreateButton()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if button then button:Show(); UpdatePosition() end
            end)
        end
    end
end)
