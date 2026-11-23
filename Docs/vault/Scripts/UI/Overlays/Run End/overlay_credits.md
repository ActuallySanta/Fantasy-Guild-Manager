---
source: Scripts/UI/Overlays/Run End/overlay_credits.gd
class_name: ""
extends: Control
scene: "[[overlay_credits (scene)]]"
systems: ["[[Run End]]", "[[UI Motion and Feedback]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_credits.gd

## Purpose
The final battle's credits roll (`HallMain.FINAL_DAY`), in two moods. **Victory**: a warm hall, the night's events rolling up like film credits, then "Begin Freeplay" ([[hall_main#start_freeplay]]). **Defeat**: a cold, slower roll with an epitaph, then "Found a New Guild" ([[hall_main#start_new_run]]). Top to bottom: title, the story and party ([[crawl_sections]]), a parchment ledger (final stats, run records, roll call), the team credits (`Data/credits.tres`, [[credits_list]]) and a closing line. The roll scrolls itself ([[crawl_roll]]) after a short delay; any touch hands it to the player for good. The button waits until the bottom is first reached. Reduced Motion: no auto-scroll, and the roll starts at its title. Reads `hall.shown_credits` ([[hall_main#build_credits]]). Scene: [[overlay_credits (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `RollCallRowScene` | preload | `Scenes/Rows/Day End/roll_call_row.tscn` ([[roll_call_row (scene)]]). |
| `TEAM_CREDITS` | preload | `Data/credits.tres`, a `CreditsList`. |
| `SCROLL_SPEED`, `DEFEAT_SCROLL_SPEED` | const | Roll speed (pixels per second) on a victory / defeat. |
| `TOP_SPACE_SHARE` | const | Share of the screen's height left blank above the title (0.85), so the roll starts from the bottom. |
| `BOTTOM_SPACE` | const | Blank space under the closing line (px), so it scrolls past the pinned button. |
| `TEAM_NAME_FONT_SIZE`, `TEAM_ROLE_FONT_SIZE`, `HEADING_FONT_SIZE`, `DAYS_FONT_SIZE` | const | Font sizes (design px). |
| `TEXT_*`, `BUTTON_FREEPLAY`, `BUTTON_NEW_RUN` | const | Captions and strings. The `TEXT_DEFEAT_*` lines are marked PLACEHOLDER in the code. |
| `_bg`, `_scroll`, `_top_space`, `_sections`, `_buildings`, `_roll_call`, `_empty_label`, `_team_heading`, `_team`, `_end`, `_end_sub`, `_bottom_space`, `_footer`, `_action_button` | onready | Scene nodes by unique name. |
| `_days_tile`, `_gold_tile`, `_quests_tile`, `_hired_tile`, `_fallen_tile`, `_standing_tile`, `_spent_tile`, `_items_tile`, `_service_tile` | onready | [[stat_tile]] nodes. |
| `hall` | var | The [[hall_main]] node. |
| `_built_credits` | var | The credits currently on screen (frozen once the final battle is over). |
| `_roll` | var | The [[crawl_roll]] that handles auto-scroll, hand-over and the button. |
| `_ink`, `_ink_soft` | var | Text ink on the dark roll, per mood (`CREDITS_INK*` or `DEFEAT_INK*` from `HallStyle`). |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:117`

Stores the hall, connects `pressed` on `%ActionButton` to [[overlay_credits#_on_action_pressed]], styles it gold, and adds a [[crawl_roll]] child set up with the scroll, top space, bottom space and footer.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in `view.setup(self)` ([[hall_main#_ready]], `hall_main.gd:424`) |

**Returns:** nothing.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:424`).

**Calls:** [[hall_style#style_button]], [[crawl_roll#setup]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:126`

Builds the roll from `hall.shown_credits` once (nothing if empty or equal to `_built_credits`): picks the mood's ink and background, builds titles, fight, stats, records, roll call and team, sets the button text (Freeplay on a win, New Guild otherwise) and starts the roll.

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1866`) while visible (visible whenever `shown_credits` is non-empty, `hall_main.gd:1846-1847`).

**Calls:** [[overlay_credits#_show_titles]], [[overlay_credits#_show_fight]], [[overlay_credits#_show_stats]], [[overlay_credits#_show_records]], [[overlay_credits#_show_roll_call]], [[overlay_credits#_show_team]], [[overlay_credits#_start_roll]].

### _on_action_pressed
`func _on_action_pressed() -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:147`

The victory button starts freeplay; the defeat button starts a new run.

**Called by:** `pressed` on `%ActionButton`.

**Calls:** [[hall_main#start_freeplay]], [[hall_main#start_new_run]].

### _start_roll
`func _start_roll() -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:158`

Back to the top with the button hidden, then (motion allowed) waits and rolls via `CrawlRoll.start(speed, TOP_SPACE_SHARE, BOTTOM_SPACE)`. A defeat rolls slower.

**Called by:** [[overlay_credits#refresh]].

**Calls:** [[crawl_roll#start]].

### _show_titles
`func _show_titles(credits: Dictionary) -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:167`

Title, subtitle and closing words in the mood's wording and ink.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `credits` | `Dictionary` | `hall.shown_credits` (keys used: `won`, `day`, `result`, `stats`, `records`) | [[overlay_credits#refresh]] |

**Called by:** [[overlay_credits#refresh]].

**Calls:** [[crawl_sections#show_title]], [[hall_style#set_font_color]].

### _show_fight
`func _show_fight(credits: Dictionary) -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:180`

The final battle's story and party as the one fight of the roll's sections (`credits.result.story`).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `credits` | `Dictionary` | As above | [[overlay_credits#refresh]] |

**Called by:** [[overlay_credits#refresh]].

**Calls:** [[crawl_sections#clear]], [[crawl_sections#add_fight]].

### _show_stats
`func _show_stats(stats: Dictionary) -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:189`

The Days tile and the grid of the run's numbers (the Game Over ledger's, without the Bone Drake).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `stats` | `Dictionary` | `credits.stats` | [[overlay_credits#refresh]] |

**Called by:** [[overlay_credits#refresh]].

**Calls:** [[stat_tile#setup]].

### _show_records
`func _show_records(records: Dictionary) -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:201`

Gold spent, items found, the longest-serving hero (or "no one served"), and one label per building with its level.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `records` | `Dictionary` | `credits.records` (see [[hall_ledger#build_run_records]]) | [[overlay_credits#refresh]] |

**Called by:** [[overlay_credits#refresh]].

**Calls:** [[stat_tile#setup]], [[hall_style#clear_children]], [[overlay_credits#_make_line]].

### _show_roll_call
`func _show_roll_call(heroes: Array, released: Array) -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:217`

One [[roll_call_row (scene)]] per hero (already in roll-call order), or the "No hero ever joined" label.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `heroes` | `Array` | Every hero ever in the guild | `credits.stats.roll_call` |
| `released` | `Array` | Released heroes | `credits.stats.released` |

**Called by:** [[overlay_credits#refresh]].

**Calls:** [[hall_style#clear_children]], [[hall_style#add_row]], [[roll_call_row#setup]].

### _show_team
`func _show_team() -> void` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:227`

The team credits from `credits.tres`: a heading per section, then each person's name with their contribution under it, and a gap before the next section. Hides the "Made By" heading if there are no sections.

**Called by:** [[overlay_credits#refresh]].

**Calls:** [[credits_list#sections]], [[hall_style#clear_children]], [[overlay_credits#_make_line]].

### _make_line
`func _make_line(text: String, ink: Color, font_size: int, look: StringName = &"LabelLight") -> Label` · `Scripts/UI/Overlays/Run End/overlay_credits.gd:247`

A centred, wrapping label in `ink`. A thin wrapper over `CrawlSections.make_line`.

**Returns:** the `Label`; callers add it to `%Buildings` or `%Team`.

**Called by:** [[overlay_credits#_show_records]], [[overlay_credits#_show_team]].

**Calls:** [[crawl_sections#make_line]].

## Suspected issues
- The `TEXT_DEFEAT_*` strings are marked PLACEHOLDER in the code (`overlay_credits.gd:49-55`).
