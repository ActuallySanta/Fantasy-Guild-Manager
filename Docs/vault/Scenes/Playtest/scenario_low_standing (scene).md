---
source: Scenes/Playtest/scenario_low_standing.tscn
uid: uid://c51w3xnnjggl4
root_type: Control
script: "[[playtest_scenario]]"
systems: ["[[Playtest Bridge]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [scene]
---

# scenario_low_standing.tscn

## Purpose
Playtest scenario: starts the hall on day 8 at rock-bottom standing (-10, so nobody new shows up For Hire) with 120 gold and two hurt heroes (injuries 2, 3); toast "Standing is at rock bottom. Two hurt adventurers left.". System: [[Playtest Bridge]].

## Parent scenes
- *(Top-level run scene: none. It lives under `Scenes/Playtest/` and is run directly with F6.)*

## Child scenes
- **Placed in editor:** [[hall_main (scene)]] at node `HallMain`
- **Instanced at runtime:** none

```mermaid
flowchart TD
  T["scenario_low_standing (scene)"] --> H["hall_main (scene)"]
```

## Node tree
- `ScenarioLowStanding` (Control, full rect), script [[playtest_scenario]]
  - `HallMain`: instance of [[hall_main (scene)]]

## Scripts attached
- Root: [[playtest_scenario]]. These are the script defaults: start_day 8, start_standing -10, start_gold 120, member_injuries [2, 3]; intro_toast set.
- Other nodes: none

## Resources used
- None beyond the two ext_resources (the script and `hall_main.tscn`).
