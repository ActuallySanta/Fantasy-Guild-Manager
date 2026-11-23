---
source: Scripts/UI/Screens/screen_character.gd
class_name: ""
extends: VBoxContainer
scene: "[[screen_character (scene)]]"
systems: ["[[Hiring Characters]]", "[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# screen_character.md

## Purpose
Character details: portrait, health, today's task, all five stats with the Armory, gear and Pluck bonuses shown, gear slots, and the full backstory. Recruits get a Hire button; guild members (living or fallen) get a Release button that opens a confirm sheet saying what releasing costs. Gear: one row per equipped item (Take off) and per empty slot (Equip); Equip opens a pick list of owned items this hero's role can use, and items worn by another hero can be taken from them (rules live in the `ItemShop` autoload). The hero shown is `hall.active_screen.character`, set by [[hall_main#open_character]], which [[member_card#setup]] (`member_card.gd:53`) and [[pick_row#setup]] (`pick_row.gd:59`) connect to their buttons. Scene: [[screen_character (scene)]]. [[hall_main]] reaches it as `_screens[SCREEN_CHARACTER]`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `GearRowScene` | const (preload) | `uid://5qr0450k1huj`, `Scenes/Rows/Items/gear_row.tscn`, [[gear_row (scene)]]. |
| `STAT_CHANGE_INK` | const | Ink a stat number flashes when it changes. |
| `STAT_CHANGE_POP` | const | How big the stat line grows (1.06). |
| `SHOW_NO_INJURIES` | const | `false`: hides "No injuries yet". |
| `SHOW_PLUCK_NOTE` | const | `false`: hides the note explaining how Pluck grows. |
| `SHOW_SLOT_HINT` | const | `false`: hides "Knight gear only" under empty slots. |
| `TEXT_*`, `BUTTON_*` | const | Text strings for the stats, task line, gear and the release sheet. |
| `_scroll`, `_portrait`, `_name`, `_role`, `_health_chip`, `_injuries`, `_task`, `_stat_lines`, `_pluck_note`, `_backstory`, `_gear_heading`, `_gear_lines`, `_gear_note`, `_back_button`, `_hire_button`, `_release_button`, `_release_*` | var | `@onready` nodes by unique name, see [[screen_character (scene)]]. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_is_picking_gear` | var | The Equip pick list is open (view state; closes when another hero is shown). |
| `_gear_character` | var | Hero the gear list was last drawn for. |
| `_stats_character`, `_shown_stat_texts` | var | Whose stats are drawn and each stat line's text, to pop lines that change for the same hero. |
| `_is_confirming_release` | var | The Release sheet is open (view state). |
| `_release_character` | var | Hero the release sheet state belongs to. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Screens/screen_character.gd:112`

Stores the hall, connects the buttons, sets the button texts and styles them.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Side effects:** `pressed` on `%BackButton` calls [[hall_main#close_screen]]; `%HireButton` → [[screen_character#_on_hire_pressed]]; `%ReleaseButton` → [[screen_character#_on_release_pressed]]; `%ReleaseCancelButton` → [[screen_character#_on_release_cancelled]]; `%ReleaseConfirmButton` → [[screen_character#_on_release_confirmed]]; `gui_input` on `%ReleaseDim` → [[screen_character#_on_release_dim_input]]. Styles the buttons with [[hall_style#style_button]].

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`). **Calls:** [[hall_style#style_button]].

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Screens/screen_character.gd:134`

Sets `%Scroll`'s `scroll_vertical` to 0. **Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1851`). **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Screens/screen_character.gd:138`

Redraws the whole screen for the shown hero: portrait, name, role, health chip, injuries, task, stats, gear, backstory, and the Hire / Release buttons (Hire shows only for recruits, disabled when the roster is full, with "Hire · free" or the price from [[character_container#hire_price]]; Release shows for everyone else).

**Side effects:** none besides view nodes.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1843`, while the Character screen is active).

**Calls:** [[screen_character#_shown_character]], [[portrait#show_character]], [[hall_style#role_name]], [[chip#set_health]], [[hall_style#count_text]], [[screen_character#_show_task]], [[screen_character#_show_stats]], [[screen_character#_show_gear]], [[hall_style#clean_backstory]], [[hall_main#is_roster_full]], [[character_container#hire_price]], [[screen_character#_show_release_confirm]].

### _shown_character
`func _shown_character() -> GuildCharacter` · `Scripts/UI/Screens/screen_character.gd:167`

**Returns:** `hall.active_screen.character` (set by [[hall_main#open_character]]). Used by [[screen_character#refresh]] and the hire, release and equip handlers.

**Called by:** [[screen_character#refresh]] (`screen_character.gd:139`), [[screen_character#_on_gear_picked]] (`:315`), [[screen_character#_on_hire_pressed]] (`:319`), [[screen_character#_on_release_confirmed]] (`:360`). **Calls:** none.

### _show_task
`func _show_task(character: GuildCharacter, is_recruit: bool) -> void` · `Scripts/UI/Screens/screen_character.gd:172`

Today's task line: "Former member" (a released hero for hire), "Recruit", "Died on Day N · where" / "Fallen", "In a Hospital bed · healthy in N nights", "Training <stat> tonight (+N)", "Free today", or "#2 Quest title (sent|picked)".

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero shown | [[screen_character#_shown_character]] in [[screen_character#refresh]] |
| `is_recruit` | `bool` | Hero is in `CharacterContainer.hireable_characters` | computed in [[screen_character#refresh]] |

**Called by:** [[screen_character#refresh]] (`screen_character.gd:151`).

**Calls:** [[hall_style#is_dead]], [[hall_main#quest_index_of]], [[guild_upgrades#is_patient]], [[guild_upgrades#get_nights_until_healthy]], [[hall_style#count_text]], [[guild_upgrades#is_training]], [[guild_upgrades#get_training_stat]], [[guild_upgrades#get_training_gain]].

### _show_stats
`func _show_stats(character: GuildCharacter) -> void` · `Scripts/UI/Screens/screen_character.gd:206`

One line per stat: name and base value, then Armory, gear and Pluck bonuses as separate tags ("5 (+1 Armory) (+2 gear)"), in that stat's ink on its paper tint. The Armory, gear and Pluck bonuses apply to the quest stats only (not Pluck itself). The number shown is the stat before any bonus. For the same hero, a changed text pops and flashes the line.

**Parameters**: `character` is the shown hero from [[screen_character#refresh]].

**Side effects:** sets `_stats_character` and `_shown_stat_texts`; [[hall_fx#pop]] and [[hall_fx#flash_text]] on changed lines.

**Called by:** [[screen_character#refresh]] (`screen_character.gd:152`).

**Calls:** [[guild_upgrades#get_stat_bonus]], [[item_shop#get_item_bonus]], [[character_resource#get_pluck_stat_bonus]], [[hall_style#quest_stat_value]], [[hall_style#stat_bonus]], [[hall_style#set_font_color]], [[hall_style#fill_art]], [[hall_fx#pop]], [[hall_fx#flash_text]].

### _show_gear
`func _show_gear(character: GuildCharacter, is_recruit: bool) -> void` · `Scripts/UI/Screens/screen_character.gd:251`

Worn items (Take off), empty slots (Equip / Cancel on the first slot, not for the dead) and, while picking, the owned items that fit this hero's role. Hidden for recruits. The note shows when the hero is dead ("can't use gear anymore") or the pick list is empty.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero shown | [[screen_character#_shown_character]] in [[screen_character#refresh]] |
| `is_recruit` | `bool` | Hero is a recruit | computed in [[screen_character#refresh]] |

**Side effects:** resets `_is_picking_gear` when the hero changes, the hero is dead or no slot is free. Adds [[gear_row (scene)]] rows: `setup(look, text, kind, on_press[, is_choice])` for worn items (press = `hall.unequip_item.bind(item)`) and pick-list items (press = [[screen_character#_on_gear_picked]]); `setup_empty` for free slots (press = [[screen_character#_toggle_gear_picker]]). `hall.pending_fx.gear_in` stamps a row in; `gear_out` fades the freed slot in.

**Called by:** [[screen_character#refresh]] (`screen_character.gd:153`).

**Calls:** [[hall_style#clear_children]], [[hall_style#is_dead]], [[hall_style#role_name]], [[hall_style#add_row]], [[gear_row#setup]], [[gear_row#setup_empty]], [[hall_style#item_look]], [[hall_main#unequip_item]], [[hall_fx#stamp_in]], [[hall_fx#fade_in]], [[item_shop#items_for]].

### _toggle_gear_picker
`func _toggle_gear_picker() -> void` · `Scripts/UI/Screens/screen_character.gd:308`

Flips `_is_picking_gear` and queues a refresh.

**Called by:** the empty slot row's button, passed as `on_press` to [[gear_row#setup_empty]] (`screen_character.gd:282`). **Calls:** [[hall_main#queue_refresh]].

### _on_gear_picked
`func _on_gear_picked(item: StandardItem) -> void` · `Scripts/UI/Screens/screen_character.gd:313`

Closes the pick list and equips the item on the shown hero.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item picked | bound per row in [[screen_character#_show_gear]] (`screen_character.gd:299`) |

**Called by:** the pick-list row's button, passed as `on_press` to [[gear_row#setup]]. **Calls:** [[screen_character#_shown_character]], [[hall_main#equip_item]].

### _on_hire_pressed
`func _on_hire_pressed() -> void` · `Scripts/UI/Screens/screen_character.gd:318`

Hires the shown recruit and closes the screen.

**Called by:** `pressed` on `%HireButton` (`screen_character.gd:115`). **Calls:** [[screen_character#_shown_character]], [[hall_main#hire]], [[hall_main#close_screen]].

### _show_release_confirm
`func _show_release_confirm(character: GuildCharacter, is_recruit: bool) -> void` · `Scripts/UI/Screens/screen_character.gd:325`

The Release confirm sheet: "Release Mira?" plus what it costs (standing, or "gear returns" for the fallen) and, if the hero is in a party, which quest they'll leave. A different hero or a recruit never opens with the sheet already up.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero shown | [[screen_character#refresh]] |
| `is_recruit` | `bool` | Hero is a recruit | [[screen_character#refresh]] |

**Side effects:** resets `_release_character`, `_is_confirming_release` on a hero change; sets `%ReleaseConfirm` visibility and texts.

**Called by:** [[screen_character#refresh]] (`screen_character.gd:163`). **Calls:** [[hall_main#release_standing_cost]], [[hall_main#quest_index_of]].

### _on_release_pressed
`func _on_release_pressed() -> void` · `Scripts/UI/Screens/screen_character.gd:346`

Footer Release: opens the confirm sheet (nothing is released yet) and queues a refresh.

**Called by:** `pressed` on `%ReleaseButton` (`screen_character.gd:116`). **Calls:** [[hall_main#queue_refresh]].

### _on_release_cancelled
`func _on_release_cancelled() -> void` · `Scripts/UI/Screens/screen_character.gd:351`

Closes the sheet and queues a refresh.

**Called by:** `pressed` on `%ReleaseCancelButton` (`screen_character.gd:117`), [[screen_character#_on_release_dim_input]] (`:367`). **Calls:** [[hall_main#queue_refresh]].

### _on_release_confirmed
`func _on_release_confirmed() -> void` · `Scripts/UI/Screens/screen_character.gd:358`

Confirmed: the hall releases the hero, then the screen goes back to where it was opened from.

**Called by:** `pressed` on `%ReleaseConfirmButton` (`screen_character.gd:118`). **Calls:** [[screen_character#_shown_character]], [[hall_main#release]], [[hall_main#close_screen]].

### _on_release_dim_input
`func _on_release_dim_input(event: InputEvent) -> void` · `Scripts/UI/Screens/screen_character.gd:365`

Tapping the dimmed background cancels, like the End Day sheet (any pressed `InputEventMouseButton`).

**Parameters**: `event` from `gui_input` on `%ReleaseDim`.

**Called by:** `gui_input` on `%ReleaseDim` (`screen_character.gd:119`). **Calls:** [[screen_character#_on_release_cancelled]].

## Suspected issues
- `GuildCharacter.get_pluck_stat_bonus(_stat)` names its parameter with a leading underscore although it uses it (style only, `character_resource.gd:267`).
- `_show_gear` sets `_gear_note.visible = not is_recruit` at the top, then overwrites it at `screen_character.gd:301` (harmless: recruits return early and the note stays hidden).
