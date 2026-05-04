local ADDON_NAME = ...
local PREFIX = "|cff33ff99EasySell|r: "

EasySell = EasySell or {}
local ES = EasySell

ES.ADDON_NAME = ADDON_NAME
ES.sessionTotal = ES.sessionTotal or 0

ES.defaults = {
    enabled = true,
    maxQuality = 0,
    protectSoulbound = true,
    sellUnboundEquipment = false,
    whitelist = {},
}

ES.qualityLabels = {
    [0] = "|cff9d9d9dpoor|r",
    [1] = "|cffffffffcommon|r",
    [2] = "|cff1eff00uncommon|r",
    [3] = "|cff0070ddrare|r",
    [4] = "|cffa335eeepic|r",
}

ES.qualityByCommand = {
    poor = 0,
    grey = 0,
    gray = 0,
    common = 1,
    white = 1,
    uncommon = 2,
    green = 2,
    rare = 3,
    blue = 3,
    epic = 4,
    purple = 4,
}

local CreateFrame = CreateFrame
local pairs = pairs
local print = print
local tonumber = tonumber
local type = type

local function Print(message)
    print(PREFIX .. message)
end

ES.Print = Print

function ES:GetStatusText(enabled)
    return enabled and "enabled" or "disabled"
end

function ES:GetQualityLabel(quality)
    return self.qualityLabels[quality] or self.qualityLabels[0]
end

function ES:GetMaxQualityLabel()
    local db = self:GetDB()
    return self:GetQualityLabel(db.maxQuality)
end

function ES:SetMaxQuality(quality)
    local db = self:GetDB()
    quality = tonumber(quality)

    if not quality or not self.qualityLabels[quality] then
        return
    end

    db.maxQuality = quality

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

local function MergeDefaults(db)
    for key, value in pairs(ES.defaults) do
        if key ~= "whitelist" and db[key] == nil then
            db[key] = value
        end
    end

    if type(db.maxQuality) ~= "number" or db.maxQuality < 0 or db.maxQuality > 4 then
        db.maxQuality = ES.defaults.maxQuality
    end

    if type(db.protectSoulbound) ~= "boolean" then
        db.protectSoulbound = ES.defaults.protectSoulbound
    end

    if type(db.sellUnboundEquipment) ~= "boolean" then
        db.sellUnboundEquipment = ES.defaults.sellUnboundEquipment
    end

    if type(db.whitelist) ~= "table" then
        db.whitelist = {}
    end
end

function ES:InitializeDatabase()
    EasySellDB = EasySellDB or {}
    EasySellCharDB = EasySellCharDB or {}

    if EasySellCharDB.useCharacterSettings == nil then
        EasySellCharDB.useCharacterSettings = false
    end

    MergeDefaults(EasySellDB)
    MergeDefaults(EasySellCharDB)
end

function ES:GetDB()
    self:InitializeDatabase()

    if EasySellCharDB.useCharacterSettings then
        return EasySellCharDB
    end

    return EasySellDB
end

function ES:SetUseCharacterSettings(enabled)
    self:InitializeDatabase()

    if enabled and not EasySellCharDB.copiedFromAccount then
        EasySellCharDB.enabled = EasySellDB.enabled
        EasySellCharDB.maxQuality = EasySellDB.maxQuality
        EasySellCharDB.protectSoulbound = EasySellDB.protectSoulbound
        EasySellCharDB.sellUnboundEquipment = EasySellDB.sellUnboundEquipment
        EasySellCharDB.whitelist = {}

        for itemID, whitelisted in pairs(EasySellDB.whitelist or {}) do
            EasySellCharDB.whitelist[itemID] = whitelisted
        end

        EasySellCharDB.copiedFromAccount = true
    end

    EasySellCharDB.useCharacterSettings = enabled and true or false

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            ES:InitializeDatabase()
            frame:UnregisterEvent("ADDON_LOADED")
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        Print("Loaded.")
    end
end)
