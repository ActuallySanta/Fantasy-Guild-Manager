---
source: Scripts/UI/Rows/Quests/pick_row.gd
class_name: ""
extends: TapPanel
scene: "[[pick_row (scene)]]"
systems: ["[[Party Drafting and Assignment]]", "[[Success Chance]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# pick_row.gd

## Purpose
One adventurer in Assign Party's picker: portrait, health and the four quest stats on one line (favored stat with a heavy border), how much they'd add to the odds, and which quest (or training) they're already on. Tap to pin / unpin; "i" opens their details. Extends [[tap_panel]]. Scene: [[pick_row (scene)]]. Created by [[screen_assign#_show_picker]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `CANT_GO_OPACITY` | const | Adventurers who can't go fade back (0.6). |
| `BUSY_OPACITY` | const | Adventurers already in another quest's party are greyed this much (0 = invisible, 1 = normal). |
| `SHOW_ADDS_CAPTION` | const | SIMPLIFIED: the "to odds" caption under "+12%" (false, hidden). |
| `TEXT_*` | const | UI strings: `TEXT_ROLE`, `TEXT_INFO`, `TEXT_PICKED_FOR`, `TEXT_SENT_ON`, `TEXT_QUEST_NAME`, `TEXT_TRAINING`, `TEXT_ADDS`, `TEXT_ADDS_SUB`, `TEXT_IN_PARTY`, `TEXT_CANT_GO`, `TEXT_CANT_GO_SUB`, `TEXT_IN_BED_SUB`, `TEXT_TRAINING_SUB`. |
| `_portrait`, `_name`, `_role`, `_stats`, `_info_button`, `_elsewhere_label`, `_adds_value`, `_adds_sub` | onready | `%Portrait` ([[portrait]]), `%Name`, `%Role`, `%Stats` ([[stat_strip]]), `%InfoButton`, `%Where`, `%AddValue`, `%AddSub`. |

## Functions

### setup
`func setup(hall: HallMain, entry: Dictionary, character: GuildCharacter, ask_to_move: Callable = Callable()) -> void` · `Scripts/UI/Rows/Quests/pick_row.gd:53`

Fills the row. A tap pins/unpins the hero, or, when they're in another quest's party and `ask_to_move` is valid, calls `ask_to_move(character)` instead.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` in [[screen_assign]] |
| `entry` | `Dictionary` | The quest being assigned | `entry` argument of [[screen_assign#_show_picker]] |
| `character` | `GuildCharacter` | Who this row shows | loop over `shown_adventurers` in [[screen_assign#_show_picker]] |
| `ask_to_move` | `Callable` | Called with `character` for a hero busy on another quest (the move popup); empty means move straight away | `_move_confirm.open` in [[screen_assign#_show_picker]] |

**Returns:** nothing.

**Side effects:** connects `pressed` to `ask_to_move.bind(character)` or `hall.toggle_in_party` ([[hall_main#toggle_in_party]]); connects `%InfoButton` `pressed` to `hall.open_character` ([[hall_main#open_character]]); the info button is locked until `OverlayTutorial.FEATURE_HERO_PAGE`.

**Called by:** [[screen_assign#_show_picker]] (`screen_assign.gd:370`).

**Calls:** [[pick_row#_is_busy_elsewhere]], [[hall_main#is_locked]], [[hall_style#set_locked]], [[portrait#show_character]], [[hall_style#role_name]], [[stat_strip#show_health]], [[stat_strip#show_stats]], [[hall_style#favored_stat_indexes]], [[pick_row#_show_elsewhere]], [[pick_row#_show_pick_state]].

### _show_elsewhere
`func _show_elsewhere(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> void` · `Scripts/UI/Rows/Quests/pick_row.gd:72`

"Picked for #2 Escort..." / "Sent on ..." when they're in another quest's party, "Training Power" when they're in the Training Yard, else the label is hidden.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | Gives `quest_index_of` and `quest_entries` | [[pick_row#setup]] |
| `entry` | `Dictionary` | The quest being assigned (not "elsewhere") | [[pick_row#setup]] |
| `character` | `GuildCharacter` | The hero | [[pick_row#setup]] |

**Returns:** nothing.

**Side effects:** sets `%Where` text, colour and visibility.

**Called by:** [[pick_row#setup]] (`pick_row.gd:66`).

**Calls:** [[hall_main#quest_index_of]], [[guild_upgrades#is_training]], [[guild_upgrades#get_training_stat]], [[hall_style#set_font_color]].

### _is_busy_elsewhere
`func _is_busy_elsewhere(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> bool` · `Scripts/UI/Rows/Quests/pick_row.gd:91`

True when `character` is in a party (picked or sent) for a quest other than `entry`'s.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For `quest_index_of`, `quest_entries` | [[pick_row#setup]] |
| `entry` | `Dictionary` | The quest being assigned | [[pick_row#setup]] |
| `character` | `GuildCharacter` | The hero | [[pick_row#setup]] |

**Returns:** `bool`. Used by [[pick_row#setup]] to choose the tap action and by [[pick_row#_show_pick_state]] to grey the row.

**Side effects:** none.

**Called by:** [[pick_row#setup]] (`pick_row.gd:55`), [[pick_row#_show_pick_state]] (`pick_row.gd:126`).

**Calls:** [[hall_main#quest_index_of]].

### _show_pick_state
`func _show_pick_state(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> void` · `Scripts/UI/Rows/Quests/pick_row.gd:99`

Right-hand column and paper tint: pinned to this party (green paper, "Assigned"), can't go (faded, "-" with a reason: dead, in a bed, training), or the odds they'd add (greyed and faded when already on another quest).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For `can_go_on_quests`, `chance_added_by`, `pending_fx` | [[pick_row#setup]] |
| `entry` | `Dictionary` | The quest being assigned | [[pick_row#setup]] |
| `character` | `GuildCharacter` | The hero | [[pick_row#setup]] |

**Returns:** nothing.

**Side effects:** restyles the panel, sets `modulate`, sets label text and colours; stamps "Assigned" in when `hall.pending_fx["seat_in"] == character` ([[hall_fx#stamp_in]]).

**Called by:** [[pick_row#setup]] (`pick_row.gd:67`).

**Calls:** [[hall_style#set_font_color]], [[hall_style#style_panel]], [[hall_fx#stamp_in]], [[hall_main#can_go_on_quests]], [[hall_style#is_dead]], [[guild_upgrades#is_patient]], [[hall_main#chance_added_by]], [[hall_style#odds_look]], [[pick_row#_is_busy_elsewhere]].

## Suspected issues
- None found.
