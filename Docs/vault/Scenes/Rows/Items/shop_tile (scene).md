---
source: Scenes/Rows/Items/shop_tile.tscn
uid: uid://b25qy8uoil5du
root_type: Button
script: "[[shop_tile]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [scene]
---

# shop_tile.tscn

## Purpose
One item for sale on the Shop's goods grid, drawn as a parchment price tag: seal, name, price, and a SOLD stamp once bought. A Button, so tapping picks the item. Belongs to [[Items and Shop]].

## Parent scenes
- **Placed in editor:** none.
- **Instanced at runtime:** by [[tab_shop#_show_goods]] (`tab_shop.gd:91`), which hands the preloaded scene to `HallStyle.add_row`. The parent scene is [[tab_shop (scene)]].

## Child scenes
- **Placed in editor:** none.
- **Instanced at runtime:** none.

```mermaid
flowchart TD
  P["tab_shop (scene)"] -.runtime.-> T["shop_tile (scene)"]
```

## Node tree
- `ShopTile` (Button), script [[shop_tile]]
  - `Col` (VBoxContainer): layout
    - `%Tag` (PanelContainer) with `%TagText`, `%TagIcon`: the seal
    - `%ItemName` (Label)
    - `%Price` (HBoxContainer) with `%PriceText` (Label) and a coin
    - `%SoldNote` (Label): "Back tomorrow"
  - `%SoldStamp` (PanelContainer): shown for a sold item

## Scripts attached
- Root: [[shop_tile]]. `setup(good, is_selected, on_pick)`.
- Other nodes: none.

## Resources used
- Textures `Sprites/UI Textures/coin.png`, `tag_hole.png`, `Sprites/Item Icons/sword_icon.png`; theme variations `GoodsTag` / `GoodsTagSelected`.
