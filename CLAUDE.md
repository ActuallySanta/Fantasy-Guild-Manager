# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Fantasy Guild Manager", a Godot **4.7** GDScript game (GL Compatibility, portrait 720x1280, phone-first). You run a guild: hire heroes, send parties on daily quests, buy gear and building upgrades. A Bone Drake milestone quest comes on day 10, and the main story ends with a final battle on day 50 (a credits roll, then endless freeplay with an S++ rank; see `MobileHall/README.md`).

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
  - Every preset has `include_filter="External Content/*.txt"`. The quest `.txt` files aren't resources, so without it they're left out of the export and quests break.
- **Web build:** `.github/workflows/deploy-web.yml` exports the `Web` preset with headless Godot and deploys it to GitHub Pages on every push to `master` (or with "Run workflow" in the Actions tab). The URL is `https://www.santibenfer.com/Fantasy-Guild-Manager/`. The repo is `ActuallySanta/Fantasy-Guild-Manager`, and the account's Pages site uses a custom domain. It's a PWA, so "Add to Home Screen" on a phone installs it full-screen in portrait. `GODOT_VERSION` in the workflow has to match the editor. `Builds/Web/` (local web exports) is gitignored.

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
- `hall_main.gd` owns all of the day's state and every game action: drafting parties, `end_day()` → `_run_quest()` → the Day Report. Everything else is split out:
  - `hall_rules.gd` (`HallRules`): static functions for building the day's quests and playing one out (`build_day_quests`, `play_quest`, `pluck_gain_for`). The quest-count and rank tuning tables live here, plus the final battle (`HallMain.FINAL_DAY`) and freeplay scaling (`freeplay_scale`, the S++ rank).
  - `hall_ledger.gd` (`HallLedger`): static functions for whether the run is over, the danger checks, the Game Over numbers, and the final battle's credits (`build_credits`, `build_run_records`). They take `run_stats` and the roster as parameters.
  - `hall_settings.gd` (`HallSettings`): loading and saving the accessibility settings.
  - `hall_save.gd` (`HallSave`): the run's save file (`user://run_save.dat`, IndexedDB on the web). `hall_main` saves after every refresh and loads in `_ready`. New run state has to be added to `build_snapshot`/`apply_snapshot` (or the `*_FIELDS` lists for heroes, items and quests). Old saves are brought up to date by `HallSave.migrate` (see "Save compatibility" below). `hall_save_transfer.gd` (`HallSaveTransfer`) turns a run into a backup code and back, and `hall_web_files.gd` (`HallWebFiles`) moves it on and off the device (share sheet, clipboard, file picker; JavaScript on the web), for the Menu's Backup save sheet. See `MobileHall/README.md` "Saving and offline play".
  - The shell pieces are scenes in `MobileHall/Scenes/Shell/`: `hall_header` (the day tile, Bone Drake countdown, gold/standing counters and their motion, danger strip), `hall_action_bar`, `hall_nav`, and `hall_toast`.
  - `hall_main` keeps one-line query wrappers (`is_run_over()`, `build_run_over_stats()`, …) so views still only talk to `hall`.
- Tabs, screens, overlays, shell pieces, and rows get `setup(hall)`, then read queries and call actions on `hall`. They never change game state themselves. After a change, `hall_main` calls `refresh()` on whatever is showing.
- Every widget is an authored scene. Each script has a header naming its scene, a `TEXT` section of string constants, and a `NODES` section of `@onready var _x = %X` unique names.
- All colors and tables live in `MobileHall/Scripts/hall_style.gd`. Story BBCode colors are bright, meant for dark backgrounds. `report_entry.gd` `STORY_RECOLORS` swaps them for colors that read on the light cards, so a new story color needs an entry there.
- `MobileHall/README.md` covers the UI's design and rules (training, hospital, revive). The root `README.md` is the GitHub front page: what the game is and how to run it. Keep both current (see Conventions).

The older prototype UI lives in `Scenes/` and `Scripts/UI/`. `hall_main` still borrows its scoring helpers: it uses `Scripts/UI/day_bar.gd` (`class_name DayBar`) for `_get_success_chance`, `_did_succeed`, and `_get_gold_earned`. Changes to quest payout or results need to keep `day_bar.gd` working too.

## Conventions

