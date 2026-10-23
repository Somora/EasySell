local ES = EasySell
local db = ES:GetDB()
db.maxQuality, db.protectSoulbound, db.sellUnboundEquipment = 2, false, true
db.whitelist = {}

-- Retail must never render a tooltip just to determine binding.
local scans = TEST_TOOLTIP_SCANS or 0
assert(ES:IsBagItemSoulbound(0, 2))
assert(not ES:IsBagItemSoulbound(0, 3))
if TEST_CLIENT == "retail" then
    assert((TEST_TOOLTIP_SCANS or 0) == scans)
    assert(EasySellTooltip == nil)
end

-- A marked opaque stand-in exercises guard ordering, not real WoW secrets.
if TEST_CLIENT == "classic" then
    TEST_SECRET = {}
    assert(not ES:IsBagItemSoulbound(0, 2))
    db.protectSoulbound = true
    assert(#ES:GetMatchingItems() == 1, "Unknown binding must protect non-junk equipment")
    db.protectSoulbound = false
    TEST_SECRET = nil
end

local sold = #TEST_SOLD
MerchantFrame:Hide()
ES:SellMatchingItems()
assert(not ES:UseBagItem(0, 1) and #TEST_SOLD == sold)
MerchantFrame:Show()
TEST_COMBAT = true
ES:SellMatchingItems()
assert(not ES:UseBagItem(0, 1) and #TEST_SOLD == sold)
TEST_COMBAT = false

-- A failed container call must not permanently lock out subsequent sales.
TEST_USE_ERROR = true
assert(not pcall(function() ES:SellMatchingItems() end))
TEST_USE_ERROR = false
ES:SellMatchingItems()
assert(#TEST_SOLD > sold)

-- The same recovery must work when UI refresh fails after submission.
local refresh = ES.RefreshOptions
ES.RefreshOptions = function() error("simulated UI refresh failure") end
assert(not pcall(function() ES:SellMatchingItems() end))
ES.RefreshOptions = refresh
sold = #TEST_SOLD
ES:SellMatchingItems()
assert(#TEST_SOLD > sold)

-- Stop if the merchant disappears midway, and count only submitted stacks.
sold = #TEST_SOLD
local total = ES.sessionTotal
TEST_CLOSE_MERCHANT = true
ES:SellMatchingItems()
assert(#TEST_SOLD == sold + 1 and ES.sessionTotal == total + 24)
TEST_CLOSE_MERCHANT = false
MerchantFrame:Show()
