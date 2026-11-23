---
source: Scripts/UI/Rows/Items/equip_pick_row.gd
class_name: ""
extends: PanelContainer
scene: "[[equip_pick_row (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# equip_pick_row.gd

## Purpose
One hero in the Equip picker ([[overlay_equip_picker]]): round portrait, name and role, how full their gear slots are, what the item would change ("Sleaziness 28 → 58"), and Equip (a free slot) or Swap... (slots full). Scene: [[equip_pick_row (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `NAME_LINE`, `SLOTS_LINE`, `SLOTS_FULL`, `CHANGE_LINE` | const | UI strings. |
| `_portrait`, `_name`, `_slots`, `_change`, `_button` | onready | `%Portrait` ([[portrait]]), `%HeroName`, `%Slots`, `%Change`, `%ActionButton`. |

## Functions

### setup
`func setup(character: GuildCharacter, change: Dictionary, button_text: String, button_kind: String, on_press: Callable) -> void` · `Scripts/UI/Rows/Items/equip_pick_row.gd:25`

Fills the row. The change line is hidden for `{}` (the item changes no stat) and coloured green when the stat goes up, red otherwise.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | A hero who can wear the item | loop over `HallGear.heroes_for(_item)` in [[overlay_equip_picker#refresh]] |
| `change` | `Dictionary` | One entry of `HallGear.preview()` (`stat`, `before`, `after`), or `{}` | `changes[0]` of `HallGear.preview(character, _item, null)`, or `{}` if empty |
| `button_text` | `String` | Button label | `BUTTON_EQUIP` if the hero has a free slot, else `BUTTON_SWAP` |
| `button_kind` | `String` | `HallStyle.style_button` kind | `"gold"` (equip) or `"paper"` (swap) |
| `on_press` | `Callable` | The button's action | a lambda emitting `equip_chosen` or `swap_chosen` with `character` |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%ActionButton` to `on_press`.

**Called by:** [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:82` for a free slot, `overlay_equip_picker.gd:84` for full slots).

**Calls:** [[portrait#show_character]], [[hall_style#role_name]], [[hall_gear#has_free_slot]], [[hall_style#set_font_color]], [[hall_style#style_button]].

## Suspected issues
- None found.
