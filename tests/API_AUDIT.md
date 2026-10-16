# Retail API audit — 2026-10-16

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
  present. Soulbound tooltip scanning is retained; localized/rendered tooltip
  behavior still needs verification in game.

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
