# AltsLedger

A lightweight cross-character overview window for your alts.

For each character you log into, AltsLedger records:

- **Item Level** (equipped + overall)
- **Gold** (per character + account total)
- **Warband Bank gold** (account-wide, recorded each time you open the warband bank)
- **Mythic+ rating**
- **Great Vault progress** (R/M/W slots unlocked this week)

A single window lists every tracked alt, sortable by any column.

## Usage

- Click the minimap button to toggle the window.
- Drag the title bar to move the window. Position is saved.
- Click any column header to sort by that field.
- Click the small × on the right of a row to forget that character.

Data for each character refreshes automatically when you log in, change gear,
gain/spend gold, complete a key, or get a Great Vault update.

## Notes

- Warband Bank gold can only be read after you've opened the warband bank at
  least once in the current session. It is then stored account-wide.
- Great Vault slots reset weekly. Stale weekly data from a previous reset will
  still show until the character logs in again.
