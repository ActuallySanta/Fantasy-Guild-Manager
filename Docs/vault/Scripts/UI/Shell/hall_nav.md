---
source: Scripts/UI/Shell/hall_nav.gd
class_name: HallNav
extends: PanelContainer
scene: "[[hall_nav (scene)]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_nav.gd

## Purpose
The bottom tab bar (Quests / Members / Guild / Shop), always visible. The open tab is parchment (`NavTabActive`) and taller; the others are dark wood (`NavTab`). Each tab can show a badge and can be locked by the tutorial. Button ids match `HallMain.TAB_IDS` (`Nav_<id>` unique names in [[hall_nav (scene)]]). It is a view: it reads queries on [[hall_main]] and the only action it triggers is `open_tab`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `NAV_HEIGHT` | const | Minimum height of a closed tab button (100 px). |
| `NAV_HEIGHT_OPEN` | const | Height of the open tab (114 px). |
| `BADGE_POP` | const | Scale a badge pops to when its text changes (1 = no pop). |
| `TAB_FONT_SIZE` / `BADGE_FONT_SIZE` | const | Tab label and badge font size in design px (26), scaled by [[hall_font_scale]]. |
| `MAX_FONT_FACTOR` | const | Most the font scale may grow those sizes (1.5), because four tabs share one row and can't wrap. |
| `BADGE_HIRE_FIRST` | const | Badge text `"!"` on Guild when the roster is empty and someone can be hired. |
| `BADGE_NEW_RECRUITS` | const | Format `"%d new"` for unseen recruits. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_shown_badges` | var | Last badge text per tab id, to pop only on change. |
| `_shown_locked` | var | Last applied locked state per tab id. |
| `_labels` | var | Each button's label from the scene, restored when its tab unlocks. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Shell/hall_nav.gd:48`

Stores the hall, remembers each button's label, connects each button and sizes the fonts.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** sets `hall`, fills `_labels`, connects `pressed` on each `Nav_<id>` button to `hall.open_tab.bind(tab_id)` ([[hall_main#open_tab]]), and calls [[hall_font_scale#set_size]] on each button and its `Badge/Text` label.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`, the `view.setup(self)` loop over `[_header, _nav] + tabs + screens + overlays`).

**Calls:** [[hall_nav#button]], [[hall_font_scale#set_size]], [[hall_main#open_tab]].

### button
`func button(tab_id: String) -> Button` · `Scripts/UI/Shell/hall_nav.gd:59`

The nav button for a tab id (one of `HallMain.TAB_IDS`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tab_id` | `String` | Tab id (`board`, `guild`, `upgrades`, `shop`) | loop over `HallMain.TAB_IDS` in [[hall_nav#setup]] and [[hall_nav#refresh]]; the `tab_id` argument of [[hall_main#nav_button]] |

**Returns:** the `Button` found with the unique name `%Nav_<tab_id>`. Used by [[hall_main#nav_button]] (`hall_main.gd:1858`), which hands it to the tutorial coach ([[overlay_tutorial]] at `overlay_tutorial.gd:870`).

**Side effects:** none.

**Called by:** [[hall_nav#setup]] (`hall_nav.gd:51`), [[hall_nav#refresh]] (`hall_nav.gd:67`), [[hall_main#nav_button]] (`hall_main.gd:1858`).

**Calls:** none (`get_node`).

### refresh
`func refresh() -> void` · `Scripts/UI/Shell/hall_nav.gd:63`

Redraws the bar: highlights the open tab, applies lock changes, and sets and pops the badges.

**Returns:** nothing.

**Side effects:** per tab sets `theme_type_variation` (`NavTabActive` / `NavTab`) and `custom_minimum_size.y`; calls [[hall_style#set_locked]] only when the locked state changed (so a refresh never re-enables a button the tutorial disabled); sets the `Badge` visibility and `Badge/Text`; [[hall_fx#pop]] on a badge whose text changed to a non-empty value.

**Called by:** [[hall_main#refresh]] (`hall_main.gd:1794`, `_nav.refresh()`).

**Calls:** [[hall_nav#button]], [[hall_main#is_tab_locked]], [[hall_style#set_locked]], [[hall_nav#_badge_text_for]], [[hall_fx#pop]].

> [!note] How it works
> While the Assign Party screen is open (`hall.active_screen.kind == HallMain.SCREEN_ASSIGN`) the `board` tab is highlighted, because Assign counts as part of Quests.

### _badge_text_for
`func _badge_text_for(tab_id: String) -> String` · `Scripts/UI/Shell/hall_nav.gd:89`

What a tab's badge says (`""` = no badge).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tab_id` | `String` | Tab id | loop variable in [[hall_nav#refresh]] |

**Returns:** `String`. `""` for a locked tab. `board`: [[hall_main#undecided_count]] as text. `guild`: `""` while hiring isn't taught ([[hall_main#is_locked]] with `OverlayTutorial.FEATURE_HIRE`); `"!"` when the roster is empty and [[hall_main#can_hire_anyone]]; otherwise `"N new"` from [[hall_main#unseen_recruit_count]]. `upgrades`: the count of [[hall_main#affordable_buildings]]. Other tabs (`shop`): `""`. Used by [[hall_nav#refresh]] (`hall_nav.gd:78`).

**Side effects:** none.

**Called by:** [[hall_nav#refresh]] (`hall_nav.gd:78`).

**Calls:** [[hall_main#is_tab_locked]], [[hall_main#undecided_count]], [[hall_main#is_locked]], [[hall_main#roster]], [[hall_main#can_hire_anyone]], [[hall_main#unseen_recruit_count]], [[hall_main#affordable_buildings]].

## Suspected issues
- None found.
