# Changelog

## 1.0.3

- Replaces the provider selection StaticPopup with a custom EasySell dialog to avoid Blizzard protected popup taint during logout.

## 1.0.2

- Prevents the provider selection popup from reappearing only because Zygor is enabled on one character and disabled on another.
- Keeps provider drift detection active for real ElvUI or Zygor auto-sell setting changes.

## 1.0.1

- Adds provider selection for EasySell, ElvUI, and Zygor.
- Adds login/reload provider selection and drift detection when ElvUI or Zygor auto-sell settings change outside EasySell.
- Syncs ElvUI grey selling through ElvUI's current vendor grays setting.
- Preserves Zygor vendor tools state while handing grey selling to Zygor.

## 1.0.0

- Initial release.
- Splits the addon into Core, Items, Vendor, Options, and Commands modules.
- Automatically sells poor/grey vendor trash at merchants.
- Adds configurable rarity thresholds through `/esell`.
- Adds an options menu with a whitelist for protected items.
- Supports dragging items into the Whitelist options tab.
- Tracks session earnings with `/esell session`.
- Protects soulbound items above grey quality by default.
- Adds `/esell preview`, a Preview options button, and shift-click preview on the rarity dropdown.
- Replaces the rarity cycle button with a dropdown.
- Adds account-wide/per-character settings.
- Adds `/esell keep cursor`.
- Restricts automatic selling to grey junk and soulbound equipment by default so reagents, trade goods, BoE gear, and Warbound-until-equipped gear are ignored.
- Adds an opt-in unbound equipment setting.
- Adds a gold summary after selling.
