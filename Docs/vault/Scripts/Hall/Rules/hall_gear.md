---
source: Scripts/Hall/Rules/hall_gear.gd
class_name: HallGear
extends: RefCounted
scene: null
systems: ["[[Items and Shop]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_gear.gd

## Purpose
Gear rules for the Items tab's Pack: which heroes can wear an item, and how a hero's stats change when gear goes on or comes off. Static functions only. They read the roster and gear from the autoloads and change nothing. Equipping itself goes through [[hall_main]] (`equip_item` / `unequip_item` / `swap_gear`). Used by [[overlay_equip_picker]], [[overlay_gear_confirm]], [[equip_pick_row]] and [[pack_tile]].

## State
No constants, variables or signals.

## Functions

### heroes_for
`static func heroes_for(item: StandardItem) -> Array[GuildCharacter]` · `Scripts/Hall/Rules/hall_gear.gd:13`

Living heroes on the roster whose role matches the item, minus whoever is wearing it now. Heroes with a free gear slot come first, then roster order.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item to put on | `_item` of [[overlay_equip_picker]] |

**Returns:** `Array[GuildCharacter]`. Used by [[overlay_equip_picker#refresh]] to list the candidate rows.

**Side effects:** none.

**Called by:** [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:76`).

**Calls:** [[hall_style#is_dead]], [[hall_gear#has_free_slot]].

### heroes_wrong_role
`static func heroes_wrong_role(item: StandardItem) -> Array[GuildCharacter]` · `Scripts/Hall/Rules/hall_gear.gd:27`

Living heroes on the roster who can't wear the item (wrong role).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item being placed | `_item` of [[overlay_equip_picker]] |

**Returns:** `Array[GuildCharacter]`. [[overlay_equip_picker#refresh]] joins their names into the "wrong role" note.

**Side effects:** none.

**Called by:** [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:88`).

**Calls:** [[hall_style#is_dead]].

### has_free_slot
`static func has_free_slot(character: GuildCharacter) -> bool` · `Scripts/Hall/Rules/hall_gear.gd:36`

True if the hero can take one more item without taking another off.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero to test | the roster entry being drawn |

**Returns:** `bool`. [[equip_pick_row#setup]] picks the "slots" caption with it; [[overlay_equip_picker#refresh]] uses it to choose an Equip (free slot) or Swap button for each hero.

**Side effects:** none.

**Called by:** [[hall_gear#heroes_for]] (`hall_gear.gd:19`), [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:81`), [[equip_pick_row#setup]] (`equip_pick_row.gd:29`).

**Calls:** none.

### item_bonus
`static func item_bonus(item: StandardItem) -> Vector2i` · `Scripts/Hall/Rules/hall_gear.gd:42`

What a passive item adds: `Vector2i(stat index, amount)`, or `(-1, 0)` for an item that doesn't add a stat.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item to read | the pack tile's item, or `item_on` / `item_off` in [[hall_gear#preview]] |

**Returns:** `Vector2i`. [[pack_tile#setup]] shows the bonus on the tile; [[hall_gear#preview]] applies it.

**Side effects:** none.

**Called by:** [[hall_gear#preview]] (`hall_gear.gd:55`, `hall_gear.gd:59`), [[pack_tile#setup]] (`pack_tile.gd:39`).

**Calls:** none.

### preview
`static func preview(character: GuildCharacter, item_on: StandardItem, item_off: StandardItem) -> Array[Dictionary]` · `Scripts/Hall/Rules/hall_gear.gd:52`

How the hero's quest stats change if `item_on` goes on and `item_off` comes off (either may be null). Only the stats that change are listed.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | the row's hero / the wearer in the confirm overlay |
| `item_on` | `StandardItem` | Item being put on, or null | `_item` (picker), `null` (take off), the new item (swap) |
| `item_off` | `StandardItem` | Item being taken off, or null | `null` (picker), the worn item (take off / swap) |

**Returns:** `Array[Dictionary]` of `{"stat": stat index, "before": int, "after": int}` in stat order. [[overlay_equip_picker#refresh]] and [[overlay_gear_confirm#_show_take_off]] / [[overlay_gear_confirm#_show_swap]] pass it on to display.

**Side effects:** none.

**Called by:** [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:78`), [[overlay_gear_confirm#_show_take_off]] (`overlay_gear_confirm.gd:110`), [[overlay_gear_confirm#_show_swap]] (`overlay_gear_confirm.gd:140`).

**Calls:** [[hall_gear#item_bonus]], [[hall_style#quest_stat_value]].

### preview_text
`static func preview_text(changes: Array[Dictionary]) -> String` · `Scripts/Hall/Rules/hall_gear.gd:74`

`preview()` as BBCode lines for a RichTextLabel, like "Power  40 → 18", with the new number green when it goes up and red when it goes down.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `changes` | `Array[Dictionary]` | The result of [[hall_gear#preview]] | argument of [[overlay_gear_confirm#_set_changes]] |

**Returns:** `String` (BBCode). [[overlay_gear_confirm#_set_changes]] assigns it to `_changes.text`.

**Side effects:** none.

**Called by:** [[overlay_gear_confirm#_set_changes]] (`overlay_gear_confirm.gd:150`).

**Calls:** none.

## Suspected issues
None found.
