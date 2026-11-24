---
source: Scripts/Hall/Style/hall_style.gd
class_name: HallStyle
extends: RefCounted
scene: ""
systems: ["[[UI Architecture and Refresh]]", "[[Success Chance]]", "[[UI Motion and Feedback]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_style.gd

## Purpose
The shared look and helpers of the Mobile Hall ("a guild hall at night": dark wood, parchment cards, blackletter titles, meaningful inks). Every other hall script reaches it through its `class_name` and calls its static helpers (`HallStyle.style_button(...)`, `HallStyle.QUEST_STATE_SENT`). It holds the ink palette, display tables (quest types, stats, injury looks, odds bands, building and item tags), the icon table, text helpers, game lookups that turn model objects into display data, and restyles that change with game state (they pick a theme look or tint white art; they never build boxes for the art). Layout lives in `.tscn` files and boxes in `Themes/Styles`. No scene. Sections: quest states, palette, display tables, text helpers, game lookups, icons, style boxes, restyles, scene helpers.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `PORTRAIT_MASK_SHADER` | const | Shader (`portrait_mask.gdshader`) that clips art to a mask, used by [[hall_style#mask_to]]. |
| `PILL_STYLE`, `INK_BOX_STYLE` | const | Outline shapes [[hall_style#fill_art]] copies into a filled box. |
| `QUEST_STATE_OPEN`, `QUEST_STATE_SENT`, `QUEST_STATE_DENIED` | const | The three states of a board quest entry (`"open"`, `"sent"`, `"denied"`): undecided, sent (leaves when the day ends), turned down but reconsiderable. Compared against `entry.state` in the quest rows and [[hall_main]]. |
| `TEXT_MAIN`, `TEXT_SOFT`, `LINE` | const | Ink on paper: main text, secondary text, rules and dashes. |
| `CREAM`, `CREAM_SOFT` | const | Text on the wood background. |
| `CARD_BG`, `NEUTRAL_BG`, `BORDER`, `WHITE`, `SENT_CARD_BG`, `DENIED_CARD_BG`, `EMPTY_SEAT_BG` | const | Paper tints multiplied over parchment art by [[hall_style#style_panel]] (white = no tint) and the default border ink. |
| `RED`/`RED_BG`, `GOLD`/`GOLD_TEXT`/`GOLD_BG`, `GREEN`/`GREEN_TEXT`/`GREEN_BG`, `BLUE_TEXT`/`BLUE_BG` | const | Meaning inks (bad, money, good/sent, odds/to-do): ink, text ink, paper tint. |
| `POINTER_GOLD`, `NAVY` | const | Bright gold for "look here" arrows (same as `OverlayTutorial.RING_COLOR`); navy for names on letters. |
| `STORY_INK`, `STORY_BG` | const | Gilt ink and paper tint for story quests (milestones, final battle). |
| `INTRO_BG`, `CREDITS_BG`/`CREDITS_INK`/`CREDITS_INK_SOFT`, `DEFEAT_BG`/`DEFEAT_INK`/`DEFEAT_INK_SOFT` | const | Dark backdrops and inks for the intro crawl and the end-of-story roll (victory warm, defeat cold). |
| `MILESTONE_TYPE_ID` (5), `FINAL_TYPE_ID` (6) | const | Keys in `QUEST_TYPES` for the Bone Drake quest and the final battle (not `CreatedQuest.QuestType` values). |
| `QUEST_TYPES` | const | Type id -> `{name, writ, color, tag, icon}`: display name, Assign Party scroll title, seal colour, short tag, `ICON_FILES` name. Read via [[hall_style#quest_type_info]]. |
| `STAT_COUNT` (5), `QUEST_STAT_COUNT` (4), `PLUCK_INDEX` (4) | const | Stats per hero, how many quests use (all but Pluck), and Pluck's index (stored on its own field, not in `GuildCharacter.stats`). |
| `STATS` | const | The five stats in `GuildCharacter.StatType` order (Pluck last): `{name, short, color, bg}`. Power is `StatType.STRENGTH`. |
| `INJURY_LOOKS` | const | `GuildCharacter.InjuryLevel` -> `{label, bg, text, icon}`. |
| `ROLE_PORTRAIT_BGS` | const | Portrait ground colour per `GuildCharacter.CharacterRole`. |
| `ODDS_BANDS`, `ODDS_NO_PARTY` | const | Success-chance bands checked top to bottom (min 80/60/40/0; words Strong odds, Fair odds, Risky, Long shot) with text and bar colours; the "No party yet" band for chance -1. |
| `BUILDING_TAGS`, `BUILDING_ICONS` | const | `GuildUpgrades.Building` (0-4) -> short seal tag (OFF, TRN, HSP, ARM, BRK) and icon name. |
| `ITEM_ICONS` | const | Item kind (name after the rarity word, e.g. "Pointy Hat") -> `ICON_FILES` name. A missing kind shows its rarity tag instead. |
| `ITEM_RARITY_LOOKS` | const | `StandardItem.Rarity` name -> `{tag, color}` (COM, UNC, RAR, LEG, MYT, NAM). |
| `STORY_TEXT_PARTS` (`[1, 3, 4]`), `STORY_LINE_MIN_LENGTH` (12) | const | Which `Story Parts.txt` columns feed [[hall_style#story_lines]] (opening, fail, success) and the minimum characters for a line to count. |
| `_bbcode_tags` | static var | Compiled `RegEx` matching `[...]` tags, used by [[hall_style#strip_bbcode]]. |
| `ICON_FILES` | const | Icon name -> uid string of the icon file (path in a comment); `star` still uses a `res://` path. Loaded lazily by [[hall_style#icon_texture]]. |
| `_icon_cache` | static var | uid -> loaded `Texture2D`, so each file loads once. The only mutable state. |
| `BUTTON_KINDS` | const | Button kind -> theme variation (`gold`/`green`/`blue` = `GoldButton`, `wood`/`red` = `WoodButton`, `paper` = `PaperButton`, `seal` = `SealButton`). |
| `BUTTON_BOX_STATES`, `BUTTON_FONT_STATES` | const | Button state names that share one box / font colour. `BUTTON_FONT_STATES` is read by [[home_row#_show_stat_picker]] (`home_row.gd:144`); `BUTTON_BOX_STATES` has no reader. |
| `PAPER_LOOK` | const | `PaperCard`, the look [[hall_style#style_panel]] gives a panel that has none. |
| `LOCKED_MODULATE` | const | Grey tint `Color(0.55, 0.55, 0.55, 0.7)` for locked controls. |
| `CARET_DOWN` (90), `CARET_UP` (-90) | const | Clockwise degrees for [[hall_style#turn_caret]] (more to open / open). |

No signals.

## Functions

### pick_plural
`static func pick_plural(amount: int, singular: String, plural: String) -> String:` · `Scripts/Hall/Style/hall_style.gd:221`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `amount` | `int` | The count | a list size or numeric field |
| `singular` | `String` | Word when amount is 1 | literal |
| `plural` | `String` | Word otherwise | literal |

**Returns:** `String`, `singular` when `amount == 1`, else `plural`. Used by [[hall_style#count_text]], [[hall_style#item_reward_text]], [[home_section#_show_training]], [[hall_header#_refresh_drake_countdown]].

**Side effects:** none

**Called by:** [[home_section#_show_training]] (`home_section.gd:86`), [[hall_header#_refresh_drake_countdown]] (`hall_header.gd:164`), [[hall_style#count_text]] (`hall_style.gd:227`), [[hall_style#item_reward_text]] (`hall_style.gd:454`)

**Calls:** none.

### count_text
`static func count_text(amount: int, singular: String, plural: String) -> String:` · `Scripts/Hall/Style/hall_style.gd:226`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `amount` | `int` | The count | e.g. `quest_entries.size()`, `results.size()`, `earnings.sent_count` |
| `singular` | `String` | Singular word | literal |
| `plural` | `String` | Plural word | literal |

**Returns:** `String` such as "3 quests". Callers drop it into a `%s` text constant.

**Side effects:** none

**Called by:** [[hall_main#start_new_day]] (`hall_main.gd:1670`), [[overlay_end_day#_show_tonights_plan]] (`overlay_end_day.gd:72`), [[overlay_report#refresh]] (`overlay_report.gd:162`), [[overlay_report#_show_totals]] (`overlay_report.gd:223, 223, 230`), [[home_row#_nights_text]] (`home_row.gd:115`), [[screen_character#refresh]] (`screen_character.gd:147`), [[screen_character#_show_task]] (`screen_character.gd:188`), [[popup_gold#_refresh_earnings]] (`popup_gold.gd:117, 123`), [[popup_standing#refresh]] (`popup_standing.gd:85`), [[tab_pack#_show_grid]] (`tab_pack.gd:138`), [[tab_shop#_show_restock_note]] (`tab_shop.gd:105`)

**Calls:** [[hall_style#pick_plural]]

### join_names
`static func join_names(characters: Array, separator := " & ") -> String:` · `Scripts/Hall/Style/hall_style.gd:231`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `characters` | `Array` | Heroes (anything with `.name`) | `entry.party`, `injured`, `died`, `others` |
| `separator` | `String` | Joiner (default `" & "`) | `", "` in report_entry.gd:168, 170 and overlay_equip_picker.gd:90; default elsewhere |

**Returns:** `String` of each `.name` joined by `separator`.

**Side effects:** none

**Called by:** [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:90`), [[plan_row#setup]] (`plan_row.gd:23`), [[report_entry#setup]] (`report_entry.gd:157, 168, 170`)

**Calls:** none.

### clean_backstory
`static func clean_backstory(character: GuildCharacter) -> String:` · `Scripts/Hall/Style/hall_style.gd:239`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |

**Returns:** `String`, the backstory with blank lines and stray spaces removed. Shown by [[hire_card#setup]] and [[screen_character#refresh]].

**Side effects:** none

**Called by:** [[hire_card#setup]] (`hire_card.gd:49`), [[screen_character#refresh]] (`screen_character.gd:154`)

**Calls:** none.

### odds_look
`static func odds_look(chance: int) -> Dictionary:` · `Scripts/Hall/Style/hall_style.gd:250`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `chance` | `int` | Success chance 0-100, or -1 for no party | `chance` computed by [[hall_main]] / the calling row; -1 when the party is empty |

**Returns:** `Dictionary` `{min, word, text_color, bar_color}`, the first `ODDS_BANDS` entry whose `min` the chance reaches, or `ODDS_NO_PARTY` when `chance < 0`. Callers read `.text_color` ([[plan_row#setup]], [[pick_row#_show_pick_state]], [[quest_row#_show_party]], [[screen_assign#_show_party]]) or `.bar_color` ([[odds_bar#set_chance]]).

**Side effects:** none

**Called by:** [[odds_bar#set_chance]] (`odds_bar.gd:19`), [[plan_row#setup]] (`plan_row.gd:27`), [[pick_row#_show_pick_state]] (`pick_row.gd:124`), [[quest_row#_show_party]] (`quest_row.gd:126`), [[screen_assign#_show_party]] (`screen_assign.gd:257`)

**Calls:** none.

> [!note] How it works
> Bands in `ODDS_BANDS`: 80+ Strong odds, 60+ Fair odds, 40+ Risky, 0+ Long shot; -1 = No party yet.

### roman_numeral
`static func roman_numeral(number: int) -> String:` · `Scripts/Hall/Style/hall_style.gd:260`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `number` | `int` | Positive integer | n/a, no caller |

**Returns:** `String`, e.g. "XIV" (empty for 0 or negative).

**Side effects:** none

**Called by:** no caller found in `Globals/`, `Scripts/` or `Scenes/`.

**Calls:** none.

### quest_type_id
`static func quest_type_id(entry: Dictionary) -> int:` · `Scripts/Hall/Style/hall_style.gd:276`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A quest entry or a quest result | the board entry (`entry`) or the day's result dict (`result`) the caller's `setup` was given |

**Returns:** `int` key into `QUEST_TYPES`: `FINAL_TYPE_ID` if `entry.final`, `MILESTONE_TYPE_ID` if `entry.milestone`, else `int(entry.quest.type)`. Used by [[hall_style#quest_type_info]].

**Side effects:** none

**Called by:** [[hall_style#quest_type_info]] (`hall_style.gd:334`)

**Calls:** none.

### is_story_quest
`static func is_story_quest(entry: Dictionary) -> bool:` · `Scripts/Hall/Style/hall_style.gd:286`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A quest entry or a quest result | the board entry (`entry`) or the day's result dict (`result`) the caller's `setup` was given |

**Returns:** `bool`, true when the entry has `milestone`, `final` or `story_quest` set. Callers promote story quests ([[tab_board#_board_order]], [[quest_row#setup]], [[report_entry#setup]]) or filter ([[overlay_report#_show_entries]] uses it as a `Callable` in `results.filter`).

**Side effects:** none

**Called by:** [[overlay_report#_show_entries]] (`overlay_report.gd:284`), [[overlay_tutorial#_has_foldable_letter]] (`overlay_tutorial.gd:912`), [[report_entry#setup]] (`report_entry.gd:152`), [[quest_row#setup]] (`quest_row.gd:71`), [[tab_board#_board_order]] (`tab_board.gd:132`)

**Calls:** none.

### strip_bbcode
`static func strip_bbcode(text: String) -> String:` · `Scripts/Hall/Style/hall_style.gd:303`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | BBCode text | `row[part]` text in [[hall_style#story_lines]]; story text in [[report_entry#_build_story_beats]] |

**Returns:** `String` with `[...]` tags removed.

**Side effects:** none

**Called by:** [[report_entry#_build_story_beats]] (`report_entry.gd:329`), [[hall_style#story_lines]] (`hall_style.gd:324`)

**Calls:** none.

### story_lines
`static func story_lines(entry: Dictionary) -> PackedStringArray:` · `Scripts/Hall/Style/hall_style.gd:312`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A quest entry or a quest result | the board entry (`entry`) or the day's result dict (`result`) the caller's `setup` was given |

**Returns:** `PackedStringArray` of plain-text lines (at least `STORY_LINE_MIN_LENGTH` chars) from the quest's opening and endings; empty when `questNum` is out of range. [[report_entry#setup]] uses it to star matching lines in the played-out story.

**Side effects:** none (reads `ExternalContentContainer`).

**Called by:** [[report_entry#setup]] (`report_entry.gd:187`)

**Calls:** [[hall_style#strip_bbcode]], `CreatedQuest`, `ExternalContentContainer.milestone_story` / `quest_story`

### quest_type_info
`static func quest_type_info(entry: Dictionary) -> Dictionary:` · `Scripts/Hall/Style/hall_style.gd:333`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A quest entry or a quest result | the board entry (`entry`) or the day's result dict (`result`) the caller's `setup` was given |

**Returns:** `Dictionary` `{name, writ, color, tag, icon}` from `QUEST_TYPES`, falling back to type 1 (Clear Dungeon). Callers read `.tag`, `.icon`, `.color`, `.writ`.

**Side effects:** none

**Called by:** [[plan_row#setup]] (`plan_row.gd:20`), [[report_entry#setup]] (`report_entry.gd:154`), [[quest_row#_show_quest_facts]] (`quest_row.gd:86`), [[quest_tab#setup]] (`quest_tab.gd:31`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:217`)

**Calls:** [[hall_style#quest_type_id]]

### favored_components
`static func favored_components(quest: CreatedQuest) -> Array[int]:` · `Scripts/Hall/Style/hall_style.gd:339`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` of a quest entry built by [[hall_main]] |

**Returns:** `Array[int]` of `STATS` indexes (Pluck included), in digit order, each clamped to 0-4.

**Side effects:** none

**Called by:** [[party_slot#setup]] (`party_slot.gd:42`), [[quest_row#_show_quest_facts]] (`quest_row.gd:96`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:230`), [[hall_style#favored_stat_indexes]] (`hall_style.gd:350`), [[hall_style#favored_label]] (`hall_style.gd:360`)

**Calls:** `CreatedQuest.favored_components`

### favored_stat_indexes
`static func favored_stat_indexes(quest: CreatedQuest) -> Array[int]:` · `Scripts/Hall/Style/hall_style.gd:348`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` of a quest entry built by [[hall_main]] |

**Returns:** `Array[int]`, the favored indexes without Pluck (empty for a Pluck-only quest). [[pick_row#setup]] passes it to `_stats.show_stats`.

**Side effects:** none

**Called by:** [[pick_row#setup]] (`pick_row.gd:65`)

**Calls:** [[hall_style#favored_components]]

### favored_label
`static func favored_label(quest: CreatedQuest) -> String:` · `Scripts/Hall/Style/hall_style.gd:358`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` of a quest entry built by [[hall_main]] |

**Returns:** `String` such as "Power + Defense". Shown in the favored chip by [[quest_row#_show_quest_facts]] and [[screen_assign#_show_quest_card]].

**Side effects:** none

**Called by:** [[quest_row#_show_quest_facts]] (`quest_row.gd:99`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:231`)

**Calls:** [[hall_style#favored_components]]

### rank_letter
`static func rank_letter(quest: CreatedQuest) -> String:` · `Scripts/Hall/Style/hall_style.gd:366`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` of a quest entry built by [[hall_main]] |

**Returns:** `String`, "F".. "S" (name of `QuestDifficulty`) or "S++" for `SPP`.

**Side effects:** none

**Called by:** [[quest_row#_show_quest_facts]] (`quest_row.gd:89`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:221`)

**Calls:** none.

### role_name
`static func role_name(character: GuildCharacter) -> String:` · `Scripts/Hall/Style/hall_style.gd:375`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |

**Returns:** `String`, the role capitalised ("Fighter", ...).

**Side effects:** none

**Called by:** [[crawl_sections#_make_party]] (`crawl_sections.gd:156`), [[overlay_tutorial#_fits_bought]] (`overlay_tutorial.gd:975`), [[home_row#_fill]] (`home_row.gd:66`), [[roll_call_row#setup]] (`roll_call_row.gd:24`), [[hire_card#setup]] (`hire_card.gd:41`), [[member_card#setup]] (`member_card.gd:57`), [[equip_pick_row#setup]] (`equip_pick_row.gd:27`), [[party_slot#setup]] (`party_slot.gd:40`), [[pick_row#setup]] (`pick_row.gd:63`), [[screen_character#refresh]] (`screen_character.gd:144`), [[screen_character#_show_gear]] (`screen_character.gd:263`), [[tab_guild#_show_for_hire]] (`tab_guild.gd:198`)

**Calls:** none.

### stat_value
`static func stat_value(character: GuildCharacter, stat_index: int) -> int:` · `Scripts/Hall/Style/hall_style.gd:381`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |
| `stat_index` | `int` | Index into `STATS` (0-3, or `PLUCK_INDEX` 4) | loop index or `stat` chosen by the calling chip/row |

**Returns:** `int`, `character.pluck` for Pluck else `int(character.stats[stat_index])`. No gear or temp bonus.

**Side effects:** none

**Called by:** [[home_row#show_training_slot]] (`home_row.gd:123`), [[home_row#show_can_train]] (`home_row.gd:158`), [[hire_card#setup]] (`hire_card.gd:45`), [[hall_style#stat_bonus]] (`hall_style.gd:399`), [[hall_style#quest_stat_total]] (`hall_style.gd:406`)

**Calls:** none.

### quest_stat_value
`static func quest_stat_value(character: GuildCharacter, stat_index: int) -> int:` · `Scripts/Hall/Style/hall_style.gd:386`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |
| `stat_index` | `int` | Index into `STATS` (0-3, or `PLUCK_INDEX` 4) | loop index or `stat` chosen by the calling chip/row |

**Returns:** `int`, Pluck, or the stat after `reset_temp_stats()` as `get_quest_stat` (base + gear + pluck bonus).

**Side effects:** calls `character.reset_temp_stats()`, which rebuilds the hero's `temp_stats`.

**Called by:** [[hall_gear#preview]] (`hall_gear.gd:67`), [[chip#set_stat]] (`chip.gd:67`), [[stat_strip#_top_stats]] (`stat_strip.gd:56`), [[screen_character#_show_stats]] (`screen_character.gd:231`), [[hall_style#stat_bonus]] (`hall_style.gd:399`)

**Calls:** `GuildCharacter.reset_temp_stats`, `GuildCharacter.get_quest_stat`

### stat_bonus
`static func stat_bonus(character: GuildCharacter, stat_index: int) -> int:` · `Scripts/Hall/Style/hall_style.gd:395`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |
| `stat_index` | `int` | Index into `STATS` (0-3, or `PLUCK_INDEX` 4) | loop index or `stat` chosen by the calling chip/row |

**Returns:** `int`, Armory bonus plus gear and pluck bonus (`quest_stat_value - stat_value`); 0 for Pluck.

**Side effects:** none

**Called by:** [[chip#set_stat]] (`chip.gd:70`), [[screen_character#_show_stats]] (`screen_character.gd:231`)

**Calls:** [[hall_style#quest_stat_value]], [[hall_style#stat_value]], [[guild_upgrades#get_stat_bonus]]

### quest_stat_total
`static func quest_stat_total(character: GuildCharacter) -> int:` · `Scripts/Hall/Style/hall_style.gd:403`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |

**Returns:** `int`, sum of `stat_value` for the four quest stats. Used by [[hire_card#setup]] and [[run_logger#_avg_hire_total]].

**Side effects:** none

**Called by:** [[run_logger#_avg_hire_total]] (`run_logger.gd:257`), [[hire_card#setup]] (`hire_card.gd:46`)

**Calls:** [[hall_style#stat_value]]

### injury_look
`static func injury_look(character: GuildCharacter) -> Dictionary:` · `Scripts/Hall/Style/hall_style.gd:411`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |

**Returns:** `Dictionary` `{label, bg, text, icon}` from `INJURY_LOOKS`, index clamped. Used by [[chip#set_health]], [[roll_call_row#setup]].

**Side effects:** none

**Called by:** [[chip#set_health]] (`chip.gd:58`), [[roll_call_row#setup]] (`roll_call_row.gd:40`)

**Calls:** none.

### is_dead
`static func is_dead(character: GuildCharacter) -> bool:` · `Scripts/Hall/Style/hall_style.gd:415`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | a hero from the roster or For Hire pool (`entry.party`, `seated`, `recruit`, `character` in the calling row) |

**Returns:** `bool`, `injury_level >= InjuryLevel.DEAD`. Used as a filter or guard by many callers (see Called by).

**Side effects:** none

**Called by:** [[hall_main#release_standing_cost]] (`hall_main.gd:530`), [[hall_main#can_go_on_quests]] (`hall_main.gd:629`), [[hall_main#toggle_in_party]] (`hall_main.gd:950`), [[hall_main#release]] (`hall_main.gd:1145`), [[run_logger#_log]] (`run_logger.gd:176`), [[hall_gear#heroes_for]] (`hall_gear.gd:17`), [[hall_gear#heroes_wrong_role]] (`hall_gear.gd:30`), [[hall_ledger#last_living_hero]] (`hall_ledger.gd:45`), [[hall_ledger#build_run_over_stats]] (`hall_ledger.gd:122, 86`), [[hall_ledger#build_run_records]] (`hall_ledger.gd:163, 128`), [[hall_rules#play_quest]] (`hall_rules.gd:418`), [[agent_bridge_actions#plan]] (`agent_bridge_actions.gd:89`), [[crawl_sections#_make_party]] (`crawl_sections.gd:144`), [[portrait#show_character]] (`portrait.gd:51`), [[stat_strip#show_health]] (`stat_strip.gd:46`), [[overlay_tutorial#_someone_fits_bought]] (`overlay_tutorial.gd:979`), [[home_section#_show_training]] (`home_section.gd:98`), [[home_section#_show_hospital]] (`home_section.gd:129`), [[roll_call_row#setup]] (`roll_call_row.gd:28`), [[member_card#_show_status]] (`member_card.gd:72`), [[member_card#_show_task]] (`member_card.gd:94`), [[pick_row#_show_pick_state]] (`pick_row.gd:110`), [[screen_assign#_show_picker]] (`screen_assign.gd:352`), [[screen_character#_show_task]] (`screen_character.gd:179`), [[screen_character#_show_gear]] (`screen_character.gd:262`), [[tab_guild#_show_roster]] (`tab_guild.gd:147, 148`)

**Calls:** none.

### item_look
`static func item_look(item: StandardItem) -> Dictionary:` · `Scripts/Hall/Style/hall_style.gd:425`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item | an owned or shop item the caller was handed |

**Returns:** `Dictionary` `{name, short, tag, color, icon, effect}`; `icon` is "" when the kind has no `ITEM_ICONS` entry. Unknown rarity falls back to COMMON.

**Side effects:** none

**Called by:** [[hall_main#buy_item]] (`hall_main.gd:1192`), [[hall_main#equip_item]] (`hall_main.gd:1202`), [[hall_main#unequip_item]] (`hall_main.gd:1225`), [[hall_main#swap_gear]] (`hall_main.gd:1243`), [[overlay_tutorial#_bought_name]] (`overlay_tutorial.gd:971`), [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:70`), [[overlay_gear_confirm#_show_take_off]] (`overlay_gear_confirm.gd:104`), [[overlay_gear_confirm#_show_swap]] (`overlay_gear_confirm.gd:128, 139, 141`), [[pack_tile#setup]] (`pack_tile.gd:36`), [[screen_character#_show_gear]] (`screen_character.gd:269, 293`), [[tab_pack#_show_item_bar]] (`tab_pack.gd:186`), [[tab_shop#_show_goods]] (`tab_shop.gd:82`), [[tab_shop#_show_buy_bar]] (`tab_shop.gd:116`)

**Calls:** [[hall_style#item_effect]]

> [!note] How it works
> `short` is the name after the first space ("Rare Sword" gives "Sword"), used as the `ITEM_ICONS` key.

### item_reward_text
`static func item_reward_text(quest: CreatedQuest, compact: bool = false) -> String:` · `Scripts/Hall/Style/hall_style.gd:447`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` of a quest entry built by [[hall_main]] |
| `compact` | `bool` | True = "3 items · best LEG" form for Board rows | `true` in [[quest_row#_show_quest_facts]] (quest_row.gd:92) |

**Returns:** `String`, e.g. "3 items · LEG, UNC, COM", or compact "3 items · best LEG", or "0 items".

**Side effects:** none

**Called by:** [[quest_row#_show_quest_facts]] (`quest_row.gd:92`)

**Calls:** [[hall_style#pick_plural]]

### item_effect
`static func item_effect(item: StandardItem) -> String:` · `Scripts/Hall/Style/hall_style.gd:463`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item | an owned or shop item the caller was handed |

**Returns:** `String` such as "+16 Power · Knights only" (just "Knights only" for non-passive items).

**Side effects:** none

**Called by:** [[hall_style#item_look]] (`hall_style.gd:437`)

**Calls:** [[hall_style#item_role_name]]

### item_role_name
`static func item_role_name(item: StandardItem) -> String:` · `Scripts/Hall/Style/hall_style.gd:472`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item | an owned or shop item the caller was handed |

**Returns:** `String`, the role that can use the item, e.g. "Knight".

**Side effects:** none

**Called by:** [[hall_main#equip_item]] (`hall_main.gd:1210`), [[overlay_tutorial#_bought_role]] (`overlay_tutorial.gd:967`), [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:86`), [[hall_style#item_effect]] (`hall_style.gd:464`)

**Calls:** none.

### buildings_in_order
`static func buildings_in_order() -> Array:` · `Scripts/Hall/Style/hall_style.gd:479`

**Returns:** `Array` of `GuildUpgrades.Building` values, implemented buildings first. Used by [[tab_upgrades#_show_building_cards]], [[tab_upgrades#_show_coming_soon]], [[hall_main#affordable_buildings]], [[hall_ledger#build_run_records]], [[agent_bridge_state#build]].

**Side effects:** none

**Called by:** [[hall_main#affordable_buildings]] (`hall_main.gd:725`), [[hall_ledger#build_run_records]] (`hall_ledger.gd:155`), [[agent_bridge_state#build]] (`agent_bridge_state.gd:39`), [[tab_upgrades#_show_building_cards]] (`tab_upgrades.gd:109`), [[tab_upgrades#_show_coming_soon]] (`tab_upgrades.gd:120`)

**Calls:** [[guild_upgrades#is_implemented]]

### icon_texture
`static func icon_texture(icon_name: String) -> Texture2D:` · `Scripts/Hall/Style/hall_style.gd:546`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `icon_name` | `String` | Key of `ICON_FILES` | literal ("skull", "check"), `ICON_FILES` keys from `type_info.icon`, `BUILDING_ICONS`, or a row's `icon_name` |

**Returns:** `Texture2D`, or null when the name isn't in `ICON_FILES` (callers hide the icon).

**Side effects:** first load of a uid stores it in `_icon_cache`.

**Called by:** [[chip#_set_ink]] (`chip.gd:48`), [[crawl_sections#_make_party]] (`crawl_sections.gd:150`), [[home_row#_show_stat_picker]] (`home_row.gd:143`), [[upgrade_card#_show_name_and_level]] (`upgrade_card.gd:71, 78`), [[beat_row#setup]] (`beat_row.gd:14`), [[roll_call_row#setup]] (`roll_call_row.gd:42`), [[screen_assign#_show_footer]] (`screen_assign.gd:432`), [[hall_style#style_icon_tag]] (`hall_style.gd:634`)

**Calls:** `load(uid)`

### flat_box
`static func flat_box(fill: Color, corner_radius: int = 12, border_width: int = 0, border_color: Color = TEXT_MAIN, padding: Vector4 = Vector4(12, 6, 12, 6)) -> StyleBoxFlat:` · `Scripts/Hall/Style/hall_style.gd:559`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `fill` | `Color` | Background | `HallStyle.NEUTRAL_BG`, `RED_BG`, `GREEN_BG` |
| `corner_radius` | `int` | Px (default 12) | 6 or 8 |
| `border_width` | `int` | Px (default 0) | 2 or 0 |
| `border_color` | `Color` | Border (default `TEXT_MAIN`) | `HallStyle.BORDER` |
| `padding` | `Vector4` | Content margins left, top, right, bottom (default (12, 6, 12, 6)) | e.g. `Vector4(16, 10, 16, 10)` (popup_gold.gd:74) |

**Returns:** `StyleBoxFlat`. Callers add it as a `panel` / `background` / `fill` stylebox override.

**Side effects:** none.

**Called by:** [[popup_gold#_ready]] (`popup_gold.gd:74, 75`), [[popup_gold#_set_price]] (`popup_gold.gd:132`), [[popup_standing#_ready]] (`popup_standing.gd:62`), [[popup_standing#_style_bar]] (`popup_standing.gd:107, 108`)

**Calls:** none.

### style_button
`static func style_button(button: Button, kind: String = "gold", font_size: int = 0) -> void:` · `Scripts/Hall/Style/hall_style.gd:596`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `button` | `Button` | Button to restyle | the node the caller's `setup` is wiring |
| `kind` | `String` | Key of `BUTTON_KINDS` (default "gold"; unknown = PaperButton) | literals "gold", "paper", "wood", "seal", "green", "red", "blue" |
| `font_size` | `int` | Design px; 0 keeps the theme's | usually omitted |

**Returns:** nothing

**Side effects:** sets `theme_type_variation`; optionally a scaled font size.

**Called by:** [[overlay_boss_crawl#setup]] (`overlay_boss_crawl.gd:65`), [[overlay_end_day#setup]] (`overlay_end_day.gd:52, 53`), [[overlay_intro#setup]] (`overlay_intro.gd:76`), [[overlay_move_confirm#setup]] (`overlay_move_confirm.gd:50, 51`), [[overlay_tutorial#_build]] (`overlay_tutorial.gd:777, 783`), [[overlay_welcome#setup]] (`overlay_welcome.gd:121, 125`), [[overlay_welcome#_add_topic_button]] (`overlay_welcome.gd:187`), [[overlay_gear_confirm#_show_take_off]] (`overlay_gear_confirm.gd:114`), [[overlay_gear_confirm#_show_swap]] (`overlay_gear_confirm.gd:144`), [[overlay_accessibility#setup]] (`overlay_accessibility.gd:41, 42`), [[overlay_backup#setup]] (`overlay_backup.gd:61, 62`), [[overlay_debug#setup]] (`overlay_debug.gd:125, 126, 127`), [[overlay_debug#_make_button]] (`overlay_debug.gd:162`), [[overlay_menu#setup]] (`overlay_menu.gd:73, 74, 75`), [[overlay_update_confirm#setup]] (`overlay_update_confirm.gd:55, 56, 57`), [[overlay_credits#setup]] (`overlay_credits.gd:120`), [[overlay_game_over#setup]] (`overlay_game_over.gd:51`), [[home_row#_set_button]] (`home_row.gd:108`), [[home_row#_show_stat_picker]] (`home_row.gd:141`), [[home_section#_show_training]] (`home_section.gd:114, 118`), [[suggest_row#setup]] (`suggest_row.gd:29`), [[equip_pick_row#setup]] (`equip_pick_row.gd:35`), [[gear_row#_set_button]] (`gear_row.gd:57`), [[screen_character#setup]] (`screen_character.gd:127, 128, 129, 130, 131`), [[tab_pack#_show_filters]] (`tab_pack.gd:131`), [[tab_pack#_show_item_bar]] (`tab_pack.gd:195, 202`), [[tab_shop#_show_buy_bar]] (`tab_shop.gd:125`)

**Calls:** [[hall_font_scale#set_size]]

### set_locked
`static func set_locked(control: Control, is_locked: bool, label: String = "") -> void:` · `Scripts/Hall/Style/hall_style.gd:612`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `control` | `Control` | Control to restyle | the node the caller is building |
| `is_locked` | `bool` | True = blank, grey, inert | `hall.is_locked(feature)` / `hall.is_tab_locked(tab)` |
| `label` | `String` | Button text restored when unlocked | the button's normal label constant |

**Returns:** nothing

**Side effects:** sets `text`/`disabled` on a Button, and `modulate` on any Control.

**Called by:** [[pick_row#setup]] (`pick_row.gd:60`), [[screen_assign#_show_picker]] (`screen_assign.gd:384`), [[screen_assign#_show_footer]] (`screen_assign.gd:421, 424, 431, 435`), [[hall_nav#refresh]] (`hall_nav.gd:76`), [[tab_guild#_show_section_buttons]] (`tab_guild.gd:113, 115`)

**Calls:** none.

> [!note] How it works
> Used for features Pip (the tutorial) hasn't taught yet; size and layout never change.

### style_tag
`static func style_tag(tag_panel: Control, tag_label: Label, text: String, fill: Color) -> void:` · `Scripts/Hall/Style/hall_style.gd:620`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tag_panel` | `Control` | The seal panel | caller's `_tag_box` |
| `tag_label` | `Label` | Text on the seal | caller's `_tag` |
| `text` | `String` | Tag text | `type_info.tag`, `BUILDING_TAGS` |
| `fill` | `Color` | Seal ink | `type_info.color` |

**Returns:** nothing

**Side effects:** sets `theme_type_variation` (`TypeSeal`, `SealLabel`), `self_modulate`, label text.

**Called by:** [[hall_style#style_icon_tag]] (`hall_style.gd:633`)

**Calls:** [[hall_style#tint_art]]

### style_icon_tag
`static func style_icon_tag(tag_panel: Control, tag_label: Label, tag_icon: TextureRect, text: String, icon_name: String, fill: Color) -> void:` · `Scripts/Hall/Style/hall_style.gd:631`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tag_panel` | `Control` | The seal panel | caller's `_tag_box` / `_type_seal` / `_drake_seal` |
| `tag_label` | `Label` | Text label (hidden when an icon shows) | caller's `_tag` |
| `tag_icon` | `TextureRect` | Icon inside the seal | caller's `_tag_icon` |
| `text` | `String` | Fallback tag text | `type_info.tag`, `look.tag`, `BUILDING_TAGS.get(building)` |
| `icon_name` | `String` | `ICON_FILES` key or "" | `type_info.get("icon", "")`, `look.icon` |
| `fill` | `Color` | Seal ink | `type_info.color`, `look.color` |

**Returns:** nothing

**Side effects:** sets the icon texture, `modulate = CREAM`, and which of icon/label is visible.

**Called by:** [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:71`), [[home_section#setup]] (`home_section.gd:56`), [[plan_row#setup]] (`plan_row.gd:21`), [[report_entry#setup]] (`report_entry.gd:155`), [[suggest_row#setup]] (`suggest_row.gd:23`), [[gear_row#setup]] (`gear_row.gd:29`), [[gear_row#setup_empty]] (`gear_row.gd:43`), [[pack_tile#setup]] (`pack_tile.gd:37`), [[shop_tile#setup]] (`shop_tile.gd:47, 51`), [[quest_row#_show_quest_facts]] (`quest_row.gd:87`), [[hall_header#_refresh_drake_countdown]] (`hall_header.gd:159`)

**Calls:** [[hall_style#style_tag]], [[hall_style#icon_texture]]

### style_panel
`static func style_panel(panel: Control, fill: Color, _border_color: Color = BORDER, _border_width: int = 3, _corner_radius: int = 14, _padding: Vector4 = Vector4.ZERO) -> void:` · `Scripts/Hall/Style/hall_style.gd:644`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `panel` | `Control` | Control to restyle | the node the caller is building |
| `fill` | `Color` | Paper tint (`CARD_BG`/`WHITE` = none) | palette constants such as `SENT_CARD_BG`, `DENIED_CARD_BG`, `STORY_BG`, `RED_BG` |
| `_border_color` | `Color` | Unused, kept for older callers | `HallStyle.BORDER` in home_row.gd:74 |
| `_border_width` | `int` | Unused | 2 or 3 in home_row.gd:74, 127 |
| `_corner_radius` | `int` | Unused | 16 in home_row.gd:74, 127 |
| `_padding` | `Vector4` | Unused | not passed |

**Returns:** nothing

**Side effects:** may set `theme_type_variation = PaperCard`; sets `self_modulate`.

**Called by:** [[home_row#_fill]] (`home_row.gd:74`), [[home_row#show_training_slot]] (`home_row.gd:127`), [[home_row#show_cant_train]] (`home_row.gd:173`), [[home_row#show_patient]] (`home_row.gd:185`), [[home_row#show_fallen]] (`home_row.gd:211, 211`), [[home_section#setup]] (`home_section.gd:60`), [[report_entry#_show_story_look]] (`report_entry.gd:201`), [[gear_row#setup]] (`gear_row.gd:34, 36`), [[gear_row#setup_empty]] (`gear_row.gd:48`), [[pick_row#_show_pick_state]] (`pick_row.gd:104, 117, 127`), [[quest_row#_show_story_look]] (`quest_row.gd:104`), [[hall_header#_refresh_danger_strip]] (`hall_header.gd:219`)

**Calls:** [[hall_style#tint_art]]

### set_look
`static func set_look(panel: Control, variation: StringName) -> void:` · `Scripts/Hall/Style/hall_style.gd:651`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `panel` | `Control` | Control to restyle | the node the caller is building |
| `variation` | `StringName` | Theme type variation | `&"PaperCard"` (overlay_tutorial.gd:696) |

**Returns:** nothing

**Side effects:** sets `theme_type_variation`.

**Called by:** [[overlay_tutorial#_build]] (`overlay_tutorial.gd:696`)

**Calls:** none.

### fill_art
`static func fill_art(panel: Control, shape: StyleBoxFlat, fill: Color, ink: Color, border_width: int = 2) -> void:` · `Scripts/Hall/Style/hall_style.gd:660`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `panel` | `Control` | Control to restyle | the node the caller is building |
| `shape` | `StyleBoxFlat` | `PILL_STYLE` or `INK_BOX_STYLE` | `HallStyle.PILL_STYLE` (chip.gd:41), `INK_BOX_STYLE` (screen_character.gd:241) |
| `fill` | `Color` | Box fill | `fill` of the chip / `stat.bg` |
| `ink` | `Color` | Border colour | `ink` of the chip / `stat.color` |
| `border_width` | `int` | Px (default 2) | chip's `border_width` |

**Returns:** nothing

**Side effects:** adds a `panel` stylebox override and resets `self_modulate` to white.

**Called by:** [[chip#set_filled]] (`chip.gd:41`), [[screen_character#_show_stats]] (`screen_character.gd:241`)

**Calls:** none.

### clear_fill
`static func clear_fill(panel: Control) -> void:` · `Scripts/Hall/Style/hall_style.gd:672`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `panel` | `Control` | Control to restyle | the node the caller is building |

**Returns:** nothing

**Side effects:** removes the `panel` stylebox override.

**Called by:** [[chip#_set_ink]] (`chip.gd:45`)

**Calls:** none.

### tint_art
`static func tint_art(node: CanvasItem, ink: Color) -> void:` · `Scripts/Hall/Style/hall_style.gd:678`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `CanvasItem` | Node to tint (`self_modulate`) | seal, portrait ground, stamp, icon the caller owns |
| `ink` | `Color` | Tint | palette or role colour |

**Returns:** nothing

**Side effects:** sets `self_modulate`.

**Called by:** [[chip#_set_ink]] (`chip.gd:52`), [[crawl_sections#_make_party]] (`crawl_sections.gd:154`), [[portrait#show_character]] (`portrait.gd:48`), [[stat_tile#setup]] (`stat_tile.gd:18`), [[overlay_report#setup]] (`overlay_report.gd:109`), [[overlay_tutorial#_build]] (`overlay_tutorial.gd:683`), [[overlay_tutorial#_build_portrait]] (`overlay_tutorial.gd:813`), [[home_row#_show_stat_picker]] (`home_row.gd:142`), [[report_entry#setup]] (`report_entry.gd:163`), [[quest_tab#setup]] (`quest_tab.gd:41`), [[screen_assign#_show_party]] (`screen_assign.gd:261`), [[hall_style#style_tag]] (`hall_style.gd:622`), [[hall_style#style_panel]] (`hall_style.gd:647`)

**Calls:** none.

### mask_to
`static func mask_to(node: CanvasItem, mask: Texture2D, mask_rect: Rect2) -> void:` · `Scripts/Hall/Style/hall_style.gd:686`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `CanvasItem` | Art clipped by the mask | `_art` (portrait.gd:42), `pip` (overlay_tutorial.gd:829) |
| `mask` | `Texture2D` | Mask texture | `_mask.texture`, `mask` in [[overlay_tutorial#_build_portrait]] |
| `mask_rect` | `Rect2` | Mask area in `node`-local px | `Rect2(-_art.position, _mask.size)` |

**Returns:** nothing

**Side effects:** creates or updates a `ShaderMaterial` on `node` with `mask_tex`, `mask_origin`, `mask_size`.

**Called by:** [[portrait#_update_mask]] (`portrait.gd:42`), [[overlay_tutorial#_build_portrait]] (`overlay_tutorial.gd:829`)

**Calls:** `PORTRAIT_MASK_SHADER`

> [!note] How it works
> Used instead of `clip_children`, which renders wrong on iPhone Safari. Call again when the node or mask resizes; the material is reused.

### set_font_color
`static func set_font_color(control: Control, font_color: Color) -> void:` · `Scripts/Hall/Style/hall_style.gd:698`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `control` | `Control` | Control to restyle | the node the caller is building |
| `font_color` | `Color` | New ink | `HallStyle.*` palette constants, or a lookup (`odds_look(...).text_color`, stat `color`) |

**Returns:** nothing

**Side effects:** adds `font_color` and `default_color` overrides.

**Called by:** [[chip#_set_ink]] (`chip.gd:47`), [[crawl_sections#show_title]] (`crawl_sections.gd:52, 53`), [[crawl_sections#make_line]] (`crawl_sections.gd:96`), [[crawl_sections#_make_story]] (`crawl_sections.gd:130`), [[stat_tile#setup]] (`stat_tile.gd:17`), [[overlay_intro#_show_text]] (`overlay_intro.gd:104, 108, 109, 120`), [[overlay_tutorial#_build]] (`overlay_tutorial.gd:761`), [[overlay_gear_confirm#_show_take_off]] (`overlay_gear_confirm.gd:115`), [[overlay_credits#_show_titles]] (`overlay_credits.gd:174, 176`), [[home_row#_set_note]] (`home_row.gd:101`), [[home_section#_show_training]] (`home_section.gd:88`), [[home_section#_show_hospital]] (`home_section.gd:134, 137, 141`), [[upgrade_card#_show_status]] (`upgrade_card.gd:105, 108, 111`), [[plan_row#setup]] (`plan_row.gd:27`), [[report_entry#setup]] (`report_entry.gd:164, 185`), [[report_entry#_add_fold_hint]] (`report_entry.gd:232, 250`), [[roll_call_row#setup]] (`roll_call_row.gd:44`), [[member_card#_show_status]] (`member_card.gd:86`), [[equip_pick_row#setup]] (`equip_pick_row.gd:33`), [[gear_row#setup]] (`gear_row.gd:32`), [[gear_row#setup_empty]] (`gear_row.gd:47`), [[pack_tile#setup]] (`pack_tile.gd:43`), [[shop_tile#setup]] (`shop_tile.gd:48`), [[party_slot#setup]] (`party_slot.gd:57`), [[pick_row#_show_elsewhere]] (`pick_row.gd:78, 86`), [[pick_row#_show_pick_state]] (`pick_row.gd:103, 116, 124`), [[quest_row#_show_party]] (`quest_row.gd:126`), [[quest_row#_show_state]] (`quest_row.gd:134, 137, 141`), [[quest_tab#setup]] (`quest_tab.gd:42, 43`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:222`), [[screen_assign#_show_party]] (`screen_assign.gd:260`), [[screen_character#_show_stats]] (`screen_character.gd:238, 239`), [[hall_header#_refresh_drake_countdown]] (`hall_header.gd:168, 165`), [[hall_header#_refresh_danger_strip]] (`hall_header.gd:222`), [[popup_gold#_ready]] (`popup_gold.gd:76`), [[popup_gold#_refresh_earnings]] (`popup_gold.gd:116`), [[popup_gold#_set_price]] (`popup_gold.gd:133`), [[popup_standing#_ready]] (`popup_standing.gd:59, 61, 63`), [[tab_guild#_show_beds]] (`tab_guild.gd:139`), [[tab_pack#_show_item_bar]] (`tab_pack.gd:193, 196, 200`)

**Calls:** none.

### turn_caret
`static func turn_caret(caret: Control, degrees: float, seconds: float = 0.0) -> void:` · `Scripts/Hall/Style/hall_style.gd:713`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `caret` | `Control` | The "›" label (must sit in a plain Control) | `_fold_caret` (report_entry.gd:265), `_chevron` (member_card.gd:49) |
| `degrees` | `float` | Clockwise turn | `CARET_DOWN` or `CARET_UP` |
| `seconds` | `float` | Tween length; 0 snaps (default 0) | report_entry.gd passes a fold time; member_card.gd omits it |

**Returns:** nothing

**Side effects:** sets pivot, connects `resized` once (meta `caret_pivot_hooked`), sets rotation or starts a tween.

**Called by:** [[report_entry#set_folded]] (`report_entry.gd:265`), [[member_card#_ready]] (`member_card.gd:49`)

**Calls:** `HallFx.reduce_motion` (read)

> [!note] How it works
> Containers reset their children's rotation on layout, so the caret has to sit in a plain Control.

### clear_children
`static func clear_children(container: Node) -> void:` · `Scripts/Hall/Style/hall_style.gd:728`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `container` | `Node` | List container to empty | the row list node of the calling view |

**Returns:** nothing

**Side effects:** removes and `queue_free`s every child.

**Called by:** [[crawl_sections#clear]] (`crawl_sections.gd:58`), [[overlay_end_day#_show_tonights_plan]] (`overlay_end_day.gd:75`), [[overlay_end_day#_show_upgrade_suggestions]] (`overlay_end_day.gd:92`), [[overlay_intro#_show_text]] (`overlay_intro.gd:107`), [[overlay_report#_show_entries]] (`overlay_report.gd:282`), [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:75`), [[overlay_gear_confirm#_show_swap]] (`overlay_gear_confirm.gd:135`), [[overlay_credits#_show_records]] (`overlay_credits.gd:210`), [[overlay_credits#_show_roll_call]] (`overlay_credits.gd:218`), [[overlay_credits#_show_team]] (`overlay_credits.gd:228`), [[overlay_game_over#_show_roll_call]] (`overlay_game_over.gd:90`), [[home_section#refresh]] (`home_section.gd:65`), [[quest_row#_show_party]] (`quest_row.gd:115`), [[screen_assign#_show_quest_tabs]] (`screen_assign.gd:207`), [[screen_assign#_show_party]] (`screen_assign.gd:243, 244`), [[screen_assign#_show_picker]] (`screen_assign.gd:368`), [[screen_character#_show_gear]] (`screen_character.gd:258`), [[tab_board#_show_quest_list]] (`tab_board.gd:121`), [[tab_guild#refresh]] (`tab_guild.gd:89, 90`), [[tab_pack#_show_grid]] (`tab_pack.gd:140`), [[tab_shop#_show_goods]] (`tab_shop.gd:79`), [[tab_upgrades#_show_building_cards]] (`tab_upgrades.gd:108`), [[tab_upgrades#_show_coming_soon]] (`tab_upgrades.gd:119`)

**Calls:** none.

### add_row
`static func add_row(container: Node, row_scene: PackedScene) -> Node:` · `Scripts/Hall/Style/hall_style.gd:736`

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `container` | `Node` | List container to fill | the row list node of the calling view |
| `row_scene` | `PackedScene` | Row scene to instance | a `preload("uid://...")` constant in the calling view |

**Returns:** nothing

**Side effects:** instances and adds a child to `container`.

**Called by:** [[overlay_end_day#_show_tonights_plan]] (`overlay_end_day.gd:77`), [[overlay_end_day#_show_upgrade_suggestions]] (`overlay_end_day.gd:94`), [[overlay_report#_show_entries]] (`overlay_report.gd:286`), [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:80`), [[overlay_gear_confirm#_show_swap]] (`overlay_gear_confirm.gd:137`), [[overlay_credits#_show_roll_call]] (`overlay_credits.gd:220`), [[overlay_game_over#_show_roll_call]] (`overlay_game_over.gd:92`), [[home_section#_add_heading]] (`home_section.gd:73`), [[home_section#_add_row]] (`home_section.gd:77`), [[report_entry#_build_story_beats]] (`report_entry.gd:332`), [[screen_assign#_show_quest_tabs]] (`screen_assign.gd:211`), [[screen_assign#_show_party]] (`screen_assign.gd:248`), [[screen_assign#_show_picker]] (`screen_assign.gd:370`), [[screen_character#_show_gear]] (`screen_character.gd:268, 279, 298`), [[tab_board#_show_quest_list]] (`tab_board.gd:123`), [[tab_guild#_show_roster]] (`tab_guild.gd:151, 159, 163`), [[tab_guild#_show_for_hire]] (`tab_guild.gd:184, 195`), [[tab_pack#_show_grid]] (`tab_pack.gd:143`), [[tab_shop#_show_goods]] (`tab_shop.gd:91`), [[tab_upgrades#_show_building_cards]] (`tab_upgrades.gd:114`), [[tab_upgrades#_show_coming_soon]] (`tab_upgrades.gd:122`)

**Calls:** none.

## Suspected issues
- `Scripts/Hall/Style/hall_style.gd:588` `BUTTON_BOX_STATES` has no reader (dead constant).
- `Scripts/Hall/Style/hall_style.gd:644` `style_panel` ignores its four underscore parameters (`_border_color`, `_border_width`, `_corner_radius`, `_padding`) but [[home_row]] still passes border and radius (`home_row.gd:74`, `127`); harmless leftovers.
- `Scripts/Hall/Style/hall_style.gd:332` the `quest_type_info` doc says `{name, writ, color, tag}`, but the table entries also carry `icon`, and callers read it ([[plan_row#setup]], [[quest_row#_show_quest_facts]]).
- `Scripts/Hall/Style/hall_style.gd:260` `roman_numeral` has no caller in `Globals/`, `Scripts/` or `Scenes/` (dead code).
- `Scripts/Hall/Style/hall_style.gd:415` `is_dead` is the only function without a `##` doc comment.
- `Scripts/Hall/Style/hall_style.gd:4-5` the header says nothing here holds state except the icon cache, but `_bbcode_tags` is also a static var (a compiled constant regex, harmless).
- `Scripts/Hall/Style/hall_style.gd:338-340` `favored_components` doc says "Never empty", which holds only if `CreatedQuest.favored_components` is never empty (not traced).
