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

- `ledger_main.tscn` + `Scripts/ledger_main.gd`: state, game-flow calls, the shell (header, day bar, nav)
- `Scenes/Pages/`: the five tabs (Home, Quests, Characters, Upgrades, Settings)
- `Scenes/Screens/`: Mission Charter and Adventurer Codex
- `Scenes/Overlays/`: day report and welcome card
- `Scenes/Rows/`: list rows (quest slip, roster / hire cards, upgrade card, charter slots and picker row, home checklist / health / last-night rows, report entry and story beats)
- `Scenes/Components/`: chip, portrait, stat grid, wax seal, dashed slot, top bar
- `Styles/` + `ledger_theme.tres`: shared boxes and the base theme
- `Scripts/ledger_style.gd`: colours and fonts, plus the restyles that depend on game state
- `Art/`: painted textures. Regenerate or re-tune with `python3 MobileLedger/Tools/generate_art.py`
  (Pillow + numpy) and `python3 MobileLedger/Tools/make_icons.py`
- `Fonts/`: Cinzel (titles, `cinzel_bold.tres` / `cinzel_black.tres` weights) and Alegreya Sans (body), both SIL Open Font License
- Portraits use the project's own `Sprites/Character Icons`.

### Editing the scenes

Every screen, row and widget is an authored scene you can open and edit in the
Godot editor. Nothing is built from code at runtime: scripts only fill in text,
show/hide nodes and instance row scenes for lists (one row per quest, character,
etc.). Shared boxes (panels, buttons, chips) are `.tres` files in `Styles/`, so
changing one restyles it everywhere; chips, stat rows and gauges are `@tool`
components with exported colours/sizes so they preview in the editor.

### Editing the scripts

Every script follows the same layout, so you can find things quickly:

- **Header comment**: what the screen is and which `.tscn` it belongs to.
- **TEXT**: every message the script fills in, as `TEXT_...` / `TOAST_...` constants at the top
  (fixed headings and the intro card are typed straight into the scenes).
  Change wording there (keep the `%d` / `%s` placeholders).
- **NODES**: `@onready var _name = %Name` for every node the script touches. The `%Name`
  matches a node marked "Access as Unique Name" in the scene, so renaming a node in the
  editor means renaming it here too.
- **setup(main)**: connects the buttons. **refresh()**: fills everything in from game state,
  split into small `_show_...()` functions, one per part of the screen.

Where to look:

- `Scripts/ledger_main.gd`: all state and game actions (hire, send, deny, end day...), with
  SETTINGS (quests per day, milestone day, timings) at the top. Screens never change game
  state themselves; they call these actions.
- `Scripts/ledger_style.gd`: colours, stat / injury / odds tables, small text helpers
  (plurals, name lists), and the restyles that change at runtime.
- Row and component scripts (`chip`, `portrait`, rows): one `setup()` each.
