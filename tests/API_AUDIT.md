# Retail API audit — 2026-10-16, follow-up 2026-10-23

Reviewed all seven modules in version 1.0.8 against Blizzard's generated API
documentation and UI Lua/XML in the Gethe/wow-ui-source `live` snapshot downloaded
on this date. This is a source audit and mocked Lua 5.1 execution, not an in-game
certification. The live branch can change independently of an installed client.

## Results

- No additional unguarded calls to removed global APIs were identified on the
  Retail paths after the 1.0.6 and 1.0.8 fixes.
- Item data uses `C_Item.GetItemInfo`; money text uses
  `C_CurrencyInfo.GetCoinTextureString` in all three consumers.
- Bag enumeration and selling use `C_Container`; ElvUI detection uses
  `C_AddOns.IsAddOnLoaded`. The old global calls are Classic fallbacks.
- Settings registration/opening uses `Settings`. The old `InterfaceOptions_*`
  helpers are guarded fallbacks. Cursor operations remain global APIs in
  `GameCursorDocumentation.lua`.
- `UIDropDownMenu_*` functions and `UIDropDownMenuTemplate` remain defined in
  the current Mainline UI. Migration to the newer menu system is optional,
  not a fix for a confirmed missing API.
- `InterfaceOptionsCheckButtonTemplate` still exists in
  `Blizzard_FrameXML/DeprecatedTemplates.xml`. Replaced its four uses with its
  supported base, `UICheckButtonTemplate`, keeping the original 26x26 size.
  This removes a deprecated dependency; it was not a confirmed 12.1.5 crash.
- `GameTooltip:SetBagItem` is supplied by `TooltipDataHandler.lua`. Tooltip
  methods, scrollbar templates, StaticPopup and frame APIs used here remain
  present. The October 23 follow-up replaces Retail binding tooltip scanning
  with the location-based binding API; older clients retain the tooltip fallback.

## Regression checks

`test_compatibility.py` executes the actual seven modules in Lua 5.1 using Lupa,
once with only modern Retail namespaces and once with only legacy Classic APIs.
Removed Retail globals are absent. UI objects expose an explicit set of modeled
methods rather than accepting every unknown method.

Scenarios cover module loading, settings refresh/opening, preview and selling,
session totals, locked/valueless/uncached items, whitelist cursor and typed input,
per-character settings, soulbound/BoE/reagent rules, provider popup selection,
ElvUI/Zygor switching, login and merchant events. Both profiles pass.

Run with Python and `lupa` installed:

```text
python tests/test_compatibility.py
```

These tests cannot reproduce Blizzard rendering, secure execution, combat taint,
secret values, asynchronous item cache behavior, real inventory mutation, or
third-party addon internals. Verify login, provider choice, options, whitelist,
preview and a merchant sale on Retail 12.1.5 before claiming full compatibility.

## Source references

- [Generated API documentation](https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_APIDocumentationGenerated)
- [Settings API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua)
- [Mainline dropdown functions](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Mainline/UIDropDownMenu.lua)
- [Deprecated templates](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/DeprecatedTemplates.xml)
- [Supported checkboxes](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml)
- [Tooltip data handler](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua)

## Secret values and taint follow-up — 2026-10-23

Rechecked the current live Item/Container API documentation, tooltip data handler,
ItemLocation implementation and merchant implementation against all seven addon
modules. No further removed API calls were identified. This is not evidence that
every possible addon combination is taint-free.

### Changes made

- Retail binding detection calls `C_Item.IsBound` with
  `ItemLocation:CreateFromBagAndSlot`. It no longer creates an inspection tooltip
  or executes tooltip rendering callbacks to make a selling decision. The API
  reports binding, including binding types other than traditional soulbinding;
  treating bound equipment conservatively is consistent with item protection.
- The older-client tooltip fallback checks `issecretvalue` before branching on
  or comparing text. Restricted text yields unknown binding; unknown binding
  cannot bypass enabled soulbound protection, even with unbound selling enabled.
- Both sale entry points require a shown merchant and no combat lockdown.
  This is defensive: container use outside a merchant can use/equip an item.
  Sales skipped during combat are not automatically retried after combat.
- Container-call errors reset the sale lock and are rethrown for normal error
  reporting. Summary callbacks release the lock before formatting text or
  refreshing options. This fixes a reproducible stuck-state path independent of
  whether the original failure came from API removal, UI code or another error.
- Only submitted stacks contribute to the summary if the merchant closes in the
  loop. A successful API call is still not confirmation of a server-side sale;
  existing earnings remain estimates. A partial batch followed by a thrown API
  error is not counted in session earnings.

### Source findings and remaining runtime checks

- The relevant item, binding and container fields are not annotated with secret
  return predicates in the examined generated documentation. The annotation
  `SecretArguments = "AllowedWhenUntainted"` describes secret *inputs*, not a
  claim that returned bag data is secret. No blanket secret guards were added to
  ordinary saved settings or bag metadata based only on that annotation.
- Core/Commands operate on addon settings, cursor data and local amounts, rather
  than restricted combat unit data. There are no secure action buttons, protected
  attribute writes, replacements of Blizzard API functions or global hooks here.
- Provider integration writes ElvUI/Zygor addon configuration and optionally calls
  ElvUI's `SaveSettings`. This does not establish a Blizzard taint chain by itself;
  interactions with those addons must still be checked in game.
- The custom provider dialog does not use shared StaticPopup frames. Whitelist
  text entry still registers its own `StaticPopupDialogs` entry and uses Blizzard's
  popup pool. Legacy dropdowns also share Blizzard menu infrastructure. No concrete
  blocked-action chain was reproduced; these surfaces are not certified taint-free.
  Their existence alone is not a reason to claim that a security failure occurred.

`restrictions.lua` adds merchant/combat checks, tooltip-free Retail binding,
conservative handling of a marked opaque tooltip stand-in, container error
recovery, UI error recovery, and interrupted batch accounting. Both Lua 5.1 client
profiles pass. The opaque stand-in only tests guard ordering and policy: standard
Lua cannot reproduce WoW's secret-value rules or taint propagation.

In-game follow-up: test login and provider changes, whitelist input followed by
logout, opening options and dropdowns, preview, ordinary merchant sales and a
merchant reachable during combat. Capture actual blocked-action errors/taint logs
if present; a clean mock run cannot replace this.

Additional references:

- [Item binding API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
- [Container API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)
- [ItemLocation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ObjectAPI/Mainline/ItemLocation.lua)
- [Merchant UI](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua)
