---
source: Scripts/UI/Shell/Header/hall_header.gd
class_name: HallHeader
extends: VBoxContainer
scene: "[[hall_header (scene)]]"
systems: ["[[Economy and Wallet]]", "[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]", "[[Day Cycle]]", "[[Run End]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# hall_header.gd

## Purpose
The top of the screen: the DAY tile, the next-boss countdown note, the gold and standing counters, the Menu button, and the red "last hero standing" strip under them. It also owns the counters' motion: numbers roll to new values, coins fly to what you paid for, and the night's earnings land at dawn. Tapping the coin or the shield drops [[popup_gold]] or [[popup_standing]]. Scene: [[hall_header (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `DRAKE_WARNING_DAYS` | const | Countdown turns red at this many days left or fewer (2). |
| `DRAKE_PULSES` | const | Pulses of the boss note on a morning inside the warning window (3). |
| `DRAKE_NOTE_PADDING_X` / `DRAKE_NOTE_PADDING_Y` | const | Padding in the boss note's torn paper, design px (8 / 6). |
| `COUNTER_ROLL_SECONDS` | const | Seconds a counter number takes to roll (0.5). |
| `COUNTER_POP` | const | Scale the counter pops to on change (1.22). |
| `COUNTER_GAIN_INK` / `COUNTER_LOSS_INK` | const | Counter flash colors (light green / light red). |
| `DELTA_GAIN_INK` / `DELTA_LOSS_INK` / `DELTA_OFFSET` | const | Floating "+40" / "-2" colors and start offset under the counter (design px, `(0, 58)`). |
| `STANDING_BOX_SIZE` | const | Standing shield box, design px (62x72), grown with the font scale. |
| `STANDING_MAX_FACTOR` | const | Cap on how far the font scale grows the standing box (1.5). |
| `FLY_ICON_SIZE` / `FLY_SECONDS` | const | Size (px) and flight time (s) of flying coins and shields (44 / 0.5). |
| `EARNINGS_COIN_COUNT` / `EARNINGS_COIN_GAP` / `EARNINGS_DELAY` | const | Coins that fly in at dawn (5), seconds between them (0.07) and before the first (0.2). |
| `TROUBLE_TITLE`, `TROUBLE_FAILURES_TEXT`, `TROUBLE_INJURIES_TEXT` | const | The milder gold "Guild in trouble" strip: title, "%d quests lost in %d days..." text and "Half the guild is hurt..." text. |
| `HEADER_*`, `DANGER_*`, `DELTA_GAIN`, `DELTA_LOSS` | const | Text formats for the day, countdown, danger strip and floating numbers. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_shown_counters` | var | Gold / standing number on screen now (-1 = not drawn yet). |
| `_held_counters` | var | Per counter: held still until [[hall_header#land_earnings]] or a coin lands. |
| `_shown_day` | var | Day on the DAY tile (-1 = not drawn yet). |
| `_day_value`, `_drake_*`, `_gold_*`, `_standing_*`, `_danger_*`, `_menu_button`, `_day_tile` | var | `@onready` nodes by unique name, see [[hall_header (scene)]]. |
| `_gold_popup`, `_standing_popup` | var | `%PopupGold` / `%PopupStanding`, typed [[header_popup]]. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Shell/Header/hall_header.gd:123`

Stores the hall, wires the Menu button and the counter taps, and sets up the two popups.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%MenuButton` to `hall.open_menu` ([[hall_main#open_menu]]); connects `gui_input` on `%GoldValueBox` and `%StandingValueBox` to [[hall_header#_on_counter_input]]; calls [[header_popup#setup]] on both popups.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_header#_trim_drake_note_padding]], [[header_popup#setup]], [[hall_main#open_menu]].

### _trim_drake_note_padding
`func _trim_drake_note_padding() -> void` · `Scripts/UI/Shell/Header/hall_header.gd:135`

Gives the boss note its own copy of the torn-paper style with `DRAKE_NOTE_PADDING_X/Y` padding (the shared style stays as it is).

**Returns:** nothing (returns early if the note has no `panel` stylebox).

**Side effects:** `add_theme_stylebox_override("panel", ...)` on `%DrakeNote`.

**Called by:** [[hall_header#setup]] (`hall_header.gd:126`).

**Calls:** none.

### _refresh_drake_countdown
`func _refresh_drake_countdown() -> void` · `Scripts/UI/Shell/Header/hall_header.gd:151`

The countdown to the next boss day: that boss quest's seal (BOSS, or FINAL for the last battle), then the days left over a "days" label. The number is always red; the label joins it at `DRAKE_WARNING_DAYS` or fewer.

**Returns:** nothing. A negative `hall.days_until_next_boss()` (no boss left, freeplay) hides the whole note. 0 days shows `!` over `today`.

**Side effects:** sets visibility, texts and colors of the drake nodes.

**Called by:** [[hall_header#refresh]] (`hall_header.gd:177`).

**Calls:** [[hall_main#days_until_next_boss]], [[hall_main#next_boss_is_final]], [[hall_style#style_icon_tag]], [[hall_style#pick_plural]], [[hall_style#set_font_color]].

### refresh
`func refresh() -> void` · `Scripts/UI/Shell/Header/hall_header.gd:173`

Redraws the day, the countdown, the counters and the danger strip, and refreshes any open popup.

**Returns:** nothing.

**Side effects:** resizes `%StandingValueBox` with [[hall_font_scale#px_vec]] (here, not in `setup`, so a text-size change follows).

**Called by:** [[hall_main#refresh]] (`hall_main.gd:1792`, `_header.refresh()`).

**Calls:** [[hall_font_scale#px_vec]], [[hall_header#_refresh_day_tile]], [[hall_header#_refresh_drake_countdown]], [[hall_header#_update_counter]], [[hall_header#_refresh_danger_strip]], [[header_popup#is_open]], [[popup_gold#refresh]], [[popup_standing#refresh]].

### _on_counter_input
`func _on_counter_input(event: InputEvent, popup: HeaderPopup, anchor: Control) -> void` · `Scripts/UI/Shell/Header/hall_header.gd:187`

A left mouse press on the coin or shield drops its popup and closes the other one.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | The input event | `gui_input` signal |
| `popup` | `HeaderPopup` | The popup to open | bound in [[hall_header#setup]] (`_gold_popup` or `_standing_popup`) |
| `anchor` | `Control` | The counter box the card drops from | bound in [[hall_header#setup]] (`_gold_box` or `_standing_box`) |

**Returns:** nothing; other events return early.

**Side effects:** [[header_popup#close]] on the other popup, [[header_popup#open]] on this one, `accept_event()`.

**Called by:** `gui_input` on `%GoldValueBox` and `%StandingValueBox` (connected at `hall_header.gd:129` and `:130`).

**Calls:** [[header_popup#close]], [[header_popup#open]].

### _refresh_danger_strip
`func _refresh_danger_strip() -> void` · `Scripts/UI/Shell/Header/hall_header.gd:199`

Shows the warning strip under the header. Red "last hero standing" while the guild is one death from falling (and the Game Over ledger isn't up). Otherwise, with no ledger up, a milder gold "Guild in trouble" strip when [[hall_main#trouble_reason]] is `"failures"` (text shows [[hall_main#recent_failures]] and `HallLedger.TROUBLE_WINDOW_DAYS`) or `"injuries"`. The red strip wins when both apply.

**Returns:** nothing.

**Side effects:** sets strip visibility, style and texts; plays `Sfx` `danger_warning` the moment it appears (either colour); the gold strip sets `GOLD_BG`, a `GOLD` icon and `GOLD_TEXT` title, the red one `RED_BG`/`RED`. Text depends on [[hall_ledger#is_short_of_recruit_gold]]: gold shortfall (price from `GuildCharacter.recruit_cost_for_day(GameState.day + 1)`) or low standing.

**Called by:** [[hall_header#refresh]] (`hall_header.gd:180`).

**Calls:** [[hall_main#last_living_hero]], [[hall_main#is_one_death_from_falling]], [[hall_main#trouble_reason]], [[hall_main#recent_failures]], [[hall_style#style_panel]], [[hall_style#set_font_color]], [[hall_ledger#is_short_of_recruit_gold]], [[character_resource#recruit_cost_for_day]].

### _refresh_day_tile
`func _refresh_day_tile() -> void` · `Scripts/UI/Shell/Header/hall_header.gd:233`

Draws the day number. A new day flips the tile (the number changes edge-on, once the dawn wash has cleared) and, inside `DRAKE_WARNING_DAYS`, pulses the boss note.

**Returns:** nothing; does nothing if the day is unchanged. The first draw and Reduced Motion set the text directly (no pulse).

**Side effects:** [[hall_fx#flip]] on `%DayTile`, [[hall_fx#pulse]] on `%DrakeNote`.

**Called by:** [[hall_header#refresh]] (`hall_header.gd:176`).

**Calls:** [[hall_fx#flip]], [[hall_fx#pulse]], [[hall_main#days_until_next_boss]].

### hold_counters
`func hold_counters() -> void` · `Scripts/UI/Shell/Header/hall_header.gd:251`

End Day: holds both counters still until [[hall_header#land_earnings]] at dawn.

**Returns:** nothing. **Side effects:** sets `_held_counters` gold and standing to true.

**Called by:** [[hall_main#end_day]] (`hall_main.gd:1538`, `_header.hold_counters()`).

**Calls:** none.

### land_earnings
`func land_earnings() -> void` · `Scripts/UI/Shell/Header/hall_header.gd:259`

Dawn: releases the held counters. A gain flies in from the middle of the screen as a few coins / shields and the counter rolls up as the last one lands; a loss or no change just rolls.

**Returns:** nothing.

**Side effects:** per counter plays `coin_land` / `standing_land` through `Sfx.play` (reduced motion, one clink) or `Sfx.play_after` (per flying coin); [[hall_fx#fly]] up to `EARNINGS_COIN_COUNT` icons from the center of `hall.fx_layer`; the last one's landing calls [[hall_header#_release_counter]].

**Called by:** [[hall_main#start_new_day]] (`hall_main.gd:1673`, `_header.land_earnings()`).

**Calls:** [[hall_header#_counter_value]], [[hall_header#_counter_art]], [[hall_header#_release_counter]], [[hall_fx#fly]].

### pay_fx
`func pay_fx(kind: String) -> void` · `Scripts/UI/Shell/Header/hall_header.gd:284`

Gold or standing just paid for what the player tapped: a coin or shield flies from the counter to the tap point (the counter drops at once).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `kind` | `String` | `"gold"` or `"standing"` | literal at each call site |

**Returns:** nothing.

**Side effects:** `Sfx` `gold_spend` or `standing_lose`; [[hall_fx#fly]] from the art to [[hall_main#tap_point]].

**Called by:** [[hall_main#deny_quest]] (`hall_main.gd:1026`, `"standing"`), [[hall_main#hire]] (`:1108`, `"gold"`), [[hall_main#release]] (`:1150`, `"standing"`), [[hall_main#upgrade_building]] (`:1170`, `"gold"`), [[hall_main#buy_item]] (`:1190`, `"gold"`).

**Calls:** [[hall_header#_counter_art]], [[hall_fx#fly]], [[hall_main#tap_point]].

### _counter_value
`func _counter_value(kind: String) -> int` · `Scripts/UI/Shell/Header/hall_header.gd:290`

**Returns:** `GameState.gold` for `"gold"`, else `GameState.standing`. **Called by:** [[hall_header#land_earnings]], [[hall_header#_update_counter]]. **Calls:** none.

### _counter_label
`func _counter_label(kind: String) -> Label` · `Scripts/UI/Shell/Header/hall_header.gd:294`

**Returns:** `%GoldValue` or `%StandingValue`. **Called by:** [[hall_header#_update_counter]]. **Calls:** none.

### _counter_box
`func _counter_box(kind: String) -> Control` · `Scripts/UI/Shell/Header/hall_header.gd:299`

The counter's box (what pops). **Returns:** `%GoldValueBox` or `%StandingValueBox`. **Called by:** [[hall_header#_update_counter]]. **Calls:** none.

### _counter_art
`func _counter_art(kind: String) -> TextureRect` · `Scripts/UI/Shell/Header/hall_header.gd:303`

The counter's art (coin / shield, what flies). **Returns:** `%Coin` or `%Shield`. **Called by:** [[hall_header#land_earnings]], [[hall_header#pay_fx]]. **Calls:** none.

### _update_counter
`func _update_counter(kind: String) -> void` · `Scripts/UI/Shell/Header/hall_header.gd:310`

Draws a counter. A changed value rolls, pops, flashes green (gain) or red (loss), and a "+40" / "-2" floats under it. A held counter (with a value already drawn) waits.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `kind` | `String` | `"gold"` or `"standing"` | literals in [[hall_header#refresh]]; `kind` in [[hall_header#_release_counter]] |

**Returns:** nothing.

**Side effects:** updates `_shown_counters`; [[hall_fx#count]], [[hall_fx#pop]], [[hall_fx#flash_text]], [[hall_fx#float_text]] (on `hall.fx_layer`). First draw or an unchanged value only sets the text.

**Called by:** [[hall_header#refresh]] (`hall_header.gd:178`, `:179`), [[hall_header#_release_counter]] (`:333`).

**Calls:** [[hall_header#_counter_value]], [[hall_header#_counter_label]], [[hall_header#_counter_box]], [[hall_fx#count]], [[hall_fx#pop]], [[hall_fx#flash_text]], [[hall_fx#float_text]], [[hall_font_scale#px_vec]].

### _release_counter
`func _release_counter(kind: String) -> void` · `Scripts/UI/Shell/Header/hall_header.gd:331`

Lets a held counter catch up to the real value.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `kind` | `String` | `"gold"` or `"standing"` | loop variable in [[hall_header#land_earnings]] |

**Returns:** nothing. **Side effects:** clears the held flag, then [[hall_header#_update_counter]].

**Called by:** [[hall_header#land_earnings]] (`hall_header.gd:268`, directly; `:275`, bound as the last coin's landing callback).

**Calls:** [[hall_header#_update_counter]].

## Suspected issues
- None found. Note `_held_counters` is only cleared by [[hall_header#land_earnings]]; a held counter would stay frozen if `end_day` held it and `start_new_day` never ran (not traced beyond the two call sites).
