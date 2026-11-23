---
source: Scenes/Rows/Items/equip_pick_row.tscn
uid: uid://tlc3k0theskd
root_type: PanelContainer
script: "[[equip_pick_row]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# equip_pick_row.tscn

## Purpose
One hero in the Equip picker: portrait, name and role, slot usage, the stat change the item would make, and an Equip / Swap button. Belongs to [[Items and Shop]].

## Parent scenes
- **Placed in editor:** none.
- **Instanced at runtime:** by [[overlay_equip_picker#refresh]] (`overlay_equip_picker.gd:80`), which hands the preloaded scene to `HallStyle.add_row`. The parent scene is [[overlay_equip_picker (scene)]].

## Child scenes
- **Placed in editor:** [[portrait (scene)]] at `Row/Portrait`.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  P["overlay_equip_picker (scene)"] -.runtime.-> T["equip_pick_row (scene)"]
  T --> A["portrait (scene)"]
```

## Node tree
- `EquipPickRow` (PanelContainer), script [[equip_pick_row]]
  - `Row` (HBoxContainer): layout
    - `%Portrait` ([[portrait]])
    - `Text`: `%HeroName`, `%Slots`, `%Change` (Labels)
    - `%ActionButton` (Button): `pressed` goes to the callable passed to [[equip_pick_row#setup]]

## Scripts attached
- Root: [[equip_pick_row]]. `setup(character, change, button_text, button_kind, on_press)`.
- Other nodes: [[portrait]].

## Resources used
- None beyond the child scene.
