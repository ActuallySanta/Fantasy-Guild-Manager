---
source: Scripts/UI/Components/chip.gd
class_name: ""
extends: PanelContainer
scene: "[[chip (scene)]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# chip.gd

## Purpose
A small ink label, optionally with an icon and an outline. Used for stats, health, gold, rank, party size and other short facts. The outline is white art (`Themes/Styles/pill.tres` or `ink_box.tres`) tinted the ink colour. Stats and health are filled pills instead: the paper tint behind the ink. Scene: [[chip (scene)]], placed in many scenes (see its Parent scenes).

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SHOW_STAT_BONUS` | const | SIMPLIFIED: true = stat chips show the bonuses split out ("Pow 5+3"), false = just the total ("Pow 8") (false). The split stays on the hero's own page ([[screen_character]]). |
| `FILLED_BORDER`, `FAVORED_BORDER` | const | Border of a filled pill in pixels: 2 normally, 4 for the quest's favored stat. |
| `_icon`, `_label` | onready | `$Row/Icon` (TextureRect), `$Row/Text` (Label). Not `%` nodes. |

## Functions

### set_chip
`func set_chip(text: String, _background: Color, text_color: Color, icon_name: String = "", outlined: bool = false) -> void` · `Scripts/UI/Components/chip.gd:28`

Ink text with an optional icon; `outlined` adds a rounded outline in the text colour (the quest's favored stat). `_background` is no longer drawn (chips are ink on paper); it is kept so older callers still work.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | The chip's text | each caller's `TEXT_*` format |
| `_background` | `Color` | Unused | e.g. `HallStyle.BLUE_BG` |
| `text_color` | `Color` | Ink for text, icon and outline | e.g. `HallStyle.TEXT_MAIN` |
| `icon_name` | `String` | A `HallStyle.ICON_FILES` name; `""` or unknown means no icon | e.g. `"coins"` |
| `outlined` | `bool` | Rounded outline | `true` for favored stats |

**Returns:** nothing.

**Called by:** [[stat_strip#show_health]] (`stat_strip.gd:48`), [[home_row#_show_task_chip]] (`home_row.gd:90`, `93`, `95`), [[member_card#_show_task]] (`member_card.gd:96`, `100`, `104`, `107`, `110`, `113`), [[quest_row#_show_quest_facts]] (`quest_row.gd:92`, `94`, `95`, `99`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:226`, `227`, `229`, `231`).

**Calls:** [[chip#_set_ink]].

### set_box
`func set_box(text: String, text_color: Color, icon_name: String = "") -> void` · `Scripts/UI/Components/chip.gd:33`

Text in a square ink outline ("RANK F", the report's totals, the Story Quest ribbon).

**Parameters:** `text`, `text_color`, `icon_name` as in [[chip#set_chip]].

**Returns:** nothing.

**Called by:** [[overlay_report#_show_totals]] (`overlay_report.gd:213`, `220`, `223`, `225`, `230`), [[quest_row#_show_quest_facts]] (`quest_row.gd:89`), [[quest_row#_show_story_look]] (`quest_row.gd:110`), [[report_entry#_show_story_look]] (`report_entry.gd:206`).

**Calls:** [[chip#_set_ink]].

### set_filled
`func set_filled(text: String, fill: Color, ink: Color, icon_name: String = "", border_width: int = FILLED_BORDER) -> void` · `Scripts/UI/Components/chip.gd:39`

Text on a filled pill: `fill` behind, `ink` for the text, icon and border; `border_width` in pixels (`FILLED_BORDER` or `FAVORED_BORDER`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | Chip text | [[chip#set_health]] (injury label), [[chip#set_stat]] ("Pow 8") |
| `fill` | `Color` | Paper tint behind the ink | `look.bg` or `stat.bg` |
| `ink` | `Color` | Text, icon and border colour | `look.text` or `stat.color` |
| `icon_name` | `String` | Icon name | `look.icon`, or `""` for stats |
| `border_width` | `int` | Border thickness (px) | `FAVORED_BORDER` if favored, else the default |

**Returns:** nothing.

**Called by:** [[chip#set_health]] (`chip.gd:59`), [[chip#set_stat]] (`chip.gd:74`).

**Calls:** [[chip#_set_ink]], [[hall_style#fill_art]].

### _set_ink
`func _set_ink(text: String, text_color: Color, icon_name: String, outline_look: StringName) -> void` · `Scripts/UI/Components/chip.gd:44`

Shared body: clears any fill, sets the text, its colour, the icon (hidden if none) and tint, the theme variation (`Pill`, `InkBox` or none), and tints the outline art.

**Parameters:** as the public setters; `outline_look` is `&"Pill"`, `&"InkBox"` or `&""`.

**Returns:** nothing.

**Called by:** [[chip#set_chip]] (`chip.gd:29`), [[chip#set_box]] (`chip.gd:34`), [[chip#set_filled]] (`chip.gd:40`).

**Calls:** [[hall_style#clear_fill]], [[hall_style#set_font_color]], [[hall_style#icon_texture]], [[hall_style#tint_art]].

### set_health
`func set_health(character: GuildCharacter) -> void` · `Scripts/UI/Components/chip.gd:57`

Health from a character's injury level ("Healthy" in green, "Hurt"...), as a filled pill with its icon.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | each caller's hero |

**Returns:** nothing.

**Called by:** [[stat_strip#show_health]] (`stat_strip.gd:45`), [[home_row#_fill]] (`home_row.gd:67`), [[screen_character#refresh]] (`screen_character.gd:145`).

**Calls:** [[hall_style#injury_look]], [[chip#set_filled]].

### set_stat
`func set_stat(character: GuildCharacter, stat_index: int, is_favored: bool = false) -> void` · `Scripts/UI/Components/chip.gd:65`

One stat as its total, "Pow 8" (base plus Armory, gear and Pluck; quests use the sum), in the stat's ink on its paper tint. The favored stat gets a heavy border. With `SHOW_STAT_BONUS` it splits out the bonus.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | each caller |
| `stat_index` | `int` | Index into `HallStyle.STATS` | loop in [[stat_strip#show_stats]], or the quest's first favored component in [[party_slot#setup]] |
| `is_favored` | `bool` | Heavy border | `favored_indexes.has(stat_index)` in [[stat_strip#show_stats]]; `true` in [[party_slot#setup]] |

**Returns:** nothing.

**Called by:** [[stat_strip#show_stats]] (`stat_strip.gd:37`), [[party_slot#setup]] (`party_slot.gd:42`).

**Calls:** [[hall_style#quest_stat_value]], [[hall_style#stat_bonus]], [[chip#set_filled]].

## Suspected issues
- None found.
