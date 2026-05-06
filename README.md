# EasySell

**EasySell** is a lightweight World of Warcraft addon that automatically sells vendor trash when you open a merchant. It pairs neatly with **EasyDelete**: EasyDelete clears deletion friction, EasySell clears bag clutter.

Current release: `1.0.1`

---

## Features

- Automatically sells grey vendor trash at merchants
- Optional rarity threshold: poor, common, uncommon, rare, or epic
- Only sells grey junk and soulbound equipment by default; reagents, trade goods, BoE gear, and Warbound-until-equipped gear are ignored
- Whitelist specific items so they are never automatically sold
- Drag items into the Whitelist options tab to protect them quickly
- Shows a clear gold summary after selling
- Tracks the total gold earned during your current login session
- Protects soulbound items above grey quality by default
- Preview what EasySell would sell before opening up broader rarity thresholds
- Choose EasySell, ElvUI, or Zygor as the active auto-sell provider
- Detects provider drift when ElvUI or Zygor auto-sell settings are changed outside EasySell
- Uses a rarity dropdown in the options menu
- Choose account-wide or per-character settings
- Configure through Blizzard's AddOns options menu or simple `/esell` commands
- Remembers your settings between sessions
- Versioned for Retail, Classic Era, TBC Classic, and Mists Classic clients

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/esell` | Toggle automatic selling on or off |
| `/esell on` | Enable automatic selling |
| `/esell off` | Disable automatic selling |
| `/esell status` | Show the current setting |
| `/esell provider easysell` | Let EasySell handle automatic selling |
| `/esell provider elvui` | Let ElvUI handle automatic grey selling |
| `/esell provider zygor` | Let Zygor handle automatic grey selling |
| `/esell preview` | Show what would be sold without selling anything |
| `/esell session` | Show the total gold earned this login session |
| `/esell options` | Open the EasySell options menu |
| `/esell profile` | Toggle account-wide or per-character settings |
| `/esell soulbound` | Toggle protection for soulbound items above grey |
| `/esell unbound` | Toggle selling BoE and Warbound-until-equipped equipment |
| `/esell keep [item]` | Add an item link or item ID to the whitelist |
| `/esell keep cursor` | Add the item currently on your cursor to the whitelist |
| `/esell unkeep [item]` | Remove an item link or item ID from the whitelist |
| `/esell poor` | Sell grey items only |
| `/esell common` | Sell grey and white items |
| `/esell uncommon` | Sell up to green items |
| `/esell rare` | Sell up to blue items |
| `/esell epic` | Sell up to purple items |

The default is intentionally safe: **poor/grey only**.

Whitelisted items are never sold, even if their rarity matches your current selling threshold.
You can add whitelist items from the options menu by dragging an item into the Whitelist tab, clicking **Add item**, or using `/esell keep [item]`.

Soulbound protection is enabled by default. Grey soulbound vendor trash can still be sold, but soulbound common/uncommon/rare/epic items are protected unless you turn this off.
Rarity thresholds above grey only apply to equipment. By default, that equipment must already be soulbound. Reagents, trade goods, consumables, BoE gear, Warbound-until-equipped gear, and similar non-equipment items are not sold automatically.

In the options menu, use **Preview** or shift-click the rarity dropdown to preview the current selling rules.
If ElvUI or Zygor is loaded, EasySell can hand off grey selling to that addon and will disable the other providers to avoid double-selling.

---

## Installation

### CurseForge App

Install **EasySell** through the CurseForge app for your WoW client. The app will place the addon in the correct `Interface/AddOns` folder automatically.

### Manual Installation

1. Download and unzip the addon.
2. Copy the `EasySell` folder into the correct AddOns folder:
   - `_retail_/Interface/AddOns`
   - `_classic_era_/Interface/AddOns`
   - `_classic_/Interface/AddOns`
   - `_anniversary_/Interface/AddOns`
3. Restart the game or type `/reload`.
4. Enable the addon in the character select AddOns menu.

---

## License

This addon is released under the GPL-3.0 License.
