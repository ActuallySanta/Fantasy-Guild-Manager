# Mobile Flow UI (playtest variant)

A phone-first UI for the guild game, built as a **guided day loop** instead of the
tab layout in `MobileLedger/`. It is **UI only**: it runs on the existing systems
(`CharacterContainer`, `GuildCharacter`, `CreatedQuest`, `GameState`, `GuildUpgrades`,
`DayBar`'s scoring helpers) and changes none of them.

- **Run it:** open `MobileFlow/flow_main.tscn` and press *Run Current Scene* (F6).
  The project's main scene is unchanged.

## Layout

Every day walks through three steps, shown in a step bar under the header
(each step can also be tapped directly):

| Step | What's on screen | Main button (bottom bar) |
|---|---|---|
| 1. Hire | Today's recruits, each with colour-coded stats and a Hire button. Skipped automatically when nobody can be hired. | Next: Quests |
| 2. Quests | **One quest per screen**: type, rank, gold, party size, favored stat; the party slots and live success chance; the roster sorted by best fit, tap to add/remove. Numbered squares jump between quests (grey = undecided, green = party set, red = denied). | Deny / Send party, which moves straight to the next undecided quest |
| 3. End Day | Today's plan (tap a row to go back to that quest), upgrades, last night's report. | End Day (locked until every quest is decided) |

The **Guild** button in the header opens roster / for hire / upgrades from any step,
and character details open from there or from "Details" on a recruit.

## Things to watch in the playtest (vs. the tab layout)

- Do players understand what to do next without being told (step bar + one main button)?
- Is one-quest-at-a-time faster or slower than scanning a list of quests?
- Do players find upgrades when they live in the End Day step instead of their own tab?
- Do players use the Guild button, or ignore the roster?

## Look

Flat grey boxes, Godot's default font. Colour only carries meaning: each stat has its own
colour, green = good / go, red = bad / deny, yellow = gold, blue = info / current, and
health runs green → yellow → orange → red. Art is only the project's own
`Sprites/Character Icons` and `Sprites/UI Icons`.

## Files

- `flow_main.tscn` + `Scripts/flow_main.gd`: state, game-flow calls, header / step bar
- `Scenes/Steps/`: the three steps (`step_hire`, `step_quest`, `step_end`), each with its footer buttons
- `Scenes/Sheets/`: Guild sheet and character details
- `Scenes/Overlays/`: day report and first-launch intro
- `Scenes/Rows/`: list rows (recruit card, roster member, party picker row, quest dot, plan row, upgrade row, report entry, party slots)
- `Scenes/Components/`: chip, stat row, portrait
- `Styles/` + `flow_theme.tres`: shared boxes and the base theme
- `Scripts/flow_style.gd`: all colours, plus the few restyles that depend on game state

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

- `Scripts/flow_main.gd`: all state and game actions (hire, send, deny, end day...), with
  SETTINGS (quests per day, milestone day, timings) at the top. Screens never change game
  state themselves; they call these actions.
- `Scripts/flow_style.gd`: colours, stat / injury / odds tables, small text helpers
  (plurals, name lists), and the restyles that change at runtime.
- Row and component scripts (`chip`, `portrait`, rows): one `setup()` each.

