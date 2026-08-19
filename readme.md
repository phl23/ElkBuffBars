# Phoenix

Phoenix is a modern aura-bar addon for WoW Classic and Anniversary TBC, built on the ideas and workflows of **EBB Heritage**. It shows player and target buffs or debuffs as readable, configurable bars with durations, icons, profiles, and visual presets.

## Installation

1. Copy the `Phoenix` folder into `World of Warcraft\_classic_era_\Interface\AddOns\`.
2. Start the game and enable **Phoenix** in the AddOns list.
3. Use `/reload` after updating the folder while the game is running.

The folder must remain named `Phoenix`: WoW uses that folder name to locate the bundled media and saved settings.

## Opening Phoenix

Use one of the following commands:

- `/px`
- `/phoenix`
- `/pheonix`

`/ebb` is also registered when no other addon already owns that command.

The Phoenix entry in the Blizzard AddOns settings opens the same options window. Right-clicking the Phoenix minimap button opens it as well.

## Basic Setup

Phoenix creates five groups by default: player buffs, player debuffs, target buffs, target debuffs, and player weapon enchants.

1. Open `/px` and enable **Show preview bars**.
2. Drag a preview bar to move its whole group.
3. Select **Group** with `Prev` and `Next` to change that group's width, height, filters, sort order, growth direction, and target limit.
4. Disable preview bars to lock the layout.

Hold `Shift` and click a bar to lock the layout again. Use **Reset Positions** to restore the default anchors for the active profile.

## Appearance

The General section provides bar-style presets, fonts, font shadow, bar spacing, icons, aura names, and optional debuff-type colors. Phoenix ships with the `Minimal Clean` style as its standalone default; it does not require another SharedMedia addon.

## Profiles

Phoenix stores a separate profile for each character by default. In the Profiles section you can switch to or create a named profile, copy settings from another profile, reset the active profile, or delete a non-active profile.

## Blizzard Aura Frames

**Hide Blizzard buffs** and **Hide Blizzard debuffs** are independent options. Enable either only after confirming that the matching Phoenix group is enabled and positioned as intended.

## Useful Commands

- `/px status` prints the active groups and their aura counts to chat.
- `/px reset` resets group positions in the active profile.

## EBB Heritage

Phoenix is a focused modern rewrite inspired by Elkano's BuffBars. The original project remains the historical reference for its established bar-based aura workflow; Phoenix uses its own code and settings database.
