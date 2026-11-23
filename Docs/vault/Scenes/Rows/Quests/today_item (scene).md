---
source: Scenes/Rows/Quests/today_item.tscn
uid: uid://edhkrbpcjf3j
root_type: PanelContainer
script: "[[today_item]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# today_item.tscn

## Purpose
One pinned paper note in the Board's "Today" checklist: a pin, a title and a value. Tapping it jumps to the matching tab or quest. Belongs to [[UI Architecture and Refresh]].

## Parent scenes
- **Placed in editor:** [[tab_board (scene)]] at `Margin/Col/Today/TodayRecruits`, `Margin/Col/Today/TodayQuests`, `Margin/Col/Today/TodayUpgrades`.
- **Instanced at runtime:** none.

## Child scenes
- **Placed in editor:** none.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  P["tab_board (scene)"] --> T["today_item (scene) x3"]
```

## Node tree
- `TodayItem` (PanelContainer), script [[today_item]]
  - `Col` (VBoxContainer): layout
    - `PinBox/Pin` (TextureRect): the pin art
    - `%Title` (Label), `%Value` (Label): set in [[today_item#set_item]]

## Scripts attached
- Root: [[today_item]]. `set_item(title, value, icon_name, look)`.
- Other nodes: none.

## Resources used
- Texture `Sprites/UI Textures/pin.png`.
