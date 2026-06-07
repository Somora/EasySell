local ES = EasySell

local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs

local pendingPopupData

function ES:ShowProviderPopup(providers)
    pendingPopupData = {
        providers = providers,
        signature = self:BuildProviderSignature(providers),
    }

    local labels = {}
    for index, provider in ipairs(providers) do
        labels[index] = self:GetProviderLabel(provider)
    end

    StaticPopupDialogs[self.POPUP_NAME] = {
        text = "Choose which addon should handle automatic selling.",
        button1 = labels[1],
        button2 = labels[2],
        button3 = labels[3],
        OnAccept = function()
            ES:SetProvider(pendingPopupData.providers[1])
            pendingPopupData = nil
        end,
        OnCancel = function(_, reason)
            if reason == "clicked" and pendingPopupData and pendingPopupData.providers[2] then
                ES:SetProvider(pendingPopupData.providers[2])
                pendingPopupData = nil
                return
            end

            if pendingPopupData then
                ES:GetDB().providerPromptSignature = "dismissed"
            end
            pendingPopupData = nil
            ES.Print("Provider selection skipped. Use /esell provider easysell, /esell provider elvui, or /esell provider zygor anytime.")
        end,
        OnAlt = function()
            if pendingPopupData and pendingPopupData.providers[3] then
                ES:SetProvider(pendingPopupData.providers[3])
            end
            pendingPopupData = nil
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show(self.POPUP_NAME)
end

function ES:MaybePromptForProviderSelection()
    local providers = self:GetAvailableProviders()
    if #providers <= 1 then
        return false
    end

    local db = self:GetDB()
    local signature = self:BuildProviderSignature(providers)
    local drifted = self:IsProviderConfigurationOutOfSync()

    if drifted then
        db.providerPromptSignature = ""

        if self.promptedSessionSignature == signature then
            return false
        end

        self.promptedSessionSignature = signature
        self.Print("An auto-sell provider setting changed outside EasySell. Please confirm your preferred provider again.")
        self:ShowProviderPopup(providers)
        return true
    end

    if db.providerPromptSignature ~= "" then
        return false
    end

    if self.promptedSessionSignature == signature then
        return false
    end

    self.promptedSessionSignature = signature
    self:ShowProviderPopup(providers)
    return true
end
