# Changelog

## v0.5.2

- The currently logged-in character is now highlighted in the list: soft
  gold background tint, gold glow on the left next to the class color bar,
  and an `[active]` badge after the character name.

## v0.5.1

- Fix: previously stored gold values for other alts could be overwritten with
  0 because `GetMoney()` may briefly return 0 during the logout transition
  and the addon was capturing on `PLAYER_LOGOUT`. The logout-time capture has
  been removed (SavedVariables are saved by the client regardless), and
  non-authoritative captures will no longer clobber a known positive balance
  with a transient zero. Captures triggered by `PLAYER_MONEY` are still
  authoritative, so legitimately spending down to 0 is recorded correctly.

## v0.5.0

- Window title now reads "Alts Ledger" (with the space).
- New tip line in the footer explaining that each alt has to be logged into
  once to be added to the ledger, since the game does not expose a way to
  enumerate account characters in-game.

## v0.4.0

- Header and row cells now share a single column layout, fixing the previous
  horizontal misalignment between the column headers and the data rows.
- The character column stretches to absorb extra horizontal space.
- Window is resizable: drag the bottom-right corner. Size is persisted between
  sessions (min 720×260, max 1600×1000).
- Remove "x" button now lives inside the dedicated last column instead of
  hugging the right edge, so it no longer overlaps the Great Vault cell.
- Slightly smaller Great Vault indicators (11px) and a wider Vault column to
  prevent truncation on narrow widths.

## v0.3.0

- New layout: taller rows with class-color accent bar on the left and
  character name / realm stacked on two lines for a cleaner look.
- Gold values now use Blizzard's coin texture icons (g/s/c icons).
- Great Vault dots replaced with `Indicator-Yellow/Gray/Green` textures
  (the previous unicode bullets did not render with every game font).
- Sort arrow on the active column is now a Blizzard texture instead of text.
- Titlebar and footer use a vertical gradient with a gold accent line.
- Slimmer scrollbar without the up/down arrow buttons.
- Larger frame (820×500) with more breathing room.

## v0.2.0

- Restyled window: two-tone titlebar/footer with gold accent line.
- Rows now show the class icon next to the character name.
- Row hover highlight; remove "x" tints red on hover.
- Sortable column headers show a v/^ arrow on the active key.
- Great Vault column uses colored dots (filled = unlocked) per category.

## v0.1.0

Initial release.

- Cross-character overview window with one row per alt.
- Tracks item level, gold, Mythic+ rating, and Great Vault slot progress.
- Tracks account-wide Warband Bank gold (recorded when the warband bank is opened).
- Minimap button toggles the window; window position is saved.
- Sortable columns (character, level, ilvl, gold, M+).
- Per-row remove button to drop a character from the ledger.
