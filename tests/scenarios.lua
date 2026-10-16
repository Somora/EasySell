local ES = EasySell
ES:InitializeDatabase()
ES:RefreshOptions()
assert(ES.generalPanel.sessionText.text == "Session total: 0 copper")
ES:OpenOptions()
assert(TEST_OPEN_CATEGORY == (TEST_CLIENT == "retail" and 35 or ES.optionsPanel))

local matches, money, count = ES:GetMatchingItems()
assert(#matches == 1 and money == 24 and count == 2, "Default must sell only junk")
ES:PrintPreview()
ES:SellMatchingItems()
assert(#TEST_SOLD == 1 and ES.sessionTotal == 24)
SlashCmdList.EASYSELL("session")
assert(string.find(TEST_MESSAGES[#TEST_MESSAGES], "Session total: 24 copper.", 1, true))

ES:SetWhitelisted(100, true)
assert(#ES:GetMatchingItems() == 0)
ES:SetWhitelisted(100, false)
TEST_ITEMS[100].locked = true
assert(#ES:GetMatchingItems() == 0)
TEST_ITEMS[100].locked = false
TEST_ITEMS[100].noValue = true
assert(#ES:GetMatchingItems() == 0)
TEST_ITEMS[100].noValue = false
TEST_ITEMS[100].uncached = true
assert(#ES:GetMatchingItems() == 0, "Missing item cache must never sell")
TEST_ITEMS[100].uncached = false

local db = ES:GetDB()
db.maxQuality = 2
assert(#ES:GetMatchingItems() == 1, "Soulbound protection")
db.protectSoulbound = false
assert(#ES:GetMatchingItems() == 2, "Only soulbound equipment plus junk")
db.sellUnboundEquipment = true
assert(#ES:GetMatchingItems() == 3, "Reagents must still be excluded")

SlashCmdList.EASYSELL("keep cursor")
assert(ES:IsWhitelisted(100) and TEST_CURSOR_CLEARED)
ES.whitelistPanel.addItem.scripts.OnClick()
-- Cursor path adds the item immediately. Exercise typed input separately.
GetCursorInfo = function() return nil end
ES.whitelistPanel.addItem.scripts.OnClick()
local dialog = {EditBox = {GetText = function() return "101" end}}
TEST_POPUP.OnAccept(dialog)
assert(ES:IsWhitelisted(101))
ES:SetUseCharacterSettings(true)
assert(EasySellCharDB.useCharacterSettings and ES:IsWhitelisted(101))
ES:SetUseCharacterSettings(false)

ZGV = {db = {profile = {autosell = true, enable_vendor_tools = true}}}
assert(ES:MaybePromptForProviderSelection())
EasySellProviderPopup.buttons[1].scripts.OnClick()
assert(not EasySellProviderPopup.shown, "Provider selection must refresh options and close")
assert(not ZGV.db.profile.autosell)
ES:SetProvider(ES.PROVIDER_ZYGOR)
assert(ZGV.db.profile.autosell)
ES:SetProvider(ES.PROVIDER_EASYSELL)
ElvUI = {{db = {bags = {vendorGrays = {enable = true}}}}}
ES:SetProvider(ES.PROVIDER_EASYSELL)
assert(not ElvUI[1].db.bags.vendorGrays.enable)
ES:SetProvider(ES.PROVIDER_ELVUI)
assert(ElvUI[1].db.bags.vendorGrays.enable)
ES:SetProvider(ES.PROVIDER_EASYSELL)

for _, frame in ipairs(TEST_FRAMES) do
    if frame.events.PLAYER_LOGIN then frame.scripts.OnEvent(frame, "PLAYER_LOGIN") end
    if frame.events.MERCHANT_SHOW then frame.scripts.OnEvent(frame, "MERCHANT_SHOW") end
end
assert(ES.playerLoggedIn)
