# OctoScanner 1.0.0

OctoScanner reads adverts in your joined chat channels and organizes them into PvE, PvP, Trade and Guild sections. Built for OctoWoW with the Vanilla 1.12 addon API, Interface 11200 and Lua 5.0.

## Features

- Sortable tables with roles, classes, levels, named activities, group progress and full-message tooltips.
- Vanilla and Octo/Turtle content profiles, including custom dungeons, raids, world bosses, quest groups, battlegrounds and trade services.
- `DM` / `VC` for The Deadmines, with separate aliases for Dire Maul wings and Tribute. Contact instructions such as `DM me` do not name an activity.
- Per-section filters and column choices. PvE defaults hide Class, Filled and Lvl; PvP defaults hide Role and Lvl. All remain available through Rows.
- Repeat adverts update the same player's row, including moves between tabs while retaining manual cell edits.
- Records remain throughout the current session. Reload restores only records younger than one hour.
- Filtered sound/chat/popup alerts and a resizable mini feed with one-click whisper.
- Seven editable whisper templates with placeholders for your own character's name, class and level.
- Seven skins and saved scale from 50% to 100% for windows, menus, tooltips and dialogs.

## Installation

Close the game and extract the single **OctoScanner** folder from `OctoScanner-1.0.0-OctoWoW.zip` into `Interface\AddOns`. Check that `Interface\AddOns\OctoScanner\OctoScanner.toc` exists, enable the addon and open it with `/ocs`.

Replace existing addon files when upgrading. Per-character `OCS_DB` settings are retained. SuperWoW, Nampower and ClassicAPI are not required.

Code is MIT licensed, by Kropackova. Based on AscensionChatScanner v1.2.1. Bundled game artwork retains its original ownership and documented attribution.
