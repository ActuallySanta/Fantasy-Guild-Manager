# Mobile Hall art

Every image and font the Mobile Hall UI draws lives in this folder. The ones here now are
**placeholders** (generated parchment, wood, seals and simple line icons) so you can swap
them for your own art one piece at a time. Nothing in the scripts needs to change.

## The three ways to reskin

| You want to change... | Do this |
|---|---|
| **An image** (wood, paper, seal, coin, icon...) | Overwrite the file in `Art/Textures` or `Art/Icons` with your own art, **same name**. Godot re-imports it and every screen picks it up. |
| **A font** | Drop your `.ttf`/`.otf` in `Art/Fonts`, open the matching `font_*.tres` and point its *Base Font* at it. |
| **A colour, font size or which look a thing uses** | Open `MobileHall/hall_theme.tres` in the Theme editor. Each look (`TitleLabel`, `PaperCard`, `GoldButton`...) is a type variation there. Ink colours that change with game state are at the top of `Scripts/hall_style.gd`. |

## Images

### Surfaces (9-slice): `Art/Textures`, used through `MobileHall/Styles/*.tres`

These stretch to any size. The outer *margin* (in pixels) stays crisp and the middle
tiles, so keep borders and torn edges inside the margin. If your art has a different
border width, open the matching `Styles/*.tres` and change its *Texture Margin*.

| File | Used for | Margin (px) | Style file |
|---|---|---|---|
| `wood.png` | Background behind everything (tiles) | none | set on `Bg` in `hall_main.tscn` and `overlay_report.tscn` |
| `paper.png` | Parchment cards: picker rows, letters, sheets | 12 | `paper_card.tres`, `sheet.tres` |
| `paper_grid.png` | Building plans on the Upgrades tab | 10 | `paper_grid.tres` |
| `paper_ledger.png` | Treasury ledger | 10 | `paper_ledger.tres` |
| `paper_note.png` | Pinned "Today" notes on the Board | 12 | `paper_note.tres` |
| `torn.png` | Torn strips: action banner, Bone Drake note, report totals (top/bottom edges are torn) | 16 top / bottom | `torn_paper.tres`, `torn_note.tres` |
| `scroll_body_h.png` | Board quest rows, between the rollers (border top/bottom only) | 8 top / bottom | `scroll_body_h.tres` |
| `scroll_body_v.png` | The quest writ on Assign Party (border left/right only) | 8 left / right | `scroll_body_v.tres` |
| `roller_v.png` / `roller_h.png` | Scroll rollers (NinePatchRect, ends stay crisp) | 22 at the ends | set on the `Roller*` nodes |
| `folder_body.png` | Guild tab folder with the dashed edge | 20 | `folder_body.tres` |
| `btn_gold.png`, `btn_gold_down.png` | Gold buttons (For Hire, Build, Barracks) | 16 | `btn_gold*.tres` |
| `btn_wood.png`, `btn_wood_down.png` | Dark wood buttons (Deny, Board, Open the doors) | 16 | `btn_wood*.tres` |
| `btn_paper.png`, `btn_paper_down.png`, `btn_disabled.png` | Paper buttons, the seal button, disabled buttons | 16 | `btn_paper*.tres`, `btn_seal*.tres`, `btn_disabled.tres` |
| `nav_tile.png`, `nav_tile_active.png` | Bottom tabs (idle / open) | 22 | `nav_tile*.tres` |
| `strip_tab.png` | Little scrolls in Assign Party's quest strip | 26 left / right | `quest_tab.tres` |
| `stamp.png` | "Success" / "Failed" stamp (white, tinted in code) | 16 | `stamp.tres` |
| `odds_track.png`, `odds_fill.png`, `odds_over.png` | Success-chance bar: track, hatched fill (white, tinted by odds), border + ticks on top | 6 | `Scenes/Components/odds_bar.tscn` |
| `speech_bubble.png` | The shopkeeper's speech bubble (the tail sits in the bottom-left corner) | 96 left, 30 top / right, 40 bottom | `speech_bubble.tres` |
| `shop_sign.png` | The shop's hanging name sign (the ropes sit in the top corners) | 56 left / right, 44 top, 14 bottom | `shop_sign.tres` |
| `goods_tag.png`, `goods_tag_selected.png` | Shop goods as price tags (normal / picked) | 34 | `goods_tag*.tres` |
| `awning.png` | Striped awning over the shopkeeper (tiles sideways) | none | set on `Awning` in `tab_shop.tscn` |

