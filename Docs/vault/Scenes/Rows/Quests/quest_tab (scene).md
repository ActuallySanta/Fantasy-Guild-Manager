---
source: Scenes/Rows/Quests/quest_tab.tscn
uid: uid://cp5084mci60mt
root_type: VBoxContainer
script: "[[quest_tab]]"
systems: ["[[Party Drafting and Assignment]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# quest_tab.tscn

## Purpose
One quest in Assign Party's strip: a small rolled scroll with the quest number and a SENT / NO / type tag under it. Tapping it switches Assign Party to that quest. Belongs to [[Party Drafting and Assignment]].

## Parent scenes
- **Placed in editor:** none.
- **Instanced at runtime:** by [[screen_assign#_show_quest_tabs]] (`screen_assign.gd:211`), which hands the preloaded scene to `HallStyle.add_row`. The parent scene is [[screen_assign (scene)]].

## Child scenes
- **Placed in editor:** none.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  P["screen_assign (scene)"] -.runtime.-> T["quest_tab (scene)"]
```

## Node tree
- `QuestTab` (VBoxContainer), script [[quest_tab]]
  - `%Tab` (Button): `pressed` goes to `hall.open_assign` (connected in [[quest_tab#setup]])
    - `%Band` (Panel): tinted by state (StyleBox `quest_band.tres`)
    - `%Mark` (Label): the quest number
  - `%Tag` (Label): type tag, SENT or NO

## Scripts attached
- Root: [[quest_tab]]. `setup(hall, quest_index, is_current)`.
- Other nodes: none.

## Resources used
- StyleBox `Themes/Styles/quest_band.tres`.