- New code uses GDScript naming: `snake_case` variables and functions (leading `_` for private ones), `PascalCase` classes and enums, `CONSTANT_CASE` constants, and full readable names.
  - `quest_resource.gd` has legacy camelCase (`goldReward`, `questNum`, `generateResults`). Reference those as they are; don't rename them, since UI code depends on them.
- Comment new code thoroughly. Tunables get `##` doc comments with units, functions get doc comments covering their params and return value, and non-obvious logic gets `#` comments. This matches the style of the newer files (`item_shop.gd`, `guild_upgrades.gd`, MobileHall scripts).
- Tuning numbers go in named, documented variables or constants at the top of the file that owns them, not inline.
- Keep each script to one job, so no new "master script" grows the way `hall_main.gd` once did (1,900 lines).
  - Soft limit: about 800 lines per script. Past that, find a piece to pull out before adding more. `hall_main.gd` is already near 1,350, so new MobileHall code goes in another file and `hall_main` just calls it.
  - Game rules that don't touch nodes (quest generation, payouts, run-over checks) go in a script of static functions with a `class_name`, like `HallRules` and `HallLedger`. They take what they need as parameters.
  - A part of the screen with its own nodes and refresh code becomes its own authored scene with `setup(hall)` and `refresh()`, like the tabs, overlays, and `Scenes/Shell/` pieces. Don't add inline nodes to `hall_main.tscn` for `hall_main.gd` to draw.
  - `hall_main.gd` keeps only the day's state, the actions that change it, thin query wrappers, and refresh orchestration.
  - **Save compatibility:** saves and backup codes from older versions must keep loading (`HallSave.migrate`).
    - Safe: adding a saved field, building, or run-state value. Old saves get the default, as long as `apply_snapshot` reads it with `.get(key, default)`.
    - Breaks old saves: renaming or removing a saved field (`*_FIELDS`, `build_snapshot` keys), changing what a saved value means or its units, reordering a saved enum (`Rarity`, roles, stats, injury levels), or changing the `REF_*` / item `kind` handling.
    - When a change would break old saves, tell Santi before making it, then bump `SAVE_VERSION` and add a `_migrate_N_to_N+1` step to `HallSave._migration_steps()`.
  - Run state that has to reset on a new run stays in instance variables on `HallMain`. Never put it in a `static var` or a new autoload: `start_new_run` resets by reloading the scene, and those survive the reload.
- File references should survive files being moved:
  - Reach scripts through their `class_name` (`HallStyle`, `HallMain`, `HallFx`, `TapPanel`, `DayBar`, …), not `preload("res://….gd")`. Name them directly (`HallStyle.X`, `HallFx.X`): GDScript rejects `const Style := HallStyle` as "not a constant expression" here.
  - Load scenes and assets by uid with the path in a trailing comment: `preload("uid://…")  # MobileHall/Scenes/Rows/quest_row.tscn`. Look up a file's uid in its header (`.tscn`/`.tres`), its `.import` file, or its `.gd.uid` file.
  - Text data in `External Content/` (`.txt`, `.csv`) has no UID, so it stays on `res://` paths.
  - Move files in the Godot FileSystem dock. If you move one outside the editor, move its `.uid` or `.import` file along with it, and commit the `.uid` files.
  - Hand-written `.tscn`/`.tres` files need a `uid="uid://…"` in their header, and each `ext_resource` line needs a `uid=` as well as its `path=`. Saving the file in the editor fills these in.
- Keep the READMEs current in the same change that makes them wrong. Before committing, check whether the change touches something either one describes, and update only the affected lines (no rewrites).
  - `README.md` (repo root) is what players and newcomers see on GitHub: the game's pitch and daily loop, the play link, running from source (Godot version, main scene, F5/F6), playtest scenarios, the "Save runs" switch and Debug tools, builds and deploy, and the folder layout table. Update it when any of those change: a new or renamed tab or major feature, a different Godot version or main scene, a new top-level folder, a changed deploy URL or workflow, or a new player-facing setting.
  - `MobileHall/README.md` covers the UI's design and rules. Update it when you change a screen, an overlay, a game rule it explains (training, hospital, revive, Game Over, freeplay), saving, or the Debug tools.
  - If a fact in this file changes too (for example the Godot version or the main scene), update it here as well.
