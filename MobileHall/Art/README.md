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

### Icons: `Art/Icons`

Line icons, **white** so the UI can tint them (ink on paper, cream on wood). Keep your
replacements white on transparent and they'll be tinted the same way. The table that maps
names to files is `ICONS` in `Scripts/hall_style.gd`; add a row there to add an icon.
Buildings pick their icon in `BUILDINGS` in the same file.

## Fonts: `Art/Fonts`

| Wrapper | File now | Used for |
|---|---|---|
| `font_title.tres` | Pirata One | Blackletter titles, names, big numbers, gold / wood buttons |
| `font_body.tres` | Alegreya (weight 450) | Body text |
| `font_bold.tres` | Alegreya (weight 700) | Nav tabs, paper buttons, bold story words |
| `font_caps.tres` | Alegreya (weight 800, wider spacing) | Small caps labels (TREASURY LEDGER, NAME...) |
| `font_italic.tres` | Alegreya Italic | Hints and asides |

Pirata One and Alegreya are under the SIL Open Font License (`OFL-*.txt`), so they're
free to ship with the game.

## Things drawn without art

A few simple shapes are plain `StyleBoxFlat`s: the header and nav bar, the day tile,
badges, the gear button, folder tabs, outline boxes and pills, the toast. To give one
of them art, open its file in `MobileHall/Styles`, choose *New StyleBoxTexture* in the
inspector, and set its texture and margins. Every node using it updates.
