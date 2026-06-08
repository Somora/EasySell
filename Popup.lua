local ES = EasySell

local CreateFrame = CreateFrame
local UIParent = UIParent
local pendingPopupData
local providerFrame

local function SetTextureColor(texture, red, green, blue, alpha)
    if texture.SetColorTexture then
        texture:SetColorTexture(red, green, blue, alpha)
    else
        texture:SetTexture(red, green, blue, alpha)
    end
end

local function HideProviderPopup()
    if providerFrame then
        providerFrame:Hide()
    end

    pendingPopupData = nil
end

local function SelectProvider(provider)
    ES:SetProvider(provider)
    HideProviderPopup()
end

local function DismissProviderPopup()
    if pendingPopupData then
        ES:GetDB().providerPromptSignature = "dismissed"
    end

    HideProviderPopup()
    ES.Print("Provider selection skipped. Use /esell provider easysell, /esell provider elvui, or /esell provider zygor anytime.")
end

local function CreateProviderFrame()
    if providerFrame then
        return providerFrame
    end

    local frame = CreateFrame("Frame", "EasySellProviderPopup", UIParent)
    frame:SetSize(430, 118)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:EnableKeyboard(true)
    frame:Hide()

    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetAllPoints()
    SetTextureColor(frame.background, 0, 0, 0, 0.9)

    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetPoint("TOPLEFT", 1, -1)
    frame.border:SetPoint("BOTTOMRIGHT", -1, 1)
    SetTextureColor(frame.border, 0.18, 0.18, 0.18, 1)

    frame.inner = frame:CreateTexture(nil, "ARTWORK")
    frame.inner:SetPoint("TOPLEFT", 2, -2)
    frame.inner:SetPoint("BOTTOMRIGHT", -2, 2)
    SetTextureColor(frame.inner, 0.02, 0.02, 0.02, 0.95)

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetPoint("TOP", 0, -18)
    frame.text:SetWidth(390)
    frame.text:SetText("Choose which addon should handle automatic selling.")

    frame.buttons = {}
    for index = 1, 3 do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(118, 24)
        button:SetPoint("BOTTOMLEFT", 30 + ((index - 1) * 128), 22)
        frame.buttons[index] = button
    end

    frame:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then
            DismissProviderPopup()
        end
    end)

    providerFrame = frame
    return providerFrame
end

function ES:ShowProviderPopup(providers)
    pendingPopupData = {
        providers = providers,
        signature = self:BuildProviderSignature(providers),
    }

    local frame = CreateProviderFrame()
    for index, provider in ipairs(providers) do
        local selectedProvider = provider
        local button = frame.buttons[index]
        button:SetText(self:GetProviderLabel(selectedProvider))
        button:SetScript("OnClick", function()
            SelectProvider(selectedProvider)
        end)
        button:Show()
    end

    for index = #providers + 1, #frame.buttons do
        frame.buttons[index]:Hide()
    end

    frame:Show()
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
