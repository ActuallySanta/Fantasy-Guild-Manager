---
source: Scenes/Rows/Day End/beat_row.tscn
uid: uid://nm3rjurnk3x2
root_type: HBoxContainer
script: "[[beat_row]]"
systems: ["[[Quest Resolution and Injuries]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# beat_row.tscn

## Purpose
One line of a quest's story inside a Day Report letter: a small icon and a rich-text line.

## Parent scenes
- **Placed in editor:** none.
- **Instanced at runtime:** by [[report_entry#_build_story_beats]] (`report_entry.gd:332`), which hands the preloaded scene to `HallStyle.add_row`. The parent scene is [[report_entry (scene)]].

## Child scenes
- **Placed in editor:** none.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  P["report_entry (scene)"] -.runtime.-> T["beat_row (scene)"]
```

## Node tree
- `BeatRow` (HBoxContainer), script [[beat_row]]
  - `Icon` (TextureRect): found with `$Icon`, not a `%` node
  - `Text` (RichTextLabel): found with `$Text`, not a `%` node

## Scripts attached
- Root: [[beat_row]]. `setup(icon_name, icon_tint, bbcode)`.
- Other nodes: none.

## Resources used
- Texture `Sprites/Hall Icons/scroll.tres`.
