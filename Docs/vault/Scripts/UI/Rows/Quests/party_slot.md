---
source: Scripts/UI/Rows/Quests/party_slot.gd
class_name: ""
extends: TapPanel
scene: "[[party_slot (scene)]]"
systems: ["[[Party Drafting and Assignment]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# party_slot.gd

## Purpose
One seat in Assign Party's party: a pinned card with portrait, name, role and the hero's value in the quest's favored stat (tap to take them out), or a compact empty seat waiting for someone (tap to scroll down to the adventurers; empty seats share a row and split its width). Extends [[tap_panel]]. Scene: [[party_slot (scene)]]. Created by [[screen_assign#_show_party]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `EMPTY_SEAT_OPACITY` | const | Empty seats fade back (0.55). |
| `EMPTY_SEAT_MIN_WIDTH`, `EMPTY_SEAT_HEIGHT`, `EMPTY_SEAT_FONT_SIZE` | const | Empty seats share a row, so they're shorter and stretch: smallest width and height (design px) and the "Empty seat" text size. |
| `TEXT_ROLE`, `TEXT_EMPTY` | const | UI strings ("the %s", "Empty seat"). |
| `_portrait`, `_name`, `_hint`, `_favored_chip` | onready | `%Portrait` ([[portrait]]), `%SlotName`, `%SlotHint`, `%FavChip` ([[chip]]). |

## Functions

### setup
`func setup(hall: HallMain, entry: Dictionary, seated: GuildCharacter, on_empty_pressed: Callable = Callable()) -> void` · `Scripts/UI/Rows/Quests/party_slot.gd:32`

Fills the seat. Filled: portrait, name, role, favored-stat chip, tap takes them out. Empty: compact, stretched, faded; tap calls `on_empty_pressed` if valid.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` in [[screen_assign]] |
| `entry` | `Dictionary` | The quest being assigned | the `entry` argument of [[screen_assign#_show_party]] |
| `seated` | `GuildCharacter` | Hero in this seat, or null for an empty seat | `entry.party[seat_index]` when `seat_index < entry.party.size()`, else null, in [[screen_assign#_show_party]] |
| `on_empty_pressed` | `Callable` | Called when an empty seat is tapped; empty means it does nothing | `scroll_to_picker` ([[screen_assign#scroll_to_picker]]) |

**Returns:** nothing.

**Side effects:** connects `pressed` to `hall.toggle_in_party` bound with `seated` ([[hall_main#toggle_in_party]]) or to `on_empty_pressed`; when `hall.pending_fx["seat_in"] == seated` the portrait stamps in and the card pops ([[hall_fx#stamp_in]], [[hall_fx#pop]]).

**Called by:** [[screen_assign#_show_party]] (`screen_assign.gd:249`).

**Calls:** [[portrait#show_character]], [[hall_style#role_name]], [[chip#set_stat]], [[hall_style#favored_components]], [[hall_font_scale#px]], [[hall_font_scale#set_size]], [[hall_style#set_font_color]], [[hall_fx#stamp_in]], [[hall_fx#pop]].

## Suspected issues
- None found.
