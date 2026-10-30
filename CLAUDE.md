# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Fantasy Guild Manager", a Godot **4.7** GDScript game (GL Compatibility, portrait 720x1280, phone-first). You run a guild: hire heroes, send parties on daily quests, buy gear and building upgrades. A Bone Drake milestone quest comes on day 10.

## Running and testing

There's no build step, linter CLI, or test framework. Godot 4.7 is the Steam copy:

```bash
"/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
```

- **Run the game:** the main scene is `MobileHall/hall_main.tscn`. The `MobileHall/README.md` line saying the main scene is unchanged is out of date.
- **Playtest scenarios:** run `MobileHall/Playtest/scenario_*.tscn`, which start the hall from a preset day, gold, standing, and roster (`playtest_scenario.gd`).
- **Headless behavior tests:** write a throwaway `extends Node` script plus a `.tscn` and run it with `--headless --path <project> res://that_test.tscn`. Running a scene loads the autoloads.
  - Do this in a scratch copy of the project, so `--import` and `.uid` churn don't land in the repo.
  - Don't trust `--check-only --script`: it doesn't load autoloads, so every script reports false "Identifier not found: GameState/ExternalContentContainer/…" errors.
- **Formatting:** the GDQuest GDScript formatter editor plugin (`addons/GDQuest_GDScript_formatter`) is enabled. It runs from inside the editor.
- **Exports** (`export_presets.cfg`) write to `Builds/`, which is committed. Don't regenerate builds unless asked.

## Architecture

**Autoloads are the game model** (`project.godot` `[autoload]`, scripts in `Globals/`). They load in this order, and later ones depend on earlier ones:
- `ExternalContentContainer`: loads every text asset at startup (names, backstories, locations, monsters, quest story parts) from `External Content/`. `GuildCharacter.new()` and item naming fail if it hasn't run yet. That's why scene `_enter_tree` code can't create characters (see the `playtest_scenario.gd` header).
- `CharacterContainer`: the roster (`active_characters`), today's For Hire pool, and released heroes who may return.
- `GuildUpgrades`: the gold and standing wallet, building levels and effects (Armory, Barracks, Training Yard, Hospital), and `run_night()` for training and healing. The tuning constants sit at the top of the file.
- `GameState`: the day counter. `start_new_day()` emits `day_started`, which other systems listen to (ItemShop restock, hire refresh). `gold` and `standing` just forward to `GuildUpgrades`.
- `QuestManager`: holds the `world_regions` (`Region` from `region_resource.gd`) that quests pull locations and monsters from. It also prints debug quests in `_ready`.
- `ItemContainer` (owned items, equip/unequip) and `ItemShop` (daily stock, buying, role-locked equipping with a slot cap).

**Domain resources** live in `Scripts/`:
- `GuildCharacter` (`Character Generator/character_resource.gd`): role, injury level, `stats` plus `temp_stats`. Quests read `temp_stats`, which `reset_temp_stats()` rebuilds from the base stats, pluck, and gear. Gear never writes to `stats`.
- `CreatedQuest` (`Quest Creator/quest_resource.gd`): generating a quest, `calcSuccessChance`, and playing it out. `generateResults` (or `generateMilestoneResults`) returns BBCode story text and changes the quest's `goldReward` and the party's injuries as it goes.
  - Success is detected by searching the text: `DayBar._did_succeed` checks for "NOT SUCCESSFUL".
  - Quest story text comes from pipe-delimited rows in `External Content/Quest Stuff (Test)/Story Parts.txt` (`type|intro|middle|fail|success`), read with `get_Quest_Story(questNum, column)`. `{location}` is filled in with `String.format`.
- Items (`Item System/`): `StandardItem` (abstract: rarity weights in the `Rarity` enum values, cost) → `PassiveItem` (a stat bonus) and `ActiveItem`.

**There are two UIs.** `MobileHall/` is the current one:
- `hall_main.gd` owns all of the day's state and every game action: building quests, drafting parties, `end_day()` → `_run_quest()` → the Day Report.
- Tabs, screens, overlays, and rows get `setup(hall)`, then read queries and call actions on `hall`. They never change game state themselves. After a change, `hall_main` calls `refresh()` on whatever is showing.
- Every widget is an authored scene. Each script has a header naming its scene, a `TEXT` section of string constants, and a `NODES` section of `@onready var _x = %X` unique names.
- All colors and tables live in `MobileHall/Scripts/hall_style.gd`. Story BBCode colors are bright, meant for dark backgrounds. `report_entry.gd` `STORY_RECOLORS` swaps them for colors that read on the light cards, so a new story color needs an entry there.
- `MobileHall/README.md` covers the UI's design and rules (training, hospital, revive).

The older prototype UI lives in `Scenes/` and `Scripts/UI/`. `hall_main` still borrows its scoring helpers: it preloads `Scripts/UI/day_bar.gd` for `_get_success_chance`, `_did_succeed`, and `_get_gold_earned`. Changes to quest payout or results need to keep `day_bar.gd` working too.

## Conventions

- New code uses GDScript naming: `snake_case` variables and functions (leading `_` for private ones), `PascalCase` classes and enums, `CONSTANT_CASE` constants, and full readable names.
  - `quest_resource.gd` has legacy camelCase (`goldReward`, `questNum`, `generateResults`). Reference those as they are; don't rename them, since UI code depends on them.
- Comment new code thoroughly. Tunables get `##` doc comments with units, functions get doc comments covering their params and return value, and non-obvious logic gets `#` comments. This matches the style of the newer files (`item_shop.gd`, `guild_upgrades.gd`, MobileHall scripts).
- Tuning numbers go in named, documented variables or constants at the top of the file that owns them, not inline.
