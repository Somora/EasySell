local ES = EasySell

local CreateFrame = CreateFrame
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetItemInfo = GetItemInfo
local ITEM_SOULBOUND = ITEM_SOULBOUND
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local UIParent = UIParent
local _G = _G
local strmatch = strmatch
local strtrim = strtrim
local tonumber = tonumber
local type = type

local ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON or (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local ITEM_CLASS_ARMOR = LE_ITEM_CLASS_ARMOR or (Enum and Enum.ItemClass and Enum.ItemClass.Armor) or 4
local tooltip = CreateFrame("GameTooltip", "EasySellTooltip", UIParent, "GameTooltipTemplate")

function ES:GetItemIDFromLink(link)
    if type(link) ~= "string" then
        return
    end

    return tonumber(strmatch(link, "item:(%d+)"))
end

function ES:GetItemIDFromInput(input)
    input = strtrim(input or "")

    if input == "" then
        return
    end

    return self:GetItemIDFromLink(input) or tonumber(input)
end

function ES:GetItemLabel(itemID)
    local name, link, _, _, _, _, _, _, _, icon

    if C_Item and C_Item.GetItemInfo then
        name, link, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
    elseif GetItemInfo then
        name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
    end

    local iconText = icon and ("|T" .. icon .. ":16:16:0:0|t ") or ""
    return iconText .. (link or name or ("Item " .. itemID)) .. " |cff888888(" .. itemID .. ")|r"
end

function ES:SetWhitelisted(itemID, enabled)
    local db = self:GetDB()
    itemID = tonumber(itemID)

    if not itemID then
        return false
    end

    if enabled then
        db.whitelist[itemID] = true
    else
        db.whitelist[itemID] = nil
    end

    if self.RefreshOptions then
        self:RefreshOptions()
    end

    return true
end

function ES:IsWhitelisted(itemID)
    local db = self:GetDB()
    return itemID and db.whitelist and db.whitelist[itemID]
end

local function GetBagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end

    if GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end

    return 0
end

local function GetBagItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if not info then
            return
        end

        return info.hyperlink, info.stackCount or 1, info.quality, info.isLocked, info.hasNoValue
    end

    if not GetContainerItemInfo then
        return
    end

    local _, count, locked, quality, _, _, link, _, noValue = GetContainerItemInfo(bag, slot)

    if not link and GetContainerItemLink then
        link = GetContainerItemLink(bag, slot)
    end

    return link, count or 1, quality, locked, noValue
end

function ES:UseBagItem(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(bag, slot)
        return
    end

    UseContainerItem(bag, slot)
end

local function GetItemValue(link)
    if not link then
        return 0
    end

    local _, _, quality, _, _, _, _, _, equipLoc, _, sellPrice, classID, _, bindType = GetItemInfo(link)

    return quality, sellPrice or 0, bindType, classID, equipLoc
end

function ES:IsBagItemSoulbound(bag, slot)
    if not tooltip or not ITEM_SOULBOUND then
        return false
    end

    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetBagItem(bag, slot)

    for lineIndex = 2, tooltip:NumLines() do
        local line = _G["EasySellTooltipTextLeft" .. lineIndex]
        if line and line:GetText() == ITEM_SOULBOUND then
            tooltip:Hide()
            return true
        end
    end

    tooltip:Hide()
    return false
end

local function IsProtectedSoulbound(itemQuality, bindType, bag, slot)
    local db = ES:GetDB()
    return db.protectSoulbound and itemQuality and itemQuality > 0 and (ES:IsBagItemSoulbound(bag, slot) or bindType == 1)
end

local function IsSellableCategory(itemQuality, classID, equipLoc, bag, slot)
    if itemQuality == 0 then
        return true
    end

    if not ((classID == ITEM_CLASS_WEAPON or classID == ITEM_CLASS_ARMOR) and equipLoc and equipLoc ~= "") then
        return false
    end

    local db = ES:GetDB()
    return db.sellUnboundEquipment or ES:IsBagItemSoulbound(bag, slot)
end

function ES:GetMatchingItems()
    local db = self:GetDB()
    local matches = {}
    local totalMoney = 0
    local totalItems = 0

    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, GetBagSlots(bag) do
            local link, count, bagQuality, locked, noValue = GetBagItemInfo(bag, slot)

            if link and not locked and not noValue then
                local itemQuality, sellPrice, bindType, classID, equipLoc = GetItemValue(link)
                local itemID = self:GetItemIDFromLink(link)
                itemQuality = itemQuality or bagQuality

                if itemQuality and itemQuality <= db.maxQuality and sellPrice > 0 and IsSellableCategory(itemQuality, classID, equipLoc, bag, slot) and not self:IsWhitelisted(itemID) and not IsProtectedSoulbound(itemQuality, bindType, bag, slot) then
                    matches[#matches + 1] = {
                        bag = bag,
                        slot = slot,
                        link = link,
                        count = count,
                        quality = itemQuality,
                        value = sellPrice * count,
                    }
                    totalMoney = totalMoney + (sellPrice * count)
                    totalItems = totalItems + count
                end
            end
        end
    end

    return matches, totalMoney, totalItems
end
