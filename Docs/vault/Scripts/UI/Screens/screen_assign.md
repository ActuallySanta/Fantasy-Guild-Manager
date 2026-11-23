---
source: Scripts/UI/Screens/screen_assign.gd
class_name: ""
extends: VBoxContainer
scene: "[[screen_assign (scene)]]"
systems: ["[[Party Drafting and Assignment]]", "[[Success Chance]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# screen_assign.gd

## Purpose
Assign Party: one quest at a time, with every other quest one tap away. Top to bottom: a strip (back to the Quests tab, then one little scroll per quest), the "writ" (the quest as an unrolled scroll with type, title, reward, party size, favored stat, the pinned party and the live success chance), the picker (every adventurer, best fit first; pinning anyone sends the quest) and a footer (Deny or Recall, and Back to Quests; Quests / Reconsider once denied). It is a screen that covers the tabs: [[hall_main]] shows it when `active_screen.kind == SCREEN_ASSIGN` (`_screens[SCREEN_ASSIGN]`). Scene: [[screen_assign (scene)]]. See [[Party Drafting and Assignment]] and [[Success Chance]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `QuestTabScene` | const (preload) | `uid://cp5084mci60mt`, `Scenes/Rows/Quests/quest_tab.tscn`, [[quest_tab (scene)]]. |
| `PartySlotScene` | const (preload) | `uid://cisymsmond1`, `Scenes/Rows/Quests/party_slot.tscn`, [[party_slot (scene)]]. |
| `PickRowScene` | const (preload) | `uid://cfnuyteanwwp5`, `Scenes/Rows/Quests/pick_row.tscn`, [[pick_row (scene)]]. |
| `ODDS_ROLL_SECONDS` | const | Seconds the odds number and bar take to move to a new chance (0.4). |
| `ODDS_POP` | const | Scale the odds circle pops to on a change (1.2). |
| `ODDS_DELTA_FONT_SIZE`, `ODDS_UP_INK`, `ODDS_DOWN_INK` | const | The floating "+12%" / "-12%" text (32 px, green / red). |
| `DENY_SHAKE` | const | Pixels the writ shakes when denied (12). |
| `WRIT_STAMP_AT` / `WRIT_STAMP_FONT_SIZE` / `WRIT_STAMP_TILT` | const | SENT stamp centre (fraction of the card size), text size (60) and tilt (radians, -0.16). |
| `ODDS_STACK_SIZE` | const | Odds circle box (design px, 210x100), grown with the font scale. |
| `PICKER_SCROLL_SECONDS` / `PICKER_SCROLL_GAP` | const | Seconds (0.35) and gap in design px (12) for scrolling to the picker. |
| `LEFT_BUTTON_MIN_WIDTH` | const | Footer left button's normal minimum width (200 design px). |
| `HIDE_BUSY_OPTION` | const | `false`: busy adventurers are always listed (at the bottom) and the "Show busy" toggle and note are hidden. |
| `TEXT_*`, `PICK_*`, `BUTTON_*`, `NO_ROSTER`, `DENY_COST_ROOM` | const | Text strings and the room kept on Deny's right for the shield (64 px). |
| `_back_button`, `_quest_tabs`, `_scroll`, `_type_label`, `_title`, `_gold_chip`, `_standing_chip`, `_party_size_chip`, `_favored_chip`, `_quest_card`, `_party_box`, `_party_seats`, `_empty_seats`, `_odds_*`, `_pick_*`, `_show_busy_toggle`, `_all_busy_label`, `_no_roster_box`, `_hire_button`, `_left_button`, `_deny_cost*`, `_right_button`, `_move_confirm` | var | `@onready` nodes by unique name (`_quest_card` by path `$Scroll/Margin/Col/Writ/WritMargin/QuestCard`), see [[screen_assign (scene)]]. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_odds_quest_index`, `_shown_chance` | var | The quest and chance the odds were last drawn for (-1 = not drawn yet), to animate a change only on the same quest. |
| `_writ_stamp`, `_writ_stamp_quest` | var | The SENT ink on the quest card (null = none) and which quest it's for. |
| `_hire_label` | var | The No Roster Hire button's scene label, restored once hiring unlocks. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Screens/screen_assign.gd:145`

Stores the hall, wires the buttons, and sets up the move-confirm overlay.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Side effects:** `pressed` on `%BackButton` calls [[hall_main#close_screen]]; `pressed` on `%HireButton` calls [[hall_main#open_tab]] (`"guild"`, `GUILD_SECTION_HIRE`); `pressed` on `%LeftButton` / `%RightButton` runs [[screen_assign#_on_left_button_pressed]] / [[screen_assign#_on_right_button_pressed]]; `toggled` on `%BusyToggle` calls [[hall_main#set_show_busy_adventurers]]; calls [[overlay_move_confirm#setup]].

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`). **Calls:** [[screen_assign#_make_room_for_deny_cost]], [[overlay_move_confirm#setup]].

### _make_room_for_deny_cost
`func _make_room_for_deny_cost() -> void` · `Scripts/UI/Screens/screen_assign.gd:161`

The Deny button's shield sits on its right edge: pads the right content margin of every stylebox look (normal, hover, pressed, disabled, focus) of `%LeftButton` by `DENY_COST_ROOM` so the text never runs under it.

**Called by:** [[screen_assign#setup]] (`screen_assign.gd:156`). **Calls:** none.

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Screens/screen_assign.gd:171`

Sets `%Scroll`'s `scroll_vertical` to 0. **Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1851`). **Calls:** none.

### scroll_to_picker
`func scroll_to_picker() -> void` · `Scripts/UI/Screens/screen_assign.gd:178`

An empty seat's tap: slides the screen down so the "Your adventurers" heading sits near the top, `PICKER_SCROLL_GAP` below it (snaps with Reduce Motion on). Target is clamped to the scroll's range.

**Side effects:** a cubic ease-out tween on `scroll_vertical` over `PICKER_SCROLL_SECONDS`.

**Called by:** `pressed` on an empty [[party_slot (scene)]] seat, through the `on_empty_pressed` callable passed at `screen_assign.gd:249` and connected in [[party_slot#setup]] (`party_slot.gd:60`). **Calls:** [[hall_font_scale#px]].

### refresh
`func refresh() -> void` · `Scripts/UI/Screens/screen_assign.gd:189`

Redraws the whole screen from `hall.current_quest_entry()`. Returns early (after sizing the odds stack) when there is no current entry.

**Side effects:** sets `%Circle`'s parent minimum size with [[hall_font_scale#px_vec]] (here, not in `setup`, so a Text size change follows).

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1843`, while the Assign screen is active).

**Calls:** [[hall_main#current_quest_entry]], [[screen_assign#_show_quest_tabs]], [[screen_assign#_show_quest_card]], [[screen_assign#_show_writ_stamp]], [[screen_assign#_show_party]], [[screen_assign#_show_picker]], [[screen_assign#_show_footer]].

### _show_quest_tabs
`func _show_quest_tabs() -> void` · `Scripts/UI/Screens/screen_assign.gd:206`

One [[quest_tab (scene)]] per quest, hidden when there's only one quest (milestone day). Marks the one at `hall.active_screen.quest_index` as current.

**Side effects:** clears `%QuestTabs`; [[quest_tab#setup]] (`hall, quest_index, is_current`) on each new row.

**Called by:** [[screen_assign#refresh]] (`screen_assign.gd:195`). **Calls:** [[hall_style#clear_children]], [[hall_style#add_row]], [[quest_tab#setup]].

### _show_quest_card
`func _show_quest_card(entry: Dictionary) -> void` · `Scripts/UI/Screens/screen_assign.gd:216`

Fills the writ: type and rank, title, and the chips (gold reward, standing on a win / loss, party size, favored stat).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | The quest entry (has `quest`, `state`, `party`) | `hall.current_quest_entry()` in [[screen_assign#refresh]] |

**Called by:** [[screen_assign#refresh]] (`screen_assign.gd:196`).

**Calls:** [[hall_style#quest_type_info]], [[hall_main#party_size_limit]], [[hall_style#rank_letter]], [[hall_style#set_font_color]], [[chip#set_chip]], [[hall_rules#standing_for_win]], [[hall_rules#standing_for_loss]], [[hall_style#favored_components]], [[hall_style#favored_label]].

### _show_party
`func _show_party(entry: Dictionary) -> void` · `Scripts/UI/Screens/screen_assign.gd:240`

Seats and the party's success chance, circled in its ink. Filled seats stack in the column beside the odds; empty seats share one row under them. The whole party box is hidden for denied quests.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | The quest entry | [[screen_assign#refresh]] |

**Side effects:** one [[party_slot (scene)]] per seat (`setup(hall, entry, seated, scroll_to_picker)`); the seat just vacated fades in when `hall.pending_fx.seat_out`; sets the odds text, caption and colors; calls [[screen_assign#_show_odds_change]].

**Called by:** [[screen_assign#refresh]] (`screen_assign.gd:198`).

**Calls:** [[hall_style#clear_children]], [[hall_main#party_size_limit]], [[hall_style#add_row]], [[party_slot#setup]], [[hall_fx#fade_in]], [[hall_main#success_chance]], [[hall_style#odds_look]], [[screen_assign#_odds_caption]], [[hall_style#set_font_color]], [[hall_style#tint_art]], [[screen_assign#_show_odds_change]].

### _odds_caption
`func _odds_caption(entry: Dictionary, chance: int, odds_word: String) -> String` · `Scripts/UI/Screens/screen_assign.gd:269`

The caption under the odds: the odds word, then what a win grows. At good odds for the quest's rank that is a stat to train (`TEXT_TRAIN_ON_WIN`), otherwise Pluck (`TEXT_PLUCK_ON_WIN`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | The quest entry | [[screen_assign#_show_party]] |
| `chance` | `int` | Party success chance, -1 = no party | [[hall_main#success_chance]] in [[screen_assign#_show_party]] |
| `odds_word` | `String` | `HallStyle.odds_look(chance).word` | [[hall_style#odds_look]] in [[screen_assign#_show_party]] |

**Returns:** `String`; just `odds_word` when `chance < 0`. Used as `%OddsWord` text in [[screen_assign#_show_party]] (`screen_assign.gd:259`).

**Called by:** [[screen_assign#_show_party]]. **Calls:** [[hall_main#trains_stat]], [[hall_main#trained_stat_options]], [[hall_main#pluck_gain_for]].

### _show_odds_change
`func _show_odds_change(chance: int) -> void` · `Scripts/UI/Screens/screen_assign.gd:283`

The odds number and bar. On the same quest, a new chance rolls the number, slides the bar, pops the circle, and floats "+12%" / "-12%" off the tapped row. Switching quests (or the first draw) just snaps.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `chance` | `int` | Party success chance (capped to 100 here; -1 = none) | [[hall_main#success_chance]] in [[screen_assign#_show_party]] |

**Side effects:** updates `_odds_quest_index` and `_shown_chance`; [[odds_bar#set_chance]], [[hall_fx#pop]], [[hall_fx#count]], [[hall_fx#float_text]] at [[hall_main#tap_point]] on `hall.fx_layer`.

**Called by:** [[screen_assign#_show_party]] (`screen_assign.gd:262`). **Calls:** [[odds_bar#set_chance]], [[hall_fx#pop]], [[hall_fx#count]], [[hall_fx#float_text]], [[hall_main#tap_point]].

### _show_writ_stamp
`func _show_writ_stamp(entry: Dictionary) -> void` · `Scripts/UI/Screens/screen_assign.gd:312`

A sent quest has SENT inked on it: animated right after Send (`hall.pending_fx.writ_stamp`), just there when looking at an earlier sent quest, lifted off when recalled or when the current quest changes.

**Parameters**: `entry` is the quest entry from [[screen_assign#refresh]].

**Side effects:** frees the old stamp when needed; [[hall_fx#stamp_onto]] on `%QuestCard`.

**Called by:** [[screen_assign#refresh]] (`screen_assign.gd:197`). **Calls:** [[hall_fx#stamp_onto]].

### stamp_point
`func stamp_point() -> Vector2` · `Scripts/UI/Screens/screen_assign.gd:328`

Where hall_main lands the DENIED stamp: the middle of the quest title, clamped inside the visible part of the scroll.

**Returns:** `Vector2` global position. Used by [[hall_main#deny_quest]] (`hall_main.gd:1031`) as the `HallFx.stamp_mark` position.

**Called by:** [[hall_main#deny_quest]] (`hall_main.gd:1031`). **Calls:** none.

### shake_writ
`func shake_writ() -> void` · `Scripts/UI/Screens/screen_assign.gd:335`

Deny: the quest writ shakes its head ([[hall_fx#shake]] with `DENY_SHAKE`).

**Called by:** [[hall_main#deny_quest]] (`hall_main.gd:1030`). **Calls:** [[hall_fx#shake]].

### _show_picker
`func _show_picker(entry: Dictionary) -> void` · `Scripts/UI/Screens/screen_assign.gd:347`

Lists every living adventurer, best fit for this quest first. Order: free (or pinned here), then those in another quest's party (greyed; tapping asks before moving them via [[overlay_move_confirm]]), then those who can't go (hospital bed, training). Within a group, most chance added first. With `HIDE_BUSY_OPTION` on, busy ones are hidden unless "Show busy" is on.

**Parameters**: `entry` is the quest entry from [[screen_assign#refresh]].

**Side effects:** rebuilds `%PickList` with [[pick_row (scene)]] rows (`setup(hall, entry, character, _move_confirm.open)`); sets heading, hint, toggle, empty states; [[hall_style#set_locked]] on `%HireButton` while hiring isn't taught.

**Called by:** [[screen_assign#refresh]] (`screen_assign.gd:199`).

**Calls:** [[hall_main#roster]], [[hall_style#is_dead]], [[screen_assign#_is_busy_elsewhere]], [[screen_assign#_pick_group]], [[hall_main#chance_added_by]], [[hall_style#clear_children]], [[hall_style#add_row]], [[pick_row#setup]], [[overlay_move_confirm#open]], [[hall_style#set_locked]], [[hall_main#is_locked]].

### _is_busy_elsewhere
`func _is_busy_elsewhere(entry: Dictionary, character: GuildCharacter) -> bool` · `Scripts/UI/Screens/screen_assign.gd:389`

**Returns:** `true` when `character` is in a party (picked or sent) for a quest other than `entry`'s. Used to group and hide picker entries.

**Called by:** [[screen_assign#_show_picker]] (`screen_assign.gd:354`), [[screen_assign#_pick_group]] (`:400`). **Calls:** [[hall_main#quest_index_of]].

### _pick_group
`func _pick_group(entry: Dictionary, character: GuildCharacter) -> int` · `Scripts/UI/Screens/screen_assign.gd:397`

**Returns:** `int` picker group: 0 free (or pinned here), 1 in another quest's party, 2 can't go (hospital bed, training). Used as the primary sort key in [[screen_assign#_show_picker]] (`screen_assign.gd:362`).

**Called by:** [[screen_assign#_show_picker]]. **Calls:** [[hall_main#can_go_on_quests]], [[screen_assign#_is_busy_elsewhere]].

### _show_footer
`func _show_footer(entry: Dictionary) -> void` · `Scripts/UI/Screens/screen_assign.gd:413`

Footer buttons depend on the quest's state (pinning anyone sends an open quest, so there is no Send button): open: Deny (with shield `-N`) and Back to Quests (the final battle has no Deny); sent: Recall and Back to Quests; denied: Quests and Reconsider. The left button is wood, the right gold.

**Parameters**: `entry` is the quest entry from [[screen_assign#refresh]].

**Side effects:** sets text, icon, locked state and width of `%LeftButton`, the deny cost tag, and `%RightButton` text. Deny is blank, greyed and inert until the tutorial teaches it (`FEATURE_DENY`); its labelled width is measured and held while locked.

**Called by:** [[screen_assign#refresh]] (`screen_assign.gd:200`). **Calls:** [[hall_main#can_deny_quest]], [[hall_style#set_locked]], [[hall_main#is_locked]], [[hall_style#icon_texture]], [[hall_rules#standing_for_deny]].

### _on_left_button_pressed
`func _on_left_button_pressed() -> void` · `Scripts/UI/Screens/screen_assign.gd:442`

Recall (sent), Quests (denied) or Deny (open), by the current quest's state.

**Called by:** `pressed` on `%LeftButton` (connected at `screen_assign.gd:150`). **Calls:** [[hall_main#recall_party]], [[hall_main#close_screen]], [[hall_main#deny_quest]].

### _on_right_button_pressed
`func _on_right_button_pressed() -> void` · `Scripts/UI/Screens/screen_assign.gd:453`

Reconsider (denied) or Back to Quests (open or sent).

**Called by:** `pressed` on `%RightButton` (connected at `screen_assign.gd:151`). **Calls:** [[hall_main#reconsider_quest]], [[hall_main#close_screen]].

## Suspected issues
- `_show_picker` sets `_pick_heading.text`, `_show_busy_toggle.visible` and the other static fields on every refresh although they never change (harmless).
- The class comment says "pinning anyone sends the quest", while `BUTTON_BACK_TO_QUESTS` doubles as both open and sent right button (by design).
