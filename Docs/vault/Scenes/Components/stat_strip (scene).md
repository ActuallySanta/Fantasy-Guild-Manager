---
source: Scenes/Components/stat_strip.tscn
uid: uid://eyqpbr188oi2
root_type: HFlowContainer
script: "[[stat_strip]]"
systems: ["[[Success Chance]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# stat_strip.tscn

## Purpose
A wrapping row of chips: a health chip, an "At risk" chip and one chip per stat (`Stat0` to `Stat4`, in `HallStyle.STATS` order). Used on roster cards and in the Assign Party picker.

## Parent scenes
- **Placed in editor:** [[member_card (scene)]] at `Row/Info/Stats`; [[pick_row (scene)]] at `Row/Info/Stats`.
- **Instanced at runtime:** none.

## Child scenes
- **Placed in editor:** [[chip (scene)]] at `Health`, `AtRisk`, `Stat0`, `Stat1`, `Stat2`, `Stat3`, `Stat4`.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  A["member_card (scene)"] --> T["stat_strip (scene)"]
  B["pick_row (scene)"] --> T
  T --> C["chip (scene) x7"]
```

## Node tree
- `StatStrip` (HFlowContainer), script [[stat_strip]]
  - `%Health` ([[chip]]): set in [[stat_strip#show_health]]
  - `%AtRisk` ([[chip]]): the "At risk" tag
  - `Stat0` to `Stat4` ([[chip]]): found by name in [[stat_strip#show_stats]]

## Scripts attached
- Root: [[stat_strip]].
- Other nodes: [[chip]] on every chip.

## Resources used
- None beyond the chip scene.
