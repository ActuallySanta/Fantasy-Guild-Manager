# Mobile Ledger UI (prototype)

A phone-first UI for the guild game, styled after the "Guild Ledger" reference art
(painted parchment, wood, wax seals, bookmark tabs). It is **UI only**: it runs on the
existing systems and changes none of them.

- **Run it:** open `MobileLedger/ledger_main.tscn` and press *Run Current Scene* (F6).
  The project's main scene is unchanged; set this one as the main scene to try it as the default.
- **Built on:** `CharacterContainer`, `GuildCharacter`, `CreatedQuest`
  (`calcSuccessChance`, `generateResults`), `GameState` (day, gold, standing,
  `start_new_day`), `GuildUpgrades` (levels, costs, `try_upgrade`, Armory bonuses) and
  `DayBar`'s static helpers for scoring results. The scene also contains a `QuestManager`
  node, because quest results read monster names through it.

## Screens

| Tab / page | What it shows |
|---|---|
| Home | Day + Bone Drake countdown, today's checklist, everyone's injury level, last night's results |
| Quests | Quest slips with wax seal, type, gold, party size, favored stat, live success chance; Accept / Deny |
| Mission Charter | Pick the party; every adventurer's four quest stats on screen (favored one outlined), what each adds to the odds, and a live success gauge |
| Characters | "Your Guild" and "For Hire" as two clearly different halves; hiring is free |
| Adventurer Codex | Portrait, health ribbon, backstory, all five stats with Armory bonuses shown as +N |
| Upgrades | Every building, level pips, now/next effect, gold + standing cost; "coming soon" ones faded |
| Settings | Welcome again, plus the debug buttons (only when `GuildUpgrades.SHOW_DEBUG_BUTTONS`) |
| Day Report | DaySummary as a full page: per quest result, gold, injuries, the story split into beats |

## Files

- `Scripts/ledger_main.gd`: state, the game-flow calls, and the shell (header, day bar, nav)
- `Scripts/ledger_style.gd`: colours, fonts and widget helpers. Tune the look here.
- `Scripts/page_*.gd`, `screen_*.gd`, `overlay_*.gd`: one file per screen
- `Art/`: painted textures. Regenerate or re-tune with `python3 MobileLedger/Tools/generate_art.py`
  (Pillow + numpy) and `python3 MobileLedger/Tools/make_icons.py`
- `Fonts/`: Cinzel (titles) and Alegreya Sans (body), both SIL Open Font License
- Portraits use the project's own `Sprites/Character Icons`.
