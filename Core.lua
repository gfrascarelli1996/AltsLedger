local ADDON_NAME, NS = ...

local DEFAULTS = {
    characters = {},
    warbandGold = 0,
    warbandUpdatedAt = 0,
    minimapShown = true,
    minimapAngle = 215,
    framePoint = { "CENTER", 0, 0 },
    frameSize = { 820, 500 },
    frameScale = 1.0,
    sortKey = "ilvl",
    sortDesc = true,
}

NS.db = nil
NS.readyHandlers = {}
NS.refreshCallbacks = {}

function NS:OnReady(fn)
    if self.db then fn() else table.insert(self.readyHandlers, fn) end
end

function NS:RegisterRefresh(fn)
    table.insert(self.refreshCallbacks, fn)
end

function NS:FireRefresh()
    for _, fn in ipairs(self.refreshCallbacks) do pcall(fn) end
end

function NS:CharacterKey(name, realm)
    name = name or UnitName("player")
    realm = realm or GetRealmName()
    return name .. "-" .. realm
end

function NS:GetCurrentEntry()
    local key = self:CharacterKey()
    self.db.characters[key] = self.db.characters[key] or {}
    return self.db.characters[key], key
end

function NS:GetCharacters()
    local out = {}
    if not self.db then return out end
    for key, data in pairs(self.db.characters) do
        local copy = {}
        for k, v in pairs(data) do copy[k] = v end
        copy.key = key
        table.insert(out, copy)
    end
    return out
end

function NS:RemoveCharacter(key)
    if not self.db or not key then return end
    self.db.characters[key] = nil
    self:FireRefresh()
end

function NS:FormatGold(copper)
    copper = copper or 0
    if GetCoinTextureString then
        return GetCoinTextureString(copper)
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return string.format("|cffffd100%d|rg |cffc7c7cf%d|rs |cffeda55f%d|rc", g, s, c)
end

function NS:ClassColor(classFile)
    if not classFile then return "ffffffff" end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if c and c.colorStr then return c.colorStr end
    if c then return string.format("ff%02x%02x%02x", (c.r or 1) * 255, (c.g or 1) * 255, (c.b or 1) * 255) end
    return "ffffffff"
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event ~= "ADDON_LOADED" or arg1 ~= ADDON_NAME then return end

    AltsLedgerDB = AltsLedgerDB or {}
    for k, v in pairs(DEFAULTS) do
        if AltsLedgerDB[k] == nil then
            if type(v) == "table" then
                AltsLedgerDB[k] = {}
                for kk, vv in pairs(v) do AltsLedgerDB[k][kk] = vv end
            else
                AltsLedgerDB[k] = v
            end
        end
    end
    AltsLedgerDB.characters = AltsLedgerDB.characters or {}

    NS.db = AltsLedgerDB

    for _, fn in ipairs(NS.readyHandlers) do pcall(fn) end
    NS.readyHandlers = nil
end)
