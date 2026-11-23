---
source: Scripts/UI/Rows/Quests/quest_row.gd
class_name: ""
extends: TapPanel
scene: "[[quest_row (scene)]]"
systems: ["[[UI Architecture and Refresh]]", "[[Party Drafting and Assignment]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# quest_row.gd

## Purpose
One quest on the Board, drawn as a scroll: type seal, title, rank, reward, party size and favored stat on the left; its state (party picked, sent, denied) and odds on the right. Tapping it opens Assign Party on that quest. Story quests (`HallStyle.is_story_quest`) get gilt paper and a "Story Quest" ribbon above the title. Extends [[tap_panel]]. Scene: [[quest_row (scene)]]. Created by [[tab_board#_show_quest_list]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `PortraitScene` | preload | `Scenes/Components/portrait.tscn` ([[portrait (scene)]]), one per party member in [[quest_row#_show_party]]. |
| `ChipScene` | preload | `Scenes/Components/chip.tscn` ([[chip (scene)]]), the story ribbon in [[quest_row#_show_story_look]]. |
| `MINI_PORTRAIT_SIZE` | const | Size (pixels) of the little party portraits under the state. |
| `DENIED_OPACITY` | const | Denied quests fade back so the open ones stand out (0.7). |
| `SENT_STAMP_AT`, `SENT_STAMP_FONT_SIZE`, `SENT_STAMP_TILT` | const | The SENT stamp inked on a sent quest's row: centre as a fraction of the row's size, text size, tilt (radians). |
| `TYPE_SEAL_SIZE`, `STATE_COLUMN_SIZE` | const | Boxes that hold text, in design px, grown with the font scale (`HallFontScale.px_vec`) so text keeps fitting. |
| `SIDE_BOX_MAX_FACTOR` | const | The most those two boxes (and the seal's tag, `metadata/font_max_factor` in the scene) grow: 1.5. |
| `TEXT_RANK`, `TEXT_GOLD`, `TEXT_PARTY_SIZE`, `TEXT_OPEN`, `TEXT_SENT`, `TEXT_SENT_STAMP`, `TEXT_DENIED`, `TEXT_ODDS`, `TEXT_STORY_RIBBON`, `STORY_ICON` | const | UI strings and the ribbon icon name. |
| `_type_seal`, `_type_tag`, `_type_icon`, `_title`, `_rank_chip`, `_gold_chip`, `_party_size_chip`, `_favored_chip`, `_state_column`, `_state_label`, `_odds_label`, `_party_portraits`, `_scroll_body` | onready | Scene nodes `%TypeSeal`, `%TypeTag`, `%TypeIcon`, `%Title`, `%RankChip`, `%GoldChip`, `%SlotsChip`, `%FavChip` ([[chip]]), `%StateCol`, `%StateLabel`, `%OddsLabel`, `%Party`, and `$Row/BodyMargin/Body`. |

## Functions

### setup
`func setup(hall: HallMain, quest_index: int) -> void` · `Scripts/UI/Rows/Quests/quest_row.gd:63`

Fills the row from `hall.quest_entries[quest_index]`, connects the tap to open Assign Party, sizes the seal and state column for the font scale, then calls the `_show_*` helpers. Sent quests get the SENT stamp (pressed on if it was just sent); a just-denied quest's state word stamps in.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` stored by [[tab_board#setup]] |
| `quest_index` | `int` | Index into `hall.quest_entries` | `quest_index` from `_board_order()` in [[tab_board#_show_quest_list]] |

**Returns:** nothing.

**Side effects:** connects `pressed` (from [[tap_panel]]) to `hall.open_assign` bound with `quest_index` ([[hall_main#open_assign]]); may fade the row (denied); starts stamp/pop tweens ([[hall_fx#stamp_onto]], [[hall_fx#stamp_in]], [[hall_fx#pop]]) when `hall.pending_fx["quest_stamp"] == quest_index`.

**Called by:** [[tab_board#_show_quest_list]] (`tab_board.gd:123`, `HallStyle.add_row(_quest_list, QuestRowScene).setup(hall, quest_index)`). The other `setup(` hits in the index (`hall_main.gd`, overlays) are different objects.

**Calls:** [[hall_font_scale#px_vec]], [[quest_row#_show_quest_facts]], [[quest_row#_show_party]], [[quest_row#_show_state]], [[hall_style#is_story_quest]], [[quest_row#_show_story_look]], [[hall_fx#stamp_onto]], [[hall_fx#stamp_in]], [[hall_fx#pop]].

### _show_quest_facts
`func _show_quest_facts(hall: HallMain, entry: Dictionary) -> void` · `Scripts/UI/Rows/Quests/quest_row.gd:85`

Type seal, title, rank, reward, party size, favored stat. Item quests (`entry.quest.pays_in_items()`) show the item count and rarities (blue chest chip) instead of gold. The favored chip uses the full stat name (see the SIMPLIFIED comment in the code).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For `party_size_limit(entry)` | `hall` in [[quest_row#setup]] |
| `entry` | `Dictionary` | The quest entry (`quest`, `party`, `state`) | `hall.quest_entries[quest_index]` in [[quest_row#setup]] |

**Returns:** nothing.

**Side effects:** sets text and colours on the seal, title and the four [[chip]] nodes.

**Called by:** [[quest_row#setup]] (`quest_row.gd:68`).

**Calls:** [[hall_style#quest_type_info]], [[hall_style#style_icon_tag]], [[chip#set_box]], [[hall_style#rank_letter]], [[quest_resource#pays_in_items]], [[chip#set_chip]], [[hall_style#item_reward_text]], [[hall_main#party_size_limit]], [[hall_style#favored_components]], [[hall_style#favored_label]].

### _show_story_look
`func _show_story_look() -> void` · `Scripts/UI/Rows/Quests/quest_row.gd:103`

Gilt paper and a "Story Quest" ribbon (a [[chip (scene)]] instance) added as the first child of the info column.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** restyles `$Row/BodyMargin/Body`, adds a child to `_title`'s parent.

**Called by:** [[quest_row#setup]] (`quest_row.gd:72`), only when `HallStyle.is_story_quest(entry)`.

**Calls:** [[hall_style#style_panel]], [[chip#set_box]].

### _show_party
`func _show_party(hall: HallMain, entry: Dictionary) -> void` · `Scripts/UI/Rows/Quests/quest_row.gd:114`

Mini portraits of the picked party and their success chance. `%OddsLabel` is hidden when the chance is negative and capped at 100.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For `success_chance` | `hall` in [[quest_row#setup]] |
| `entry` | `Dictionary` | The quest entry, `entry.party` is the picked heroes | [[quest_row#setup]] |

**Returns:** nothing.

**Side effects:** clears and refills `%Party` with [[portrait (scene)]] instances; sets the odds label text and colour.

**Called by:** [[quest_row#setup]] (`quest_row.gd:69`).

**Calls:** [[hall_style#clear_children]], [[portrait#show_character]], [[hall_main#success_chance]], [[hall_style#set_font_color]], [[hall_style#odds_look]].

### _show_state
`func _show_state(entry: Dictionary) -> void` · `Scripts/UI/Rows/Quests/quest_row.gd:130`

State word in its ink: green = sent, red = denied (and the row fades to `DENIED_OPACITY`), blue = open ("Pick a party").

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | Quest entry; `entry.state` is a `HallStyle.QUEST_STATE_*` value | [[quest_row#setup]] |

**Returns:** nothing.

**Side effects:** sets `%StateLabel` text and colour; sets `modulate` when denied.

**Called by:** [[quest_row#setup]] (`quest_row.gd:70`).

**Calls:** [[hall_style#set_font_color]].

## Suspected issues
- None found.
