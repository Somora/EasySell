local ES = EasySell

local ClearCursor = ClearCursor
local GetCoinTextureString = GetCoinTextureString
local GetCursorInfo = GetCursorInfo
local strlower = strlower
local strmatch = strmatch
local strtrim = strtrim
local tostring = tostring

local function PrintStatus()
    local db = ES:GetDB()
    local profile = EasySellCharDB.useCharacterSettings and "character" or "account"
    local provider = ES:GetProviderLabel(db.provider)
    local elvUIStatus = db.elvUIDetected and "detected" or "not detected"
    local zygorStatus = db.zygorDetected and "detected" or "not detected"
    ES.Print("Auto sell is " .. ES:GetStatusText(db.enabled) .. ". Provider: " .. provider .. ". ElvUI: " .. elvUIStatus .. ". Zygor: " .. zygorStatus .. ". Selling up to " .. ES:GetMaxQualityLabel() .. ". Soulbound protection is " .. ES:GetStatusText(db.protectSoulbound) .. ". Unbound equipment selling is " .. ES:GetStatusText(db.sellUnboundEquipment) .. ". Profile: " .. profile .. ".")
end

local function PrintSession()
    ES.Print("Session total: " .. GetCoinTextureString(ES.sessionTotal or 0) .. ".")
end

local function RefreshOptions()
    if ES.RefreshOptions then
        ES:RefreshOptions()
    end
end

SLASH_EASYSELL1 = "/esell"
SLASH_EASYSELL2 = "/easysell"
SlashCmdList.EASYSELL = function(msg)
    msg = strlower(strtrim(msg or ""))
    local db = ES:GetDB()

    if msg == "on" then
        db.enabled = true
        ES:SyncProviderState(false)
        ES.Print("Auto sell is now enabled.")
    elseif msg == "off" then
        db.enabled = false
        ES:SyncProviderState(false)
        ES.Print("Auto sell is now disabled.")
    elseif msg == "" or msg == "toggle" then
        db.enabled = not db.enabled
        ES:SyncProviderState(false)
        ES.Print("Auto sell is now " .. ES:GetStatusText(db.enabled) .. ".")
    elseif msg == "status" then
        ES:MaybePromptForProviderSelection()
        PrintStatus()
    elseif msg == "session" then
        PrintSession()
    elseif msg == "preview" then
        ES:PrintPreview()
    elseif msg == "help" then
        ES.Print("Usage: /esell, /esell on/off, /esell status, /esell provider easysell/elvui/zygor, /esell preview, /esell session, /esell options, /esell profile, /esell soulbound, /esell unbound, /esell poor/common/uncommon/rare/epic, /esell keep [item], /esell keep cursor, or /esell unkeep [item].")
    elseif msg == "options" or msg == "config" then
        if ES.OpenOptions then
            ES:OpenOptions()
        end
    elseif msg == "soulbound" or msg == "soulbound toggle" then
        db.protectSoulbound = not db.protectSoulbound
        ES.Print("Soulbound protection is now " .. ES:GetStatusText(db.protectSoulbound) .. ".")
        RefreshOptions()
    elseif msg == "soulbound on" then
        db.protectSoulbound = true
        ES.Print("Soulbound protection is now enabled.")
        RefreshOptions()
    elseif msg == "soulbound off" then
        db.protectSoulbound = false
        ES.Print("Soulbound protection is now disabled.")
        RefreshOptions()
    elseif msg == "unbound" or msg == "unbound toggle" then
        db.sellUnboundEquipment = not db.sellUnboundEquipment
        ES.Print("Unbound equipment selling is now " .. ES:GetStatusText(db.sellUnboundEquipment) .. ".")
        RefreshOptions()
    elseif msg == "unbound on" then
        db.sellUnboundEquipment = true
        ES.Print("Unbound equipment selling is now enabled.")
        RefreshOptions()
    elseif msg == "unbound off" then
        db.sellUnboundEquipment = false
        ES.Print("Unbound equipment selling is now disabled.")
        RefreshOptions()
    elseif msg == "profile" or msg == "profile toggle" then
        ES:SetUseCharacterSettings(not EasySellCharDB.useCharacterSettings)
        ES.Print("Using " .. (EasySellCharDB.useCharacterSettings and "character" or "account") .. " settings.")
    elseif msg == "profile account" then
        ES:SetUseCharacterSettings(false)
        ES.Print("Using account settings.")
    elseif msg == "profile character" then
        ES:SetUseCharacterSettings(true)
        ES.Print("Using character settings.")
    elseif msg == "provider easysell" or msg == "provider easy" or msg == "provider es" then
        ES:SetProvider(ES.PROVIDER_EASYSELL)
    elseif msg == "provider elvui" then
        ES:SetProvider(ES.PROVIDER_ELVUI)
    elseif msg == "provider zygor" then
        ES:SetProvider(ES.PROVIDER_ZYGOR)
    elseif msg == "keep cursor" then
        local cursorType, itemID, itemLink = GetCursorInfo()
        itemID = itemID or ES:GetItemIDFromLink(itemLink)
        if cursorType == "item" and ES:SetWhitelisted(itemID, true) then
            ES.Print("Whitelisted " .. ES:GetItemLabel(itemID) .. ".")
            ClearCursor()
        else
            ES.Print("Pick up an item first, then use /esell keep cursor.")
        end
    elseif strmatch(msg, "^keep%s+") then
        local itemID = ES:GetItemIDFromInput(strmatch(msg, "^keep%s+(.+)$"))
        if ES:SetWhitelisted(itemID, true) then
            ES.Print("Whitelisted " .. ES:GetItemLabel(itemID) .. ".")
        else
            ES.Print("Please enter an item link or item ID.")
        end
    elseif strmatch(msg, "^unkeep%s+") then
        local itemID = ES:GetItemIDFromInput(strmatch(msg, "^unkeep%s+(.+)$"))
        if ES:SetWhitelisted(itemID, false) then
            ES.Print("Removed " .. ES:GetItemLabel(itemID) .. " from the whitelist.")
        else
            ES.Print("Please enter an item link or item ID.")
        end
    elseif ES.qualityByCommand[msg] ~= nil then
        db.maxQuality = ES.qualityByCommand[msg]
        ES.Print("Selling up to " .. ES:GetMaxQualityLabel() .. ".")
        RefreshOptions()
    else
        ES.Print("Unknown option '" .. tostring(msg) .. "'. Use /esell help.")
    end
end
