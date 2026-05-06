local ES = EasySell

local whitelistRows = {}

local QUALITY_OPTIONS = {
    { value = 0, label = "|cff9d9d9dpoor|r" },
    { value = 1, label = "|cffffffffcommon|r" },
    { value = 2, label = "|cff1eff00uncommon|r" },
    { value = 3, label = "|cff0070ddrare|r" },
    { value = 4, label = "|cffa335eeepic|r" },
}

local PROVIDER_OPTIONS = {
    { value = ES.PROVIDER_EASYSELL },
    { value = ES.PROVIDER_ELVUI },
    { value = ES.PROVIDER_ZYGOR },
}

local function CreateTitle(parent, text)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(text)
    return title
end

local function CreateText(parent, text, template)
    local line = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlightSmall")
    line:SetJustifyH("LEFT")
    line:SetText(text)
    return line
end

local function CreateButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 110, 24)
    button:SetText(text)
    return button
end

local function InitializeRarityDropdown(dropdown)
    if not UIDropDownMenu_CreateInfo then
        return
    end

    UIDropDownMenu_Initialize(dropdown, function()
        for _, option in ipairs(QUALITY_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = "  " .. option.label
            info.value = option.value
            info.arg1 = option.value
            info.checked = ES:GetDB().maxQuality == option.value
            info.isNotRadio = false
            info.keepShownOnClick = false
            info.func = function()
                ES:SetMaxQuality(option.value)
                ES.Print("Selling up to " .. ES:GetMaxQualityLabel() .. ".")
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetWidth(dropdown, 160)
end

local function InitializeProviderDropdown(dropdown)
    if not UIDropDownMenu_CreateInfo then
        return
    end

    UIDropDownMenu_Initialize(dropdown, function()
        local db = ES:GetDB()
        for _, option in ipairs(PROVIDER_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            local available = option.value == ES.PROVIDER_EASYSELL
                or (option.value == ES.PROVIDER_ELVUI and db.elvUIDetected)
                or (option.value == ES.PROVIDER_ZYGOR and db.zygorDetected)

            info.text = ES:GetProviderLabel(option.value) .. (available and "" or " (not loaded)")
            info.value = option.value
            info.arg1 = option.value
            info.checked = db.provider == option.value
            info.disabled = not available
            info.isNotRadio = false
            info.keepShownOnClick = false
            info.func = function()
                ES:SetProvider(option.value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetWidth(dropdown, 160)
end

local function AddCursorItem()
    local cursorType, itemID, itemLink = GetCursorInfo()

    if cursorType ~= "item" then
        return false
    end

    itemID = itemID or ES:GetItemIDFromLink(itemLink)

    if not itemID then
        ES.Print("Please drag an item link or item from your bags.")
        ClearCursor()
        return true
    end

    ES:SetWhitelisted(itemID, true)
    ES.Print("Whitelisted " .. ES:GetItemLabel(itemID) .. ".")
    ClearCursor()
    return true
end

local function GetSortedWhitelist()
    local itemIDs = {}

    for itemID, enabled in pairs(ES:GetDB().whitelist or {}) do
        local numericItemID = tonumber(itemID)
        if enabled and numericItemID then
            itemIDs[#itemIDs + 1] = numericItemID
        end
    end

    table.sort(itemIDs, function(left, right)
        return ES:GetItemLabel(left) < ES:GetItemLabel(right)
    end)

    return itemIDs
end

local function UpdateWhitelistScroll()
    local panel = ES.whitelistPanel
    if not panel or not panel.scrollFrame then
        return
    end

    local count = #GetSortedWhitelist()
    local height = math.max(1, count * 34)
    panel.scrollChild:SetHeight(height)

    local maxScroll = math.max(0, height - panel.scrollFrame:GetHeight())
    panel.scrollBar:SetMinMaxValues(0, maxScroll)

    if panel.scrollBar:GetValue() > maxScroll then
        panel.scrollBar:SetValue(maxScroll)
    end

    panel.scrollBar:SetShown(maxScroll > 0)
end

function ES:RefreshOptions()
    local db = self:GetDB()

    if self.generalPanel then
        self.generalPanel.enabledCheck:SetChecked(db.enabled)
        self.generalPanel.profileCheck:SetChecked(EasySellCharDB.useCharacterSettings)
        self.generalPanel.soulboundCheck:SetChecked(db.protectSoulbound)
        self.generalPanel.unboundCheck:SetChecked(db.sellUnboundEquipment)
        if UIDropDownMenu_SetText and self.generalPanel.providerDropDown then
            UIDropDownMenu_SetText(self.generalPanel.providerDropDown, "Provider: " .. self:GetProviderLabel(db.provider))
        end
        if UIDropDownMenu_SetText and self.generalPanel.rarityDropDown then
            UIDropDownMenu_SetText(self.generalPanel.rarityDropDown, "Sell up to: " .. self:GetMaxQualityLabel())
        end
        self.generalPanel.sessionText:SetText("Session total: " .. GetCoinTextureString(self.sessionTotal or 0))
    end

    if self.whitelistPanel then
        local whitelist = GetSortedWhitelist()
        self.whitelistPanel.emptyText:SetShown(#whitelist == 0)
        self.whitelistPanel.scrollFrame:SetShown(#whitelist > 0)

        for index, itemID in ipairs(whitelist) do
            local row = whitelistRows[index]
            if not row then
                row = CreateFrame("Frame", nil, self.whitelistPanel.scrollChild)
                row:SetSize(540, 30)
                row:SetPoint("TOPLEFT", self.whitelistPanel.scrollChild, "TOPLEFT", 0, -((index - 1) * 34))

                row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.label:SetPoint("LEFT", 6, 0)
                row.label:SetJustifyH("LEFT")
                row.label:SetWidth(400)

                row.delete = CreateButton(row, "Delete", 74)
                row.delete:SetPoint("RIGHT", -6, 0)

                whitelistRows[index] = row
            end

            row.label:SetText(self:GetItemLabel(itemID))
            row.delete:SetScript("OnClick", function()
                ES:SetWhitelisted(itemID, false)
            end)
            row:Show()
        end

        for index = #whitelist + 1, #whitelistRows do
            whitelistRows[index]:Hide()
        end

        UpdateWhitelistScroll()
    end
end

function ES:OpenOptions()
    if Settings and Settings.OpenToCategory and self.settingsCategoryID then
        Settings.OpenToCategory(self.settingsCategoryID)
        return
    end

    if InterfaceOptionsFrame_OpenToCategory and self.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    end
end

local function AddWhitelistItem()
    if AddCursorItem() then
        return
    end

    StaticPopupDialogs.EASYSELL_ADD_WHITELIST_ITEM = {
        text = "Enter item link or item ID to whitelist",
        button1 = OKAY,
        button2 = CANCEL,
        hasEditBox = true,
        OnAccept = function(dialog)
            local editBox = dialog.editBox or dialog.EditBox or (dialog.GetEditBox and dialog:GetEditBox())
            local itemID = editBox and ES:GetItemIDFromInput(editBox:GetText())

            if not itemID then
                ES.Print("Please enter an item link or item ID.")
                return
            end

            ES:SetWhitelisted(itemID, true)
            ES.Print("Whitelisted " .. ES:GetItemLabel(itemID) .. ".")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopup_Show("EASYSELL_ADD_WHITELIST_ITEM")
end

local mainPanel = CreateFrame("Frame")
mainPanel.name = "EasySell"
ES.optionsPanel = mainPanel
ES.generalPanel = mainPanel

mainPanel.title = CreateTitle(mainPanel, "EasySell")

mainPanel.description = CreateText(mainPanel, "Automatically sells vendor trash and optional item rarities at merchants.")
mainPanel.description:SetPoint("TOPLEFT", mainPanel.title, "BOTTOMLEFT", 0, -8)

mainPanel.enabledCheck = CreateFrame("CheckButton", nil, mainPanel, "InterfaceOptionsCheckButtonTemplate")
mainPanel.enabledCheck:SetPoint("TOPLEFT", mainPanel.description, "BOTTOMLEFT", 0, -18)
mainPanel.enabledCheck.Text:SetText("Enable automatic selling")
mainPanel.enabledCheck:SetScript("OnClick", function(self)
    ES:GetDB().enabled = self:GetChecked()
    ES:SyncProviderState(false)
end)

mainPanel.profileCheck = CreateFrame("CheckButton", nil, mainPanel, "InterfaceOptionsCheckButtonTemplate")
mainPanel.profileCheck:SetPoint("TOPLEFT", mainPanel.enabledCheck, "BOTTOMLEFT", 0, -8)
mainPanel.profileCheck.Text:SetText("Use per-character settings")
mainPanel.profileCheck:SetScript("OnClick", function(self)
    ES:SetUseCharacterSettings(self:GetChecked())
    ES.Print("Using " .. (EasySellCharDB.useCharacterSettings and "character" or "account") .. " settings.")
end)

mainPanel.providerLabel = CreateText(mainPanel, "Provider", "GameFontNormal")
mainPanel.providerLabel:SetPoint("TOPLEFT", mainPanel.profileCheck, "BOTTOMLEFT", 2, -18)

mainPanel.providerDropDown = CreateFrame("Frame", "EasySellProviderDropDown", mainPanel, "UIDropDownMenuTemplate")
mainPanel.providerDropDown:SetPoint("TOPLEFT", mainPanel.providerLabel, "BOTTOMLEFT", -18, -4)
InitializeProviderDropdown(mainPanel.providerDropDown)

mainPanel.rarityLabel = CreateText(mainPanel, "Rarity threshold", "GameFontNormal")
mainPanel.rarityLabel:SetPoint("TOPLEFT", mainPanel.providerDropDown, "BOTTOMLEFT", 18, -12)

mainPanel.rarityDropDown = CreateFrame("Frame", "EasySellRarityDropDown", mainPanel, "UIDropDownMenuTemplate")
mainPanel.rarityDropDown:SetPoint("TOPLEFT", mainPanel.rarityLabel, "BOTTOMLEFT", -18, -4)
InitializeRarityDropdown(mainPanel.rarityDropDown)

local rarityDropDownButton = _G.EasySellRarityDropDownButton or mainPanel.rarityDropDown.Button
if rarityDropDownButton and rarityDropDownButton.HookScript then
    rarityDropDownButton:HookScript("OnClick", function()
        if IsShiftKeyDown and IsShiftKeyDown() then
            ES:PrintPreview()
        end
    end)
else
    mainPanel.rarityDropDown:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and IsShiftKeyDown and IsShiftKeyDown() then
            ES:PrintPreview()
        end
    end)
end

mainPanel.previewButton = CreateButton(mainPanel, "Preview", 90)
mainPanel.previewButton:SetPoint("LEFT", mainPanel.rarityDropDown, "RIGHT", -8, 2)
mainPanel.previewButton:SetScript("OnClick", function()
    ES:PrintPreview()
end)

mainPanel.soulboundCheck = CreateFrame("CheckButton", nil, mainPanel, "InterfaceOptionsCheckButtonTemplate")
mainPanel.soulboundCheck:SetPoint("TOPLEFT", mainPanel.rarityDropDown, "BOTTOMLEFT", 18, -12)
mainPanel.soulboundCheck.Text:SetText("Protect soulbound items above grey")
mainPanel.soulboundCheck:SetScript("OnClick", function(self)
    ES:GetDB().protectSoulbound = self:GetChecked()
end)

mainPanel.unboundCheck = CreateFrame("CheckButton", nil, mainPanel, "InterfaceOptionsCheckButtonTemplate")
mainPanel.unboundCheck:SetPoint("TOPLEFT", mainPanel.soulboundCheck, "BOTTOMLEFT", 0, -8)
mainPanel.unboundCheck.Text:SetText("Allow selling BoE and Warbound equipment")
mainPanel.unboundCheck:SetScript("OnClick", function(self)
    ES:GetDB().sellUnboundEquipment = self:GetChecked()
end)

mainPanel.sessionText = CreateText(mainPanel, "Session total: 0", "GameFontHighlight")
mainPanel.sessionText:SetPoint("TOPLEFT", mainPanel.unboundCheck, "BOTTOMLEFT", 2, -16)

mainPanel.whitelistHint = CreateText(mainPanel, "Use the Whitelist tab to protect specific items from automatic selling.", "GameFontDisableSmall")
mainPanel.whitelistHint:SetPoint("TOPLEFT", mainPanel.sessionText, "BOTTOMLEFT", 0, -14)

mainPanel:SetScript("OnShow", function()
    ES:RefreshOptions()
end)

local whitelistPanel = CreateFrame("Frame")
whitelistPanel.name = "Whitelist"
whitelistPanel.parent = "EasySell"
whitelistPanel:EnableMouse(true)
ES.whitelistPanel = whitelistPanel

whitelistPanel.title = CreateTitle(whitelistPanel, "Whitelist")

whitelistPanel.addItem = CreateButton(whitelistPanel, "Add item", 90)
whitelistPanel.addItem:SetPoint("TOPLEFT", whitelistPanel.title, "BOTTOMLEFT", 0, -16)
whitelistPanel.addItem:SetScript("OnClick", AddWhitelistItem)
whitelistPanel.addItem:SetScript("OnReceiveDrag", AddCursorItem)
whitelistPanel.addItem:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
        AddCursorItem()
    end
end)

whitelistPanel.dropHint = CreateText(whitelistPanel, "Drag an item here to whitelist it.", "GameFontDisableSmall")
whitelistPanel.dropHint:SetPoint("LEFT", whitelistPanel.addItem, "RIGHT", 10, 0)

whitelistPanel.emptyText = whitelistPanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
whitelistPanel.emptyText:SetPoint("TOPLEFT", whitelistPanel.addItem, "BOTTOMLEFT", 6, -28)
whitelistPanel.emptyText:SetText("No whitelisted items")

whitelistPanel.scrollFrame = CreateFrame("ScrollFrame", nil, whitelistPanel)
whitelistPanel.scrollFrame:SetPoint("TOPLEFT", whitelistPanel.addItem, "BOTTOMLEFT", 0, -28)
whitelistPanel.scrollFrame:SetSize(560, 404)
whitelistPanel.scrollFrame:EnableMouse(true)

whitelistPanel.scrollChild = CreateFrame("Frame", nil, whitelistPanel.scrollFrame)
whitelistPanel.scrollChild:SetSize(540, 1)
whitelistPanel.scrollFrame:SetScrollChild(whitelistPanel.scrollChild)

whitelistPanel.scrollBar = CreateFrame("Slider", nil, whitelistPanel.scrollFrame, "UIPanelScrollBarTemplate")
whitelistPanel.scrollBar:SetPoint("TOPLEFT", whitelistPanel.scrollFrame, "TOPRIGHT", -18, -16)
whitelistPanel.scrollBar:SetPoint("BOTTOMLEFT", whitelistPanel.scrollFrame, "BOTTOMRIGHT", -18, 16)
whitelistPanel.scrollBar:SetValueStep(34)
whitelistPanel.scrollBar:SetObeyStepOnDrag(true)
whitelistPanel.scrollBar:SetScript("OnValueChanged", function(_, value)
    whitelistPanel.scrollFrame:SetVerticalScroll(value)
end)
whitelistPanel.scrollBar:Hide()

whitelistPanel.scrollFrame:EnableMouseWheel(true)
whitelistPanel.scrollFrame:SetScript("OnReceiveDrag", AddCursorItem)
whitelistPanel.scrollFrame:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
        AddCursorItem()
    end
end)
whitelistPanel.scrollFrame:SetScript("OnMouseWheel", function(_, delta)
    local current = whitelistPanel.scrollBar:GetValue()
    local minValue, maxValue = whitelistPanel.scrollBar:GetMinMaxValues()
    local nextValue = current - (delta * 34)
    whitelistPanel.scrollBar:SetValue(math.min(maxValue, math.max(minValue, nextValue)))
end)

whitelistPanel:SetScript("OnShow", function()
    ES:RefreshOptions()
end)
whitelistPanel:SetScript("OnReceiveDrag", AddCursorItem)
whitelistPanel:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
        AddCursorItem()
    end
end)

local function GetCategoryID(category)
    if type(category) == "table" and category.GetID then
        return category:GetID()
    end

    return category and category.ID
end

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterCanvasLayoutSubcategory then
    local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name, mainPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(category, whitelistPanel, whitelistPanel.name, whitelistPanel.name)
    Settings.RegisterAddOnCategory(category)
    ES.settingsCategoryID = GetCategoryID(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(mainPanel)
    InterfaceOptions_AddCategory(whitelistPanel)
end
