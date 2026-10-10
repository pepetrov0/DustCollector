local ADDON_NAME = ...

local PREFIX = "|cffc8a2c8DustCollector|r: "

local DEFAULTS = {
    enabled    = false,
    maxQuality = 2, -- 2 = Uncommon (green)
}

local QUALITY_NAMES = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
}

local QUALITY_ALIASES = {
    poor = 0,     gray = 0,   grey = 0,
    common = 1,   white = 1,
    uncommon = 2, green = 2,
    rare = 3,     blue = 3,
    epic = 4,     purple = 4,
}

local ROLL_GREED       = 2
local ROLL_DISENCHANT  = 3

local db
local pending = {} -- rollIDs that we rolled on ourselves

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end

local function QualityText(q)
    local name = QUALITY_NAMES[q] or tostring(q)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    if c and c.hex then
        return c.hex .. name .. "|r"
    end
    return name
end

local function InitDB()
    DustCollectorDB = DustCollectorDB or {}
    for k, v in pairs(DEFAULTS) do
        if DustCollectorDB[k] == nil then
            DustCollectorDB[k] = v
        end
    end
    db = DustCollectorDB
end

------------------------------------------------------------
-- Rolling
------------------------------------------------------------
local function HandleRoll(rollID)
    if not db or not db.enabled then return end

    local _, itemName, _, quality, _, _, canGreed, canDisenchant = GetLootRollItemInfo(rollID)
    if not quality or quality > db.maxQuality then return end

    local rollType, action
    if canDisenchant then
        rollType, action = ROLL_DISENCHANT, "Rolled disenchant on"
    elseif canGreed then
        rollType, action = ROLL_GREED, "Rolled greed on"
    else
        return
    end

    -- Fetch the link before rolling: RollOnLoot fires CANCEL_LOOT_ROLL
    -- synchronously and roll data may be gone afterwards.
    local itemText = GetLootRollItemLink(rollID) or itemName or "?"

    pending[rollID] = true
    Print(action .. itemText)
    RollOnLoot(rollID, rollType)
end

------------------------------------------------------------
-- Events
------------------------------------------------------------
local frame = CreateFrame("Frame")

local queue = {} -- rollIDs waiting to be handled on the next frame

local function OnUpdate(self)
    self:SetScript("OnUpdate", nil)
    local ids = queue
    queue = {}
    for i = 1, #ids do
        HandleRoll(ids[i])
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("START_LOOT_ROLL")
frame:RegisterEvent("CONFIRM_LOOT_ROLL")
frame:RegisterEvent("CANCEL_LOOT_ROLL")

frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            InitDB()
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "START_LOOT_ROLL" then
        pending[arg1] = nil -- clear any stale entry from an earlier roll
        -- Don't roll inside this handler: rolling makes the client fire
        -- CANCEL_LOOT_ROLL immediately, and if that happens before other
        -- addons (e.g. ElvUI's roll bars) have processed START_LOOT_ROLL,
        -- they never see the cancel and their frame stays up forever.
        -- Defer to the next frame instead.
        queue[#queue + 1] = arg1
        self:SetScript("OnUpdate", OnUpdate)

    elseif event == "CONFIRM_LOOT_ROLL" then
        -- Only auto-confirm bind prompts for rolls we made ourselves
        if pending[arg1] then
            ConfirmLootRoll(arg1, arg2)
            StaticPopup_Hide("CONFIRM_LOOT_ROLL")
            pending[arg1] = nil
        end

    elseif event == "CANCEL_LOOT_ROLL" then
        pending[arg1] = nil
    end
end)

------------------------------------------------------------
-- Slash commands
------------------------------------------------------------
local function PrintStatus()
    Print(string.format("%s, rolling on items up to %s.",
        db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r",
        QualityText(db.maxQuality)))
end

local function PrintHelp()
    Print("commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  /dc on | off | toggle  - enable or disable")
    DEFAULT_CHAT_FRAME:AddMessage("  /dc rarity <poor|common|uncommon|rare|epic>  (or 0-4)")
    DEFAULT_CHAT_FRAME:AddMessage("  /dc status  - show current settings")
end

SLASH_DUSTCOLLECTOR1 = "/dustcollector"
SLASH_DUSTCOLLECTOR2 = "/dc"

SlashCmdList["DUSTCOLLECTOR"] = function(msg)
    if not db then return end

    msg = (msg or ""):lower()
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")

    if cmd == "on" then
        db.enabled = true
        PrintStatus()

    elseif cmd == "off" then
        db.enabled = false
        PrintStatus()

    elseif cmd == "toggle" then
        db.enabled = not db.enabled
        PrintStatus()

    elseif cmd == "rarity" or cmd == "quality" then
        local q = QUALITY_ALIASES[arg]
        if q == nil then
            local n = tonumber(arg)
            if n and QUALITY_NAMES[n] then q = n end
        end

        if q == nil then
            Print("unknown rarity '" .. arg .. "'. Use poor, common, uncommon, rare, epic (or 0-4).")
        else
            db.maxQuality = q
            PrintStatus()
        end

    elseif cmd == "status" or cmd == "" then
        PrintStatus()
        if cmd == "" then PrintHelp() end

    else
        PrintHelp()
    end
end
