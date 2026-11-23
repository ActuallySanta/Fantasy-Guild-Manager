---
source: Scenes/Rows/Buildings/home_heading.tscn
uid: uid://bve0dglxrk3x4
root_type: Label
script: ""
systems: ["[[Night - Training Hospital Revive]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# home_heading.tscn

## Purpose
A small caps heading label ("PICK A HERO", "IN A BED", "NEEDS CARE", "FALLEN") between groups of rows. It has no script.

## Parent scenes
- **Placed in editor:** none.
- **Instanced at runtime:** by [[home_section#_add_heading]] (`home_section.gd:73`), which hands the preloaded scene to `HallStyle.add_row` and sets `.text`. The parent scene is [[home_section (scene)]]. Also by [[tab_guild#_show_roster]] (`tab_guild.gd:159`), where it heads the fallen heroes. The parent scene there is [[tab_guild (scene)]].

## Child scenes
- **Placed in editor:** none.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  A["home_section (scene)"] -.runtime.-> T["home_heading (scene)"]
  B["tab_guild (scene)"] -.runtime.-> T
```

## Node tree
- `HomeHeading` (Label, `CapsLabel` variation, uppercase, autowrap): the whole scene.

## Scripts attached
- None.

## Resources used
- None.
