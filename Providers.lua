local ES = EasySell

local C_AddOns = C_AddOns
local IsAddOnLoaded = IsAddOnLoaded
local pairs = pairs
local pcall = pcall
local table = table
local type = type

function ES:GetProviderLabel(provider)
    if provider == self.PROVIDER_ELVUI then
        return "ElvUI"
    end

    if provider == self.PROVIDER_ZYGOR then
        return "Zygor"
    end

    return "EasySell"
end

function ES:IsElvUIAvailable()
    if type(_G.ElvUI) == "table" and type(_G.ElvUI[1]) == "table" then
        return true
    end

    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" and C_AddOns.IsAddOnLoaded(self.ELVUI_ADDON_NAME) then
        return true
    end

    if IsAddOnLoaded and IsAddOnLoaded(self.ELVUI_ADDON_NAME) then
        return true
    end

    return false
end

function ES:IsZygorAvailable()
    return (_G.ZGV or _G.ZygorGuidesViewer) and true or false
end

function ES:GetAvailableProviders()
    local providers = { self.PROVIDER_EASYSELL }
    local elvUIAvailable = self:IsElvUIAvailable()
    local zygorAvailable = self:IsZygorAvailable()
    local db = self:GetDB()

    db.elvUIDetected = elvUIAvailable and true or false
    db.zygorDetected = zygorAvailable and true or false

    if elvUIAvailable then
        providers[#providers + 1] = self.PROVIDER_ELVUI
    end

    if zygorAvailable then
        providers[#providers + 1] = self.PROVIDER_ZYGOR
    end

    return providers
end

function ES:BuildProviderSignature(providers)
    return table.concat(providers, "|")
end

function ES:GetElvUIEngine()
    local elvUI = _G.ElvUI
    if type(elvUI) ~= "table" or type(elvUI[1]) ~= "table" then
        return nil
    end

    if type(elvUI[1].db) ~= "table" then
        return nil
    end

    return elvUI[1]
end

function ES:GetZygorEngine()
    local engine = _G.ZGV or _G.ZygorGuidesViewer
    if type(engine) ~= "table" or type(engine.db) ~= "table" or type(engine.db.profile) ~= "table" then
        return nil
    end

    return engine
end

function ES:GetElvUIAutoSell()
    local engine = self:GetElvUIEngine()
    if not engine then
        return nil
    end

    if type(engine.db.bags) == "table" and type(engine.db.bags.vendorGrays) == "table" then
        return engine.db.bags.vendorGrays.enable and true or false
    end

    if type(engine.db.general) == "table" and engine.db.general.vendorGrays ~= nil then
        return engine.db.general.vendorGrays and true or false
    end

    return nil
end

function ES:SetElvUIAutoSell(enabled)
    local engine = self:GetElvUIEngine()
    if not engine then
        return false
    end

    if type(engine.db.bags) == "table" and type(engine.db.bags.vendorGrays) == "table" then
        engine.db.bags.vendorGrays.enable = enabled and true or false
    elseif type(engine.db.general) == "table" and engine.db.general.vendorGrays ~= nil then
        engine.db.general.vendorGrays = enabled and true or false
    else
        return false
    end

    if type(engine.SaveSettings) == "function" then
        pcall(engine.SaveSettings, engine)
    end

    return true
end

function ES:GetZygorAutoSell()
    local engine = self:GetZygorEngine()
    if not engine then
        return nil
    end

    return engine.db.profile.autosell and true or false
end

function ES:SetZygorAutoSell(enabled)
    local engine = self:GetZygorEngine()
    if not engine then
        return false
    end

    local db = self:GetDB()
    if enabled then
        if engine.db.profile.enable_vendor_tools == false then
            db.zygorEnableVendorTools = false
            engine.db.profile.enable_vendor_tools = true
        end

        engine.db.profile.autosell = true
    else
        if engine.db.profile.autosell then
            db.zygorEnableVendorTools = engine.db.profile.enable_vendor_tools and true or false
        end

        engine.db.profile.autosell = false
        if db.zygorEnableVendorTools == false then
            engine.db.profile.enable_vendor_tools = false
        end
    end

    return true
end

function ES:SyncProviderState(notify)
    local db = self:GetDB()
    local elvUIAvailable = self:IsElvUIAvailable()
    local zygorAvailable = self:IsZygorAvailable()
    local provider = db.provider

    db.elvUIDetected = elvUIAvailable and true or false
    db.zygorDetected = zygorAvailable and true or false

    if not db.enabled then
        if elvUIAvailable then
            self:SetElvUIAutoSell(false)
        end
        if zygorAvailable then
            self:SetZygorAutoSell(false)
        end
        if notify then
            self.Print("Auto sell is disabled.")
        end
        return
    end

    if provider == self.PROVIDER_ELVUI then
        if zygorAvailable then
            self:SetZygorAutoSell(false)
        end

        if elvUIAvailable then
            self:SetElvUIAutoSell(true)
            if notify then
                self.Print("Sell provider set to ElvUI.")
            end
        elseif notify then
            self.Print("ElvUI was selected, but ElvUI is not loaded.")
        end
        return
    end

    if provider == self.PROVIDER_ZYGOR then
        if elvUIAvailable then
            self:SetElvUIAutoSell(false)
        end

        if zygorAvailable then
            self:SetZygorAutoSell(true)
            if notify then
                self.Print("Sell provider set to Zygor.")
            end
        elseif notify then
            self.Print("Zygor was selected, but Zygor is not loaded.")
        end
        return
    end

    if elvUIAvailable then
        self:SetElvUIAutoSell(false)
    end
    if zygorAvailable then
        self:SetZygorAutoSell(false)
    end

    if notify then
        self.Print("Sell provider set to EasySell.")
    end
end

function ES:SetProvider(provider)
    local db = self:GetDB()
    db.provider = provider
    db.providerPromptSignature = self:BuildProviderSignature(self:GetAvailableProviders())
    self.promptedSessionSignature = db.providerPromptSignature
    self:SyncProviderState(true)

    if provider == self.PROVIDER_ELVUI then
        self.Print("EasySell selling will stay inactive while ElvUI handles grey items.")
    elseif provider == self.PROVIDER_ZYGOR then
        self.Print("EasySell selling will stay inactive while Zygor handles grey items.")
    else
        self.Print("ElvUI and Zygor auto selling have been disabled when available.")
    end

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

function ES:IsProviderConfigurationOutOfSync()
    local db = self:GetDB()
    if not db.enabled then
        return false
    end

    local provider = db.provider
    local elvSell = self:GetElvUIAutoSell()
    local zygorSell = self:GetZygorAutoSell()

    if provider == self.PROVIDER_EASYSELL then
        return elvSell == true or zygorSell == true
    end

    if provider == self.PROVIDER_ELVUI then
        return elvSell == false or zygorSell == true
    end

    if provider == self.PROVIDER_ZYGOR then
        return elvSell == true or zygorSell == false
    end

    return false
end
