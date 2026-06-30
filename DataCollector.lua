local ADDON_NAME, NS = ...

local function SafeAverageItemLevel()
    if not GetAverageItemLevel then return nil, nil end
    local avg, equipped = GetAverageItemLevel()
    return avg or 0, equipped or 0
end

local function CaptureBasics(entry)
    entry.name    = UnitName("player")
    entry.realm   = GetRealmName()
    local _, classFile = UnitClass("player")
    entry.class   = classFile
    entry.level   = UnitLevel("player")
    entry.faction = UnitFactionGroup("player")
    entry.race    = select(2, UnitRace("player"))
    entry.lastSeen = time()
end

local function CaptureMoney(entry, authoritative)
    local money = GetMoney()
    if not money then return end
    if authoritative then
        entry.gold = money
        return
    end
    if money > 0 or (entry.gold or 0) == 0 then
        entry.gold = money
    end
end

local function CaptureItemLevel(entry)
    local avg, equipped = SafeAverageItemLevel()
    if avg and avg > 0 then
        entry.ilvl = avg
        entry.ilvlEquipped = equipped
    end
end

function NS:Collect(opts)
    if not self.db then return end
    opts = opts or {}
    local entry = self:GetCurrentEntry()
    CaptureBasics(entry)
    CaptureMoney(entry, opts.authoritativeMoney)
    CaptureItemLevel(entry)
    if self.CollectMythicPlus then self:CollectMythicPlus(entry) end
    if self.CollectVault       then self:CollectVault(entry)       end
    self:FireRefresh()
end

local function ScheduleCollect(delay, opts)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay or 0.5, function() NS:Collect(opts) end)
    else
        NS:Collect(opts)
    end
end

NS:OnReady(function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("PLAYER_MONEY")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    f:RegisterEvent("WEEKLY_REWARDS_UPDATE")
    f:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")

    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            ScheduleCollect(2.5)
            ScheduleCollect(6.0)
        elseif event == "PLAYER_MONEY" then
            ScheduleCollect(0.3, { authoritativeMoney = true })
        else
            ScheduleCollect(0.5)
        end
    end)
end)
