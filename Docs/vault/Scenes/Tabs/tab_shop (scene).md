---
source: Scenes/Tabs/tab_shop.tscn
uid: uid://crrj07shkvbrv
root_type: VBoxContainer
script: "[[tab_shop]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 2fae2e0b444f59e9c76be8bda1b39c0f01fc4ea2
tags: [scene]
---

# tab_shop.tscn

## Purpose
The Shop sub-tab of the Items tab: today's goods in a grid, and a buy bar above the nav. Part of [[Items and Shop]].

## Parent scenes
- **Placed in editor:** [[tab_items (scene)]] at node `TabShop`
- **Instanced at runtime:** none.
- *(Top-level run scene: no)*

## Child scenes
- **Placed in editor:** none
- **Instanced at runtime:** [[shop_tile (scene)]], created by [[tab_shop#_show_goods]] (`tab_shop.gd:80`) through `HallStyle.add_row`

```mermaid
flowchart TD
  P["tab_items (scene)"] --> T["tab_shop (scene)"]
  T -.runtime.-> X["shop_tile (scene)"]
```

## Node tree
- `TabShop` (VBoxContainer), script [[tab_shop]]
  - `%Scroll` (ScrollContainer) → `Body`
    - `Margin/Goods`: `Head/%GoodsTitle`, `Head/%RestockNote` (Label); `%Grid` (GridContainer, runtime tiles)
  - `BuyBar/Banner/Row`: `Text/%ItemName`, `Text/%ItemEffect` (Label); `%BuyButton` (Button, `pressed` → [[tab_shop#_on_buy_pressed]])

## Scripts attached
- Root: [[tab_shop]]. `setup(hall)` is called by [[tab_items#setup]]; `refresh()` by [[tab_items#refresh]].

## Resources used
- `Sprites/Hall Icons/coins.tres`, `Themes/Styles/action_bar.tres`.
