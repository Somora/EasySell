local ES = EasySell

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetCoinTextureString = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
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
    if isSelling or not MerchantFrame or not MerchantFrame:IsShown() or (InCombatLockdown and InCombatLockdown()) then
        return
    end

    local matches = self:GetMatchingItems()

    isSelling = true

    local submittedMoney = 0
    local submittedItems = 0
    local ok, message = pcall(function()
        for _, item in ipairs(matches) do
            if not self:UseBagItem(item.bag, item.slot) then
                break
            end
            submittedMoney = submittedMoney + item.value
            submittedItems = submittedItems + 1
        end
    end)
    if not ok then
        isSelling = false
        error(message, 0)
    end

    local function PrintSummary()
        -- Release first: a formatting/UI error must not disable subsequent sales.
        isSelling = false
        if submittedItems > 0 then
            ES.sessionTotal = (ES.sessionTotal or 0) + submittedMoney
            ES.Print("Sold items for " .. GetCoinTextureString(submittedMoney) .. ".")

            if ES.RefreshOptions then
                ES:RefreshOptions()
            end
        end
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
