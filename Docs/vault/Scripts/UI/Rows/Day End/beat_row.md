---
source: Scripts/UI/Rows/Day End/beat_row.gd
class_name: ""
extends: HBoxContainer
scene: "[[beat_row (scene)]]"
systems: ["[[Quest Resolution and Injuries]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# beat_row.gd

## Purpose
One line of a quest's story in the Day Report: an icon and a BBCode text line. Scene: [[beat_row (scene)]]. Created by [[report_entry#_build_story_beats]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `_icon` | onready | `$Icon` (TextureRect). Not a `%` node. |
| `_text` | onready | `$Text` (RichTextLabel). Not a `%` node. |

## Functions

### setup
`func setup(icon_name: String, icon_tint: Color, bbcode: String) -> void` · `Scripts/UI/Rows/Day End/beat_row.gd:13`

Sets the icon (from `HallStyle` `ICON_FILES`), its ink and the story line.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `icon_name` | `String` | A name from `HallStyle.ICON_FILES` | `BEAT_ICON_STORY` or `_icon_for_beat(plain_text)` in [[report_entry#_build_story_beats]] |
| `icon_tint` | `Color` | The icon's ink | `HallStyle.STORY_INK` for story lines, else `HallStyle.TEXT_SOFT` |
| `bbcode` | `String` | The story line, already recoloured with `STORY_RECOLORS` | `beat_text` in [[report_entry#_build_story_beats]] |

**Returns:** nothing.

**Called by:** [[report_entry#_build_story_beats]] (`report_entry.gd:334` for written-story lines, `report_entry.gd:336` for the rest).

**Calls:** [[hall_style#icon_texture]].

## Suspected issues
- None found.
