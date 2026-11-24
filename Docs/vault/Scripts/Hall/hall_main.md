---
source: Scripts/Hall/hall_main.gd
class_name: HallMain
extends: Control
scene: "[[hall_main (scene)]]"
systems: ["[[Boot and Autoload Order]]", "[[Day Cycle]]", "[[Hiring Characters]]", "[[Party Drafting and Assignment]]", "[[Success Chance]]", "[[Quest Generation and Difficulty]]", "[[Quest Resolution and Injuries]]", "[[Night - Training Hospital Revive]]", "[[Economy and Wallet]]", "[[Items and Shop]]", "[[Saving Migration and Backup Codes]]", "[[Run End]]", "[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 42bbb8f33545f8af5fb02766713031b11eecd919
tags: [script]
---

# hall_main.gd

## Purpose
The Mobile Hall's root script (`class_name HallMain`, scene [[hall_main (scene)]]). It owns the day's state and every game action: drafting parties, End Day, hiring, upgrades, gear, settings, overlays. Each shell piece, tab, screen and overlay gets `setup(self)` once (in [[hall_main#_ready]]), keeps that reference as `hall`, reads the QUERIES and calls the ACTIONS, and never changes game state itself. After any change this script calls `refresh()` (usually via `queue_refresh()`) on whatever is showing.

Rules live in other scripts: `HallRules` (building the day's quests, playing one out), `HallLedger` (run over, Game Over numbers, credits), `HallSettings`, `HallSave`, `HallDebug`. The file is 1893 lines. This note covers every function: setup, queries, navigation, overlays and `toggle_in_party` first, then quest actions, guild, gear, facilities, settings, debug tools, end of day, refresh and toasts.

Sections of the file: SETTINGS, TEXT, STATE, NODES, SETUP, QUERIES, ACTIONS (navigation, overlays, quests, guild, end of day), REFRESH (content, overlays), TOAST.

## State

### Signal
| Name | Kind | Meaning (units) |
|---|---|---|
| `tutorial_event` | signal | `tutorial_event(event: String, data: Variant)` (`hall_main.gd:60`). Fired at the end of each player action. `event` is one of `tab, hire, character, close, assign, pick, send, deny, end_check, end_day, read_letter, new_day, upgrade, training_picker, train, admit, buy, equip, game_over, freeplay`. Listeners: `OverlayTutorial` (`overlay_tutorial.gd:236`, `hall.tutorial_event.connect(_on_event)`) and `RunLogger` (`run_logger.gd:89`). |

### Constants: rules and ids
| Name | Kind | Meaning (units) |
|---|---|---|
| `MILESTONE_DAY` | const | `10`. The day the board is swapped for the milestone (Bone Drake) quest. |
| `FINAL_DAY` | const | `50`. The main story's final battle: the board holds only that quest, a win rolls the credits and offers freeplay, a loss ends the run. |
| `RELEASE_BASE_STANDING_COST` | const | `1`. Standing lost for releasing a living hero, plus their Pluck (see [[hall_main#release_standing_cost]]). Releasing the fallen is free. |
| `TAB_IDS` | const | `["board", "guild", "upgrades", "shop"]`, left to right (ids match the `Nav_<id>` buttons and the Tab nodes). |
| `TAB_SHOP` | const | `"shop"`. The Items tab (Pack + Shop); the id stays `"shop"` for the tutorial and saves. |
| `ITEMS_SECTION_PACK`, `ITEMS_SECTION_SHOP` | const | Halves of the Items tab (`"pack"`, `"shop"`). |
| `SCREEN_ASSIGN`, `SCREEN_CHARACTER` | const | Screen kinds that can cover the tabs (see `active_screen`). |
| `GUILD_SECTION_ROSTER`, `GUILD_SECTION_HIRE` | const | Halves of the Guild tab (`"roster"`, `"hire"`). |
| `UPGRADES_SECTION_TONIGHT`, `UPGRADES_SECTION_BUILD` | const | Halves of the Upgrades tab (`"tonight"`, `"build"`). |
| `MAIN_SCENE_PATH` | const | `uid://dtw7iu2s1gibm`. The scene a new run starts in (not a playtest scenario, so its preset isn't re-applied). |
| `DRAKE_RESULT_NONE`, `_SLAIN`, `_LOST` | const | `run_stats.drake_result` values (`""`, `"Slain"`, `"Lost"`). |
| `FINAL_RESULT_NONE`, `_WON`, `_LOST` | const | `run_stats.final_result` values (`""`, `"Won"`, `"Lost"`). |
| `STAMP_DENIED`, `STAMP_HIRED` | const | Stamp words `"DENIED"` and `"HIRED"`. |

### Constants: motion (seconds unless noted)
| Name | Kind | Meaning (units) |
|---|---|---|
| `STAMP_HOLD_SECONDS` | const | `0.5`. A SENT / DENIED stamp stays this long before the next quest shows (taps blocked meanwhile). |
| `HIRE_FLY_SECONDS` | const | `0.45`. The hired letter's flight to the roster. |
| `HIRE_STAMP_HOLD_SECONDS` | const | `0.5`. How long the letter sits with its HIRED stamp before it goes. |
| `HIRE_STAMP_AT` | const | `Vector2(0.68, 0.32)`. HIRED stamp centre as a fraction of the letter's size. |
| `HIRE_STAMP_FONT_SIZE` | const | `64`. HIRED stamp text size (px). |
| `HIRE_STAMP_TILT` | const | `-0.2`. HIRED stamp tilt (radians). |
| `DUSK_INK` | const | `Color("#26304A")`. The dusk wash over the screen while the night plays out. |
| `DUSK_IN_SECONDS`, `DUSK_OUT_SECONDS` | const | `0.35`, `0.45`. Dusk fade in / out. |
| `DEFEAT_DUSK_IN_SECONDS`, `DEFEAT_DUSK_OUT_SECONDS` | const | `1.2`, `1.4`. After a lost final battle the dusk lingers this long before the defeat screen shows, and clears this slowly. |
| `FX_LAYER_Z_INDEX` | const | `15`. Draw order of `fx_layer`: above the overlays (z 10 in the scene), so the dusk wash covers the End Day sheet and Day Report, and below Pip (`OverlayTutorial.TUTORIAL_Z_INDEX`). |
| `VIEW_FADE_SECONDS` | const | `0.14`. Each new tab or screen fades in this fast. |

### Constants: text
`TOAST_*` (line 133 to 182) are `String.format` templates for toasts (sent, denied, recalled, hired, released, upgraded, training, hospital, shop, gear, welcome-back, debug tools). They are used by the actions that show them; the ones used by functions in this note are `TOAST_WELCOME_BACK` (`_ready`), `TOAST_DEAD`, `TOAST_IN_HOSPITAL`, `TOAST_IN_TRAINING`, `TOAST_PARTY_FULL`, `TOAST_MOVED`, `TOAST_SENT` (`toggle_in_party`). `TOAST_FINAL_NOT_DENIABLE` is shown when Deny is tried on the final battle (`HallRules.can_deny`).

### Variables: the day
| Name | Kind | Meaning (units) |
|---|---|---|
| `quest_entries` | var (Array) | Today's quests in board order. Each entry is a Dictionary: `quest` (CreatedQuest), `state` (`HallStyle.QUEST_STATE_OPEN` / `SENT` / `DENIED`), `party` (Array of GuildCharacter; anyone pinned means the quest is sent), `milestone` (bool, the Bone Drake quest), `final` (bool, the `FINAL_DAY` battle). Set by [[hall_main#_generate_quests]]. |
| `active_tab` | var (String) | Showing bottom tab, one of `TAB_IDS`. Default `"board"`. |
| `guild_section` | var (String) | `GUILD_SECTION_ROSTER` or `_HIRE`. |
| `upgrades_section` | var (String) | `UPGRADES_SECTION_TONIGHT` or `_BUILD`. |
| `items_section` | var (String) | `ITEMS_SECTION_PACK` or `_SHOP`. Default shop. |
| `shop_last_seen_day` | var (int) | Day the Items tab last opened on its own: the first visit each day shows the Shop, later ones keep the half left open. |
| `training_picker_open` | var (bool) | Upgrades > Facilities: the "+ Add a hero" list under the Training Yard is open. |
| `active_screen` | var (Dictionary) | Screen covering the tabs, or `{}`: `{kind: SCREEN_ASSIGN, quest_index: int}` or `{kind: SCREEN_CHARACTER, character: GuildCharacter, return_to: Dictionary}` (the screen to go back to). |
| `show_busy_adventurers` | var (bool) | Assign Party also lists adventurers already in another party. Off by default. |
| `for_hire_last_seen_day` | var (int) | Day the player last opened For Hire (the Guild badge clears then). |

### Variables: reports and overlays
| Name | Kind | Meaning (units) |
|---|---|---|
| `shown_report` | var (Dictionary) | The Day Report showing, or `{}`: `{day, results, starts_next_day, home, released}`. `starts_next_day` is true right after End Day. |
| `shown_boss_crawl` | var (Dictionary) | Boss crawl shown after End Day on a boss day (not the final), or `{}`: `{day, results}`. Its Continue button (`close_boss_crawl`) opens the Day Report, kept in `_pending_report`. |
| `is_quest_travel_open` | var (bool) | The "Going on a quest" screen ([[overlay_quest_travel]]) is showing after End Day; the night is already rolled and saved. Set by [[hall_main#_go_on_quest]], cleared in the curtain's peak callbacks of [[hall_main#end_day]] and [[hall_main#_show_final_credits]]. Never saved. |
| `skip_quest_travel` | var (bool) | When true, End Day skips the travel screen and runs the dusk curtain straight away. Set by [[agent_bridge_actions#end_day]] (`agent_bridge_actions.gd:244`) and headless tests. |
| `_after_quest_travel` | var (Callable) | The dusk curtain waiting for the travel screen's button; run once by [[hall_main#close_quest_travel]], then cleared. |
| `_pending_report` | var (Dictionary) | The night's Day Report, waiting behind the boss crawl until Continue. |
| `released_today` | var (Array) | Heroes released today for the Day Report: `{character, standing (cost), fallen}`. Cleared when the next day starts. |
| `previous_report` | var (Dictionary) | Last night's report, so the Menu can show it again. |
| `is_end_check_open` | var (bool) | The End Day sheet is showing. |
| `is_night_falling` | var (bool) | True from End Day until the night's report (or credits) shows. The quests have already played out; the End Day sheet stays as left while the dusk falls. |
| `is_welcome_open` | var (bool) | Welcome card showing. Starts `true`. |
| `is_intro_seen` | var (bool) | True once Begin was pressed on the intro crawl. Saved with the run, so the crawl shows once per save. |
| `is_intro_replay` | var (bool) | Debug tools' Replay intro: shows the crawl on any day (not saved). |
| `is_welcome_from_menu` | var (bool) | How to Play was opened from the Menu (Close keeps the tab). |
| `is_menu_open`, `is_accessibility_open`, `is_backup_open`, `is_debug_open` | var (bool) | The Menu and its three sheets (Accessibility, Backup save, Debug tools). |
| `run_over_stats` | var (Dictionary) | The Game Over ledger's numbers, or `{}` while the run goes on. Filled once by `_check_run_over` (see [[hall_main#build_run_over_stats]]). |
| `shown_credits` | var (Dictionary) | The final battle's credits roll, or `{}`. Filled by `end_day` on `FINAL_DAY` (keys in `HallLedger.build_credits`). It covers every other overlay: a win leaves through `start_freeplay`, a loss through `start_new_run`. |
| `final_battle_lost` | var (bool) | True once the final battle is lost: the run is over (`is_run_over`) and the defeat credits stand in for the Game Over ledger. |

### Variables: the run
| Name | Kind | Meaning (units) |
|---|---|---|
| `run_stats` | var (Dictionary) | Tallies for the Game Over ledger, zero at the start of every run (the scene is reloaded). Keys: `gold_earned` (int), `quests_sent` (int), `quests_won` (int), `heroes_hired` (int), `drake_result` (`DRAKE_RESULT_*`), `released` (Array of GuildCharacter), `gold_spent` (int), `items_found` (int), `final_result` (`FINAL_RESULT_*`), `final_party` (Array of GuildCharacter), `failed_by_day` (Dictionary: day -> quests lost that day; old saves lack it, so read it with `.get`; written in [[hall_main#_run_quest]], read by [[hall_ledger#recent_failures]]). |
| `color_filter` | var (int) | Colorblind filter: index into `HallSettings.COLOR_FILTERS` (0 = off). Saved by `HallSettings`. |
| `reduce_motion` | var (bool) | Reduced Motion (`HallFx.reduce_motion` mirrors it). Saved by `HallSettings`. |
| `text_size` | var (int) | Index into `HallSettings.TEXT_SIZES`, applied by `HallFontScale`. Saved by `HallSettings`. Set in [[hall_main#_enter_tree]]. |
| `is_save_enabled` | var (bool) | Dev switch ("Save runs" in Menu > Debug tools): when false the run is neither loaded nor saved. Saved by `HallSettings`. |
| `is_debug_run` | var (bool) | True once Debug tools were turned on this run (`enable_debug_tools`): the run is never saved again. Never saved itself. |
| `uses_save_file` | var (bool) | True only when this hall is the scene root (the game itself). A playtest scenario wraps the hall, so its preset day never touches the real save. Set in [[hall_main#_ready]]. |
| `shows_intro_without_save` | var (bool) | Day 1 intro shows even without the save file. Only the playtest bridge (`--intro`) sets it. |
| `is_resumed_run` | var (bool) | Start-up brought back a saved run (no Welcome card, a welcome-back toast). |
| `night_save` | var (Dictionary) | While End Day's dusk falls, the report or credits about to show: `{"shown_report": ...}` or `{"shown_credits": ..., "previous_report": ...}`. `HallSave` saves them as already showing, so closing mid-dusk can't replay the night. `{}` otherwise. |

### Variables: motion and internal
| Name | Kind | Meaning (units) |
|---|---|---|
| `pending_fx` | var (Dictionary) | One-shot hints from an action to the rows the next refresh rebuilds. Cleared at the end of every refresh. Keys: `quest_stamp` (int quest index), `writ_stamp` (bool), `seat_in` (GuildCharacter), `seat_out` (bool), `hire_next` (bool), `upgraded` (int Building), `home_row` (GuildCharacter), `gear_in` (StandardItem) / `gear_out` (bool), `bought` (int stock index). |
| `fx_layer` | var (Control) | Full-screen layer for motion that outlives a refresh (coins, floating numbers, stamps, dusk wash). Built in [[hall_main#_ready]]. |
| `_is_refresh_queued` | var (bool) | A refresh is waiting for the end of the frame. |
| `_last_view_key` | var (String) | Which tab / screen was showing at the last refresh (to know when to scroll to top). |
| `tutorial` | var (Control) | Pip, the tutorial coach (an `OverlayTutorial`), built in `_ready`, on top of every overlay. |

### Node references (`@onready`, unique names in [[hall_main (scene)]])
`_header` (`%Header`, HallHeader), `_nav` (`%Nav`, HallNav), `_toast` (`%Toast`, HallToast), `_tabs` (dictionary `board`/`guild`/`upgrades`/`shop` to `%TabBoard`/`%TabGuild`/`%TabUpgrades`/`%TabItems`), `_screens` (`SCREEN_ASSIGN` to `%ScreenAssign`, `SCREEN_CHARACTER` to `%ScreenCharacter`), overlays `_end_check_overlay` (`%OverlayEndDay`), `_report_overlay`, `_welcome_overlay`, `_menu_overlay`, `_accessibility_overlay`, `_backup_overlay`, `_debug_overlay`, `_game_over_overlay`, `_credits_overlay`, `_boss_crawl_overlay`, `_quest_travel_overlay` (`%OverlayQuestTravel`), `_intro_overlay`, and `_color_filter` (`%ColorFilter`, ColorRect).

## Functions

### _enter_tree
`func _enter_tree() -> void` · `Scripts/Hall/hall_main.gd:416`

Engine callback, before any child enters. Reads the saved Text size, scales the theme for this screen (`HallFontScale.init`), and connects `get_tree().node_added` to `HallFontScale.scale_authored_overrides` (so nodes added later get their `.tscn` font-size overrides scaled).

**Side effects:** sets `text_size`; scales the theme; connects `SceneTree.node_added` (only if not already connected).

**Called by:** the engine.

**Calls:** [[hall_settings#load_settings]] (`.text_size`), [[hall_settings#text_size_factor]], [[hall_font_scale#init]], [[hall_font_scale#scale_authored_overrides]].

### _exit_tree
`func _exit_tree() -> void` · `Scripts/Hall/hall_main.gd:424`

Engine callback. Disconnects `node_added` from `HallFontScale.scale_authored_overrides` if it is connected, so a reloaded hall doesn't leave a stale listener.

**Called by:** the engine.

### _ready
`func _ready() -> void` · `Scripts/Hall/hall_main.gd:429`

Engine callback. Start-up order:
1. On the web, if a newer deploy is waiting (`HallWebUpdate.apply_waiting_update()`), return at once (the page reloads).
2. `setup(self)` on the header, nav, tabs, screens and overlays ([[hall_main#_all_overlays]]).
3. Connect the redraw signals (see below).
4. Build `fx_layer` (full-rect `Control`, mouse ignored, z `FX_LAYER_Z_INDEX`) and the `OverlayTutorial` (`tutorial`).
5. `uses_save_file` is true when the parent is the tree root; `is_save_enabled` is read from settings. If both, `HallSave.request_persistent_storage()`, `HallSave.load_run(self)` (result in `is_resumed_run`) and [[hall_main#_send_picked_drafts]].
6. Add the tutorial and `tutorial.setup(self)`; add a `RunLogger` and `setup(self)`.
7. `_load_settings()`. A resumed run closes the Welcome card, toasts `TOAST_WELCOME_BACK` and calls `tutorial.resume_today()`; a fresh run calls [[hall_main#_add_starting_hero]] and [[hall_main#_generate_quests]].
8. `refresh()`, `HallWebUpdate.watch(self)`, and a deferred [[hall_main#_check_run_over]] (a playtest scenario builds its roster in its own `_ready`, which runs after this one).

**Connections made here** (all to `queue_refresh` unless noted): `GameState.day_started` to [[hall_main#_on_day_started]], `GameState.resources_changed`, `GuildUpgrades.upgrades_changed`, `GuildUpgrades.home_changed`, `CharacterContainer.on_character_added`, `on_character_removed`, `on_hireables_refreshed`, `ItemShop.stock_changed`, `ItemShop.gear_changed`.

**Called by:** the engine.

**Calls:** [[hall_main#_all_overlays]], [[hall_main#queue_refresh]], [[hall_main#_send_picked_drafts]], [[hall_main#_load_settings]], [[hall_main#show_toast]], [[hall_main#refresh]], [[hall_main#_check_run_over]], [[hall_main#_add_starting_hero]], [[hall_main#_generate_quests]], [[hall_web_update#apply_waiting_update]] / [[hall_web_update#watch]], [[hall_save#request_persistent_storage]] / [[hall_save#load_run]], [[hall_settings#load_settings]], [[overlay_tutorial#setup]] / [[overlay_tutorial#resume_today]], [[run_logger#setup]].

### _add_starting_hero
`func _add_starting_hero() -> void` · `Scripts/Hall/hall_main.gd:500`

A fresh run (Day 1, empty roster) starts with Uncle John (`HallRules.make_starting_hero`). Does nothing on a later day or with a non-empty roster (a saved run, or a playtest scenario that fills the roster in its own `_ready`).

**Returns:** nothing.

**Side effects:** adds a hero to `CharacterContainer.active_characters`; `GuildUpgrades.sync_characters()`.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:477`).

**Calls:** [[hall_rules#make_starting_hero]], [[character_container#add_character_to_guild]], [[guild_upgrades#sync_characters]].

### _on_day_started
`func _on_day_started(_day: int) -> void` · `Scripts/Hall/hall_main.gd:507`

Handler for `GameState.day_started`: builds the new day's quests and queues a redraw.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_day` | `int` | New day number, unused (the day is read from `GameState.day`) | Emitted by [[game_state#start_new_day]] |

**Called by:** signal `GameState.day_started` ([[game_state]]) (connected at `hall_main.gd:430`).

**Calls:** [[hall_main#_generate_quests]], [[hall_main#queue_refresh]].

### _generate_quests
`func _generate_quests() -> void` · `Scripts/Hall/hall_main.gd:513`

Fills `quest_entries` for today with `HallRules.build_day_quests(GameState.day, GuildUpgrades.standing, GameState.is_freeplay)`.

**Side effects:** replaces `quest_entries` (any drafted parties are gone).

**Called by:** [[hall_main#_ready]] (`hall_main.gd:478`, fresh run), [[hall_main#_on_day_started]] (`hall_main.gd:498`), [[hall_main#debug_reroll_today]] (`hall_main.gd:1483`).

**Calls:** [[hall_rules#build_day_quests]].

### freeplay_scale
`func freeplay_scale() -> float` · `Scripts/Hall/hall_main.gd:518`

Freeplay's multiplier on today's quest requirements and rewards: `HallRules.freeplay_scale(GameState.day)`.

**Returns:** `float`. No caller of the wrapper was found (the rules call `HallRules.freeplay_scale` directly); see Suspected issues.

**Calls:** [[hall_rules#freeplay_scale]].

### roster
`func roster() -> Array` · `Scripts/Hall/hall_main.gd:528`

Everyone in the guild: `CharacterContainer.active_characters` (the same array, not a copy).

**Returns:** `Array` of `GuildCharacter`. Used by the ledger wrappers below, by tabs and rows to list heroes (`tab_guild.gd:147`, `screen_assign.gd:351`, `home_section.gd:84`), by the tutorial (`overlay_tutorial.gd:926`) and by the bridge (`agent_bridge_state.gd:34`).

**Called by:** [[hall_main#trouble_reason]] (`hall_main.gd:564`), [[hall_main#last_living_hero]] (`hall_main.gd:574`), `overlay_tutorial.gd:979`, [[hall_main#build_run_over_stats]] (`:579`), [[hall_main#build_run_records]] (`:584`), [[hall_main#build_credits]] (`:590`), [[hall_main#hurt_waiting_count]] (`:635`), `run_logger.gd:175`, `agent_bridge_actions.gd:124`, `agent_bridge_actions.gd:335`, `agent_bridge_state.gd:34`, `overlay_tutorial.gd:926`, `overlay_tutorial.gd:955`, `home_section.gd:84`, `home_section.gd:125`, `screen_assign.gd:351`, `hall_nav.gd:99`, `tab_guild.gd:147`, `tab_guild.gd:167` (plus further bridge sites at `agent_bridge_actions.gd:128`, `:148`, `:170`, `:180`, `:200`).

**Calls:** `CharacterContainer.active_characters` ([[character_container]]).

### is_roster_full
`func is_roster_full() -> bool` · `Scripts/Hall/hall_main.gd:533`

True when every bed is taken by a living hero (no more hiring or reviving): `not CharacterContainer.has_free_bed()`.

**Returns:** `bool`. `can_hire_anyone`, `unseen_recruit_count`, `hire` and `revive` use it to refuse; cards disable their Hire buttons with it.

**Called by:** [[hall_main#can_hire_anyone]] (`hall_main.gd:537`), [[hall_main#unseen_recruit_count]] (`:542`), [[hall_main#hire]] (`:1098`), [[hall_main#revive]] (`:1318`), `home_row.gd:203`, `hire_card.gd:54`, `screen_character.gd:157`, `tab_board.gd:80`, `tab_guild.gd:122`.

**Calls:** [[character_container#has_free_bed]].

### release_standing_cost
`func release_standing_cost(character: GuildCharacter) -> int` · `Scripts/Hall/hall_main.gd:539`

Standing it costs to release this hero: 0 for the fallen, otherwise `RELEASE_BASE_STANDING_COST + character.pluck`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero being released | the character page's hero in `screen_character.gd:335`; the argument of [[hall_main#release]] |

**Returns:** `int`, standing points. `release` subtracts it; `screen_character.gd` shows it on the Release button.

**Called by:** [[hall_main#release]] (`hall_main.gd:1144`), `screen_character.gd:335`.

**Calls:** [[hall_style#is_dead]].

### can_hire_anyone
`func can_hire_anyone() -> bool` · `Scripts/Hall/hall_main.gd:546`

True when there is at least one recruit in `CharacterContainer.hireable_characters` and a free bed.

**Returns:** `bool`. `hall_nav.gd:99` uses it for the Guild badge when the roster is empty.

**Called by:** `hall_nav.gd:99`.

**Calls:** [[hall_main#is_roster_full]].

### unseen_recruit_count
`func unseen_recruit_count() -> int` · `Scripts/Hall/hall_main.gd:551`

Recruits the player hasn't looked at yet today (drives the Guild badge). Returns 0 when the hire feature is locked, For Hire was already opened today (`for_hire_last_seen_day == GameState.day`), or the roster is full; otherwise the size of the hire pool.

**Returns:** `int`. `hall_nav.gd:101` formats it into the badge text; `tab_board.gd:82` tests `> 0`.

**Called by:** `hall_nav.gd:101`, `tab_board.gd:82`.

**Calls:** [[hall_main#is_locked]], [[hall_main#is_roster_full]].

### is_run_over
`func is_run_over() -> bool` · `Scripts/Hall/hall_main.gd:561`

True when the guild can never send anyone out again (`HallLedger.is_run_over()`), or the final battle was lost.

**Returns:** `bool`. [[hall_main#_check_run_over]] uses it to decide whether to build the Game Over ledger.

**Called by:** [[hall_main#_check_run_over]] (`hall_main.gd:1683`).

**Calls:** [[hall_ledger#is_run_over]].

### is_one_death_from_falling
`func is_one_death_from_falling() -> bool` · `Scripts/Hall/hall_main.gd:567`

True when one hero is left alive and losing them would (or nearly would) end the run (`HallLedger.is_one_death_from_falling`). Drives the header's warning strip.

**Called by:** `hall_header.gd:202` (sets `_danger_strip.visible`).

**Calls:** [[hall_ledger#is_one_death_from_falling]].

### trouble_reason
`func trouble_reason() -> String` · `Scripts/Hall/hall_main.gd:573`

Why the guild is "in trouble" (`"failures"` or `"injuries"`), or `""` when it isn't. A thin wrapper over [[hall_ledger#trouble_reason]] with `run_stats`, `roster()` and `GameState.day`. Drives the header's second (gold) warning strip.

**Returns:** `String`. [[hall_header#_refresh_danger_strip]] uses it.

**Called by:** [[hall_header#_refresh_danger_strip]] (`hall_header.gd:203`).

**Calls:** [[hall_ledger#trouble_reason]], [[hall_main#roster]].

### recent_failures
`func recent_failures() -> int` · `Scripts/Hall/hall_main.gd:578`

Quests lost over the last `HallLedger.TROUBLE_WINDOW_DAYS` days (wrapper over [[hall_ledger#recent_failures]]).

**Returns:** `int`. [[hall_header#_refresh_danger_strip]] puts it in the "N quests lost in M days" text.

**Called by:** [[hall_header#_refresh_danger_strip]] (`hall_header.gd:215`).

**Calls:** [[hall_ledger#recent_failures]].

### last_living_hero
`func last_living_hero() -> GuildCharacter` · `Scripts/Hall/hall_main.gd:583`

The one living member of the guild, or `null` if there isn't exactly one.

**Called by:** `hall_header.gd:200` (the danger strip's hero).

**Calls:** [[hall_main#roster]], [[hall_ledger#last_living_hero]].

### build_run_over_stats
`func build_run_over_stats() -> Dictionary` · `Scripts/Hall/hall_main.gd:588`

Everything the Game Over ledger shows (keys in `HallLedger.build_run_over_stats`), from `run_stats` and the roster.

**Returns:** `Dictionary`. [[hall_main#_check_run_over]] stores it in `run_over_stats`.

**Called by:** [[hall_main#_check_run_over]] (`hall_main.gd:1685`).

**Calls:** [[hall_main#roster]], [[hall_ledger#build_run_over_stats]].

### build_run_records
`func build_run_records() -> Dictionary` · `Scripts/Hall/hall_main.gd:593`

The run's extra records for the credits roll (keys in `HallLedger.build_run_records`).

**Returns:** `Dictionary`. No caller of this wrapper was found; `HallLedger.build_credits` calls the static version itself (`hall_ledger.gd:196`). See Suspected issues.

**Calls:** [[hall_main#roster]], [[hall_ledger#build_run_records]].

### build_credits
`func build_credits(result: Dictionary) -> Dictionary` · `Scripts/Hall/hall_main.gd:599`

Everything the final battle's credits roll shows (see `HallLedger.build_credits`).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result` | `Dictionary` | The final quest's `_run_quest` result | `result` in [[hall_main#_show_final_credits]] |

**Returns:** `Dictionary`, stored in `shown_credits`.

**Called by:** [[hall_main#_show_final_credits]] (`hall_main.gd:1585`).

**Calls:** [[hall_main#roster]], [[hall_ledger#build_credits]].

### can_deny_quest
`func can_deny_quest(entry: Dictionary) -> bool` · `Scripts/Hall/hall_main.gd:606`

True when `entry` may be denied (false for the final battle): `HallRules.can_deny(entry)`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A `quest_entries` entry | `hall.current_quest_entry()` in `screen_assign.gd:417`; `hall.quest_entries[quest]` in `agent_bridge_actions.gd:219` |

**Called by:** `screen_assign.gd:417` (shows the left button), `agent_bridge_actions.gd:219`.

**Calls:** [[hall_rules#can_deny]].

### undecided_count
`func undecided_count() -> int` · `Scripts/Hall/hall_main.gd:611`

Quests still needing Send or Deny (state `QUEST_STATE_OPEN`).

**Returns:** `int`. [[hall_main#open_end_check]] and [[hall_main#end_day]] test `> 0`; the nav badge shows it; the Board uses it for its checklist and button.

**Called by:** [[hall_main#decided_count]] (`hall_main.gd:607`), [[hall_main#open_end_check]] (`:1513`), [[hall_main#end_day]] (`:1534`), `agent_bridge_actions.gd:234`, `hall_nav.gd:94`, `tab_board.gd:92`, `tab_board.gd:108`.

### decided_count
`func decided_count() -> int` · `Scripts/Hall/hall_main.gd:616`

Quests that have been sent or denied: `quest_entries.size() - undecided_count()`.

**Called by:** `tab_board.gd:91` (the "decided / total" text).

**Calls:** [[hall_main#undecided_count]].

### sent_entries
`func sent_entries() -> Array` · `Scripts/Hall/hall_main.gd:621`

Entries whose party goes out tonight (state `QUEST_STATE_SENT`).

**Called by:** [[hall_main#end_day]] (`hall_main.gd:1544`, plays each one), `overlay_end_day.gd:68`.

### denied_entries
`func denied_entries() -> Array` · `Scripts/Hall/hall_main.gd:625`

Entries the player denied (state `QUEST_STATE_DENIED`). No `##` comment in the code.

**Called by:** `overlay_end_day.gd:79`.

### quest_index_of
`func quest_index_of(character: GuildCharacter) -> int` · `Scripts/Hall/hall_main.gd:630`

Index of the quest whose party (sent or draft) has this character.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero to look for | the row's or screen's hero (`member_card.gd:69`, `pick_row.gd:73`, `screen_assign.gd:390`) |

**Returns:** `int`, index into `quest_entries`, or `-1` when the hero is in no party. Callers test `>= 0` to treat the hero as busy or to name the quest they are on.

**Called by:** [[hall_main#toggle_in_party]] (`hall_main.gd:969`), [[hall_main#_leave_quest]] (`:1331`), `overlay_move_confirm.gd:57`, `home_row.gd:88`, `:163`, `:193`, `member_card.gd:69`, `:93`, `pick_row.gd:73`, `:92`, `screen_assign.gd:390`, `screen_character.gd:185`, `:340`.

### can_go_on_quests
`func can_go_on_quests(character: GuildCharacter) -> bool` · `Scripts/Hall/hall_main.gd:638`

False for anyone who can't be put in a party: dead, in a Hospital bed, or training.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero to check | the picker row's hero (`pick_row.gd:108`, `screen_assign.gd:398`) |

**Returns:** `bool`.

**Called by:** `pick_row.gd:108`, `screen_assign.gd:398`, `agent_bridge_state.gd:61`.

**Calls:** [[hall_style#is_dead]], [[guild_upgrades#is_patient]], [[guild_upgrades#is_training]].

### hurt_waiting_count
`func hurt_waiting_count() -> int` · `Scripts/Hall/hall_main.gd:644`

Hurt heroes who aren't in a Hospital bed (the Upgrades > Facilities badge).

**Returns:** `int`. `tab_upgrades.gd:91` shows it; the tutorial step skips itself when it is 0 (`overlay_tutorial.gd:1090`).

**Called by:** `tab_upgrades.gd:91`, `overlay_tutorial.gd:1090`.

**Calls:** [[hall_main#roster]], [[guild_upgrades#needs_care]], [[guild_upgrades#is_patient]].

### party_size_limit
`func party_size_limit(entry: Dictionary) -> int` · `Scripts/Hall/hall_main.gd:650`

How many adventurers a quest takes at most: `QuestScoring.get_slot_count(entry.quest)`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A `quest_entries` entry | `current_quest_entry()` (`toggle_in_party`, `screen_assign.gd:219`); the row's own entry (`quest_row.gd:95`) |

**Returns:** `int`. [[hall_main#toggle_in_party]] uses it to refuse a full party (solo quests swap instead); `screen_assign.gd:245` draws that many seats.

**Called by:** [[hall_main#toggle_in_party]] (`hall_main.gd:959`), `quest_row.gd:95`, `screen_assign.gd:219`, `:245`, `overlay_tutorial.gd:926`, `:932`, `agent_bridge_state.gd:91`.

**Calls:** [[quest_scoring#get_slot_count]].

### success_chance
`func success_chance(entry: Dictionary, party: Array) -> int` · `Scripts/Hall/hall_main.gd:655`

Success chance (0-100+) as the quest computes it (`entry.quest.calcSuccessChance(party)`).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A `quest_entries` entry | the row's or screen's entry |
| `party` | `Array` | Heroes to score | `entry.party` in all callers (`quest_row.gd:123`, `plan_row.gd:25`, `screen_assign.gd:256`) |

**Returns:** `int` percent, or `-1` for an empty party (callers show "no party").

**Called by:** `quest_row.gd:123`, `plan_row.gd:25`, `screen_assign.gd:256`, `agent_bridge_state.gd:93`.

**Calls:** [[quest_resource#calcSuccessChance]].

### pluck_gain_for
`func pluck_gain_for(chance: float) -> int` · `Scripts/Hall/hall_main.gd:663`

Pluck each party member gains for winning a quest sent at `chance` percent (`HallRules.pluck_gain_for`).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `chance` | `float` | Success chance in percent | `chance` computed by `success_chance` in `screen_assign.gd` (call at `:277`) |

**Called by:** `screen_assign.gd:277`.

**Calls:** [[hall_rules#pluck_gain_for]].

### trains_stat
`func trains_stat(entry: Dictionary, chance: float) -> bool` · `Scripts/Hall/hall_main.gd:669`

Whether winning this quest at `chance` percent trains a stat instead of giving Pluck: `HallRules.trains_stat(chance, entry.quest.difficulty)`.

**Returns:** `bool`. `screen_assign.gd:272` picks the preview text from it.

**Called by:** `screen_assign.gd:272`.

**Calls:** [[hall_rules#trains_stat]].

### trained_stat_options
`func trained_stat_options(entry: Dictionary) -> Array[int]` · `Scripts/Hall/hall_main.gd:675`

The one or two `GuildCharacter.StatType` indexes a good-odds win on this quest can train (`entry.quest.trained_stat_options()`).

**Called by:** `screen_assign.gd:274` (lists the stat names).

**Calls:** [[quest_resource#trained_stat_options]].

### chance_added_by
`func chance_added_by(entry: Dictionary, character: GuildCharacter) -> int`  · `Scripts/Hall/hall_main.gd:680`

How many points of success chance this character gives a quest on their own: `int(entry.quest.calcSuccessChance([character]))`.

**Called by:** `pick_row.gd:120` (shows the chance), `screen_assign.gd:366` (sorts the picker by it).

**Calls:** [[quest_resource#calcSuccessChance]].

### current_quest_entry
`func current_quest_entry() -> Dictionary` · `Scripts/Hall/hall_main.gd:685`

The quest shown on Assign Party (index clamped into range), or `{}` when that screen isn't open or there are no quests.

**Returns:** `Dictionary` entry or `{}`. Every caller checks `is_empty()` or reads `.state`.

**Called by:** [[hall_main#toggle_in_party]] (`hall_main.gd:937`), [[hall_main#deny_quest]] (`:1017`), [[hall_main#recall_party]] (`:1039`), [[hall_main#reconsider_quest]] (`:1051`), `screen_assign.gd:192`, `:443`, `:454`, `overlay_tutorial.gd:931`.

### next_undecided_index
`func next_undecided_index(start_index: int = 0) -> int` · `Scripts/Hall/hall_main.gd:692`

First undecided (open) quest at or after `start_index`, wrapping around.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `start_index` | `int` | Where to start looking | `0` from the Board (`tab_board.gd:109`) and [[hall_main#open_end_check]] (`:1496`); `active_screen.quest_index + 1` in [[hall_main#_go_to_next_undecided]] (`:1070`) |

**Returns:** `int` index, or `-1` when every quest is decided.

**Called by:** [[hall_main#_go_to_next_undecided]] (`hall_main.gd:1084`), [[hall_main#open_end_check]] (`:1514`), `tab_board.gd:109`.

### is_locked
`func is_locked(feature: String) -> bool` · `Scripts/Hall/hall_main.gd:706`

True while a feature is held back: a bottom tab until its unlock day (every run), or a control Pip hasn't taught yet while the tutorial is on (`OverlayTutorial.UNLOCK_DAY`: Applicants, hero pages, Deny).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `feature` | `String` | A tab id (`"upgrades"`, `"shop"`) or an `OverlayTutorial.FEATURE_*` id | constants at each call site, or `tab_id` in [[hall_main#open_tab]] |

**Returns:** `bool`. Callers disable or hide the control, or (actions) return without doing anything.

**Called by:** [[hall_main#unseen_recruit_count]] (`hall_main.gd:542`), [[hall_main#open_tab]] (`:755`, `:757`), [[hall_main#open_character]] (`:806`), [[hall_main#deny_quest]] (`:1015`), [[hall_main#hire]] (`:1096`), [[hall_main#upgrade_building]] (`:1165`), and views: `member_card.gd:54`, `pick_row.gd:60`, `screen_assign.gd:384`, `:428`, `hall_nav.gd:97`, `tab_board.gd:76`, `tab_guild.gd:99`, `:108`, plus the bridge (`agent_bridge_actions.gd:114`, `:133`, `:189`, `:213`; `agent_bridge_state.gd:47`).

**Calls:** [[hall_main#is_tab_locked]], [[overlay_tutorial#is_locked]] (via `tutorial`, `hall_main.gd:699`).

### is_tab_locked
`func is_tab_locked(tab_id: String) -> bool` · `Scripts/Hall/hall_main.gd:715`

True while a bottom tab is held back. In every run, tutorial or not, the Guild tab (id `"upgrades"`) stays locked until `GuildUpgrades.UNLOCK_DAY` and the Items tab (id `"shop"`) until `ItemShop.UNLOCK_DAY`. Compares `GameState.day` with [[hall_main#tab_unlock_day]].

**Called by:** [[hall_main#is_locked]] (`hall_main.gd:697`), [[hall_main#affordable_buildings]] (`:723`), `hall_nav.gd:74`, `:90`, `tab_board.gd:97`, `tab_guild.gd:115`.

**Calls:** [[hall_main#tab_unlock_day]].

### tab_unlock_day
`func tab_unlock_day(tab_id: String) -> int` · `Scripts/Hall/hall_main.gd:720`

The day a tab opens: `GuildUpgrades.UNLOCK_DAY` for `"upgrades"`, `ItemShop.UNLOCK_DAY` for `"shop"`, `0` (always open) for anything else.

**Called by:** [[hall_main#is_tab_locked]] (`hall_main.gd:706`).

### affordable_buildings
`func affordable_buildings() -> Array` · `Scripts/Hall/hall_main.gd:732`

Buildings that can be upgraded right now (status `READY`: enough gold and standing), in `HallStyle.buildings_in_order()` order. Empty while the Guild tab (id `"upgrades"`) is still locked, so nothing (End Day sheet, Board note, badge) offers them early.

**Returns:** `Array` of `GuildUpgrades.Building` values.

**Called by:** `overlay_end_day.gd:89`, `overlay_tutorial.gd:1074`, `hall_nav.gd:103`, `tab_board.gd:100`, `tab_upgrades.gd:70`.

**Calls:** [[hall_main#is_tab_locked]], [[hall_style#buildings_in_order]], [[guild_upgrades#get_upgrade_status]].

### days_until_next_boss
`func days_until_next_boss() -> int` · `Scripts/Hall/hall_main.gd:740`

Days left before the next boss day: `0` = today, `-1` = no boss is left. Uses `HallRules.next_boss_day(GameState.day)`.

**Called by:** [[hall_main#days_until_drake]] (`hall_main.gd:742`), `hall_header.gd:152`, `:243` (the countdown).

**Calls:** [[hall_rules#next_boss_day]].

### next_boss_is_final
`func next_boss_is_final() -> bool` · `Scripts/Hall/hall_main.gd:746`

True when the next boss day is the final battle (`FINAL_DAY`).

**Called by:** `hall_header.gd:157` (picks the final or milestone seal).

**Calls:** [[hall_rules#next_boss_day]].

### days_until_drake
`func days_until_drake() -> int` · `Scripts/Hall/hall_main.gd:751`

Older name for [[hall_main#days_until_next_boss]], kept for the playtest bridge.

**Called by:** `agent_bridge_state.gd:28`.

### open_tab
`func open_tab(tab_id: String, section: String = "") -> void` · `Scripts/Hall/hall_main.gd:763`

Switch bottom tab. Closes any screen; party drafts stay on their quests. A locked tab (or the locked Applicants half) just doesn't open.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tab_id` | `String` | One of `TAB_IDS` | literal at each caller, or the nav button's id |
| `section` | `String` | Optional half: `GUILD_SECTION_*`, `UPGRADES_SECTION_*`, or `ITEMS_SECTION_*` for the Items tab | `HallMain.GUILD_SECTION_HIRE` etc. in `tab_board.gd:45`, `screen_assign.gd:149` |

**Side effects:** plays `tab_switch`; sets `active_tab` and the matching `*_section` (Items tab: an explicit section wins, otherwise the first visit each day shows the Shop; `shop_last_seen_day` updated); opening For Hire sets `for_hire_last_seen_day`; clears `active_screen`; `queue_refresh()`; emits `tutorial_event("tab", {tab, guild, upgrades})`.

**Called by:** [[hall_main#show_guild_section]], [[hall_main#show_upgrades_section]], [[hall_main#show_items_section]] (`hall_main.gd:780`, `:785`, `:790`), [[hall_main#close_welcome]] (`:908`), `screen_assign.gd:149`, `tab_board.gd:45`, `:47`, `tab_guild.gd:77`, and `pressed` on each bottom nav button (`hall_nav.gd:53`, bound to `tab_id`).

**Calls:** [[hall_main#is_locked]], [[hall_main#queue_refresh]], [[sound_effects#play]].

### show_guild_section
`func show_guild_section(section: String) -> void` · `Scripts/Hall/hall_main.gd:789`

The Guild tab's Your Guild / For Hire buttons: `open_tab("guild", section)`.

**Called by:** `pressed` on the roster section button (`tab_guild.gd:75`) and the hire section button (`tab_guild.gd:76`).

**Calls:** [[hall_main#open_tab]].

### show_upgrades_section
`func show_upgrades_section(section: String) -> void` · `Scripts/Hall/hall_main.gd:794`

The Upgrades tab's Facilities / Build buttons: `open_tab("upgrades", section)`.

**Called by:** `pressed` on `_tonight_button` (`tab_upgrades.gd:57`) and `_build_button` (`tab_upgrades.gd:58`).

**Calls:** [[hall_main#open_tab]].

### show_items_section
`func show_items_section(section: String) -> void` · `Scripts/Hall/hall_main.gd:799`

The Items tab's Pack / Shop folder tabs: `open_tab(TAB_SHOP, section)`.

**Called by:** `pressed` on `_pack_button` (`tab_items.gd:41`) and `_shop_button` (`tab_items.gd:42`).

**Calls:** [[hall_main#open_tab]].

### open_assign
`func open_assign(quest_index: int) -> void` · `Scripts/Hall/hall_main.gd:804`

Open Assign Party on one quest. Does nothing when there are no quests.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest_index` | `int` | Index into `quest_entries` (clamped) | `next_undecided_index(0)` in `tab_board.gd:109` and [[hall_main#open_end_check]]; the bridge's `quest` argument |

**Side effects:** sets `active_screen = {kind: SCREEN_ASSIGN, quest_index}` and `active_tab = "board"`; plays `page_open`; `queue_refresh()`; emits `tutorial_event("assign", quest_index)`.

**Called by:** [[hall_main#open_end_check]] (`hall_main.gd:1514`), `tab_board.gd:109`, `agent_bridge_actions.gd:203`, `:221`, `pressed` on the quest row (`quest_row.gd:65`, bound to `quest_index`) and on the quest strip tab (`quest_tab.gd:27`).

**Calls:** [[hall_main#queue_refresh]], [[sound_effects#play]].

### open_character
`func open_character(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:815`

Open a character's details over whatever is showing. Does nothing while `OverlayTutorial.FEATURE_HERO_PAGE` is locked.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero to show | bound by the row: `hall.open_character.bind(character)` |

**Side effects:** `active_screen = {kind: SCREEN_CHARACTER, character, return_to: active_screen.duplicate()}`; plays `page_open`; `queue_refresh()`; emits `tutorial_event("character", character)`.

**Called by:** `pressed` on the member card (`member_card.gd:53`) and on the picker row's info button (`pick_row.gd:59`).

**Calls:** [[hall_main#is_locked]], [[hall_main#queue_refresh]], [[sound_effects#play]].

### close_screen
`func close_screen() -> void` · `Scripts/Hall/hall_main.gd:825`

Character goes back to wherever it was opened from (`return_to`); Assign Party goes to the Board (`active_screen = {}`).

**Side effects:** plays `page_close`; `queue_refresh()`; emits `tutorial_event("close", null)`.

**Called by:** `pressed` on the Back buttons (`screen_assign.gd:148`, `screen_character.gd:114`), and `screen_assign.gd:447`, `:457`, `screen_character.gd:320`, `:361`.

**Calls:** [[hall_main#queue_refresh]], [[sound_effects#play]].

### open_menu
`func open_menu() -> void` · `Scripts/Hall/hall_main.gd:838`

Opens the Menu (`is_menu_open = true`), plays `page_open`, `queue_refresh()`. No `##` comment.

**Called by:** `pressed` on `_menu_button` (`hall_header.gd:125`).

### close_menu
`func close_menu() -> void` · `Scripts/Hall/hall_main.gd:844`

Closes the Menu, plays `page_close`, `queue_refresh()`. No `##` comment.

**Called by:** `pressed` on `_close_button` (`overlay_menu.gd:60`), and `overlay_menu.gd:99`.

### open_accessibility
`func open_accessibility() -> void` · `Scripts/Hall/hall_main.gd:851`

The Menu's Accessibility button: its sheet replaces the Menu (`is_menu_open = false`, `is_accessibility_open = true`), plays `page_open`, `queue_refresh()`.

**Called by:** `pressed` on `_accessibility_button` (`overlay_menu.gd:48`).

### close_accessibility
`func close_accessibility(go_to_menu: bool = true) -> void` · `Scripts/Hall/hall_main.gd:860`

Back from Accessibility to the Menu. `go_to_menu = false` closes both (a tap on the dimmed background).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `go_to_menu` | `bool` | True: return to the Menu; false: close everything | default from the Back button's `pressed` (`overlay_accessibility.gd:36`); `false` at `overlay_accessibility.gd:54` |

**Side effects:** clears `is_accessibility_open`, sets `is_menu_open = go_to_menu`, plays `page_close`, `queue_refresh()`.

**Called by:** `pressed` on `_back_button` (`overlay_accessibility.gd:36`), `overlay_accessibility.gd:54`.

### open_backup
`func open_backup() -> void` · `Scripts/Hall/hall_main.gd:868`

The Menu's Backup save button: its sheet replaces the Menu, then `queue_refresh()`. Plays no sound.

**Called by:** `pressed` on `_backup_button` (`overlay_menu.gd:49`).

### close_backup
`func close_backup(go_to_menu: bool = true) -> void` · `Scripts/Hall/hall_main.gd:876`

Back from Backup save to the Menu (`go_to_menu = false` closes both, for a tap on the dimmed background). Plays no sound.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `go_to_menu` | `bool` | True: return to the Menu | default from `_back_button` `pressed` (`overlay_backup.gd:52`); `false` at `overlay_backup.gd:125` |

**Called by:** `pressed` on `_back_button` (`overlay_backup.gd:52`), `overlay_backup.gd:125`.

### open_debug
`func open_debug() -> void` · `Scripts/Hall/hall_main.gd:884`

The Menu's Debug tools button: its sheet replaces the Menu. The first time in a run the sheet only asks to turn the tools on (see `enable_debug_tools`). Plays `page_open`.

**Called by:** `pressed` on `_debug_button` (`overlay_menu.gd:50`).

### close_debug
`func close_debug(go_to_menu: bool = true) -> void` · `Scripts/Hall/hall_main.gd:893`

Back from Debug tools to the Menu (`go_to_menu = false` closes both). Plays `page_close`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `go_to_menu` | `bool` | True: return to the Menu | default from `_back_button` `pressed` (`overlay_debug.gd:92`); `false` at `overlay_debug.gd:196` |

**Called by:** `pressed` on `_back_button` (`overlay_debug.gd:92`), `overlay_debug.gd:196`.

### open_welcome
`func open_welcome() -> void` · `Scripts/Hall/hall_main.gd:900`

The Menu's How to Play button: closes the Menu and shows the Welcome card (`is_welcome_from_menu = true`, `is_welcome_open = true`), plays `page_open`. No `##` comment.

**Called by:** `pressed` on `_how_to_play_button` (`overlay_menu.gd:46`).

### close_welcome
`func close_welcome() -> void` · `Scripts/Hall/hall_main.gd:910`

The fresh-run welcome leads to the Board. Opened from the Menu, closing just goes back to where you were (clears the flag, plays `page_close`, `queue_refresh()`); otherwise it calls `open_tab("board")`, which plays the tab sound.

**Called by:** `overlay_welcome.gd:170`.

**Calls:** [[hall_main#open_tab]].

### is_intro_open
`func is_intro_open() -> bool` · `Scripts/Hall/hall_main.gd:925`

True while the intro story crawl should cover the hall: a new run's Day 1 until Begin is pressed, once per save. Only for the real game (`uses_save_file`) or when the bridge asked (`shows_intro_without_save`), so playtest scenarios skip it. Also true while Debug's Replay intro has it open.

**Returns:** `bool`. [[hall_main#_refresh_overlays]] shows or hides the intro from it; the tutorial waits on it.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1886`), `overlay_tutorial.gd:241`, `:253`, `agent_bridge.gd:229`.

### close_intro
`func close_intro() -> void` · `Scripts/Hall/hall_main.gd:931`

The crawl's Begin button: plays `page_close`; a debug replay just closes (`is_intro_replay = false`); otherwise `is_intro_seen = true`, `queue_refresh()` and `tutorial.resume_today()` (Pip's Day 1 tutorial waited for it).

**Called by:** `pressed` on `_begin_button` (`overlay_intro.gd:75`).

**Calls:** [[hall_main#queue_refresh]], [[overlay_tutorial#resume_today]].

### toggle_in_party
`func toggle_in_party(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:946`

Assign Party: tap an adventurer to add or remove them. Someone already in another quest's party (sent or draft) moves over, so nobody is in two. Pinning anyone sends an open quest (there is no separate Send button).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The tapped hero | `character` in `overlay_move_confirm.gd:83` (the confirm sheet's hero); `hero` found by id in `agent_bridge_actions.gd:207` |

**Returns:** nothing. It does nothing on a denied or missing quest.

**Side effects:** edits `entry.party` and `entry.state`; sets `pending_fx` (`seat_out`, or `seat_in` and, for a newly sent quest, `writ_stamp`); plays `party_leave`, `quest_send` or `party_join`; toasts (`TOAST_MOVED`, `TOAST_SENT`, or an error toast for dead / in Hospital / training / party full); `queue_refresh()`; emits `tutorial_event("pick", entry)` and, if the quest was open, `tutorial_event("send", entry)`.

**Called by:** `overlay_move_confirm.gd:83`, `agent_bridge_actions.gd:207`, `pressed` on the picker row (`pick_row.gd:58`) and on a filled party seat (`party_slot.gd:43`).

**Calls:** [[hall_main#current_quest_entry]], [[hall_main#_remove_from_party]], [[hall_main#party_size_limit]], [[hall_main#quest_index_of]], [[hall_main#show_error_toast]], [[hall_main#show_toast]], [[hall_main#queue_refresh]], [[guild_upgrades#is_patient]], [[guild_upgrades#is_training]], [[hall_style#is_dead]], [[sound_effects#play]].

> [!note] How it works
> Order of checks: already in this party means remove (and stop); then dead, patient, training, and "party full" (only when the limit is above 1) are refused with a toast. A solo quest (`size_limit == 1`) clears the party first, so the new hero replaces the old one. If the hero sits in another quest's party, they are removed from it and a "moved from" toast shows. Then they are appended; an `OPEN` quest becomes `SENT`.

### _remove_from_party
`func _remove_from_party(entry: Dictionary, character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1003`

Take someone out of a party. A sent quest left with nobody goes back to open.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | The quest entry whose party changes | `current_quest_entry()` or `quest_entries[quest_index_of(character)]` |
| `character` | `GuildCharacter` | The hero to remove | the argument of [[hall_main#toggle_in_party]] / [[hall_main#_leave_quest]] |

**Returns:** nothing.

**Side effects:** erases the hero from `entry.party`; sets `entry.state` to `QUEST_STATE_OPEN` if the party is now empty and the state was `SENT`.

**Called by:** [[hall_main#toggle_in_party]] (`hall_main.gd:943`, `:972`), [[hall_main#_leave_quest]] (`hall_main.gd:1335`).

### set_show_busy_adventurers
`func set_show_busy_adventurers(is_on: bool) -> void` · `Scripts/Hall/hall_main.gd:1010`

Assign Party's "Show busy" toggle: stores `show_busy_adventurers` and queues a refresh.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `is_on` | `bool` | Toggle state | `toggled` signal of `_show_busy_toggle` (`screen_assign.gd:152`) |

**Returns:** nothing. **Side effects:** sets `show_busy_adventurers`; `queue_refresh()`.

**Called by:** `toggled` on `_show_busy_toggle` ([[screen_assign#setup]], `screen_assign.gd:152`).

**Calls:** [[hall_main#queue_refresh]].

### _send_picked_drafts
`func _send_picked_drafts() -> void` · `Scripts/Hall/hall_main.gd:1017`

Migration for old saves: an open quest that holds a draft party becomes sent (pinning anyone now always sends).

**Returns:** nothing. **Side effects:** sets `state = SENT` on every `OPEN` entry with a non-empty party.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:459`).

### deny_quest
`func deny_quest() -> void` · `Scripts/Hall/hall_main.gd:1024`

Turn the shown quest down (costs standing), then jump to the next undecided quest. Does nothing when the Deny feature is tutorial-locked or there is no current quest; the final battle can't be denied (error toast `TOAST_FINAL_NOT_DENIABLE`).

**Returns:** nothing.

**Side effects:** clears `entry.party`; sets state `DENIED`; `GameState.reduce_standing(cost)` with cost from `HallRules.standing_for_deny`; header pay animation for standing; toast `TOAST_DENIED`; plays `quest_deny`; shakes the writ on `ScreenAssign`; a red `DENIED` stamp via `HallFx.stamp_mark`; emits `tutorial_event("deny", entry)`.

**Called by:** [[screen_assign#_on_left_button_pressed]] (`screen_assign.gd:449`), [[agent_bridge_actions#_deny]] (`agent_bridge_actions.gd:222`).

**Calls:** [[hall_main#is_locked]], [[hall_main#current_quest_entry]], [[hall_rules#can_deny]], [[hall_rules#standing_for_deny]], [[hall_header#pay_fx]], [[game_state#reduce_standing]], [[hall_main#show_toast]], [[hall_main#show_error_toast]], [[sound_effects#play]], [[screen_assign#shake_writ]], [[screen_assign#stamp_point]], [[hall_fx#stamp_mark]], [[hall_main#_hold_then_move_on]].

### recall_party
`func recall_party() -> void` · `Scripts/Hall/hall_main.gd:1048`

Undo Send: the shown quest's party is cleared and the quest is open again (a pinned party always means sent, so it can't stay as a draft).

**Returns:** nothing. **Side effects:** `entry.party.clear()`, state `OPEN`; toast `TOAST_RECALLED`; plays `quest_undo`; `queue_refresh()`. Does nothing if there is no current quest.

**Called by:** [[screen_assign#_on_left_button_pressed]] (`screen_assign.gd:445`).

**Calls:** [[hall_main#current_quest_entry]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### reconsider_quest
`func reconsider_quest() -> void` · `Scripts/Hall/hall_main.gd:1060`

Undo Deny: the shown quest is open again (the standing lost isn't given back).

**Returns:** nothing. **Side effects:** state `OPEN`; toast `TOAST_RECONSIDER`; plays `quest_undo`; `queue_refresh()`.

**Called by:** [[screen_assign#_on_right_button_pressed]] (`screen_assign.gd:455`).

**Calls:** [[hall_main#current_quest_entry]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### _hold_then_move_on
`func _hold_then_move_on() -> void` · `Scripts/Hall/hall_main.gd:1073`

After Deny: the quest shows its new state, taps are blocked for `STAMP_HOLD_SECONDS`, then the next undecided quest shows (or the Board). With `HallFx.reduce_motion` it skips the wait.

**Returns:** nothing. **Side effects:** `queue_refresh()`; `HallFx.block_input`; a scene-tree timer whose `timeout` calls [[hall_main#_after_stamp]] with `active_screen.quest_index` as it was.

**Called by:** [[hall_main#deny_quest]] (`hall_main.gd:1032`).

**Calls:** [[hall_main#queue_refresh]], [[hall_main#_after_stamp]], [[hall_fx#block_input]].

### _after_stamp
`func _after_stamp(decided_index: int) -> void` · `Scripts/Hall/hall_main.gd:1083`

Runs after the stamp hold. Sets `pending_fx.quest_stamp = decided_index` (so that quest's row / strip tab stamps in). If Assign Party was closed meanwhile (Pip, End Day) it only refreshes; otherwise it moves on.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `decided_index` | `int` | Index of the quest just decided | `active_screen.quest_index` captured in [[hall_main#_hold_then_move_on]] (`:1064`) |

**Returns:** nothing.

**Called by:** [[hall_main#_hold_then_move_on]] (`hall_main.gd:1067` directly, `:1070` through the timer's `timeout`).

**Calls:** [[hall_main#queue_refresh]], [[hall_main#_go_to_next_undecided]].

### _go_to_next_undecided
`func _go_to_next_undecided() -> void` · `Scripts/Hall/hall_main.gd:1093`

Show the next undecided quest after the current one, or close to the Board (`active_screen = {}`) when none is left.

**Returns:** nothing. **Side effects:** changes `active_screen`; `queue_refresh()`.

**Called by:** [[hall_main#_after_stamp]] (`hall_main.gd:1079`).

**Calls:** [[hall_main#next_undecided_index]], [[hall_main#queue_refresh]].

### hire
`func hire(character: GuildCharacter) -> bool` · `Scripts/Hall/hall_main.gd:1105`

Hire an applicant from the For Hire pool.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The applicant | `recruit` in [[hire_card#_on_hire_pressed]] (`hire_card.gd:66`); `_shown_character()` in [[screen_character#_on_hire_pressed]] (`screen_character.gd:319`); `applicant` found by id in [[agent_bridge_actions#_hire]] (`agent_bridge_actions.gd:119`) |

**Returns:** `bool`, true when they joined. `hire_card.gd:66` then calls `send_hired_letter(self)` only on true; `agent_bridge_actions.gd:119` turns false into "cannot hire (gold or roster full)"; `screen_character.gd:319` ignores it. False also when the Hire feature is tutorial-locked or the roster is full (error toast `TOAST_ROSTER_FULL`, plus a refresh).

**Side effects:** `CharacterContainer.add_character_to_guild` (spends gold); `run_stats.heroes_hired += 1`; `_count_spent`; header gold pay animation if gold fell; `pending_fx.hire_next = true`; toast `TOAST_HIRED`; plays `hire`; emits `tutorial_event("hire", character)`; `queue_refresh()`.

**Called by:** [[hire_card#_on_hire_pressed]] (`hire_card.gd:66`), [[screen_character#_on_hire_pressed]] (`screen_character.gd:319`), [[agent_bridge_actions#_hire]] (`agent_bridge_actions.gd:119`).

**Calls:** [[hall_main#is_locked]], [[hall_main#is_roster_full]], [[hall_main#show_error_toast]], [[character_container#add_character_to_guild]], [[hall_main#_count_spent]], [[hall_header#pay_fx]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### send_hired_letter
`func send_hired_letter(card: Control) -> void` · `Scripts/Hall/hall_main.gd:1130`

The hired letter lifts off its stack, gets HIRED pressed onto it, sits `HIRE_STAMP_HOLD_SECONDS`, then flies to the "Your Guild" tab (see [[hall_main#_fly_hired_letter]]). Does nothing under Reduced Motion.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `card` | `Control` | The hire card that was just hired | `self` in [[hire_card#_on_hire_pressed]] (`hire_card.gd:67`) |

**Returns:** nothing. **Side effects:** `HallFx.detach(card, fx_layer)` (off the stack before the refresh can free it), `HallFx.stamp_onto`, a timer that calls `_fly_hired_letter`.

**Called by:** [[hire_card#_on_hire_pressed]] (`hire_card.gd:67`).

**Calls:** [[hall_fx#detach]], [[hall_fx#stamp_onto]], [[hall_main#_fly_hired_letter]].

### _fly_hired_letter
`func _fly_hired_letter(card: Control) -> void` · `Scripts/Hall/hall_main.gd:1139`

Second half of the hire animation: the letter flies to the roster tab button, which pops. Returns early if the card was freed meanwhile.

**Returns:** nothing. **Side effects:** plays `hire_letter_fly`; `HallFx.fly_away` to the centre of the roster button; `HallFx.pop` on the button.

**Called by:** the scene-tree timer's `timeout` created in [[hall_main#send_hired_letter]] (`hall_main.gd:1126`, bound with the card).

**Calls:** [[tab_guild#roster_button]], [[sound_effects#play]], [[hall_fx#fly_away]], [[hall_fx#pop]].

### release
`func release(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1152`

Let a hero go for good (Character screen's Release button, after its confirm sheet). They leave any quest party first, then `CharacterContainer` takes their gear off and frees their training slot and Hospital bed. Living heroes cost standing.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero to release | `_shown_character()` in [[screen_character#_on_release_confirmed]] (`screen_character.gd:360`); `hero` found by id in [[agent_bridge_actions#_release]] (`agent_bridge_actions.gd:127`) |

**Returns:** nothing; returns early if `remove_character_from_guild` refuses.

**Side effects:** reads cost and fallen state first; `GameState.reduce_standing` and standing pay animation when cost > 0; toast `TOAST_RELEASED_COST` or `TOAST_RELEASED`; plays `release`; appends to `released_today` and `run_stats.released`; `queue_refresh()`; then `_check_run_over()`.

**Called by:** [[screen_character#_on_release_confirmed]] (`screen_character.gd:360`), [[agent_bridge_actions#_release]] (`agent_bridge_actions.gd:127`).

**Calls:** [[hall_main#release_standing_cost]], [[hall_style#is_dead]], [[hall_main#_leave_quest]], [[character_container#remove_character_from_guild]], [[hall_header#pay_fx]], [[game_state#reduce_standing]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]], [[hall_main#_check_run_over]].

### upgrade_building
`func upgrade_building(building: int) -> void` · `Scripts/Hall/hall_main.gd:1173`

Buy the next level of a building. Blocked while the `"upgrades"` feature is tutorial-locked. No `##` comment.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `building` | `int` | Building id | bound in `pressed` on `_upgrade_button` ([[upgrade_card#setup]], `upgrade_card.gd:49`) and `_buy_button` ([[suggest_row#setup]], `suggest_row.gd:30`); `building` in [[agent_bridge_actions#_upgrade]] (`agent_bridge_actions.gd:192`) |

**Returns:** nothing. **Side effects:** on success of `GuildUpgrades.try_upgrade`: `_count_spent`, gold pay animation, plays `building_upgrade`, `pending_fx.upgraded = building`, toast `TOAST_UPGRADED`, emits `tutorial_event("upgrade", building)`. Always `queue_refresh()`.

**Called by:** `pressed` on `_upgrade_button` (`upgrade_card.gd:49`) and `_buy_button` (`suggest_row.gd:30`), [[agent_bridge_actions#_upgrade]] (`agent_bridge_actions.gd:192`).

**Calls:** [[hall_main#is_locked]], [[guild_upgrades#try_upgrade]], [[hall_main#_count_spent]], [[hall_header#pay_fx]], [[guild_upgrades#get_building_name]], [[guild_upgrades#get_level]], [[sound_effects#play]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### buy_item
`func buy_item(index: int) -> void` · `Scripts/Hall/hall_main.gd:1192`

Buy one of today's goods.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `index` | `int` | Index into `ItemShop.stock` | `_selected` in [[tab_shop#_on_buy_pressed]] (`tab_shop.gd:140`); `index` in [[agent_bridge_actions#_buy]] (`agent_bridge_actions.gd:139`) |

**Returns:** nothing; returns early for a missing or already sold item. **Side effects:** `ItemShop.buy`; on success `_count_spent`, gold pay animation (if cost > 0), `pending_fx.bought = index`, toast `TOAST_BOUGHT`, plays `shop_buy`, emits `tutorial_event("buy", item)`; on failure an error toast `TOAST_CANT_BUY`. Always `queue_refresh()`.

**Called by:** [[tab_shop#_on_buy_pressed]] (`tab_shop.gd:140`), [[agent_bridge_actions#_buy]] (`agent_bridge_actions.gd:139`).

**Calls:** [[item_shop#get_item]], [[item_shop#is_sold]], [[item_shop#buy]], [[hall_main#_count_spent]], [[hall_header#pay_fx]], [[hall_style#item_look]], [[hall_main#show_toast]], [[hall_main#show_error_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### equip_item
`func equip_item(item: StandardItem, character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1211`

Put an owned item on a hero (moves it off whoever had it). Shows a toast per `ItemShop.EquipResult`: `OK` toast `TOAST_EQUIPPED`, sound `equip`, `pending_fx.gear_in`, `tutorial_event("equip", item)`; `WRONG_ROLE`, `SLOTS_FULL` and `DEAD` show error toasts.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item to wear | the picked item in [[screen_character#_on_gear_picked]] (`:315`), [[tab_pack#_on_equip_chosen]] (`:239`); found by id in [[agent_bridge_actions#_equip]] (`:151`) |
| `character` | `GuildCharacter` | Who wears it | `_shown_character()` / the chosen hero / hero found by id; `character` in [[hall_main#swap_gear]] |

**Returns:** nothing. **Side effects:** as above; always `queue_refresh()`.

**Called by:** [[screen_character#_on_gear_picked]] (`screen_character.gd:315`), [[tab_pack#_on_equip_chosen]] (`tab_pack.gd:239`), [[agent_bridge_actions#_equip]] (`agent_bridge_actions.gd:151`), [[hall_main#swap_gear]] (`hall_main.gd:1235`, `:1240`).

**Calls:** [[hall_style#item_look]], [[item_shop#equip]], [[hall_style#item_role_name]], [[hall_main#show_toast]], [[hall_main#show_error_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### unequip_item
`func unequip_item(item: StandardItem) -> void` · `Scripts/Hall/hall_main.gd:1229`

Take an item off whoever wears it (back to the pack). Does nothing if nobody wears it.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The worn item | bound on the Take off button in [[screen_character]] (`screen_character.gd:269`); [[tab_pack#_on_take_off_confirmed]] (`:250`); [[agent_bridge_actions#_unequip]] (`:162`) |

**Returns:** nothing. **Side effects:** `ItemShop.unequip`; `pending_fx.gear_out = true`; toast `TOAST_UNEQUIPPED`; plays `unequip`; `queue_refresh()`.

**Called by:** `pressed` on a worn-row button (`screen_character.gd:269`), [[tab_pack#_on_take_off_confirmed]] (`tab_pack.gd:250`), [[agent_bridge_actions#_unequip]] (`agent_bridge_actions.gd:162`).

**Calls:** [[item_shop#unequip]], [[hall_style#item_look]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### swap_gear
`func swap_gear(item_on: StandardItem, item_off: StandardItem, character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1243`

Swap gear on a hero whose slots are full: `item_off` goes back to the pack, `item_on` goes on. If `item_on` can't go on, `item_off` is put back, so a failed swap leaves the hero as they were (and `equip_item` then shows why). If `item_off` isn't worn by `character`, it is just an `equip_item`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item_on` | `StandardItem` | Item to put on | [[tab_pack#_on_swap_confirmed]] (`tab_pack.gd:255`) |
| `item_off` | `StandardItem` | Item to take off | same |
| `character` | `GuildCharacter` | The hero | same |

**Returns:** nothing. **Side effects:** on success `pending_fx.gear_in`, toast `TOAST_SWAPPED`, plays `equip`, emits `tutorial_event("equip", item_on)`, `queue_refresh()`.

**Called by:** [[tab_pack#_on_swap_confirmed]] (`tab_pack.gd:255`).

**Calls:** [[hall_main#equip_item]], [[item_shop#unequip]], [[item_shop#equip]], [[hall_style#item_look]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### toggle_training_picker
`func toggle_training_picker() -> void` · `Scripts/Hall/hall_main.gd:1263`

"+ Add a hero" under the Training Yard: show or hide who can train.

**Returns:** nothing. **Side effects:** flips `training_picker_open`; `queue_refresh()`; emits `tutorial_event("training_picker", training_picker_open)`.

**Called by:** `pressed` on `_add_button` ([[home_section#setup]], `home_section.gd:59`).

**Calls:** [[hall_main#queue_refresh]].

### train
`func train(character: GuildCharacter, stat: int) -> void` · `Scripts/Hall/hall_main.gd:1271`

Put a hero in a training slot drilling `stat`, or change their stat. Someone in a quest party leaves it first. Refused with an error toast if they are too hurt (`TOAST_TOO_HURT`) or no slot is free for a new trainee (`TOAST_SLOTS_FULL`).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The trainee | bound in [[home_row]] button handlers (`home_row.gd:150`, `:164`, `:166`); hero found by id in [[agent_bridge_actions#_train]] (`:173`) |
| `stat` | `int` | Stat index to drill | `stat_index` / `best_stat` in `home_row.gd`; `int(pair[1])` in the bridge |

**Returns:** nothing. **Side effects:** `_leave_quest`; `GuildUpgrades.set_training`; `pending_fx.home_row = character`; for a new trainee toast `TOAST_TRAINING` and plays `training_start`; closes the picker when slots are full; `queue_refresh()`; emits `tutorial_event("train", character)`.

**Called by:** `pressed` buttons built in [[home_row]] (`home_row.gd:150`, `:164`, `:166`), [[agent_bridge_actions#_train]] (`agent_bridge_actions.gd:173`).

**Calls:** [[guild_upgrades#can_train]], [[guild_upgrades#is_training]], [[guild_upgrades#has_free_training_slot]], [[hall_main#_leave_quest]], [[guild_upgrades#set_training]], [[hall_main#show_toast]], [[hall_main#show_error_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### stop_training
`func stop_training(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1292`

Take a hero out of their training slot. No `##` comment.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The trainee | bound on the Remove button (`home_row.gd:126`); hero by id in the bridge (`agent_bridge_actions.gd:79`) |

**Returns:** nothing. **Side effects:** `GuildUpgrades.stop_training`; toast `TOAST_STOPPED_TRAINING`; `queue_refresh()`.

**Called by:** `pressed` on the side button of [[home_row]] (`home_row.gd:126`), passed as a callable by `agent_bridge_actions.gd:79`.

**Calls:** [[guild_upgrades#stop_training]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### admit
`func admit(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1299`

Put a hurt hero in a Hospital bed (they leave any party; the training slot is freed by `GuildUpgrades.admit`). Does nothing but `queue_refresh()` when gold is below tonight's bed fee (`GuildUpgrades.nightly_fee()`), so a hero is never pulled from a party for a bed the guild can't pay.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The patient | bound on the admit button (`home_row.gd:195`); bridge (`agent_bridge_actions.gd:82`) |

**Returns:** nothing. **Side effects:** `_leave_quest`; if `GuildUpgrades.admit` succeeds: `pending_fx.home_row`, toast `TOAST_ADMITTED`, plays `hospital_admit`, emits `tutorial_event("admit", character)`. Always `queue_refresh()`.

**Called by:** `pressed` on the main button of [[home_row]] (`home_row.gd:195`), `agent_bridge_actions.gd:82`.

**Calls:** [[guild_upgrades#nightly_fee]], [[hall_main#_leave_quest]], [[guild_upgrades#admit]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### discharge
`func discharge(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1313`

Send a patient home from the Hospital. No `##` comment.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The patient | bound on the discharge button (`home_row.gd:184`); bridge (`agent_bridge_actions.gd:85`) |

**Returns:** nothing. **Side effects:** `GuildUpgrades.discharge`; `pending_fx.home_row`; toast `TOAST_DISCHARGED`; plays `hospital_discharge`; `queue_refresh()`.

**Called by:** `pressed` on [[home_row]] main button (`home_row.gd:184`), `agent_bridge_actions.gd:85`.

**Calls:** [[guild_upgrades#discharge]], [[hall_main#show_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### revive
`func revive(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1321`

Pay to bring a fallen hero back. No `##` comment.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The fallen hero | bound on the Revive button (`home_row.gd:205`); bridge (`agent_bridge_actions.gd:88`) |

**Returns:** nothing. **Side effects:** on success of `GuildUpgrades.revive`: `_count_spent`, `pending_fx.home_row`, toast `TOAST_REVIVED`, plays `revive`. If it failed and the roster is full, error toast `TOAST_REVIVE_NO_BED`. Always `queue_refresh()`.

**Called by:** `pressed` on [[home_row]] main button (`home_row.gd:205`), `agent_bridge_actions.gd:88`.

**Calls:** [[guild_upgrades#revive]], [[hall_main#_count_spent]], [[hall_main#is_roster_full]], [[hall_main#show_toast]], [[hall_main#show_error_toast]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### _count_spent
`func _count_spent(gold_before: int) -> void` · `Scripts/Hall/hall_main.gd:1335`

Add whatever gold left the wallet since `gold_before` to `run_stats.gold_spent` (for the credits' records). Never subtracts.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `gold_before` | `int` | Gold before the purchase | `GameState.gold` read just before the purchase in each caller |

**Returns:** nothing.

**Called by:** [[hall_main#hire]] (`:1106`), [[hall_main#upgrade_building]] (`:1169`), [[hall_main#buy_item]] (`:1188`), [[hall_main#revive]] (`:1314`), [[hall_main#end_day]] (`:1542`, the Hospital bill).

### _leave_quest
`func _leave_quest(character: GuildCharacter) -> void` · `Scripts/Hall/hall_main.gd:1340`

Take a hero out of whatever quest party they are in (sent or draft); toast `TOAST_LEFT_QUEST`. Does nothing if they are in none.

**Returns:** nothing.

**Called by:** [[hall_main#release]] (`:1146`), [[hall_main#train]] (`:1269`), [[hall_main#admit]] (`:1294`).

**Calls:** [[hall_main#quest_index_of]], [[hall_main#_remove_from_party]], [[hall_main#show_toast]].

### cycle_color_filter
`func cycle_color_filter() -> void` · `Scripts/Hall/hall_main.gd:1353`

Menu's colorblind button: Off, Red-weak, Green-weak, Blue-yellow, Off (steps to `(color_filter + 1) % COLOR_FILTERS.size()`).

**Called by:** `pressed` on `_color_button` ([[overlay_accessibility#setup]], `overlay_accessibility.gd:34`).

**Calls:** [[hall_main#set_color_filter]], [[hall_settings]] (`COLOR_FILTERS`).

### set_color_filter
`func set_color_filter(filter_index: int) -> void` · `Scripts/Hall/hall_main.gd:1357`

Set the colorblind filter and save it. No `##` comment.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `filter_index` | `int` | Filter id (0 = off) | `(color_filter + 1) % size` in `cycle_color_filter`; `options.get("color_filter", 0)` in [[agent_bridge#_apply_launch_flags]] (`agent_bridge.gd:101`) |

**Returns:** nothing. **Side effects:** clamps into `color_filter`; applies the shader; saves `KEY_COLOR_FILTER`; `queue_refresh()`.

**Called by:** [[hall_main#cycle_color_filter]] (`:1344`), [[agent_bridge#_apply_launch_flags]] (`agent_bridge.gd:101`).

**Calls:** [[hall_settings#clamp_color_filter]], [[hall_main#_apply_color_filter]], [[hall_settings#save_value]], [[hall_main#queue_refresh]].

### toggle_reduce_motion
`func toggle_reduce_motion() -> void` · `Scripts/Hall/hall_main.gd:1365`

Menu's Reduced Motion button: on or off.

**Called by:** `pressed` on `_motion_button` ([[overlay_accessibility#setup]], `overlay_accessibility.gd:35`).

**Calls:** [[hall_main#set_reduce_motion]].

### cycle_text_size
`func cycle_text_size() -> void` · `Scripts/Hall/hall_main.gd:1370`

Accessibility's Text size button: Small, Normal, Large, Small.

**Called by:** `pressed` on `_text_size_button` ([[overlay_accessibility#setup]], `overlay_accessibility.gd:33`).

**Calls:** [[hall_main#set_text_size]].

### set_text_size
`func set_text_size(size_index: int) -> void` · `Scripts/Hall/hall_main.gd:1376`

Every font in the hall is resized right away (`HallFontScale`), then everything redraws so boxes sized from the text follow.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `size_index` | `int` | Index into `HallSettings.TEXT_SIZES` | `(text_size + 1) % size` in `cycle_text_size`; `options.get("text_size", DEFAULT_TEXT_SIZE)` in [[agent_bridge#_apply_launch_flags]] (`agent_bridge.gd:100`) |

**Returns:** nothing. **Side effects:** sets `text_size`; `HallFontScale.set_text_factor(factor, theme, self)`; saves `KEY_TEXT_SIZE`; `queue_refresh()`.

**Called by:** [[hall_main#cycle_text_size]] (`:1361`), [[agent_bridge#_apply_launch_flags]] (`agent_bridge.gd:100`).

**Calls:** [[hall_settings#clamp_text_size]], [[hall_settings#text_size_factor]], [[hall_font_scale#set_text_factor]], [[hall_settings#save_value]], [[hall_main#queue_refresh]].

### set_reduce_motion
`func set_reduce_motion(is_on: bool) -> void` · `Scripts/Hall/hall_main.gd:1384`

Reduced Motion: `hall_fx.gd` skips every animation and lands things in place.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `is_on` | `bool` | New setting | `not reduce_motion` in `toggle_reduce_motion`; launch options in [[agent_bridge#_apply_launch_flags]] (`:102`); `true` in [[agent_bridge_actions#use_rules_motion]] (`:45`) |

**Returns:** nothing. **Side effects:** sets `reduce_motion` and `HallFx.reduce_motion`; saves `KEY_REDUCE_MOTION`; `queue_refresh()`.

**Called by:** [[hall_main#toggle_reduce_motion]] (`:1356`), `agent_bridge.gd:102`, `agent_bridge_actions.gd:45`.

**Calls:** [[hall_settings#save_value]], [[hall_main#queue_refresh]].

### set_save_enabled
`func set_save_enabled(is_on: bool) -> void` · `Scripts/Hall/hall_main.gd:1394`

The "Save runs" checkbox (Menu > Debug tools). On: saves the current run on the refresh this queues (overwriting the old save). Off: leaves the save file on disk untouched.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `is_on` | `bool` | Checkbox state | `toggled` on `_save_check` (`overlay_debug.gd:91`) |

**Returns:** nothing. **Side effects:** sets `is_save_enabled`; saves it in `SECTION_DEV`; `queue_refresh()`.

**Called by:** `toggled` on `_save_check` ([[overlay_debug#setup]], `overlay_debug.gd:91`).

**Calls:** [[hall_settings#save_value]], [[hall_main#queue_refresh]].

### _load_settings
`func _load_settings() -> void` · `Scripts/Hall/hall_main.gd:1400`

Reads `HallSettings.load_settings()` into `color_filter`, `reduce_motion`, `is_save_enabled`, sets `HallFx.reduce_motion` and applies the colour filter. (Text size is applied separately in `_ready`.) No `##` comment.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:470`).

**Calls:** [[hall_settings#load_settings]], [[hall_main#_apply_color_filter]].

### _apply_color_filter
`func _apply_color_filter() -> void` · `Scripts/Hall/hall_main.gd:1410`

Shows the filter rect only when `color_filter > 0` (off costs nothing) and passes it as the shader's `mode` parameter on `_color_filter`.

**Called by:** [[hall_main#set_color_filter]] (`:1349`), [[hall_main#_load_settings]] (`:1396`).

### enable_debug_tools
`func enable_debug_tools() -> void` · `Scripts/Hall/hall_main.gd:1420`

Debug tools' confirm button: the tools show, and from now on this run is never saved (`is_debug_run`). The save on disk keeps the run from before. Does nothing if already on.

**Side effects:** `is_debug_run = true`; toast `TOAST_DEBUG_ON`; `queue_refresh()`.

**Called by:** `pressed` on `_enable_button` ([[overlay_debug#setup]], `overlay_debug.gd:81`).

**Calls:** [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### reset_upgrades
`func reset_upgrades() -> void` · `Scripts/Hall/hall_main.gd:1429`

Debug tools' Reset upgrades button: `GuildUpgrades.reset()` and toast `TOAST_RESET`. (No `queue_refresh()` here; the toast only.)

**Called by:** `pressed` on `_reset_button` ([[overlay_debug#setup]], `overlay_debug.gd:87`).

**Calls:** [[guild_upgrades#reset]], [[hall_main#show_toast]].

### debug_skip_day
`func debug_skip_day() -> void` · `Scripts/Hall/hall_main.gd:1435`

Debug tools' Skip day button. `HallDebug.skip_day(self)` does the skip (and `start_new_day` shows the new day's toast); if it refuses, toast `TOAST_DEBUG_CANT_SKIP` and a refresh.

**Called by:** `pressed` on `_skip_button` ([[overlay_debug#setup]], `overlay_debug.gd:82`).

**Calls:** [[hall_debug#skip_day]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### debug_jump_to_day
`func debug_jump_to_day(day: int) -> void` · `Scripts/Hall/hall_main.gd:1442`

Debug tools' Jump to day buttons. If `HallDebug.jump_to_day` returns 0 (nothing skipped), toast `TOAST_DEBUG_CANT_SKIP` and a refresh.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | Day to land on | bound per button in [[overlay_debug]] (`overlay_debug.gd:104`) |

**Called by:** `pressed` on the jump buttons (`overlay_debug.gd:104`).

**Calls:** [[hall_debug#jump_to_day]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### debug_add_gold
`func debug_add_gold(amount: int) -> void` · `Scripts/Hall/hall_main.gd:1449`

Debug tools' gold buttons: `GuildUpgrades.add_gold(amount)`, toast `TOAST_DEBUG_GOLD`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `amount` | `int` | Gold to add | one of `HallDebug.GOLD_STEPS`, bound in `overlay_debug.gd:107` |

**Called by:** `pressed` on the wallet buttons (`overlay_debug.gd:107`).

**Calls:** [[guild_upgrades#add_gold]], [[hall_main#show_toast]].

### debug_add_standing
`func debug_add_standing(amount: int) -> void` · `Scripts/Hall/hall_main.gd:1455`

Debug tools' standing buttons: `GuildUpgrades.add_standing(amount)`, toast `TOAST_DEBUG_STANDING`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `amount` | `int` | Standing to add | one of `HallDebug.STANDING_STEPS`, bound in `overlay_debug.gd:109` |

**Called by:** `pressed` on the wallet buttons (`overlay_debug.gd:109`).

**Calls:** [[guild_upgrades#add_standing]], [[hall_main#show_toast]].

### debug_add_hero
`func debug_add_hero() -> void` · `Scripts/Hall/hall_main.gd:1461`

Debug tools' Add hero button: a free random hero if there's a bed; otherwise `TOAST_ROSTER_FULL`. Refreshes.

**Called by:** `pressed` on `_hero_button` ([[overlay_debug#setup]], `overlay_debug.gd:83`).

**Calls:** [[hall_debug#add_hero]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### debug_add_item
`func debug_add_item() -> void` · `Scripts/Hall/hall_main.gd:1468`

Debug tools' Add item button: a free random item in the Pack, toast `TOAST_DEBUG_ITEM`, refresh.

**Called by:** `pressed` on `_item_button` ([[overlay_debug#setup]], `overlay_debug.gd:84`).

**Calls:** [[hall_debug#add_random_item]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### debug_heal_everyone
`func debug_heal_everyone() -> void` · `Scripts/Hall/hall_main.gd:1475`

Debug tools' Heal everyone button. `HallDebug.heal_everyone()` returns counts (`healed`, `revived`, `left_dead`); the toast is `TOAST_DEBUG_LEFT_DEAD` if any were left dead, else `TOAST_DEBUG_HEALED`. Refreshes.

**Called by:** `pressed` on `_heal_button` ([[overlay_debug#setup]], `overlay_debug.gd:85`).

**Calls:** [[hall_debug#heal_everyone]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### debug_max_buildings
`func debug_max_buildings() -> void` · `Scripts/Hall/hall_main.gd:1485`

Debug tools' Max buildings button: `HallDebug.max_buildings()`, toast `TOAST_DEBUG_MAXED` (with `GuildUpgrades.MAX_LEVEL`).

**Called by:** `pressed` on `_max_button` ([[overlay_debug#setup]], `overlay_debug.gd:86`).

**Calls:** [[hall_debug#max_buildings]], [[hall_main#show_toast]].

### debug_reroll_today
`func debug_reroll_today() -> void` · `Scripts/Hall/hall_main.gd:1492`

Debug tools' Reroll button: new quests for today (drafted parties are dropped with them) and a new For Hire pool, without moving the day on. Closes any open screen (it would point at a quest that's gone).

**Side effects:** `_generate_quests()`, `HallDebug.reroll_hires()`, `active_screen = {}`, toast `TOAST_DEBUG_REROLLED`, `queue_refresh()`.

**Called by:** `pressed` on `_reroll_button` ([[overlay_debug#setup]], `overlay_debug.gd:88`).

**Calls:** [[hall_main#_generate_quests]], [[hall_debug#reroll_hires]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### debug_skip_tutorial
`func debug_skip_tutorial() -> void` · `Scripts/Hall/hall_main.gd:1502`

Debug tools' Skip tutorial button: `tutorial.skip_tutorial()` if Pip is running, toast `TOAST_DEBUG_TUTORIAL`, refresh.

**Called by:** `pressed` on `_tutorial_button` ([[overlay_debug#setup]], `overlay_debug.gd:89`).

**Calls:** [[overlay_tutorial#is_running]], [[overlay_tutorial#skip_tutorial]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

### debug_replay_intro
`func debug_replay_intro() -> void` · `Scripts/Hall/hall_main.gd:1511`

Debug tools' Replay intro: closes the Debug sheet and the Menu and rolls the intro crawl again on any day (`is_intro_replay = true`). Its Begin button just closes it ([[hall_main#close_intro]]).

**Called by:** `pressed` on `_intro_button` ([[overlay_debug#setup]], `overlay_debug.gd:90`).

**Calls:** [[hall_main#queue_refresh]].

### open_end_check
`func open_end_check() -> void` · `Scripts/Hall/hall_main.gd:1522`

The End Day check: tonight's plan and anything worth buying first. If a quest is still undecided, opens it instead (`open_assign(next_undecided_index(0))`).

**Side effects:** `is_end_check_open = true`; plays `page_open`; `queue_refresh()`; emits `tutorial_event("end_check", null)`.

**Called by:** `pressed` on `_end_day_button` ([[tab_board#setup]], `tab_board.gd:48`).

**Calls:** [[hall_main#undecided_count]], [[hall_main#open_assign]], [[hall_main#next_undecided_index]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### close_end_check
`func close_end_check() -> void` · `Scripts/Hall/hall_main.gd:1532`

Closes the End Day check: `is_end_check_open = false`, plays `page_close`, refresh. No `##` comment.

**Called by:** `pressed` on `_back_button` ([[overlay_end_day#setup]], `overlay_end_day.gd:47`); [[overlay_end_day#_on_dim_input]] (`overlay_end_day.gd:100`).

**Calls:** [[sound_effects#play]], [[hall_main#queue_refresh]].

### end_day
`func end_day() -> void` · `Scripts/Hall/hall_main.gd:1542`

Run every quest that has a party, pay out, show the report. Dusk washes over the screen while the night plays out; the report shows under it. The gold and standing counters hold still until dawn ([[hall_main#start_new_day]]).

**Returns:** nothing. Does nothing while a quest is undecided or `is_night_falling` (a second tap).

**Side effects:** `is_night_falling = true`; plays `night_fall`; `_header.hold_counters()`; `GuildUpgrades.run_night()` (the Hospital bill, training and healing first), then `_count_spent` so the bill counts as gold spent; `_run_quest` for each `sent_entries()`; builds the report `{starts_next_day, day, results, home, released}`. If a result is `final`, hands over to `_show_final_credits` and stops. Otherwise `night_save = {"shown_report": report}`, `save_now()`, then `_go_on_quest` with a callback that runs a dusk `HallFx.curtain` (so the travel screen comes first unless `skip_quest_travel`); the curtain's peak callback clears `is_quest_travel_open` and the night flags and open sheets, and either sets `shown_report` or, after a non-final boss (`milestone`), stores `_pending_report` and `shown_boss_crawl` and plays `victory` / `defeat`; then `queue_refresh()` and emits `tutorial_event("end_day", results)`.

**Called by:** `pressed` on `_end_button` ([[overlay_end_day#setup]], `overlay_end_day.gd:48`); [[agent_bridge_actions#end_day]] (`agent_bridge_actions.gd:243`).

**Calls:** [[hall_main#undecided_count]], [[hall_header#hold_counters]], [[guild_upgrades#run_night]], [[hall_main#_count_spent]], [[hall_main#sent_entries]], [[hall_main#_run_quest]], [[hall_main#_show_final_credits]], [[hall_main#save_now]], [[hall_main#_go_on_quest]], [[hall_fx#curtain]], [[hall_main#queue_refresh]], [[sound_effects#play]].

### _show_final_credits
`func _show_final_credits(result: Dictionary, report: Dictionary) -> void` · `Scripts/Hall/hall_main.gd:1596`

End Day on `FINAL_DAY`: freeze the run's numbers into `shown_credits` and open the credits roll under the dusk wash (a slower, darker one for a defeat).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result` | `Dictionary` | The final quest's `_run_quest` result | `final_results[0]` in [[hall_main#end_day]] (`:1552`) |
| `report` | `Dictionary` | The night's Day Report | built in `end_day`; kept for the Menu's "Last night's report" |

**Returns:** nothing.

**Side effects:** `build_credits(result)`; `final_battle_lost = not credits.won`; `night_save = {shown_credits, previous_report}` and `save_now()`; `_go_on_quest` runs the curtain (travel screen first unless `skip_quest_travel`); the curtain's callback clears `is_quest_travel_open` and the sheets, sets `previous_report` and `shown_credits`, skips a running tutorial, plays `victory` / `defeat`, `queue_refresh()`, emits `tutorial_event("end_day", report.results)`. The win curtain uses `DUSK_*` times, a loss `DEFEAT_DUSK_*`.

**Called by:** [[hall_main#end_day]] (`hall_main.gd:1552`).

**Calls:** [[hall_main#build_credits]], [[hall_main#save_now]], [[hall_main#_go_on_quest]], [[overlay_tutorial#skip_tutorial]], [[hall_fx#curtain]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### _go_on_quest
`func _go_on_quest(then: Callable) -> void` · `Scripts/Hall/hall_main.gd:1628`

Shows the "Going on a quest" screen; its button runs `then` (the night's curtain). With `skip_quest_travel` set, runs `then` straight away.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `then` | `Callable` | The dusk curtain call | a lambda wrapping `HallFx.curtain(... show_report ...)` in [[hall_main#end_day]] (`hall_main.gd:1588`), or the win/defeat curtain in [[hall_main#_show_final_credits]] (`hall_main.gd:1619`) |

**Returns:** nothing.

**Side effects:** stores `_after_quest_travel`, sets `is_quest_travel_open = true`, `queue_refresh()` (which shows [[overlay_quest_travel]]). Nothing saved here: `end_day` / `_show_final_credits` saved the night first.

**Called by:** [[hall_main#end_day]], [[hall_main#_show_final_credits]].

**Calls:** [[hall_main#queue_refresh]].

### close_quest_travel
`func close_quest_travel() -> void` · `Scripts/Hall/hall_main.gd:1639`

The travel screen's "View quest report" button: runs the stored curtain once (a second press finds `_after_quest_travel` cleared and does nothing). The curtain's peak closes the screen.

**Side effects:** clears `_after_quest_travel`, then calls it (the dusk curtain to the Day Report, boss crawl or credits).

**Called by:** [[overlay_quest_travel#_on_continue_pressed]] (`overlay_quest_travel.gd:155`).

**Calls:** the stored curtain callable ([[hall_fx#curtain]]).

### _run_quest
`func _run_quest(entry: Dictionary) -> Dictionary` · `Scripts/Hall/hall_main.gd:1649`

Play out one quest (`HallRules.play_quest` pays its gold and standing) and add it to the run's tallies.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A sent quest entry | each of `sent_entries()` in [[hall_main#end_day]] (`:1544`) |

**Returns:** `Dictionary`, the Day Report result from `HallRules.play_quest` (keys used here: `gold`, `succeeded`, `items`, `reward_items`). `end_day` collects it into `results`.

**Side effects:** `run_stats`: `quests_sent`, `gold_earned`, `quests_won`, and on a lost quest `failed_by_day[GameState.day] += 1` (the dictionary is created first for old saves); `drake_result` (only for the day-10 milestone); for the final entry `final_result` and `final_party`; `items_found`.

**Called by:** [[hall_main#end_day]] (`hall_main.gd:1545`).

**Calls:** [[hall_rules#play_quest]].

### close_boss_crawl
`func close_boss_crawl() -> void` · `Scripts/Hall/hall_main.gd:1672`

The boss crawl's Continue button: closes the crawl and opens the night's Day Report (the stored `_pending_report`). Does nothing if no crawl is showing.

**Side effects:** `shown_boss_crawl = {}`; `shown_report = _pending_report`; `_pending_report = {}`; `night_save = {}`; plays `page_close`; `queue_refresh()`.

**Called by:** `pressed` on `_continue_button` ([[overlay_boss_crawl#setup]], `overlay_boss_crawl.gd:64`); [[agent_bridge_actions#end_day]] (`agent_bridge_actions.gd:251`).

**Calls:** [[sound_effects#play]], [[hall_main#queue_refresh]].

### start_new_day
`func start_new_day() -> void` · `Scripts/Hall/hall_main.gd:1684`

The Day Report's "New Day" button. Keeps tonight's report for the Menu and opens on the Board. A skipped day (no report) keeps last night's.

**Side effects:** moves `shown_report` into `previous_report` (`starts_next_day = false`); clears `released_today`; `active_tab = "board"`, `active_screen = {}`; `GameState.start_new_day()` (which emits `day_started`, see [[hall_main#_on_day_started]]); `Sfx.cancel_scheduled()`; toast and sound by day (`TOAST_MILESTONE_DAY` on day 10, `TOAST_FINAL_DAY` on `FINAL_DAY` outside freeplay, both with `story_day`; else `day_start` and `TOAST_NEW_DAY`); `queue_refresh()`; `_header.land_earnings()`; emits `tutorial_event("new_day", day)`; then `_check_run_over()`.

**Called by:** [[hall_main#close_report]] (through the curtain, `hall_main.gd:1756`), [[hall_main#start_freeplay]] (`hall_main.gd:1740`), [[hall_debug#skip_day]] (`hall_debug.gd:39`, on the `HallMain` it is passed), [[agent_bridge_actions#end_day]] (`agent_bridge_actions.gd:256`).

**Calls:** [[game_state#start_new_day]], [[sound_effects#cancel_scheduled]], [[sound_effects#play]], [[hall_style#count_text]], [[hall_main#show_toast]], [[hall_main#queue_refresh]], [[hall_header#land_earnings]], [[hall_main#_check_run_over]].

### _check_run_over
`func _check_run_over() -> void` · `Scripts/Hall/hall_main.gd:1716`

If the guild is stuck (`is_run_over`), freeze the ledger's numbers and open the Game Over overlay. Pip stops coaching. Skipped when game-over stats already exist, credits are showing (a lost final battle has its own ending), or the run isn't over.

**Side effects:** `run_over_stats = build_run_over_stats()`; closes End Day check, Menu and Welcome; `active_screen = {}`; skips a running tutorial; plays `game_over`; `queue_refresh()`; emits `tutorial_event("game_over", run_over_stats)`.

**Called by:** [[hall_main#release]] (`:1160`), [[hall_main#start_new_day]] (`:1676`).

**Calls:** [[hall_main#is_run_over]], [[hall_main#build_run_over_stats]], [[overlay_tutorial#skip_tutorial]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### start_new_run
`func start_new_run() -> void` · `Scripts/Hall/hall_main.gd:1736`

The Game Over ledger's "Found a New Guild" button (and the Menu's Abandon run): the saved run is deleted, every autoload goes back to a fresh Day 1, then the hall scene is reloaded (resetting this script's state, the Welcome card and Pip).

**Side effects:** if `uses_save_file`: `HallSave.delete_save()` and `uses_save_file = false` (so the resets' queued refresh doesn't save a half-reset run); `reset_autoloads()`; `change_scene_to_file(MAIN_SCENE_PATH)`.

**Called by:** `pressed` on `_new_run_button` ([[overlay_game_over#setup]], `overlay_game_over.gd:50`); [[overlay_menu#_on_abandon_pressed]] (`overlay_menu.gd:93`); [[overlay_credits#_on_action_pressed]] (`overlay_credits.gd:151`).

**Calls:** [[hall_save#delete_save]], [[hall_main#reset_autoloads]].

### reset_autoloads
`func reset_autoloads() -> void` · `Scripts/Hall/hall_main.gd:1748`

Every autoload back to a fresh Day 1: `GameState.reset()`, `GuildUpgrades.reset()`, `ItemContainer.owned_items.clear()`, `ItemShop.restock()`, then `CharacterContainer.reset()` (after the game state, so For Hire is sized for Day 1). Callers must set `uses_save_file = false` first.

**Called by:** [[hall_main#start_new_run]] (`:1706`), [[hall_save_transfer#import_snapshot]] (`hall_save_transfer.gd:98`).

**Calls:** [[game_state#reset]], [[guild_upgrades#reset]], [[item_shop#restock]], [[character_container#reset]].

### import_run
`func import_run(snapshot: Dictionary) -> bool` · `Scripts/Hall/hall_main.gd:1759`

The Backup sheet's import: replace this run with `snapshot`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `snapshot` | `Dictionary` | Parsed run | `result.snapshot` from `HallSaveTransfer.parse_code` in [[overlay_backup#_import_text]] (`overlay_backup.gd:112`) |

**Returns:** `bool`, false if it couldn't be written. `overlay_backup.gd:113` shows `TOAST_IMPORT_FAILED` on false.

**Called by:** [[overlay_backup#_import_text]] (`overlay_backup.gd:112`).

**Calls:** [[hall_save_transfer#import_snapshot]].

### start_freeplay
`func start_freeplay() -> void` · `Scripts/Hall/hall_main.gd:1767`

The victory credits' "Begin Freeplay" button: days continue without end (`GameState.is_freeplay`) and quests keep scaling (the S++ rank). Does nothing unless `shown_credits` is a win. Dawn breaks under the usual dusk wash.

**Side effects:** a `HallFx.curtain` whose peak callback sets `GameState.is_freeplay = true`, clears `shown_credits` and `shown_report`, calls `start_new_day()` and emits `tutorial_event("freeplay", day)`.

**Called by:** [[overlay_credits#_on_action_pressed]] (`overlay_credits.gd:149`).

**Calls:** [[hall_fx#curtain]], [[hall_main#start_new_day]].

### report_letter_opened
`func report_letter_opened() -> void` · `Scripts/Hall/hall_main.gd:1782`

A Day Report letter was tapped open; Pip's Day 1 walkthrough waits for this. Emits `tutorial_event("read_letter", null)`.

**Called by:** signal `opened` on each report entry ([[overlay_report#_show_entries]], `overlay_report.gd:289`; emitter in [[report_entry]]).

### close_report
`func close_report() -> void` · `Scripts/Hall/hall_main.gd:1789`

The report's button. After End Day (`starts_next_day`) it starts the next day under a dusk curtain; otherwise it just closes (clears `shown_report`, cancels scheduled sounds, plays `page_close`, refresh).

**Called by:** `pressed` on `_action_button` ([[overlay_report#setup]], `overlay_report.gd:108`).

**Calls:** [[hall_fx#curtain]], [[hall_main#start_new_day]], [[sound_effects#cancel_scheduled]], [[sound_effects#play]], [[hall_main#queue_refresh]].

### open_previous_report
`func open_previous_report() -> void` · `Scripts/Hall/hall_main.gd:1800`

Menu's "Last night's report": closes the Menu and shows a copy of `previous_report` with `starts_next_day = false`. With none kept it only closes the Menu.

**Called by:** `pressed` on `_report_button` ([[overlay_menu#setup]], `overlay_menu.gd:47`).

**Calls:** [[hall_main#queue_refresh]].

### queue_refresh
`func queue_refresh() -> void` · `Scripts/Hall/hall_main.gd:1813`

Ask for a refresh at the end of this frame (many changes become one refresh): sets `_is_refresh_queued` and `refresh.call_deferred()`.

**Called by:** nearly every action in this script; signals connected in [[hall_main#_ready]] (`hall_main.gd:431` to `:438`); [[hall_main#_on_day_started]]; and from outside: [[playtest_scenario#_ready]] (`playtest_scenario.gd:74`), [[overlay_tutorial#_finish]] (`overlay_tutorial.gd:350`), [[screen_character#_toggle_gear_picker]] (`:310`), [[screen_character#_on_release_pressed]] (`:348`), [[screen_character#_on_release_cancelled]] (`:353`), [[tab_guild#_bring_to_top]] (`tab_guild.gd:204`), [[tab_pack#_pick]] (`:214`), [[tab_pack#_set_filter]] (`:219`), [[tab_pack#_on_hide_worn_toggled]] (`:224`), [[tab_shop#_pick]] (`tab_shop.gd:136`).

**Calls:** [[hall_main#refresh]] (deferred).

### refresh
`func refresh() -> void` · `Scripts/Hall/hall_main.gd:1821`

Redraw the whole shell and whatever tab, screen or overlay is showing. Returns early if the hall isn't in the tree (a refresh queued by `start_new_run`'s resets can land after the scene swap).

**Side effects:** `_header.refresh()`, `_refresh_content()`, `_nav.refresh()`, `_refresh_overlays()`, `DragScroll.fix_tree(self)` (so lists drag-scroll from anywhere), `pending_fx.clear()` (rows have read their hints), then `save_now()` (this is the autosave; an unchanged run isn't rewritten).

**Called by:** [[hall_main#_ready]] (`hall_main.gd:479`) and deferred from [[hall_main#queue_refresh]]. (Other `refresh` calls on tabs, header and overlays are different objects.)

**Calls:** [[hall_header#refresh]], [[hall_main#_refresh_content]], [[hall_nav#refresh]], [[hall_main#_refresh_overlays]], [[drag_scroll#fix_tree]], [[hall_main#save_now]].

### save_now
`func save_now() -> void` · `Scripts/Hall/hall_main.gd:1843`

Write the run to the save file now (`HallSave.save_run` skips it if nothing changed). Does nothing for a playtest scenario (`uses_save_file`), while the dev switch is off (`is_save_enabled`), in a debug run, or outside the tree.

**Called by:** [[hall_main#end_day]] (`:1557`), [[hall_main#_show_final_credits]] (`:1591`), [[hall_main#refresh]] (`:1802`), [[hall_main#_notification]] (`:1818`), [[hall_web_update#update_now]] (`hall_web_update.gd:123`), [[hall_web_update#_on_update_available]] (`hall_web_update.gd:157`).

**Calls:** [[hall_save#save_run]].

### _notification
`func _notification(what: int) -> void` · `Scripts/Hall/hall_main.gd:1850`

Engine callback. On `NOTIFICATION_APPLICATION_FOCUS_OUT`, `NOTIFICATION_APPLICATION_PAUSED` or `NOTIFICATION_WM_CLOSE_REQUEST` (phone home button, hidden browser tab, closing) it saves right away, if the node is ready.

**Called by:** the engine.

**Calls:** [[hall_main#save_now]].

### _refresh_content
`func _refresh_content() -> void` · `Scripts/Hall/hall_main.gd:1858`

Shows exactly one tab or one screen and refreshes it. An Assign Party screen whose quest vanished (new day) closes itself. When the view key (tab and sections, or screen kind and quest index) changes, the new view fades in (`VIEW_FADE_SECONDS`, not on first draw) and scrolls to the top; ordinary refreshes keep the scroll position. No `##` comment.

**Called by:** [[hall_main#refresh]] (`:1793`).

**Calls:** [[hall_fx#fade_in]]; `refresh()` and `scroll_to_top()` on the shown tab or screen.

### nav_button
`func nav_button(tab_id: String) -> Button` · `Scripts/Hall/hall_main.gd:1892`

The nav button for a tab id (one of `TAB_IDS`), for Pip to point at.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tab_id` | `String` | A `TAB_IDS` value | `tab_id` in [[overlay_tutorial#_nav]] (`overlay_tutorial.gd:870`) |

**Returns:** `Button`, used by `_nav` in the tutorial as a spotlight target.

**Called by:** [[overlay_tutorial#_nav]] (`overlay_tutorial.gd:870`).

**Calls:** [[hall_nav#button]].

### end_day_button
`func end_day_button() -> Button` · `Scripts/Hall/hall_main.gd:1897`

The Board tab's End Day button, for Pip to point at.

**Returns:** `Button`, used as the target of the `end_check` step in [[overlay_tutorial#_day_one]] (`overlay_tutorial.gd:1019`).

**Called by:** [[overlay_tutorial#_day_one]] (`overlay_tutorial.gd:1019`).

**Calls:** [[tab_board#end_day_button]].

### _refresh_overlays
`func _refresh_overlays() -> void` · `Scripts/Hall/hall_main.gd:1905`

Sets each overlay's visibility, then refreshes the visible ones. Priority: the credits roll hides every other overlay, then the Game Over ledger; the boss crawl, the "Going on a quest" screen (`is_quest_travel_open`, hidden under the credits) and the Day Report hide the rest. The intro crawl comes before everything (it hides the Welcome card).

**Called by:** [[hall_main#refresh]] (`:1795`).

**Calls:** [[hall_main#is_intro_open]], [[hall_main#_all_overlays]].

### _all_overlays
`func _all_overlays() -> Array` · `Scripts/Hall/hall_main.gd:1932`

Returns the twelve overlay nodes (report, end check, menu, accessibility, backup, debug, welcome, game over, credits, boss crawl, quest travel, intro). No `##` comment.

**Returns:** `Array` of overlay `Control`s; [[hall_main#_ready]] (`:425`) uses it to call `setup`, [[hall_main#_refresh_overlays]] (`:1889`) to refresh the visible ones.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:425`), [[hall_main#_refresh_overlays]] (`hall_main.gd:1889`).

### show_toast
`func show_toast(message: String) -> void` · `Scripts/Hall/hall_main.gd:1939`

Short message just above the nav that fades out.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `message` | `String` | Text, usually a formatted `TOAST_*` constant | local actions; also [[hall_web_update#update_now]] (`:125`, `:132`), `_on_update_available` (`:156`, `:160`), [[overlay_backup]] (`:75`, `:82`, `:108`, `:110`, `:113`), [[overlay_debug#_on_update_checked]] (`:182`, `:188`, `:190`), [[overlay_update_confirm#_on_export_pressed]] (`:80`), [[playtest_scenario#_ready]] (`:73`) |

**Returns:** nothing. **Side effects:** [[hall_toast#show_message]].

**Called by:** the actions in this script, [[hall_web_update]], [[overlay_backup]], [[overlay_debug]], [[overlay_update_confirm]], [[playtest_scenario]] (lines above).

**Calls:** [[hall_toast#show_message]].

### show_error_toast
`func show_error_toast(message: String) -> void` · `Scripts/Hall/hall_main.gd:1945`

A toast for something the player tried that can't be done (locked tab, party full, not enough gold): same toast plus the `ui_error` sound.

**Called by:** the actions in this script, and [[overlay_tutorial#_on_event]] (`overlay_tutorial.gd:382`, the `reject` text of a tutorial step).

**Calls:** [[hall_main#show_toast]], [[sound_effects#play]].

### tap_point
`func tap_point() -> Vector2` · `Scripts/Hall/hall_main.gd:1955`

Where the player last pressed (global mouse position), for things that fly to or from their tap.

**Returns:** `Vector2`, used as the start of a floating text in [[screen_assign#_show_odds_change]] (`screen_assign.gd:305`) and as the flight target in [[hall_header#pay_fx]] (`hall_header.gd:287`).

**Called by:** [[screen_assign#_show_odds_change]] (`screen_assign.gd:305`), [[hall_header#pay_fx]] (`hall_header.gd:287`).

**Calls:** `get_global_mouse_position()` (engine).


## Suspected issues
- `hall_main.gd:1419` `reset_upgrades`, `:1439` `debug_add_gold`, `:1445` `debug_add_standing`, `:1475` `debug_max_buildings` show a toast but never call `queue_refresh()`, unlike the other debug actions (counters and buildings may stay stale until the next refresh; the toast itself triggers none).
- `hall_main.gd:1163`, `:1282`, `:1303`, `:1311`, `:1347`, `:1390`, `:1522`, `:1823`, `:1894`: more functions with no `##` doc comment (also `_after_stamp` `:1073`, `_fly_hired_letter` `:1129`, `_remove_from_party` has one).
- `hall_main.gd:508` `freeplay_scale()` and `hall_main.gd:583` `build_run_records()`: no caller was found in `Scripts/`, `Globals/` or `Scenes/` (the static `HallRules` / `HallLedger` versions are called directly). They look like unused wrappers.
- `hall_main.gd:414`, `:497`, `:615`, `:828`, `:834`, `:890`: functions with no `##` doc comment.
- `hall_main.gd:858` `open_backup` and `:866` `close_backup` play no sound, unlike the other overlay open/close functions (may be intended: the global button sound plays `ui_tap`).
