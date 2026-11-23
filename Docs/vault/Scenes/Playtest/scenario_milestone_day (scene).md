---
source: Scenes/Playtest/scenario_milestone_day.tscn
uid: uid://ch6fp6uvcpsin
root_type: Control
script: "[[playtest_scenario]]"
systems: ["[[Playtest Bridge]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [scene]
---

# scenario_milestone_day.tscn

## Purpose
Playtest scenario: starts the hall on day 10 (the Bone Drake boss quest) with 400 gold, standing 5 and two hurt heroes (injuries 1, 2); toast "Day 10. The Bone Drake is attacking!". System: [[Playtest Bridge]].

## Parent scenes
- *(Top-level run scene: none. It lives under `Scenes/Playtest/` and is run directly with F6.)*

## Child scenes
- **Placed in editor:** [[hall_main (scene)]] at node `HallMain`
- **Instanced at runtime:** none

```mermaid
flowchart TD
  T["scenario_milestone_day (scene)"] --> H["hall_main (scene)"]
```

## Node tree
- `ScenarioMilestoneDay` (Control, full rect), script [[playtest_scenario]]
  - `HallMain`: instance of [[hall_main (scene)]]

## Scripts attached
- Root: [[playtest_scenario]]. start_day 10, start_standing 5, start_gold 400, member_injuries [1, 2], intro_toast set.
- Other nodes: none

## Resources used
- None beyond the two ext_resources (the script and `hall_main.tscn`).
