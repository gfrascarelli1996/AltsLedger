local ADDON_NAME, NS = ...

local function ReadWarbandGold()
    if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType then
        local ok, value = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
        if ok and type(value) == "number" then return value end
    end
    return nil
end

local function Capture(reason)
    if not NS.db then return end
    local gold = ReadWarbandGold()
    if gold ~= nil then
        NS.db.warbandGold = gold
        NS.db.warbandUpdatedAt = time()
        NS:FireRefresh()
    end
end

function NS:GetWarbandGold()
    return (self.db and self.db.warbandGold) or 0
end

function NS:GetWarbandUpdatedAt()
    return (self.db and self.db.warbandUpdatedAt) or 0
end

NS:OnReady(function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    f:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    f:RegisterEvent("BANKFRAME_OPENED")
    f:RegisterEvent("BANKFRAME_CLOSED")
    f:RegisterEvent("ACCOUNT_MONEY")
    if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("PLAYER_ACCOUNT_BANK_TYPE_BANK_OPENED") then
        f:RegisterEvent("PLAYER_ACCOUNT_BANK_TYPE_BANK_OPENED")
    end

    f:SetScript("OnEvent", function(_, event, ...)
        Capture(event)
        if C_Timer and C_Timer.After then
            C_Timer.After(1.0, function() Capture(event .. "+1s") end)
        end
    end)
end)
