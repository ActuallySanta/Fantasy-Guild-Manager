---
source: Scenes/Rows/Day End/plan_row.tscn
uid: uid://c2ca1up8vmmc6
root_type: HBoxContainer
script: "[[plan_row]]"
systems: ["[[Day Cycle]]", "[[Success Chance]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# plan_row.tscn

## Purpose
One party going out tonight, listed on the End Day check: type seal, quest title, party names and the odds.

## Parent scenes
- **Placed in editor:** none.
- **Instanced at runtime:** by [[overlay_end_day#_show_tonights_plan]] (`overlay_end_day.gd:77`), which hands the preloaded scene to `HallStyle.add_row`. The parent scene is [[overlay_end_day (scene)]].

## Child scenes
- **Placed in editor:** none.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  P["overlay_end_day (scene)"] -.runtime.-> T["plan_row (scene)"]
```

## Node tree
- `PlanRow` (HBoxContainer), script [[plan_row]]
  - `%TagBox` (PanelContainer) with `%Tag` (Label), `%TagIcon` (TextureRect): the type seal
  - `Info`: `%Title`, `%PartyNames` (Labels)
  - `%Odds` (Label): the success chance

## Scripts attached
- Root: [[plan_row]]. `setup(hall, entry)`.
- Other nodes: none.

## Resources used
- Texture `Sprites/Hall Icons/gate.tres`.
