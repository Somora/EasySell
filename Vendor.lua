local ES = EasySell

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetCoinTextureString = GetCoinTextureString
local ipairs = ipairs

local isSelling = false

function ES:PrintPreview()
    local matches, totalMoney, totalItems = self:GetMatchingItems()

    if #matches == 0 then
        self.Print("Preview: nothing to sell.")
        return
    end

    self.Print("Preview: " .. totalItems .. " item(s) for " .. GetCoinTextureString(totalMoney) .. ".")

    for index, item in ipairs(matches) do
        if index > 5 then
            self.Print("Preview: +" .. (#matches - 5) .. " more stack(s).")
            break
        end

        self.Print("Preview: " .. item.link .. " x" .. item.count .. " = " .. GetCoinTextureString(item.value) .. ".")
    end
end

function ES:SellMatchingItems()
    if isSelling then
        return
    end

    local matches, expectedMoney = self:GetMatchingItems()

    isSelling = true

    for _, item in ipairs(matches) do
        self:UseBagItem(item.bag, item.slot)
    end

    local function PrintSummary()
        if #matches > 0 then
            ES.sessionTotal = (ES.sessionTotal or 0) + expectedMoney
            ES.Print("Sold items for " .. GetCoinTextureString(expectedMoney) .. ".")

            if ES.RefreshOptions then
                ES:RefreshOptions()
            end
        end

        isSelling = false
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, PrintSummary)
    else
        PrintSummary()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function()
    if ES.MaybePromptForProviderSelection and ES:MaybePromptForProviderSelection() then
        return
    end

    local db = ES:GetDB()
    if db.enabled and db.provider == ES.PROVIDER_EASYSELL then
        ES:SellMatchingItems()
    end
end)