### Ornaments (drawn as-is, any size): `Art/Textures`

| File | Used for |
|---|---|
| `wax_seal.png` | Seal on "Seal & send" and "Hire · free" |
| `coin.png` | Gold in the header |
| `shield.png` | Standing in the header (the number is drawn on top) |
| `disc.png` | Quest-type seals (SCT, ESC...). **White**, tinted with the quest type's colour |
| `pin.png`, `pin_red.png` | Pins on notes and plans, the red pin on portraits |
| `ink_circle.png` | Hand-drawn circle around the odds and the stat total. **White**, tinted |
| `portrait_oval_mask.png`, `portrait_oval_frame.png` | Portrait shape (the mask's alpha clips the character art) and its frame |
| `portrait_round_mask.png`, `portrait_round_frame.png` | Same, round, for the small portraits on the Board |
| `rolled_scroll.png` | "Coming soon" buildings on the Upgrades tab |
| `connector.png` | Dashed line above the report's big button |
| `dash.png` | Dashed underlines (tiles) |
| `box_on.png`, `box_off.png` | "Show busy" checkbox |
| `tag_hole.png` | The string hole at the top of each shop price tag |
| `Sprites/Shop/shopBackground.png`, `Sprites/Shop/shopkeeper.png` (outside this folder) | Grizzle on the Shop tab: the shop behind him (`Background` in `tab_shop.tscn`) and Grizzle on top (`ShopKeeper`) |

### Icons: `Art/Icons`

Pixel-art icons, **16 x 16 PNGs** (edit them in Aseprite at that size). They're **white**
(with grey shading and a dark outline) so the UI can tint them: ink on paper, cream on wood.
Keep your replacements white on transparent and they'll be tinted the same way.

Each `name.png` has a `name.tres` beside it. That's what the scenes and code use: a
`PixelIcon` (`Scripts/pixel_icon.gd`) that draws the PNG 6x bigger with sharp pixels, so a
16 x 16 icon is laid out like the old 96 x 96 ones and never blurs. **Edit the `.png`**; the
`.tres` picks it up. To add an icon: draw `name.png`, duplicate any icon's `.tres` in the
FileSystem dock as `name.tres` and set its *Source* to the new PNG, then add a row to
`ICON_FILES` in `Scripts/hall_style.gd`. Buildings pick their icon in `BUILDING_ICONS` in
the same file. `stall` is the Shop tab.

## Fonts: `Art/Fonts`

| Wrapper | File now | Used for |
|---|---|---|
| `font_title.tres` | Pirata One | Blackletter headings only (`HeadingLabel` / `HeadingLight`: screen and overlay titles, the Day number, stamps, badges) |
| `font_body.tres` | Alegreya (weight 450) | Body text |
| `font_bold.tres` | Alegreya (weight 700) | `TitleLabel` / `TitleLight` (names, quest titles, numbers), every button, nav tabs, bold story words |
| `font_caps.tres` | Alegreya (weight 800, wider spacing) | Small caps labels (RECRUITS, POW...) |

Blackletter is hard to read at small sizes and in sentences, so keep it to short headings.
Anything a player has to read or compare uses `TitleLabel` (bold Alegreya).
| `font_italic.tres` | Alegreya Italic | Hints and asides |

Pirata One and Alegreya are under the SIL Open Font License (`OFL-*.txt`), so they're
free to ship with the game.

## Things drawn without art

A few simple shapes are plain `StyleBoxFlat`s: the header and nav bar, the day tile,
badges, the gear button, folder tabs, outline boxes and pills, the toast. To give one
of them art, open its file in `MobileHall/Styles`, choose *New StyleBoxTexture* in the
inspector, and set its texture and margins. Every node using it updates.
