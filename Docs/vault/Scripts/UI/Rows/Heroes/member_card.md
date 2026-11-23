---
source: Scripts/UI/Rows/Heroes/member_card.gd
class_name: ""
extends: TapPanel
scene: "[[member_card (scene)]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# member_card.gd

## Purpose
One adventurer in the Guild tab's roster (a parchment card): portrait, what they're doing today, and health with their two strongest stats. Tap for details (the character page shows every stat). On the right: their status (on a quest, idle, training, in hospital, fallen), then a caret pointing down. Extends [[tap_panel]]. Scene: [[member_card (scene)]]. Created by [[tab_guild#_show_roster]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SHOW_QUEST_TASK` | const | SIMPLIFIED: the "Sent on #2" / "Picked for #2" chip for heroes in a quest's party (false). |
| `SHOW_FREE_TASK` | const | SIMPLIFIED: the "Free today" chip (false; no chip already means free). |
| `SHOW_FACILITY_TASK` | const | The "Training Pow" / "In a Hospital bed" chips (false; the status on the right says the same). |
| `TEXT_ROLE`, `TEXT_FREE`, `TEXT_PICKED_FOR`, `TEXT_SENT_ON`, `TEXT_TRAINING`, `TEXT_IN_BED`, `TEXT_DIED_ON` | const | Task chip strings. |
| `STATUS_ON_QUEST`, `STATUS_IDLE`, `STATUS_TRAINING`, `STATUS_IN_HOSPITAL`, `STATUS_FALLEN` | const | Status strings (right of the card); two short lines where there's a detail so the column stays narrow. |
| `SHOWN_STAT_COUNT` | const | How many stats a roster card shows (2, the strongest). |
| `_portrait`, `_name`, `_role`, `_task_chip`, `_stats`, `_chevron`, `_status` | onready | `%Portrait` ([[portrait]]), `%Name`, `%Role`, `%TaskChip` ([[chip]]), `%Stats` ([[stat_strip]]), `%Chevron`, `%Status`. |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Rows/Heroes/member_card.gd:47`

Turns the caret to point down (`HallStyle.CARET_DOWN`). Called by the engine.

**Called by:** the engine.

**Calls:** [[hall_style#turn_caret]].

### setup
`func setup(hall: HallMain, character: GuildCharacter) -> void` · `Scripts/UI/Rows/Heroes/member_card.gd:52`

Fills the card and makes a tap open the hero's page. The chevron is hidden while the hero page is still locked by the tutorial.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` in [[tab_guild]] |
| `character` | `GuildCharacter` | The hero | loop over `living` / `fallen` from `hall.roster()` in [[tab_guild#_show_roster]] |

**Returns:** nothing.

**Side effects:** connects `pressed` to `hall.open_character` bound with `character` ([[hall_main#open_character]]).

**Called by:** [[tab_guild#_show_roster]] (`tab_guild.gd:151` for the living, `tab_guild.gd:164` for the fallen, which then get `modulate` faded).

**Calls:** [[hall_main#open_character]], [[hall_main#is_locked]], [[portrait#show_character]], [[hall_style#role_name]], [[stat_strip#show_health]], [[stat_strip#show_stats]], [[member_card#_show_task]], [[member_card#_show_status]].

### _show_status
`func _show_status(hall: HallMain, character: GuildCharacter) -> void` · `Scripts/UI/Rows/Heroes/member_card.gd:68`

The status on the right: fallen (Dead ink), on a quest (green, with its number), in a Hospital bed (orange), training a stat (that stat's ink), else idle. A hero in a quest's party is always sent, so there is no separate "picked" status.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For `quest_index_of` | [[member_card#setup]] |
| `character` | `GuildCharacter` | The hero | [[member_card#setup]] |

**Returns:** nothing.

**Side effects:** sets `%Status` text and colour.

**Called by:** [[member_card#setup]] (`member_card.gd:61`).

**Calls:** [[hall_main#quest_index_of]], [[hall_style#is_dead]], [[guild_upgrades#is_patient]], [[guild_upgrades#is_training]], [[guild_upgrades#get_training_stat]], [[hall_style#set_font_color]].

### _show_task
`func _show_task(hall: HallMain, character: GuildCharacter) -> void` · `Scripts/UI/Rows/Heroes/member_card.gd:92`

Today's task chip: the day they died (hidden if not recorded), in a bed, training, free, sent on a quest, or picked for one. Each branch sets the chip and its visibility from the `SHOW_*` switches, so with the shipped constants only the "Died on Day N" chip can show.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For `quest_index_of`, `quest_entries` | [[member_card#setup]] |
| `character` | `GuildCharacter` | The hero (`died_on_day` read for the fallen) | [[member_card#setup]] |

**Returns:** nothing.

**Side effects:** sets `%TaskChip` text, colours and visibility.

**Called by:** [[member_card#setup]] (`member_card.gd:60`).

**Calls:** [[hall_main#quest_index_of]], [[hall_style#is_dead]], [[chip#set_chip]], [[guild_upgrades#is_patient]], [[guild_upgrades#is_training]], [[guild_upgrades#get_training_stat]].

## Suspected issues
- None found.
