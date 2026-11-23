---
source: Scripts/UI/Tabs/tab_upgrades.gd
class_name: ""
extends: VBoxContainer
scene: "[[tab_upgrades (scene)]]"
systems: ["[[Economy and Wallet]]", "[[Night - Training Hospital Revive]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# tab_upgrades.md

## Purpose
The Upgrades tab (the "Guild" nav button): a folder with two tabs. **Facilities** holds the Training Yard (who drills which stat) and the Hospital (who is in a bed), each a [[home_section (scene)]]; its badge counts hurt heroes not in a bed. **Build** holds the treasury ledger and a building plan ([[upgrade_card (scene)]]) for every working building, affordable ones first; its badge counts upgrades the guild can afford. Buildings that don't do anything yet show as rolled-up scrolls ([[rolled_tag (scene)]]) on one line. Two nodes (Build's `WalletBox` and Tonight's `TonightNote`) are hidden in the scene ("SIMPLIFIED (Info-Chunking)"). Scene: [[tab_upgrades (scene)]]. [[hall_main]] reaches it as `_tabs.upgrades`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `UpgradeCardScene` | const (preload) | `uid://bsodxki3j2b0o`, `Scenes/Rows/Buildings/upgrade_card.tscn`, [[upgrade_card (scene)]]. |
| `RolledTagScene` | const (preload) | `uid://dvyjbi6emukey`, `Scenes/Components/rolled_tag.tscn`, [[rolled_tag (scene)]]. |
| `FOLDER_TAB_HEIGHT` / `FOLDER_TAB_HEIGHT_OPEN` | const | Folder tab heights in px (72 / 80). |
| `SECTION_TONIGHT`, `SECTION_BUILD`, `WALLET`, `STANDING` | const | Text strings. |
| `_tonight_button`, `_build_button`, `_tonight_badge*`, `_build_badge*`, `_scroll` | var | Folder tabs, badges and scroll (`%SegTonight`, `%SegBuild`, ...). |
| `_tonight_box`, `_training_section`, `_hospital_section` | var | `%Tonight`, `%TrainingSection`, `%HospitalSection` ([[home_section]]). |
| `_build_box`, `_wallet`, `_standing`, `_card_list`, `_coming_soon_box`, `_coming_soon_row` | var | `%Build`, `%Wallet`, `%Standing`, `%List`, `%SoonBox`, `%SoonRow`. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Tabs/tab_upgrades.gd:55`

Stores the hall, connects and labels the folder tabs, and sets up the two facility sections.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Side effects:** `pressed` on `%SegTonight` / `%SegBuild` calls [[hall_main#show_upgrades_section]] with `UPGRADES_SECTION_TONIGHT` / `UPGRADES_SECTION_BUILD`; [[home_section#setup]] for the Training Yard (`GuildUpgrades.Building.TRAINING_YARD`) and the Hospital (`Building.HOSPITAL`).

**Called by:** [[hall_main#_ready]] (`hall_main.gd:424`). **Calls:** [[hall_main#show_upgrades_section]], [[home_section#setup]].

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Tabs/tab_upgrades.gd:65`

Sets `%Scroll`'s `scroll_vertical` to 0. **Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1826`). **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Tabs/tab_upgrades.gd:69`

Shows the open section. Facilities refreshes both [[home_section]]s; Build redraws the wallet, building cards and coming-soon row.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1818`).

**Calls:** [[hall_main#affordable_buildings]], [[tab_upgrades#_show_section_buttons]], [[home_section#refresh]], [[tab_upgrades#_show_wallet]], [[tab_upgrades#_show_building_cards]], [[tab_upgrades#_show_coming_soon]].

### _show_section_buttons
`func _show_section_buttons(is_tonight: bool, affordable: Array) -> void` · `Scripts/UI/Tabs/tab_upgrades.gd:86`

The open folder tab is the lighter, taller one; the closed one gets its badge: Facilities shows the count of hurt heroes waiting (when closed and above 0), Build shows the count of affordable buildings (when Facilities is open and any exist).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `is_tonight` | `bool` | Facilities section is open | `hall.upgrades_section == UPGRADES_SECTION_TONIGHT` in [[tab_upgrades#refresh]] |
| `affordable` | `Array` | Buildings the guild can afford | [[hall_main#affordable_buildings]] in [[tab_upgrades#refresh]] |

**Called by:** [[tab_upgrades#refresh]] (`tab_upgrades.gd:72`). **Calls:** [[hall_main#hurt_waiting_count]].

### _show_wallet
`func _show_wallet() -> void` · `Scripts/UI/Tabs/tab_upgrades.gd:101`

Sets the ledger texts from `GameState.gold` and `GameState.standing` (the ledger's `WalletBox` is hidden in the scene).

**Called by:** [[tab_upgrades#refresh]] (`tab_upgrades.gd:80`). **Calls:** none.

### _show_building_cards
`func _show_building_cards(affordable: Array) -> void` · `Scripts/UI/Tabs/tab_upgrades.gd:107`

One plan per implemented building, with affordable ones sorted first.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `affordable` | `Array` | Affordable buildings | passed on from [[tab_upgrades#refresh]] |

**Side effects:** `HallStyle.clear_children(%List)`, then [[upgrade_card#setup]] (`hall, building`) on each added row.

**Called by:** [[tab_upgrades#refresh]] (`tab_upgrades.gd:81`). **Calls:** [[hall_style#clear_children]], [[hall_style#buildings_in_order]], [[guild_upgrades#is_implemented]], [[hall_style#add_row]], [[upgrade_card#setup]].

### _show_coming_soon
`func _show_coming_soon() -> void` · `Scripts/UI/Tabs/tab_upgrades.gd:118`

A rolled-up scroll for each building that isn't implemented yet; the box hides when there are none.

**Called by:** [[tab_upgrades#refresh]] (`tab_upgrades.gd:82`). **Calls:** [[hall_style#clear_children]], [[hall_style#buildings_in_order]], [[guild_upgrades#is_implemented]], [[hall_style#add_row]], [[guild_upgrades#get_building_name]].

## Suspected issues
- None found.
