---
source: Scripts/UI/Components/portrait.gd
class_name: ""
extends: Control
scene: "[[portrait (scene)]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# portrait.gd

## Purpose
Character portrait: the character's own art clipped to an oval (or a circle) on a soft ground, inside an ink frame. The clipping is the `portrait_mask` shader (`HallStyle.mask_to`). The size is set on each instance with `custom_minimum_size`. Art: `Sprites/UI Textures/portrait_<oval|round>_<mask|frame>.png`. Scene: [[portrait (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `ROUND_MASK`, `ROUND_FRAME` | const | The round-portrait textures (`portrait_round_mask.png`, `portrait_round_frame.png`), swapped in when `circle` is true. |
| `ART_TINT` | const | Multiplied over the art so white backgrounds read as old paper (`#F2EADB`). |
| `DEAD_TINT` | const | Greys out the art of dead adventurers. |
| `circle` | export var | Round portrait (true) or oval (false). Set per instance in the scenes, or in code ([[quest_row#_show_party]] sets it before `add_child`). |
| `pinned` | export var | A red pin on top (pinned cards, applicant letters). |
| `_mask`, `_art`, `_frame`, `_pin` | onready | `$Mask`, `$Mask/Art`, `$Frame`, `$Pin` (TextureRects). Not `%` nodes. |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Components/portrait.gd:29`

Swaps in the round mask and frame if `circle`, shows the pin if `pinned`, connects `resized` on the art to [[portrait#_update_mask]] and calls it once. The art is much bigger than the mask (scene anchors) and is clipped by a shader, not `clip_children` (broken on iPhone Safari). Called by the engine.

**Called by:** the engine.

**Calls:** [[portrait#_update_mask]].

### _update_mask
`func _update_mask() -> void` · `Scripts/UI/Components/portrait.gd:41`

Points the art's mask shader at the mask's rect, in the art's own pixels.

**Called by:** [[portrait#_ready]] (`portrait.gd:37`), signal `resized` on `$Mask/Art` (connected at `portrait.gd:36`).

**Calls:** [[hall_style#mask_to]].

### show_character
`func show_character(character: GuildCharacter) -> void` · `Scripts/UI/Components/portrait.gd:45`

Tints the ground by role (`HallStyle.ROLE_PORTRAIT_BGS`), and shows the character's own icon (`character.icon`, or the role's default from `ExternalContentContainer.get_character_icon`), greyed when dead.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero to draw | each caller's hero |

**Returns:** nothing.

**Called by:** [[quest_row#_show_party]] (`quest_row.gd:121`), [[party_slot#setup]] (`party_slot.gd:38`), [[pick_row#setup]] (`pick_row.gd:61`), [[member_card#setup]] (`member_card.gd:55`), [[hire_card#setup]] (`hire_card.gd:39`), [[home_row#_fill]] (`home_row.gd:64`), [[equip_pick_row#setup]] (`equip_pick_row.gd:26`), [[pack_tile#setup]] (`pack_tile.gd:52`, on `%Medallion`), [[overlay_gear_confirm#_show_take_off]] (`overlay_gear_confirm.gd:105`), [[overlay_gear_confirm#_show_swap]] (`overlay_gear_confirm.gd:129`), [[screen_character#refresh]] (`screen_character.gd:142`), [[tab_pack#_show_item_bar]] (`tab_pack.gd:191`).

**Calls:** [[hall_style#tint_art]], [[hall_style#is_dead]], [[external_content_container#get_character_icon]].

## Suspected issues
- None found.
