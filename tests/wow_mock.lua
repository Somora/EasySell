-- Only explicitly modeled UI methods exist: unknown method calls must fail.
local methods = {}
local function noop() end
for name in string.gmatch([[SetPoint SetSize SetWidth SetHeight SetJustifyH
    EnableMouse EnableMouseWheel EnableKeyboard SetFrameStrata SetToplevel
    SetAllPoints SetColorTexture SetTexture SetScrollChild SetValueStep
    SetObeyStepOnDrag SetVerticalScroll SetOwner ClearLines]], "%S+") do
    methods[name] = noop
end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value end
function methods:GetHeight() return 404 end
function methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
function methods:GetMinMaxValues() return self.low or 0, self.high or 0 end
function methods:GetValue() return self.value or 0 end
function methods:SetValue(value)
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
local function object()
    return setmetatable({scripts = {}, events = {}}, {__index = methods})
end
function methods:CreateFontString() return object() end
function methods:CreateTexture() return object() end
TEST_FRAMES, TEST_MESSAGES, TEST_SOLD = {}, {}, {}
function CreateFrame(kind, name, parent, template)
    assert(template ~= "InterfaceOptionsCheckButtonTemplate", "Deprecated checkbox template")
    local frame = object()
    frame.template = template
    if kind == "CheckButton" then frame.Text = object() end
    if template == "UIDropDownMenuTemplate" then frame.Button = object() end
    if name then _G[name] = frame end
    TEST_FRAMES[#TEST_FRAMES + 1] = frame
    return frame
end
UIParent = object()
MerchantFrame = object()
MerchantFrame:Show()
function InCombatLockdown() return TEST_COMBAT or false end
function issecretvalue(value) return value == TEST_SECRET and TEST_SECRET ~= nil end
function print(message) TEST_MESSAGES[#TEST_MESSAGES + 1] = message end
strmatch, strlower = string.match, string.lower
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
NUM_BAG_SLOTS, ITEM_SOULBOUND = 4, "Soulbound"
Enum = {ItemClass = {Weapon = 2, Armor = 4}}
SlashCmdList, StaticPopupDialogs = {}, {}
OKAY, CANCEL = "Okay", "Cancel"
function StaticPopup_Show(which) TEST_POPUP = StaticPopupDialogs[which] end
function GetCursorInfo() return "item", 100, "item:100" end
function ClearCursor() TEST_CURSOR_CLEARED = true end
function IsShiftKeyDown() return false end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_Initialize(frame, callback) frame.initialize = callback; callback() end
function UIDropDownMenu_AddButton() end
function UIDropDownMenu_SetWidth() end
function UIDropDownMenu_SetText(frame, text) frame.text = text end
C_Timer = {After = function(_, callback) callback() end}
TEST_ITEMS = {
    [100] = {quality = 0, price = 12, count = 2, class = 15, equip = "", bound = false},
    [101] = {quality = 2, price = 100, count = 1, class = 4, equip = "INVTYPE_HEAD", bound = true},
    [102] = {quality = 2, price = 100, count = 1, class = 4, equip = "INVTYPE_HEAD", bound = false},
    [103] = {quality = 2, price = 100, count = 1, class = 7, equip = "", bound = false},
}
TEST_BAGS = {100, 101, 102, 103}
local function info(link)
    local id = tonumber(link) or tonumber(string.match(link, "item:(%d+)"))
    local item = TEST_ITEMS[id]
    if not item or item.uncached then return nil end
    return "Item " .. id, "item:" .. id, item.quality, 1, 1, "", "", 1,
        item.equip, 123, item.price, item.class, 0, item.bound and 1 or 2
end
local function slots(bag) return bag == 0 and #TEST_BAGS or 0 end
local function container(bag, slot)
    local id = bag == 0 and TEST_BAGS[slot]
    local item = id and TEST_ITEMS[id]
    if not item then return nil end
    return {hyperlink = "item:" .. id, stackCount = item.count, quality = item.quality,
        isLocked = item.locked, hasNoValue = item.noValue}
end
local function use(bag, slot)
    if TEST_USE_ERROR then error("simulated use failure") end
    TEST_SOLD[#TEST_SOLD + 1] = {bag, slot}
    if TEST_CLOSE_MERCHANT then MerchantFrame:Hide() end
end
local function money(value) return tostring(value) .. " copper" end
function methods:SetBagItem(bag, slot)
    TEST_TOOLTIP_SCANS = (TEST_TOOLTIP_SCANS or 0) + 1
    local item = TEST_ITEMS[TEST_BAGS[slot]]
    EasySellTooltipTextLeft2 = object()
    EasySellTooltipTextLeft2:SetText(TEST_SECRET or (item.bound and ITEM_SOULBOUND or "Unbound"))
end
function methods:NumLines() return 2 end
if TEST_CLIENT == "retail" then
    -- No legacy GetItemInfo, GetCoinTextureString, container globals,
    -- IsAddOnLoaded, LE_ITEM_CLASS_*, or InterfaceOptions_* helpers.
    ItemLocation = {CreateFromBagAndSlot = function(_, bag, slot) return {bag = bag, slot = slot} end}
    C_Item = {GetItemInfo = info, IsBound = function(location)
        return TEST_ITEMS[TEST_BAGS[location.slot]].bound
    end}
    C_CurrencyInfo = {GetCoinTextureString = money}
    C_Container = {GetContainerNumSlots = slots, GetContainerItemInfo = container,
        UseContainerItem = use}
    C_AddOns = {IsAddOnLoaded = function() return false end}
    Settings = {
        RegisterCanvasLayoutCategory = function() return {GetID = function() return 35 end} end,
        RegisterCanvasLayoutSubcategory = function() end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function(id) TEST_OPEN_CATEGORY = id end,
    }
else
    GetItemInfo, GetCoinTextureString = info, money
    GetContainerNumSlots, UseContainerItem = slots, use
    function GetContainerItemInfo(bag, slot)
        local item = container(bag, slot)
        if not item then return nil end
        return 123, item.stackCount, item.isLocked, item.quality, false, false,
            item.hyperlink, false, item.hasNoValue
    end
    function IsAddOnLoaded() return false end
    function InterfaceOptions_AddCategory() end
    function InterfaceOptionsFrame_OpenToCategory(frame) TEST_OPEN_CATEGORY = frame end
end
