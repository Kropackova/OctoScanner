# Supported recognition vocabulary

Profiles select names recognized in incoming chat; they do not query server availability.

| Profile | Vocabulary |
| --- | --- |
| `vanilla` | Original dungeons, raid instances and world bosses; standard battlegrounds, professions and trade |
| `octo` | Vanilla plus the additions below; default for Octo and unknown realms |
| `turtle` | Same additions, with the Turtle profile label |
| `auto` | Select from the realm name |

## Vanilla

Ragefire Chasm, Wailing Caverns, The Deadmines, Shadowfang Keep, Blackfathom Deeps, The Stockade, Gnomeregan, Razorfen Kraul, Scarlet Monastery and its wings, Razorfen Downs, Uldaman, Zul'Farrak, Maraudon, Sunken Temple, Blackrock Depths, Lower/Upper Blackrock Spire, Dire Maul and its wings/Tribute, Stratholme Living/Undead, Scholomance.

Molten Core, Onyxia's Lair, Blackwing Lair, Zul'Gurub, Ruins/Temple of Ahn'Qiraj and Naxxramas. World bosses: Azuregos, Kazzak, Emeriss, Lethon, Taerar and Ysondre.

## Turtle / Octo additions through 1.18.1

| Type | Names |
| --- | --- |
| Dungeons | Frostmane Hollow, Windhorn Canyon, Dragonmaw Retreat, The Crescent Grove, Stormwrought Ruins, Gilneas City, Hateforge Quarry, Karazhan Crypt, Stormwind Vault, Caverns of Time: Black Morass |
| Raids | Lower Karazhan Halls, Upper Karazhan Halls, Emerald Sanctum, Timbermaw Hold |
| World bosses | Concavius, Ostarius, Nerubian Overseer, Dark Reaver of Karazhan |
| PvP | Thorn Gorge, Blood Ring, alongside WSG / AB / AV |
| Other | LFT, Jewelcrafting / Goldsmithing / Gemology, Survival crafting, Gardening, transmog trade |

New bosses inside an existing dungeon do not need a separate activity category. This addon reads adverts rather than encounters. Sunnyglade Valley is not in the active added roster.

## Ambiguous names and fields

- `WC` means Wailing Caverns; `WHC` means Windhorn Canyon.
- `BM` in group recruitment means Black Morass unless Hunter, pet or spec wording indicates Beast Mastery. It is then excluded from Damage role detection.
- `Kara10` / `K10` / `LKH` and `Kara40` / `K40` / `UKH` distinguish the raids. Plain `Kara` stays an unspecified raid.
- Bare `DM` means The Deadmines, as does `VC`. Dire Maul uses its full name or a wing: `DME` / `DM East`, `DMW` / `DM West`, `DMN` / `DM North`, or `DMT` / `DM Tribute`. Contact phrases such as `DM me` do not name a dungeon.
- `HC` alone establishes neither dungeon difficulty nor a character's hardcore status. Emerald Sanctum mode requires explicit Normal/Hard Mode wording.
- Recognized quest links and plain-text repeats can produce Quest groups. Title words such as Shadow, Hunter or Wanted are not roles, classes or wanted counts. The observed title list is not a complete quest database.
- A post listing several activities currently chooses one matching activity. Unrecognized requests remain general Group entries.

Spelling variants are based on observed Octo adverts, including `URBS`, `Ubers`, `Scolomance`, `Stat UD`, `ONI`, `mauradon`, `Razorfren`, `gileans city` and `BLACKPHANTOM DEEPS`. New slang can be added with an anonymized message and regression.

## Sources

Content references: [Turtle dungeons and raids](https://turtlecraft.gg/raids-and-dungeons), [1.18.0 notes](https://forum.turtlecraft.gg/viewtopic.php?f=63&t=17688), [1.18.1 notes](https://forum.turtlecraft.gg/viewtopic.php?t=22214), [Timbermaw Hold](https://turtlecraft.gg/watch/timbermaw-hold), [Jewelcrafting](https://turtlecraft.gg/jewelcrafting) and [Survival / Gardening](https://turtlecraft.gg/survival-and-gardening).

Octo's content implementations and release phases can differ. These names are supported for recognition even when an encounter is not yet open on a realm.
