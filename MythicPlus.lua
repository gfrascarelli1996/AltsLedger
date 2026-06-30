local ADDON_NAME, NS = ...

local CATEGORY_KEYS = { "raid", "mythicPlus", "world" }

local function ResolveCategoryTypes()
    if not Enum or not Enum.WeeklyRewardChestThresholdType then return nil end
    local E = Enum.WeeklyRewardChestThresholdType
    return {
        raid       = E.Raid,
        mythicPlus = E.Activities or E.MythicPlus,
        world      = E.World or E.WorldActivities or E.Delves or E.RankedPvP,
    }
end

function NS:CollectMythicPlus(entry)
    if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
        local score = C_ChallengeMode.GetOverallDungeonScore()
        if score and score > 0 then entry.mythicPlusRating = score end
    end
end

function NS:CollectVault(entry)
    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return end
    local types = ResolveCategoryTypes()
    if not types then return end

    entry.vault = entry.vault or {}
    for _, key in ipairs(CATEGORY_KEYS) do
        local t = types[key]
        local activities = (t and C_WeeklyRewards.GetActivities(t)) or {}
        local unlocked, total = 0, 0
        for _, a in ipairs(activities) do
            total = total + 1
            if (a.progress or 0) >= (a.threshold or math.huge) then
                unlocked = unlocked + 1
            end
        end
        if total > 3 then total = 3 end
        if unlocked > 3 then unlocked = 3 end
        entry.vault[key] = { unlocked = unlocked, total = total }
    end
    entry.vaultUpdatedAt = time()
end

function NS:VaultSummaryString(entry)
    if not entry or not entry.vault then return "|cff666666-|r" end
    local parts = {}
    for _, key in ipairs(CATEGORY_KEYS) do
        local v = entry.vault[key]
        if v and (v.total or 0) > 0 then
            local label = (key == "raid" and "R") or (key == "mythicPlus" and "M") or "W"
            local color = (v.unlocked >= v.total) and "ff1eff00" or ((v.unlocked > 0) and "ffffd100" or "ff888888")
            table.insert(parts, string.format("|c%s%s %d/%d|r", color, label, v.unlocked, v.total))
        end
    end
    if #parts == 0 then return "|cff666666-|r" end
    return table.concat(parts, "  ")
end

function NS:WeeklyResetExpired(updatedAt)
    if not updatedAt or updatedAt == 0 then return true end
    if not C_DateAndTime or not C_DateAndTime.GetSecondsUntilWeeklyReset then return false end
    local secsLeft = C_DateAndTime.GetSecondsUntilWeeklyReset() or 0
    local nextReset = time() + secsLeft
    local thisResetStart = nextReset - 7 * 24 * 3600
    return updatedAt < thisResetStart
end
